from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from routers import users, products, orders, rag
from database.connection import get_db, engine, Base
from utils import get_hostname
import os
from datetime import datetime

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="EKS FastAPI with SQLAlchemy", version="1.0.0")

# Include routers
app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(products.router, prefix="/products", tags=["products"])
app.include_router(orders.router, prefix="/orders", tags=["orders"])
app.include_router(rag.router)

@app.get("/")
async def root():
    return {
        "message": "Hello from FastAPI on EKS with SQLAlchemy!",
        "timestamp": datetime.now().isoformat(),
        "hostname": get_hostname(),
        "version": "1.0.0",
        "status": "running"
    }

@app.get("/health")
async def health_check(db: Session = Depends(get_db)):
    try:
        # Test database connection
        db.execute("SELECT 1")
        db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)}"
    
    return {
        "status": "healthy", 
        "service": "fastapi-app",
        "hostname": get_hostname(),
        "database": db_status,
        "timestamp": datetime.now().isoformat()
    }

@app.get("/stats")
async def get_stats(db: Session = Depends(get_db)):
    from models.user import User
    from models.product import Product
    from models.order import Order
    
    total_users = db.query(User).count()
    total_products = db.query(Product).count()
    total_orders = db.query(Order).count()
    
    return {
        "total_users": total_users,
        "total_products": total_products,
        "total_orders": total_orders,
        "server_hostname": get_hostname(),
        "timestamp": datetime.now().isoformat()
    }