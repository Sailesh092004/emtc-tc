from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

# Base models for common fields
class LocationBase(BaseModel):
    latitude: float = Field(..., description="GPS latitude coordinate")
    longitude: float = Field(..., description="GPS longitude coordinate")

class TimestampBase(BaseModel):
    created_at: Optional[datetime] = Field(default_factory=datetime.now, description="Record creation timestamp")

# DPR (Demographic Purchase Return) Schema
class DPRBase(BaseModel):
    household_id: str = Field(..., description="Unique household identifier")
    respondent_name: str = Field(..., description="Name of the respondent")
    age: int = Field(..., ge=0, le=120, description="Age of the respondent")
    gender: str = Field(..., description="Gender of the respondent")
    education: str = Field(..., description="Education level of the respondent")
    occupation: str = Field(..., description="Occupation of the respondent")
    income_level: str = Field(..., description="Income level category")

class DPRCreate(DPRBase, LocationBase):
    pass

class DPRResponse(DPRBase, LocationBase, TimestampBase):
    id: int
    is_synced: bool = False

    class Config:
        from_attributes = True

# MPR (Monthly Purchase Return) Schema
class MPRBase(BaseModel):
    household_id: str = Field(..., description="Unique household identifier")
    purchase_date: str = Field(..., description="Date of purchase (YYYY-MM-DD)")
    textile_type: str = Field(..., description="Type of textile purchased")
    quantity: int = Field(..., gt=0, description="Quantity purchased")
    price: float = Field(..., gt=0, description="Price per unit")
    purchase_location: str = Field(..., description="Location where purchase was made")

class MPRCreate(MPRBase, LocationBase):
    pass

class MPRResponse(MPRBase, LocationBase, TimestampBase):
    id: int
    is_synced: bool = False

    class Config:
        from_attributes = True

# FP (Forwarding Performa) Schema
class FPBase(BaseModel):
    centre_name: str = Field(..., description="Name of the centre")
    centre_code: str = Field(..., description="Unique centre code")
    panel_size: int = Field(..., gt=0, description="Total panel size")
    mpr_collected: int = Field(..., ge=0, description="Number of MPRs collected")
    not_collected: int = Field(..., ge=0, description="Number of MPRs not collected")
    with_purchase_data: int = Field(..., ge=0, description="MPRs with purchase data")
    nil_mprs: int = Field(..., ge=0, description="Number of nil MPRs")
    nil_serial_nos: int = Field(..., ge=0, description="Number of nil serial numbers")

class FPCreate(FPBase, LocationBase):
    pass

class FPResponse(FPBase, LocationBase, TimestampBase):
    id: int
    is_synced: bool = False

    class Config:
        from_attributes = True

# API Response Models
class SuccessResponse(BaseModel):
    status: str = "success"
    message: str
    data: Optional[dict] = None

class ErrorResponse(BaseModel):
    status: str = "error"
    message: str
    error_code: Optional[str] = None

# Health Check Response
class HealthResponse(BaseModel):
    status: str = "healthy"
    timestamp: datetime
    database: str = "connected" 