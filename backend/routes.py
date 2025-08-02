from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from datetime import datetime
import logging
import json
from database import get_db
from models import DPRCreate, MPRCreate, FPCreate, SuccessResponse, ErrorResponse, HealthResponse
from crud import create_dpr, create_mpr, create_fp, get_database_stats, get_all_dpr, get_all_mpr, get_all_fp

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
        logger.info(f"DPR submission received from {client_ip} - Return No: {dpr_data.return_no}")
        
        # Create the DPR record
        db_dpr = create_dpr(db, dpr_data)
        
        return SuccessResponse(
            message="DPR record created successfully",
            data={
                "id": db_dpr.id,
                "return_no": db_dpr.return_no,
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
        logger.info(f"MPR submission received from {client_ip} - Return No: {mpr_data.return_no}")
        
        # Create the MPR record
        db_mpr = create_mpr(db, mpr_data)
        
        return SuccessResponse(
            message="MPR record created successfully",
            data={
                "id": db_mpr.id,
                "return_no": db_mpr.return_no,
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

@router.get("/dpr")
async def get_all_dpr_endpoint(db: Session = Depends(get_db)):
    """Get all DPR records"""
    try:
        dpr_records = get_all_dpr(db)
        return SuccessResponse(
            message="DPR records retrieved successfully",
            data={
                "count": len(dpr_records),
                "records": [
                    {
                        "id": dpr.id,
                        "name_and_address": dpr.name_and_address,
                        "district": dpr.district,
                        "state": dpr.state,
                        "family_size": dpr.family_size,
                        "income_group": dpr.income_group,
                        "centre_code": dpr.centre_code,
                        "return_no": dpr.return_no,
                        "month_and_year": dpr.month_and_year,
                        "household_members": json.loads(dpr.household_members) if dpr.household_members else [],
                        "latitude": dpr.latitude,
                        "longitude": dpr.longitude,
                        "otp_code": dpr.otp_code,
                        "created_at": dpr.created_at.isoformat(),
                        "is_synced": dpr.is_synced
                    }
                    for dpr in dpr_records
                ]
            }
        )
    except Exception as e:
        logger.error(f"Error retrieving DPR records: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve DPR records: {str(e)}"
        )

@router.get("/mpr")
async def get_all_mpr_endpoint(db: Session = Depends(get_db)):
    """Get all MPR records"""
    try:
        mpr_records = get_all_mpr(db)
        return SuccessResponse(
            message="MPR records retrieved successfully",
            data={
                "count": len(mpr_records),
                "records": [
                    {
                        "id": mpr.id,
                        "name_and_address": mpr.name_and_address,
                        "district_state_tel": mpr.district_state_tel,
                        "panel_centre": mpr.panel_centre,
                        "centre_code": mpr.centre_code,
                        "return_no": mpr.return_no,
                        "family_size": mpr.family_size,
                        "income_group": mpr.income_group,
                        "month_and_year": mpr.month_and_year,
                        "occupation_of_head": mpr.occupation_of_head,
                        "items": json.loads(mpr.items) if mpr.items else [],
                        "latitude": mpr.latitude,
                        "longitude": mpr.longitude,
                        "otp_code": mpr.otp_code,
                        "created_at": mpr.created_at.isoformat(),
                        "is_synced": mpr.is_synced
                    }
                    for mpr in mpr_records
                ]
            }
        )
    except Exception as e:
        logger.error(f"Error retrieving MPR records: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve MPR records: {str(e)}"
        )

@router.get("/fp")
async def get_all_fp_endpoint(db: Session = Depends(get_db)):
    """Get all FP records"""
    try:
        fp_records = get_all_fp(db)
        return SuccessResponse(
            message="FP records retrieved successfully",
            data={
                "count": len(fp_records),
                "records": [
                    {
                        "id": fp.id,
                        "centre_name": fp.centre_name,
                        "centre_code": fp.centre_code,
                        "panel_size": fp.panel_size,
                        "mpr_collected": fp.mpr_collected,
                        "not_collected": fp.not_collected,
                        "with_purchase_data": fp.with_purchase_data,
                        "nil_mprs": fp.nil_mprs,
                        "nil_serial_nos": fp.nil_serial_nos,
                        "latitude": fp.latitude,
                        "longitude": fp.longitude,
                        "created_at": fp.created_at.isoformat(),
                        "is_synced": fp.is_synced
                    }
                    for fp in fp_records
                ]
            }
        )
    except Exception as e:
        logger.error(f"Error retrieving FP records: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve FP records: {str(e)}"
        ) 