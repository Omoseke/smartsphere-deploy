from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from typing import List, Optional
from datetime import datetime, timedelta

import schemas
import models
from database import get_db
from routes.auth import get_current_active_user

router = APIRouter()

@router.get("/dashboard", response_model=schemas.DashboardStats)
def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    # Get total products
    total_products = db.query(func.count(models.Product.id)).scalar()
    
    # Get low stock products
    low_stock_products = db.query(func.count(models.Product.id)).filter(
        models.Product.quantity <= models.Product.reorder_level
    ).scalar()
    
    # Get total orders
    total_orders = db.query(func.count(models.Order.id)).scalar()
    
    # Get pending orders
    pending_orders = db.query(func.count(models.Order.id)).filter(
        models.Order.status == models.OrderStatus.PENDING
    ).scalar()
    
    # Get total revenue
    total_revenue = db.query(func.sum(models.Order.total_amount)).scalar() or 0
    
    # Calculate total profit (simplified)
    total_profit = db.query(
        func.sum(
            (models.OrderItem.unit_price - models.Product.cost) * models.OrderItem.quantity
        )
    ).join(
        models.Product, models.OrderItem.product_id == models.Product.id
    ).scalar() or 0
    
    return {
        "total_products": total_products,
        "low_stock_products": low_stock_products,
        "total_orders": total_orders,
        "pending_orders": pending_orders,
        "total_revenue": total_revenue,
        "total_profit": total_profit
    }

@router.get("/sales", response_model=List[schemas.SalesAnalytics])
def get_sales_analytics(
    period: str = Query(..., description="Period type: daily, weekly, monthly, yearly"),
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    # Set default date range if not provided
    if not end_date:
        end_date = datetime.now()
    
    if not start_date:
        if period == "daily":
            start_date = end_date - timedelta(days=30)  # Last 30 days
        elif period == "weekly":
            start_date = end_date - timedelta(weeks=12)  # Last 12 weeks
        elif period == "monthly":
            start_date = end_date - timedelta(days=365)  # Last 12 months
        elif period == "yearly":
            start_date = end_date - timedelta(days=5*365)  # Last 5 years
        else:
            raise HTTPException(status_code=400, detail="Invalid period type")
    
    # Query sales data based on period
    result = []
    
    if period == "daily":
        # Group by day
        sales_data = db.query(
            func.date(models.Order.created_at).label("date"),
            func.sum(models.Order.total_amount).label("total_sales"),
            func.count(models.Order.id).label("total_orders")
        ).filter(
            models.Order.created_at.between(start_date, end_date)
        ).group_by(
            func.date(models.Order.created_at)
        ).order_by(
            func.date(models.Order.created_at)
        ).all()
        
        for data in sales_data:
            result.append({
                "period": data.date.strftime("%Y-%m-%d"),
                "total_sales": data.total_sales,
                "total_orders": data.total_orders,
                "average_order_value": data.total_sales / data.total_orders if data.total_orders > 0 else 0
            })
    
    elif period == "weekly":
        # Group by week
        sales_data = db.query(
            func.date_trunc("week", models.Order.created_at).label("week"),
            func.sum(models.Order.total_amount).label("total_sales"),
            func.count(models.Order.id).label("total_orders")
        ).filter(
            models.Order.created_at.between(start_date, end_date)
        ).group_by(
            func.date_trunc("week", models.Order.created_at)
        ).order_by(
            func.date_trunc("week", models.Order.created_at)
        ).all()
        
        for data in sales_data:
            result.append({
                "period": data.week.strftime("%Y-%m-%d"),
                "total_sales": data.total_sales,
                "total_orders": data.total_orders,
                "average_order_value": data.total_sales / data.total_orders if data.total_orders > 0 else 0
            })
    
    elif period == "monthly":
        # Group by month
        sales_data = db.query(
            func.date_trunc("month", models.Order.created_at).label("month"),
            func.sum(models.Order.total_amount).label("total_sales"),
            func.count(models.Order.id).label("total_orders")
        ).filter(
            models.Order.created_at.between(start_date, end_date)
        ).group_by(
            func.date_trunc("month", models.Order.created_at)
        ).order_by(
            func.date_trunc("month", models.Order.created_at)
        ).all()
        
        for data in sales_data:
            result.append({
                "period": data.month.strftime("%Y-%m"),
                "total_sales": data.total_sales,
                "total_orders": data.total_orders,
                "average_order_value": data.total_sales / data.total_orders if data.total_orders > 0 else 0
            })
    
    elif period == "yearly":
        # Group by year
        sales_data = db.query(
            func.date_trunc("year", models.Order.created_at).label("year"),
            func.sum(models.Order.total_amount).label("total_sales"),
            func.count(models.Order.id).label("total_orders")
        ).filter(
            models.Order.created_at.between(start_date, end_date)
        ).group_by(
            func.date_trunc("year", models.Order.created_at)
        ).order_by(
            func.date_trunc("year", models.Order.created_at)
        ).all()
        
        for data in sales_data:
            result.append({
                "period": data.year.strftime("%Y"),
                "total_sales": data.total_sales,
                "total_orders": data.total_orders,
                "average_order_value": data.total_sales / data.total_orders if data.total_orders > 0 else 0
            })
    
    return result

@router.get("/top-products", response_model=List[schemas.ProductAnalytics])
def get_top_products(
    limit: int = 10,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_user: schemas.UserResponse = Depends(get_current_active_user)
):
    # Set default date range if not provided
    if not end_date:
        end_date = datetime.now()
    if not start_date:
        start_date = end_date - timedelta(days=30)  # Last 30 days
    
    # Query top products by sales
    top_products = db.query(
        models.Product.id.label("product_id"),
        models.Product.name.label("product_name"),
        func.sum(models.OrderItem.quantity).label("total_sold"),
        func.sum(models.OrderItem.unit_price * models.OrderItem.quantity).label("total_revenue"),
        (func.sum(models.OrderItem.unit_price * models.OrderItem.quantity) - func.sum(models.Product.cost * models.OrderItem.quantity)) / func.sum(models.OrderItem.unit_price * models.OrderItem.quantity) * 100.0
        .label("profit_margin")
    ).join(
        models.OrderItem, models.Product.id == models.OrderItem.product_id
    ).join(
        models.Order, models.OrderItem.order_id == models.Order.id
    ).filter(
        models.Order.created_at.between(start_date, end_date)
    ).group_by(
        models.Product.id, models.Product.name
    ).order_by(
        desc("total_revenue")
    ).limit(limit).all()
    
    result = []
    for product in top_products:
        result.append({
            "product_id": product.product_id,
            "product_name": product.product_name,
            "total_sold": product.total_sold,
            "total_revenue": product.total_revenue,
            "profit_margin": product.profit_margin
        })
    
    return result