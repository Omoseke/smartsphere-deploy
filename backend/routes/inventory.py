from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

import schemas
import models
from database import get_db
from routes.auth import get_current_active_user

router = APIRouter()

@router.post("/transactions", response_model=schemas.InventoryTransactionResponse)
def create_inventory_transaction(
    transaction: schemas.InventoryTransactionCreate,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    # Check if product exists
    product = db.query(models.Product).filter(models.Product.id == transaction.product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Create transaction
    db_transaction = models.InventoryTransaction(**transaction.dict())
    db.add(db_transaction)
    
    # Update product quantity based on transaction type
    if transaction.transaction_type == schemas.TransactionTypeEnum.PURCHASE:
        product.quantity += transaction.quantity
    elif transaction.transaction_type == schemas.TransactionTypeEnum.SALE:
        if product.quantity < transaction.quantity:
            raise HTTPException(status_code=400, detail="Not enough inventory")
        product.quantity -= transaction.quantity
    elif transaction.transaction_type == schemas.TransactionTypeEnum.ADJUSTMENT:
        product.quantity = transaction.quantity
    elif transaction.transaction_type == schemas.TransactionTypeEnum.RETURN:
        product.quantity += transaction.quantity
    elif transaction.transaction_type == schemas.TransactionTypeEnum.TRANSFER:
        if product.quantity < transaction.quantity:
            raise HTTPException(status_code=400, detail="Not enough inventory")
        product.quantity -= transaction.quantity
    
    db.commit()
    db.refresh(db_transaction)
    return db_transaction

@router.get("/transactions", response_model=List[schemas.InventoryTransactionResponse])
def read_inventory_transactions(
    skip: int = 0,
    limit: int = 100,
    product_id: Optional[int] = None,
    transaction_type: Optional[schemas.TransactionTypeEnum] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    query = db.query(models.InventoryTransaction)
    
    # Apply filters
    if product_id:
        query = query.filter(models.InventoryTransaction.product_id == product_id)
    if transaction_type:
        query = query.filter(models.InventoryTransaction.transaction_type == transaction_type)
    if start_date:
        query = query.filter(models.InventoryTransaction.created_at >= start_date)
    if end_date:
        query = query.filter(models.InventoryTransaction.created_at <= end_date)
    
    transactions = query.order_by(models.InventoryTransaction.created_at.desc()).offset(skip).limit(limit).all()
    return transactions

@router.get("/stock-history/{product_id}", response_model=List[schemas.InventoryTransactionResponse])
def read_product_stock_history(
    product_id: int,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    # Check if product exists
    product = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Get product's inventory transactions
    transactions = db.query(models.InventoryTransaction).filter(
        models.InventoryTransaction.product_id == product_id
    ).order_by(models.InventoryTransaction.created_at.desc()).offset(skip).limit(limit).all()
    
    return transactions