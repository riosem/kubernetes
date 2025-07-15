from database.connection import engine, Base
from models.user import User
from models.product import Product
from models.order import Order

def init_database():
    # Create all tables
    Base.metadata.create_all(bind=engine)
    print("Database tables created successfully!")

if __name__ == "__main__":
    init_database()