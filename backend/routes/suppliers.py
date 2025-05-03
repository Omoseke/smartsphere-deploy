from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

import schemas
import models
from database import get_db
from routes.auth import get_current_active_user

router = APIRouter()

@router.post("/", response_model=schemas.SupplierResponse)
def create_supplier(
    supplier: schemas.SupplierCreate,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    # Check if user has permission (admin or manager)
    if current_user.role not in [schemas.UserRoleEnum.ADMIN, schemas.UserRoleEnum.MANAGER]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    # Create supplier
    db_supplier = models.Supplier(**supplier.dict())
    db.add(db_supplier)
    db.commit()
    db.refresh(db_supplier)
    return db_supplier

@router.get("/", response_model=List[schemas.SupplierResponse])
def read_suppliers(
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    query = db.query(models.Supplier)
    
    # Apply filters
    if search:
        query = query.filter(
            (models.Supplier.name.ilike(f"%{search}%")) | 
            (models.Supplier.contact_name.ilike(f"%{search}%")) |
            (models.Supplier.email.ilike(f"%{search}%"))
        )
    
    suppliers = query.offset(skip).limit(limit).all()
    return suppliers

@router.get("/{supplier_id}", response_model=schemas.SupplierResponse)
def read_supplier(
    supplier_id: int,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    db_supplier = db.query(models.Supplier).filter(models.Supplier.id == supplier_id).first()
    if db_supplier is None:
        raise HTTPException(status_code=404, detail="Supplier not found")
    return db_supplier

@router.put("/{supplier_id}", response_model=schemas.SupplierResponse)
def update_supplier(
    supplier_id: int,
    supplier: schemas.SupplierUpdate,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    # Check if user has permission (admin or manager)
    if current_user.role not in [schemas.UserRoleEnum.ADMIN, schemas.UserRoleEnum.MANAGER]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    db_supplier = db.query(models.Supplier).filter(models.Supplier.id == supplier_id).first()
    if db_supplier is None:
        raise HTTPException(status_code=404, detail="Supplier not found")
    
    # Update supplier fields if provided
    for key, value in supplier.dict(exclude_unset=True).items():
        setattr(db_supplier, key, value)
    
    db_supplier.updated_at = datetime.now()
    db.commit()
    db.refresh(db_supplier)
    return db_supplier

@router.delete("/{supplier_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_supplier(
    supplier_id: int,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    # Check if user has permission (admin or manager)
    if current_user.role not in [schemas.UserRoleEnum.ADMIN, schemas.UserRoleEnum.MANAGER]:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    db_supplier = db.query(models.Supplier).filter(models.Supplier.id == supplier_id).first()
    if db_supplier is None:
        raise HTTPException(status_code=404, detail="Supplier not found")
    
    # Check if supplier has orders
    has_orders = db.query(models.Order).filter(models.Order.supplier_id == supplier_id).first()
    if has_orders:
        raise HTTPException(status_code=400, detail="Cannot delete supplier with existing orders")
    
    db.delete(db_supplier)
    db.commit()
    return None