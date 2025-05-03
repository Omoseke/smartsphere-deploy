from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import uuid

import schemas
import models
from database import get_db
from routes.auth import get_current_active_user

router = APIRouter()

@router.post("/", response_model=schemas.OrderResponse)
def create_order(
    order: schemas.OrderCreate,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    # Generate unique order number
    order_number = f"ORD-{uuid.uuid4().hex[:8].upper()}"
    
    # Create order
    db_order = models.Order(
        order_number=order_number,
        status=order.status,
        total_amount=order.total_amount,
        user_id=current_user.id,
        supplier_id=order.supplier_id,
        notes=order.notes
    )
    db.add(db_order)
    db.commit()
    db.refresh(db_order)
    
    # Add order items
    for item in order.items:
        # Check if product exists
        product = db.query(models.Product).filter(models.Product.id == item.product_id).first()
        if not product:
            raise HTTPException(status_code=404, detail=f"Product with ID {item.product_id} not found")
        
        # Add order item
        db_order_item = models.OrderItem(
            order_id=db_order.id,
            product_id=item.product_id,
            quantity=item.quantity,
            unit_price=item.unit_price
        )
        db.add(db_order_item)
        
        # Update inventory if not a service
        if not product.is_service:
            # Create inventory transaction
            db_transaction = models.InventoryTransaction(
                product_id=item.product_id,
                quantity=item.quantity,
                transaction_type=models.TransactionType.SALE,
                reference_id=str(db_order.id),
                notes=f"Order {order_number}"
            )
            db.add(db_transaction)
            
            # Update product quantity
            if product.quantity < item.quantity:
                raise HTTPException(status_code=400, detail=f"Not enough inventory for product {product.name}")
            product.quantity -= item.quantity
    
    db.commit()
    db.refresh(db_order)
    return db_order

@router.get("/", response_model=List[schemas.OrderResponse])
def read_orders(
    skip: int = 0,
    limit: int = 100,
    status: Optional[schemas.OrderStatusEnum] = None,
    supplier_id: Optional[int] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    query = db.query(models.Order)
    
    # Apply filters
    if status:
        query = query.filter(models.Order.status == status)
    if supplier_id:
        query = query.filter(models.Order.supplier_id == supplier_id)
    if start_date:
        query = query.filter(models.Order.created_at >= start_date)
    if end_date:
        query = query.filter(models.Order.created_at <= end_date)
    
    # Regular users can only see their own orders
    if current_user.role not in [schemas.UserRoleEnum.ADMIN, schemas.UserRoleEnum.MANAGER]:
        query = query.filter(models.Order.user_id == current_user.id)
    
    orders = query.order_by(models.Order.created_at.desc()).offset(skip).limit(limit).all()
    return orders

@router.get("/{order_id}", response_model=schemas.OrderResponse)
def read_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    db_order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if db_order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Check if user has permission to view this order
    if current_user.role not in [schemas.UserRoleEnum.ADMIN, schemas.UserRoleEnum.MANAGER] and db_order.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    return db_order

@router.put("/{order_id}", response_model=schemas.OrderResponse)
def update_order(
    order_id: int,
    order: schemas.OrderUpdate,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    db_order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if db_order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    
    # Check if user has permission to update this order
    if current_user.role not in [schemas.UserRoleEnum.ADMIN, schemas.UserRoleEnum.MANAGER] and db_order.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    # Update order fields if provided
    for key, value in order.dict(exclude_unset=True).items():
        setattr(db_order, key, value)
    
    db_order.updated_at = datetime.now()
    db.commit()
    db.refresh(db_order)
    return db_order