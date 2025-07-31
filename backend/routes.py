from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from datetime import datetime
import logging
from database import get_db
from models import DPRCreate, MPRCreate, FPCreate, SuccessResponse, ErrorResponse, HealthResponse
from crud import create_dpr, create_mpr, create_fp, get_database_stats

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create router
router = APIRouter()

@router.get("/ping", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now(),
        database="connected"
    )

@router.post("/dpr", response_model=SuccessResponse)
async def create_dpr_endpoint(
    dpr_data: DPRCreate,
    request: Request,
    db: Session = Depends(get_db)
):
    """Create a new DPR (Demographic Purchase Return) record for eMTC"""
    try:
        # Log the submission
        client_ip = request.client.host if request.client else "unknown"
        logger.info(f"DPR submission received from {client_ip} - Household: {dpr_data.household_id}")
        
        # Create the DPR record
        db_dpr = create_dpr(db, dpr_data)
        
        return SuccessResponse(
            message="DPR record created successfully",
            data={
                "id": db_dpr.id,
                "household_id": db_dpr.household_id,
                "created_at": db_dpr.created_at.isoformat()
            }
        )
    except Exception as e:
        logger.error(f"Error creating DPR record: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create DPR record: {str(e)}"
        )

@router.post("/mpr", response_model=SuccessResponse)
async def create_mpr_endpoint(
    mpr_data: MPRCreate,
    request: Request,
    db: Session = Depends(get_db)
):
    """Create a new MPR (Monthly Purchase Return) record for eMTC"""
    try:
        # Log the submission
        client_ip = request.client.host if request.client else "unknown"
        logger.info(f"MPR submission received from {client_ip} - Household: {mpr_data.household_id}")
        
        # Create the MPR record
        db_mpr = create_mpr(db, mpr_data)
        
        return SuccessResponse(
            message="MPR record created successfully",
            data={
                "id": db_mpr.id,
                "household_id": db_mpr.household_id,
                "created_at": db_mpr.created_at.isoformat()
            }
        )
    except Exception as e:
        logger.error(f"Error creating MPR record: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create MPR record: {str(e)}"
        )

@router.post("/fp", response_model=SuccessResponse)
async def create_fp_endpoint(
    fp_data: FPCreate,
    request: Request,
    db: Session = Depends(get_db)
):
    """Create a new FP (Forwarding Performa) record for eMTC"""
    try:
        # Log the submission
        client_ip = request.client.host if request.client else "unknown"
        logger.info(f"FP submission received from {client_ip} - Centre: {fp_data.centre_name}")
        
        # Create the FP record
        db_fp = create_fp(db, fp_data)
        
        return SuccessResponse(
            message="FP record created successfully",
            data={
                "id": db_fp.id,
                "centre_name": db_fp.centre_name,
                "centre_code": db_fp.centre_code,
                "created_at": db_fp.created_at.isoformat()
            }
        )
    except Exception as e:
        logger.error(f"Error creating FP record: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to create FP record: {str(e)}"
        )

@router.get("/stats")
async def get_stats(db: Session = Depends(get_db)):
    """Get database statistics"""
    try:
        stats = get_database_stats(db)
        return SuccessResponse(
            message="Database statistics retrieved successfully",
            data=stats
        )
    except Exception as e:
        logger.error(f"Error retrieving database stats: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve database statistics: {str(e)}"
        ) 