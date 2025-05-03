from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile, Form
from sqlalchemy.orm import Session
from typing import List, Optional
import os
import uuid
from datetime import datetime

import schemas
import models
from database import get_db
from routes.auth import get_current_active_user
from config import settings

router = APIRouter()

# Helper functions
def get_product(db: Session, product_id: int):
    return db.query(models.Product).filter(models.Product.id == product_id).first()

# Routes
@router.post("/", response_model=schemas.ProductResponse)
def create_product(
    product: schemas.ProductCreate,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    # Check if category exists
    category = db.query(models.Category).filter(models.Category.id == product.category_id).first()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    # Check if SKU already exists
    sku_exists = db.query(models.Product).filter(models.Product.sku == product.sku).first()
    if sku_exists:
        raise HTTPException(status_code=400, detail="SKU already exists")
    
    # Create product
    db_product = models.Product(
        **product.dict(exclude={"composite_items"}),
        owner_id=current_user.id
    )
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    
    # If it's a composite product, add components
    if product.is_composite and product.composite_items:
        for item in product.composite_items:
            # Check if component product exists
            component = db.query(models.Product).filter(models.Product.id == item.component_product_id).first()
            if not component:
                raise HTTPException(status_code=404, detail=f"Component product with ID {item.component_product_id} not found")
            
            # Add component to composite product
            db_composite_item = models.CompositeProductItem(
                parent_product_id=db_product.id,
                component_product_id=item.component_product_id,
                quantity=item.quantity
            )
            db.add(db_composite_item)
        
        db.commit()
        db.refresh(db_product)
    
    return db_product

@router.get("/", response_model=List[schemas.ProductResponse])
def read_products(
    skip: int = 0,
    limit: int = 100,
    category_id: Optional[int] = None,
    search: Optional[str] = None,
    is_service: Optional[bool] = None,
    is_composite: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    query = db.query(models.Product)
    
    # Apply filters
    if category_id:
        query = query.filter(models.Product.category_id == category_id)
    if search:
        query = query.filter(
            (models.Product.name.ilike(f"%{search}%")) | 
            (models.Product.sku.ilike(f"%{search}%")) |
            (models.Product.description.ilike(f"%{search}%"))
        )
    if is_service is not None:
        query = query.filter(models.Product.is_service == is_service)
    if is_composite is not None:
        query = query.filter(models.Product.is_composite == is_composite)
    
    products = query.offset(skip).limit(limit).all()
    return products

@router.get("/{product_id}", response_model=schemas.ProductResponse)
def read_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    db_product = get_product(db, product_id)
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    return db_product

@router.put("/{product_id}", response_model=schemas.ProductResponse)
def update_product(
    product_id: int,
    product: schemas.ProductUpdate,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    db_product = get_product(db, product_id)
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Check if user has permission (admin, manager, or owner)
    if current_user.role not in [schemas.UserRoleEnum.ADMIN, schemas.UserRoleEnum.MANAGER] and db_product.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    # Update product fields if provided
    for key, value in product.dict(exclude_unset=True).items():
        setattr(db_product, key, value)
    
    db_product.updated_at = datetime.now()
    db.commit()
    db.refresh(db_product)
    return db_product

@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    db_product = get_product(db, product_id)
    if db_product is None:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Check if user has permission (admin, manager, or owner)
    if current_user.role not in [schemas.UserRoleEnum.ADMIN, schemas.UserRoleEnum.MANAGER] and db_product.owner_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    
    db.delete(db_product)
    db.commit()
    return None

@router.post("/upload-image")
async def upload_product_image(
    file: UploadFile = File(...),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    # Check file size
    contents = await file.read()
    if len(contents) > settings.MAX_UPLOAD_SIZE:
        raise HTTPException(status_code=413, detail="File too large")
    
    # Check file type
    allowed_types = ["image/jpeg", "image/png", "image/gif"]
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=415, detail="Unsupported file type")
    if file.content_type not in allowed_types:
        raise HTTPException(status_code=415, detail="Unsupported file type")
    
    # Create upload directory if it doesn't exist
    os.makedirs(settings.UPLOAD_DIRECTORY, exist_ok=True)
    
    # Generate unique filename
    file_extension = file.filename.split(".")[-1]
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    file_path = os.path.join(settings.UPLOAD_DIRECTORY, unique_filename)
    
    # Write file
    with open(file_path, "wb") as f:
        f.write(contents)
    
    # Return file URL
    file_url = f"/uploads/{unique_filename}"
    return {"filename": unique_filename, "url": file_url}

@router.get("/low-stock", response_model=List[schemas.ProductResponse])
def get_low_stock_products(
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    # Get products where quantity is below reorder level
    products = db.query(models.Product).filter(
        models.Product.quantity <= models.Product.reorder_level
    ).all()
    return products