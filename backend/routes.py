from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from datetime import datetime
import logging
import json
import random
import string
from database import get_db
from models import DPRCreate, MPRCreate, FPCreate, DPRUpdate, MPRUpdate, SuccessResponse, ErrorResponse, HealthResponse, OTPRequest, OTPResponse, OTPVerificationRequest, OTPVerificationResponse
from crud import create_dpr, create_mpr, create_fp, get_database_stats, get_all_dpr, get_all_mpr, get_all_fp, update_dpr, update_mpr

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create router
router = APIRouter()

# In-memory OTP storage (in production, use Redis or database)
otp_storage = {}

def generate_otp():
    """Generate a 6-digit OTP"""
    return ''.join(random.choices(string.digits, k=6))

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

@router.put("/dpr/{dpr_id}", response_model=SuccessResponse)
async def update_dpr_endpoint(
    dpr_id: int,
    dpr_data: DPRUpdate,
    request: Request,
    db: Session = Depends(get_db)
):
    """Update an existing DPR (Demographic Purchase Return) record"""
    try:
        # Log the update
        client_ip = request.client.host if request.client else "unknown"
        logger.info(f"DPR update received from {client_ip} - ID: {dpr_id}, Return No: {dpr_data.return_no}")
        
        # Convert Pydantic model to dict for update
        update_data = dpr_data.dict()
        
        # Update the DPR record
        db_dpr = update_dpr(db, dpr_id, update_data)
        
        return SuccessResponse(
            message="DPR record updated successfully",
            data={
                "id": db_dpr.id,
                "return_no": db_dpr.return_no,
                "updated_at": db_dpr.created_at.isoformat()
            }
        )
    except ValueError as e:
        logger.error(f"DPR record not found: {str(e)}")
        raise HTTPException(
            status_code=404,
            detail=f"DPR record not found: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Error updating DPR record: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update DPR record: {str(e)}"
        )

@router.put("/mpr/{mpr_id}", response_model=SuccessResponse)
async def update_mpr_endpoint(
    mpr_id: int,
    mpr_data: MPRUpdate,
    request: Request,
    db: Session = Depends(get_db)
):
    """Update an existing MPR (Monthly Purchase Return) record"""
    try:
        # Log the update
        client_ip = request.client.host if request.client else "unknown"
        logger.info(f"MPR update received from {client_ip} - ID: {mpr_id}, Return No: {mpr_data.return_no}")
        
        # Convert Pydantic model to dict for update
        update_data = mpr_data.dict()
        
        # Update the MPR record
        db_mpr = update_mpr(db, mpr_id, update_data)
        
        return SuccessResponse(
            message="MPR record updated successfully",
            data={
                "id": db_mpr.id,
                "return_no": db_mpr.return_no,
                "updated_at": db_mpr.created_at.isoformat()
            }
        )
    except ValueError as e:
        logger.error(f"MPR record not found: {str(e)}")
        raise HTTPException(
            status_code=404,
            detail=f"MPR record not found: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Error updating MPR record: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to update MPR record: {str(e)}"
        ) 

@router.post("/send-otp", response_model=OTPResponse)
async def send_otp_endpoint(
    request: Request,
    otp_request: OTPRequest
):
    """Send OTP to the specified phone number"""
    try:
        # Log the request
        client_ip = request.client.host if request.client else "unknown"
        logger.info(f"OTP request received from {client_ip} for {otp_request.phone_number}")
        
        # Generate OTP
        otp_code = generate_otp()
        
        # Store OTP with phone number and purpose
        key = f"{otp_request.phone_number}_{otp_request.purpose}"
        otp_storage[key] = {
            "otp": otp_code,
            "created_at": datetime.now(),
            "purpose": otp_request.purpose
        }
        
        # In production, integrate with SMS service here
        # For now, we'll just log the OTP
        logger.info(f"OTP {otp_code} generated for {otp_request.phone_number}")
        
        return OTPResponse(
            message=f"OTP sent successfully to {otp_request.phone_number}",
            otp_sent=True,
            phone_number=otp_request.phone_number
        )
        
    except Exception as e:
        logger.error(f"Error sending OTP: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to send OTP: {str(e)}"
        )

@router.post("/verify-otp", response_model=OTPVerificationResponse)
async def verify_otp_endpoint(
    request: Request,
    verification_request: OTPVerificationRequest
):
    """Verify OTP for the specified phone number"""
    try:
        # Log the request
        client_ip = request.client.host if request.client else "unknown"
        logger.info(f"OTP verification request received from {client_ip} for {verification_request.phone_number}")
        
        # Check if OTP exists
        key = f"{verification_request.phone_number}_{verification_request.purpose}"
        
        if key not in otp_storage:
            return OTPVerificationResponse(
                message="OTP not found or expired",
                verified=False
            )
        
        stored_otp_data = otp_storage[key]
        
        # Check if OTP is expired (15 minutes)
        time_diff = datetime.now() - stored_otp_data["created_at"]
        if time_diff.total_seconds() > 900:  # 15 minutes
            del otp_storage[key]
            return OTPVerificationResponse(
                message="OTP has expired",
                verified=False
            )
        
        # Verify OTP
        if stored_otp_data["otp"] == verification_request.otp_code:
            # Remove OTP after successful verification
            del otp_storage[key]
            return OTPVerificationResponse(
                message="OTP verified successfully",
                verified=True
            )
        else:
            return OTPVerificationResponse(
                message="Invalid OTP",
                verified=False
            )
        
    except Exception as e:
        logger.error(f"Error verifying OTP: {str(e)}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to verify OTP: {str(e)}"
        ) 