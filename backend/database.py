from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Boolean, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv('config.env')

# Database URL from environment
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./mtc_nanna.db")

# Create SQLAlchemy engine
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
)

# Create SessionLocal class
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Create Base class
Base = declarative_base()

# Database dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Database models
class DPR(Base):
    __tablename__ = "dpr"
    
    id = Column(Integer, primary_key=True, index=True)
    household_id = Column(String, index=True)
    respondent_name = Column(String)
    age = Column(Integer)
    gender = Column(String)
    education = Column(String)
    occupation = Column(String)
    income_level = Column(String)
    latitude = Column(Float)
    longitude = Column(Float)
    created_at = Column(DateTime)
    is_synced = Column(Boolean, default=False)

class MPR(Base):
    __tablename__ = "mpr"
    
    id = Column(Integer, primary_key=True, index=True)
    household_id = Column(String, index=True)
    purchase_date = Column(String)
    textile_type = Column(String)
    quantity = Column(Integer)
    price = Column(Float)
    purchase_location = Column(String)
    latitude = Column(Float)
    longitude = Column(Float)
    created_at = Column(DateTime)
    is_synced = Column(Boolean, default=False)

class FP(Base):
    __tablename__ = "fp"
    
    id = Column(Integer, primary_key=True, index=True)
    centre_name = Column(String)
    centre_code = Column(String)
    panel_size = Column(Integer)
    mpr_collected = Column(Integer)
    not_collected = Column(Integer)
    with_purchase_data = Column(Integer)
    nil_mprs = Column(Integer)
    nil_serial_nos = Column(Integer)
    latitude = Column(Float)
    longitude = Column(Float)
    created_at = Column(DateTime)
    is_synced = Column(Boolean, default=False)

# Create tables
def create_tables():
    Base.metadata.create_all(bind=engine) 