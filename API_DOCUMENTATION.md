# eMTC API Documentation

This document provides comprehensive documentation for the eMTC FastAPI backend API endpoints.

## Base URL

- **Development**: `http://localhost:8000`
- **Production**: `https://your-app-name.onrender.com`

## API Version

All endpoints are prefixed with `/api/v1`

## Authentication

Currently, the API uses a simple OTP-based authentication system:
- **Mock OTP**: `123456` (for development)
- **Phone Number**: Required for all data submissions

## Endpoints Overview

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/ping` | Health check |
| `POST` | `/dpr` | Create DPR record |
| `PUT` | `/dpr/{dpr_id}` | Update DPR record |
| `GET` | `/dpr` | Get all DPR records |
| `POST` | `/mpr` | Create MPR record |
| `PUT` | `/mpr/{mpr_id}` | Update MPR record |
| `GET` | `/mpr` | Get all MPR records |
| `POST` | `/fp` | Create FP record |
| `GET` | `/fp` | Get all FP records |
| `GET` | `/stats` | Database statistics |

## Health Check

### GET `/api/v1/ping`

Check if the API is running.

**Response:**
```json
{
  "status": "success",
  "message": "API is running",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## DPR (Demographic Purchase Return) Endpoints

### POST `/api/v1/dpr`

Create a new DPR record.

**Request Body:**
```json
{
  "name_and_address": "John Doe, 123 Main St, Mumbai",
  "district": "Mumbai",
  "state": "Maharashtra",
  "family_size": 4,
  "income_group": "Middle",
  "centre_code": "C001",
  "return_no": "R001",
  "month_and_year": "January 2024",
  "household_members": [
    {
      "name": "John Doe",
      "age": 35,
      "gender": "Male",
      "relationship_with_head": "Self",
      "education": "Graduate",
      "occupation": "Engineer",
      "monthly_income": 50000
    },
    {
      "name": "Jane Doe",
      "age": 32,
      "gender": "Female",
      "relationship_with_head": "Spouse",
      "education": "Post Graduate",
      "occupation": "Teacher",
      "monthly_income": 40000
    }
  ],
  "latitude": 19.0760,
  "longitude": 72.8777,
  "otp_code": "123456"
}
```

**Response:**
```json
{
  "status": "success",
  "message": "DPR record created successfully",
  "data": {
    "id": 1,
    "return_no": "R001",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### PUT `/api/v1/dpr/{dpr_id}`

Update an existing DPR record.

**Path Parameters:**
- `dpr_id` (integer): The ID of the DPR record to update

**Request Body:** Same as POST `/api/v1/dpr`

**Response:**
```json
{
  "status": "success",
  "message": "DPR record updated successfully",
  "data": {
    "id": 1,
    "return_no": "R001",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

### GET `/api/v1/dpr`

Get all DPR records.

**Response:**
```json
{
  "status": "success",
  "message": "DPR records retrieved successfully",
  "data": [
    {
      "id": 1,
      "name_and_address": "John Doe, 123 Main St, Mumbai",
      "district": "Mumbai",
      "state": "Maharashtra",
      "family_size": 4,
      "income_group": "Middle",
      "centre_code": "C001",
      "return_no": "R001",
      "month_and_year": "January 2024",
      "household_members": [
        {
          "name": "John Doe",
          "age": 35,
          "gender": "Male",
          "relationship_with_head": "Self",
          "education": "Graduate",
          "occupation": "Engineer",
          "monthly_income": 50000
        }
      ],
      "latitude": 19.0760,
      "longitude": 72.8777,
      "otp_code": "123456",
      "created_at": "2024-01-15T10:30:00Z",
      "is_synced": true
    }
  ]
}
```

## MPR (Monthly Purchase Return) Endpoints

### POST `/api/v1/mpr`

Create a new MPR record.

**Request Body:**
```json
{
  "name_and_address": "John Doe, 123 Main St, Mumbai",
  "district": "Mumbai",
  "state": "Maharashtra",
  "centre_code": "C001",
  "return_no": "R001",
  "month_and_year": "January 2024",
  "items": [
    {
      "item_name": "Cotton Shirt",
      "quantity": 2,
      "price_per_unit": 500,
      "total_amount": 1000,
      "purchase_date": "2024-01-15",
      "purchase_location": "Local Market"
    },
    {
      "item_name": "Denim Jeans",
      "quantity": 1,
      "price_per_unit": 800,
      "total_amount": 800,
      "purchase_date": "2024-01-16",
      "purchase_location": "Shopping Mall"
    }
  ],
  "latitude": 19.0760,
  "longitude": 72.8777
}
```

**Response:**
```json
{
  "status": "success",
  "message": "MPR record created successfully",
  "data": {
    "id": 1,
    "return_no": "R001",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### PUT `/api/v1/mpr/{mpr_id}`

Update an existing MPR record.

**Path Parameters:**
- `mpr_id` (integer): The ID of the MPR record to update

**Request Body:** Same as POST `/api/v1/mpr`

**Response:**
```json
{
  "status": "success",
  "message": "MPR record updated successfully",
  "data": {
    "id": 1,
    "return_no": "R001",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

### GET `/api/v1/mpr`

Get all MPR records.

**Response:**
```json
{
  "status": "success",
  "message": "MPR records retrieved successfully",
  "data": [
    {
      "id": 1,
      "name_and_address": "John Doe, 123 Main St, Mumbai",
      "district": "Mumbai",
      "state": "Maharashtra",
      "centre_code": "C001",
      "return_no": "R001",
      "month_and_year": "January 2024",
      "items": [
        {
          "item_name": "Cotton Shirt",
          "quantity": 2,
          "price_per_unit": 500,
          "total_amount": 1000,
          "purchase_date": "2024-01-15",
          "purchase_location": "Local Market"
        }
      ],
      "latitude": 19.0760,
      "longitude": 72.8777,
      "created_at": "2024-01-15T10:30:00Z",
      "is_synced": true
    }
  ]
}
```

## FP (Forwarding Performa) Endpoints

### POST `/api/v1/fp`

Create a new FP record.

**Request Body:**
```json
{
  "centre_name": "Mumbai Textile Centre",
  "centre_code": "C001",
  "panel_size": 100,
  "mpr_collected": 85,
  "not_collected": 15,
  "with_purchase_data": 75,
  "nil_mprs": 10,
  "nil_serial_nos": 5,
  "latitude": 19.0760,
  "longitude": 72.8777
}
```

**Response:**
```json
{
  "status": "success",
  "message": "FP record created successfully",
  "data": {
    "id": 1,
    "centre_code": "C001",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### GET `/api/v1/fp`

Get all FP records.

**Response:**
```json
{
  "status": "success",
  "message": "FP records retrieved successfully",
  "data": [
    {
      "id": 1,
      "centre_name": "Mumbai Textile Centre",
      "centre_code": "C001",
      "panel_size": 100,
      "mpr_collected": 85,
      "not_collected": 15,
      "with_purchase_data": 75,
      "nil_mprs": 10,
      "nil_serial_nos": 5,
      "latitude": 19.0760,
      "longitude": 72.8777,
      "created_at": "2024-01-15T10:30:00Z",
      "is_synced": true
    }
  ]
}
```

## Statistics Endpoint

### GET `/api/v1/stats`

Get database statistics.

**Response:**
```json
{
  "status": "success",
  "message": "Database statistics retrieved successfully",
  "data": {
    "total_dpr": 150,
    "total_mpr": 300,
    "total_fp": 25,
    "synced_dpr": 145,
    "synced_mpr": 295,
    "synced_fp": 25,
    "pending_dpr": 5,
    "pending_mpr": 5,
    "pending_fp": 0,
    "last_sync": "2024-01-15T10:30:00Z"
  }
}
```

## Error Responses

### 400 Bad Request
```json
{
  "detail": [
    {
      "type": "missing",
      "loc": ["body", "name_and_address"],
      "msg": "Field required"
    }
  ]
}
```

### 404 Not Found
```json
{
  "detail": "DPR record not found: Record with ID 999 not found"
}
```

### 422 Validation Error
```json
{
  "detail": [
    {
      "type": "value_error",
      "loc": ["body", "family_size"],
      "msg": "Value error, family_size must be greater than 0"
    }
  ]
}
```

### 500 Internal Server Error
```json
{
  "detail": "Failed to create DPR record: Database connection error"
}
```

## Data Models

### DPR Model
```python
class DPRBase(BaseModel):
    name_and_address: str
    district: str
    state: str
    family_size: int
    income_group: str
    centre_code: str
    return_no: str
    month_and_year: str
    household_members: List[HouseholdMember]
    latitude: float
    longitude: float
    otp_code: str

class DPRCreate(DPRBase):
    pass

class DPRUpdate(DPRBase):
    pass
```

### MPR Model
```python
class MPRBase(BaseModel):
    name_and_address: str
    district: str
    state: str
    centre_code: str
    return_no: str
    month_and_year: str
    items: List[PurchaseItem]
    latitude: float
    longitude: float

class MPRCreate(MPRBase):
    pass

class MPRUpdate(MPRBase):
    pass
```

### FP Model
```python
class FPBase(BaseModel):
    centre_name: str
    centre_code: str
    panel_size: int
    mpr_collected: int
    not_collected: int
    with_purchase_data: int
    nil_mprs: int
    nil_serial_nos: int
    latitude: float
    longitude: float

class FPCreate(FPBase):
    pass
```

### Household Member Model
```python
class HouseholdMember(BaseModel):
    name: str
    age: int
    gender: str
    relationship_with_head: str
    education: str
    occupation: str
    monthly_income: float
```

### Purchase Item Model
```python
class PurchaseItem(BaseModel):
    item_name: str
    quantity: int
    price_per_unit: float
    total_amount: float
    purchase_date: str
    purchase_location: str
```

## Usage Examples

### cURL Examples

#### Create DPR Record
```bash
curl -X POST https://your-app-name.onrender.com/api/v1/dpr \
  -H "Content-Type: application/json" \
  -d '{
    "name_and_address": "John Doe, 123 Main St, Mumbai",
    "district": "Mumbai",
    "state": "Maharashtra",
    "family_size": 4,
    "income_group": "Middle",
    "centre_code": "C001",
    "return_no": "R001",
    "month_and_year": "January 2024",
    "household_members": [
      {
        "name": "John Doe",
        "age": 35,
        "gender": "Male",
        "relationship_with_head": "Self",
        "education": "Graduate",
        "occupation": "Engineer",
        "monthly_income": 50000
      }
    ],
    "latitude": 19.0760,
    "longitude": 72.8777,
    "otp_code": "123456"
  }'
```

#### Update DPR Record
```bash
curl -X PUT https://your-app-name.onrender.com/api/v1/dpr/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name_and_address": "John Doe Updated, 123 Main St, Mumbai",
    "district": "Mumbai",
    "state": "Maharashtra",
    "family_size": 5,
    "income_group": "Upper Middle",
    "centre_code": "C001",
    "return_no": "R001",
    "month_and_year": "January 2024",
    "household_members": [
      {
        "name": "John Doe",
        "age": 35,
        "gender": "Male",
        "relationship_with_head": "Self",
        "education": "Graduate",
        "occupation": "Engineer",
        "monthly_income": 60000
      }
    ],
    "latitude": 19.0760,
    "longitude": 72.8777,
    "otp_code": "123456"
  }'
```

#### Get All DPR Records
```bash
curl -X GET https://your-app-name.onrender.com/api/v1/dpr
```

#### Get Statistics
```bash
curl -X GET https://your-app-name.onrender.com/api/v1/stats
```

### Python Examples

#### Using requests library
```python
import requests
import json

# Base URL
base_url = "https://your-app-name.onrender.com/api/v1"

# Create DPR record
dpr_data = {
    "name_and_address": "John Doe, 123 Main St, Mumbai",
    "district": "Mumbai",
    "state": "Maharashtra",
    "family_size": 4,
    "income_group": "Middle",
    "centre_code": "C001",
    "return_no": "R001",
    "month_and_year": "January 2024",
    "household_members": [
        {
            "name": "John Doe",
            "age": 35,
            "gender": "Male",
            "relationship_with_head": "Self",
            "education": "Graduate",
            "occupation": "Engineer",
            "monthly_income": 50000
        }
    ],
    "latitude": 19.0760,
    "longitude": 72.8777,
    "otp_code": "123456"
}

response = requests.post(f"{base_url}/dpr", json=dpr_data)
print(response.json())

# Get all DPR records
response = requests.get(f"{base_url}/dpr")
print(response.json())

# Get statistics
response = requests.get(f"{base_url}/stats")
print(response.json())
```

## Rate Limiting

Currently, no rate limiting is implemented. For production use, consider implementing rate limiting to prevent abuse.

## CORS Configuration

The API is configured to accept requests from any origin for development. For production, configure specific allowed origins.

## Swagger UI

Interactive API documentation is available at:
- **Development**: `http://localhost:8000/docs`
- **Production**: `https://your-app-name.onrender.com/docs`

## Testing

Use the provided test script:
```bash
python test_deployed_api.py
```

This script tests all endpoints and provides detailed feedback on API functionality.

## Support

For API support or questions:
- Check the Swagger UI documentation
- Review this documentation
- Contact the development team
- Create an issue in the repository 