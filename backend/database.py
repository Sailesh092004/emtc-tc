from sqlalchemy import create_engine, Column, Integer, String, Float, DateTime, Boolean, Text, JSON
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
    name_and_address = Column(String)
    district = Column(String)
    state = Column(String)
    family_size = Column(Integer)
    income_group = Column(String)
    centre_code = Column(String)
    return_no = Column(String)
    month_and_year = Column(String)
    household_members = Column(JSON)  # Store as JSON array
    latitude = Column(Float)
    longitude = Column(Float)
    otp_code = Column(String)
    created_at = Column(DateTime)
    is_synced = Column(Boolean, default=False)

class MPR(Base):
    __tablename__ = "mpr"
    
    id = Column(Integer, primary_key=True, index=True)
    name_and_address = Column(String)
    district_state_tel = Column(String)
    panel_centre = Column(String)
    centre_code = Column(String)
    return_no = Column(String)
    family_size = Column(Integer)
    income_group = Column(String)
    month_and_year = Column(String)
    occupation_of_head = Column(String)
    items = Column(JSON)  # Store as JSON array of PurchaseItem objects
    latitude = Column(Float)
    longitude = Column(Float)
    otp_code = Column(String)
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