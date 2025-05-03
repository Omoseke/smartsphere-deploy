from pydantic import BaseModel, EmailStr, Field, validator
from typing import List, Optional, Union
from datetime import datetime
from enum import Enum

# Enums
class UserRoleEnum(str, Enum):
    ADMIN = "admin"
    MANAGER = "manager"
    STAFF = "staff"
    VIEWER = "viewer"

class OrderStatusEnum(str, Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    SHIPPED = "shipped"
    DELIVERED = "delivered"
    CANCELLED = "cancelled"
    RETURNED = "returned"

class TransactionTypeEnum(str, Enum):
    PURCHASE = "purchase"
    SALE = "sale"
    ADJUSTMENT = "adjustment"
    RETURN = "return"
    TRANSFER = "transfer"

# Base schemas
class UserBase(BaseModel):
    email: EmailStr
    username: str
    full_name: Optional[str] = None
    role: Optional[UserRoleEnum] = UserRoleEnum.STAFF
    preferred_language: Optional[str] = "en"

class CategoryBase(BaseModel):
    name: str
    description: Optional[str] = None

class ProductBase(BaseModel):
    name: str
    description: Optional[str] = None
    sku: str
    barcode: Optional[str] = None
    price: float = Field(..., gt=0)
    cost: float = Field(..., ge=0)
    quantity: int = Field(0, ge=0)
    reorder_level: int = Field(10, ge=0)
    is_service: bool = False
    is_composite: bool = False
    image_url: Optional[str] = None
    category_id: int

class SupplierBase(BaseModel):
    name: str
    contact_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    address: Optional[str] = None

class OrderBase(BaseModel):
    status: OrderStatusEnum = OrderStatusEnum.PENDING
    total_amount: float = Field(..., ge=0)
    supplier_id: Optional[int] = None
    notes: Optional[str] = None

class OrderItemBase(BaseModel):
    product_id: int
    quantity: int = Field(..., gt=0)
    unit_price: float = Field(..., gt=0)

class InventoryTransactionBase(BaseModel):
    product_id: int
    quantity: int
    transaction_type: TransactionTypeEnum
    reference_id: Optional[str] = None
    notes: Optional[str] = None

class CompositeProductItemBase(BaseModel):
    component_product_id: int
    quantity: int = Field(..., gt=0)

# Create schemas
class UserCreate(UserBase):
    password: str

class CategoryCreate(CategoryBase):
    pass

class ProductCreate(ProductBase):
    composite_items: Optional[List[CompositeProductItemBase]] = None

class SupplierCreate(SupplierBase):
    pass

class OrderItemCreate(OrderItemBase):
    pass

class OrderCreate(OrderBase):
    items: List[OrderItemCreate]

class InventoryTransactionCreate(InventoryTransactionBase):
    pass

# Update schemas
class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    username: Optional[str] = None
    full_name: Optional[str] = None
    role: Optional[UserRoleEnum] = None
    preferred_language: Optional[str] = None
    is_active: Optional[bool] = None

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    sku: Optional[str] = None
    barcode: Optional[str] = None
    price: Optional[float] = None
    cost: Optional[float] = None
    quantity: Optional[int] = None
    reorder_level: Optional[int] = None
    is_service: Optional[bool] = None
    is_composite: Optional[bool] = None
    image_url: Optional[str] = None
    category_id: Optional[int] = None

class SupplierUpdate(BaseModel):
    name: Optional[str] = None
    contact_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    address: Optional[str] = None

class OrderUpdate(BaseModel):
    status: Optional[OrderStatusEnum] = None
    total_amount: Optional[float] = None
    supplier_id: Optional[int] = None
    notes: Optional[str] = None

# Response schemas
class UserResponse(UserBase):
    id: int
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class CategoryResponse(CategoryBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class CompositeProductItemResponse(CompositeProductItemBase):
    id: int
    parent_product_id: int

    class Config:
        from_attributes = True

class ProductResponse(ProductBase):
    id: int
    owner_id: int
    created_at: datetime
    updated_at: datetime
    composite_items: Optional[List[CompositeProductItemResponse]] = None

    class Config:
        from_attributes = True

class SupplierResponse(SupplierBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class OrderItemResponse(OrderItemBase):
    id: int
    order_id: int
    product: ProductResponse

    class Config:
        from_attributes = True

class OrderResponse(OrderBase):
    id: int
    order_number: str
    user_id: int
    created_at: datetime
    updated_at: datetime
    items: List[OrderItemResponse]

    class Config:
        from_attributes = True

class InventoryTransactionResponse(InventoryTransactionBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

# Authentication schemas
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

# Dashboard schemas
class DashboardStats(BaseModel):
    total_products: int
    low_stock_products: int
    total_orders: int
    pending_orders: int
    total_revenue: float
    total_profit: float

# Analytics schemas
class SalesAnalytics(BaseModel):
    period: str
    total_sales: float
    total_orders: int
    average_order_value: float

class ProductAnalytics(BaseModel):
    product_id: int
    product_name: str
    total_sold: int
    total_revenue: float
    profit_margin: float

class SupplierAnalytics(BaseModel):
    supplier_id: int
    supplier_name: str
    total_orders: int
    total_spent: float
    on_time_delivery_rate: float