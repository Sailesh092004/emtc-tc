from sqlalchemy.orm import Session
from datetime import datetime
from database import DPR, MPR, FP
from models import DPRCreate, MPRCreate, FPCreate
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# DPR CRUD operations
def create_dpr(db: Session, dpr_data: DPRCreate) -> DPR:
    """Create a new DPR record in the database"""
    try:
        db_dpr = DPR(
            household_id=dpr_data.household_id,
            respondent_name=dpr_data.respondent_name,
            age=dpr_data.age,
            gender=dpr_data.gender,
            education=dpr_data.education,
            occupation=dpr_data.occupation,
            income_level=dpr_data.income_level,
            latitude=dpr_data.latitude,
            longitude=dpr_data.longitude,
            created_at=datetime.now(),
            is_synced=False
        )
        db.add(db_dpr)
        db.commit()
        db.refresh(db_dpr)
        
        logger.info(f"DPR record created successfully - ID: {db_dpr.id}, Household: {dpr_data.household_id}")
        return db_dpr
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating DPR record: {str(e)}")
        raise

def get_dpr_by_id(db: Session, dpr_id: int) -> DPR:
    """Get a DPR record by ID"""
    return db.query(DPR).filter(DPR.id == dpr_id).first()

def get_all_dpr(db: Session, skip: int = 0, limit: int = 100):
    """Get all DPR records with pagination"""
    return db.query(DPR).offset(skip).limit(limit).all()

def get_unsynced_dpr(db: Session):
    """Get all unsynced DPR records"""
    return db.query(DPR).filter(DPR.is_synced == False).all()

def update_dpr_sync_status(db: Session, dpr_id: int, synced: bool = True):
    """Update the sync status of a DPR record"""
    dpr = get_dpr_by_id(db, dpr_id)
    if dpr:
        dpr.is_synced = synced
        db.commit()
        logger.info(f"DPR sync status updated - ID: {dpr_id}, Synced: {synced}")
    return dpr

# MPR CRUD operations
def create_mpr(db: Session, mpr_data: MPRCreate) -> MPR:
    """Create a new MPR record in the database"""
    try:
        db_mpr = MPR(
            household_id=mpr_data.household_id,
            purchase_date=mpr_data.purchase_date,
            textile_type=mpr_data.textile_type,
            quantity=mpr_data.quantity,
            price=mpr_data.price,
            purchase_location=mpr_data.purchase_location,
            latitude=mpr_data.latitude,
            longitude=mpr_data.longitude,
            created_at=datetime.now(),
            is_synced=False
        )
        db.add(db_mpr)
        db.commit()
        db.refresh(db_mpr)
        
        logger.info(f"MPR record created successfully - ID: {db_mpr.id}, Household: {mpr_data.household_id}")
        return db_mpr
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating MPR record: {str(e)}")
        raise

def get_mpr_by_id(db: Session, mpr_id: int) -> MPR:
    """Get an MPR record by ID"""
    return db.query(MPR).filter(MPR.id == mpr_id).first()

def get_all_mpr(db: Session, skip: int = 0, limit: int = 100):
    """Get all MPR records with pagination"""
    return db.query(MPR).offset(skip).limit(limit).all()

def get_unsynced_mpr(db: Session):
    """Get all unsynced MPR records"""
    return db.query(MPR).filter(MPR.is_synced == False).all()

def update_mpr_sync_status(db: Session, mpr_id: int, synced: bool = True):
    """Update the sync status of an MPR record"""
    mpr = get_mpr_by_id(db, mpr_id)
    if mpr:
        mpr.is_synced = synced
        db.commit()
        logger.info(f"MPR sync status updated - ID: {mpr_id}, Synced: {synced}")
    return mpr

# FP CRUD operations
def create_fp(db: Session, fp_data: FPCreate) -> FP:
    """Create a new FP record in the database"""
    try:
        db_fp = FP(
            centre_name=fp_data.centre_name,
            centre_code=fp_data.centre_code,
            panel_size=fp_data.panel_size,
            mpr_collected=fp_data.mpr_collected,
            not_collected=fp_data.not_collected,
            with_purchase_data=fp_data.with_purchase_data,
            nil_mprs=fp_data.nil_mprs,
            nil_serial_nos=fp_data.nil_serial_nos,
            latitude=fp_data.latitude,
            longitude=fp_data.longitude,
            created_at=datetime.now(),
            is_synced=False
        )
        db.add(db_fp)
        db.commit()
        db.refresh(db_fp)
        
        logger.info(f"FP record created successfully - ID: {db_fp.id}, Centre: {fp_data.centre_name}")
        return db_fp
    except Exception as e:
        db.rollback()
        logger.error(f"Error creating FP record: {str(e)}")
        raise

def get_fp_by_id(db: Session, fp_id: int) -> FP:
    """Get an FP record by ID"""
    return db.query(FP).filter(FP.id == fp_id).first()

def get_all_fp(db: Session, skip: int = 0, limit: int = 100):
    """Get all FP records with pagination"""
    return db.query(FP).offset(skip).limit(limit).all()

def get_unsynced_fp(db: Session):
    """Get all unsynced FP records"""
    return db.query(FP).filter(FP.is_synced == False).all()

def update_fp_sync_status(db: Session, fp_id: int, synced: bool = True):
    """Update the sync status of an FP record"""
    fp = get_fp_by_id(db, fp_id)
    if fp:
        fp.is_synced = synced
        db.commit()
        logger.info(f"FP sync status updated - ID: {fp_id}, Synced: {synced}")
    return fp

# Statistics functions
def get_database_stats(db: Session):
    """Get database statistics"""
    total_dpr = db.query(DPR).count()
    total_mpr = db.query(MPR).count()
    total_fp = db.query(FP).count()
    unsynced_dpr = db.query(DPR).filter(DPR.is_synced == False).count()
    unsynced_mpr = db.query(MPR).filter(MPR.is_synced == False).count()
    unsynced_fp = db.query(FP).filter(FP.is_synced == False).count()
    
    return {
        "total_dpr": total_dpr,
        "total_mpr": total_mpr,
        "total_fp": total_fp,
        "unsynced_dpr": unsynced_dpr,
        "unsynced_mpr": unsynced_mpr,
        "unsynced_fp": unsynced_fp
    } 