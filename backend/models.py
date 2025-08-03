from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

# Base models for common fields
class LocationBase(BaseModel):
    latitude: float = Field(..., description="GPS latitude coordinate")
    longitude: float = Field(..., description="GPS longitude coordinate")

class TimestampBase(BaseModel):
    created_at: Optional[datetime] = Field(default_factory=datetime.now, description="Record creation timestamp")

# Household Member Schema for DPR
class HouseholdMember(BaseModel):
    name: str = Field(..., description="Name of household member")
    relationship_with_head: str = Field(..., description="Relationship with head of household")
    gender: str = Field(..., description="Gender (M/F/Other)")
    age: int = Field(..., ge=0, le=120, description="Age of member")
    education: str = Field(..., description="Education level")
    occupation: str = Field(..., description="Occupation")
    annual_income_job: float = Field(..., ge=0, description="Annual income from job")
    annual_income_other: float = Field(..., ge=0, description="Annual income from other sources")
    other_income_source: str = Field(..., description="Source of other income")
    total_income: float = Field(..., ge=0, description="Total annual income")

# Purchase Item Schema for MPR
class PurchaseItem(BaseModel):
    item_name: str = Field(..., description="Name of the item")
    item_code: str = Field(..., description="Item code")
    month_of_purchase: str = Field(..., description="Month of purchase")
    fibre_code: str = Field(..., description="Fibre code")
    sector_of_manufacture_code: str = Field(..., description="Sector of manufacture code")
    colour_design_code: str = Field(..., description="Colour/Design code")
    person_age_gender: str = Field(..., description="Person age and gender")
    type_of_shop_code: str = Field(..., description="Type of shop code")
    purchase_type_code: str = Field(..., description="Purchase type code")
    dress_intended_code: str = Field(..., description="Dress intended code")
    length_in_meters: float = Field(..., gt=0, description="Length in meters")
    price_per_meter: float = Field(..., gt=0, description="Price per meter")
    total_amount_paid: float = Field(..., gt=0, description="Total amount paid")
    brand_mill_name: str = Field(..., description="Brand/Mill name")
    is_imported: bool = Field(..., description="Whether item is imported")

# DPR (Demographic Particulars Return) Schema
class DPRBase(BaseModel):
    name_and_address: str = Field(..., description="Name and address")
    district: str = Field(..., description="District")
    state: str = Field(..., description="State")
    family_size: int = Field(..., gt=0, description="Family size")
    income_group: str = Field(..., description="Income group")
    centre_code: str = Field(..., description="Centre code")
    return_no: str = Field(..., description="Return number")
    month_and_year: str = Field(..., description="Month and year")
    household_members: List[HouseholdMember] = Field(..., max_items=8, description="Household members (max 8)")

class DPRCreate(DPRBase, LocationBase):
    otp_code: str = Field(..., description="OTP code for verification")

class DPRUpdate(DPRBase, LocationBase):
    otp_code: str = Field(..., description="OTP code for verification")

class DPRResponse(DPRBase, LocationBase, TimestampBase):
    id: int
    otp_code: str
    is_synced: bool = False

    class Config:
        from_attributes = True

# MPR (Monthly Purchase Return) Schema
class MPRBase(BaseModel):
    name_and_address: str = Field(..., description="Name and address")
    district_state_tel: str = Field(..., description="District, State, Tel No.")
    panel_centre: str = Field(..., description="Panel centre")
    centre_code: str = Field(..., description="Centre code")
    return_no: str = Field(..., description="Return number")
    family_size: int = Field(..., gt=0, description="Family size")
    income_group: str = Field(..., description="Income group")
    month_and_year: str = Field(..., description="Month and year")
    occupation_of_head: str = Field(..., description="Occupation of head of family")
    items: List[PurchaseItem] = Field(..., max_items=10, description="Purchase items (max 10)")

class MPRCreate(MPRBase, LocationBase):
    otp_code: str = Field(..., description="OTP code for verification")

class MPRUpdate(MPRBase, LocationBase):
    otp_code: str = Field(..., description="OTP code for verification")

class MPRResponse(MPRBase, LocationBase, TimestampBase):
    id: int
    otp_code: str
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