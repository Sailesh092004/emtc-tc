# eMTC Backend API

FastAPI backend for the eMTC mobile app data collection system. eMTC is a digital platform for textile consumption data collection across India, developed under the aegis of the Textiles Committee, Government of India.

## Features

- **DPR Endpoint**: `POST /api/v1/dpr` - Demographic Purchase Return data
- **MPR Endpoint**: `POST /api/v1/mpr` - Monthly Purchase Return data  
- **FP Endpoint**: `POST /api/v1/fp` - Forwarding Performa data
- **Health Check**: `GET /api/v1/ping` - API health status
- **Statistics**: `GET /api/v1/stats` - Database statistics
- **CORS Enabled**: Cross-origin requests supported
- **Swagger UI**: Interactive API documentation at `/docs`
- **SQLite/PostgreSQL**: Database support with SQLAlchemy ORM

## Setup

1. **Install Dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure Environment**:
   - Copy `config.env` and modify as needed
   - Default uses SQLite database
   - For PostgreSQL, update `DATABASE_URL` in `config.env`

3. **Run the Server**:
   ```bash
   python main.py
   ```
   
   Or using uvicorn directly:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

## API Endpoints

### Health Check
```bash
GET /api/v1/ping
```

### DPR (Demographic Purchase Return)
```bash
POST /api/v1/dpr
Content-Type: application/json

{
  "household_id": "HH001",
  "respondent_name": "John Doe",
  "age": 35,
  "gender": "Male",
  "education": "Graduate",
  "occupation": "Engineer",
  "income_level": "Middle",
  "latitude": 28.6139,
  "longitude": 77.2090
}
```

### MPR (Monthly Purchase Return)
```bash
POST /api/v1/mpr
Content-Type: application/json

{
  "household_id": "HH001",
  "purchase_date": "2024-01-15",
  "textile_type": "Cotton",
  "quantity": 2,
  "price": 1500.0,
  "purchase_location": "Local Market",
  "latitude": 28.6139,
  "longitude": 77.2090
}
```

### FP (Forwarding Performa)
```bash
POST /api/v1/fp
Content-Type: application/json

{
  "centre_name": "Centre A",
  "centre_code": "CA001",
  "panel_size": 100,
  "mpr_collected": 85,
  "not_collected": 15,
  "with_purchase_data": 70,
  "nil_mprs": 10,
  "nil_serial_nos": 5,
  "latitude": 28.6139,
  "longitude": 77.2090
}
```

### Statistics
```bash
GET /api/v1/stats
```

## Database Schema

### DPR Table
- `id` (Primary Key)
- `household_id` (String)
- `respondent_name` (String)
- `age` (Integer)
- `gender` (String)
- `education` (String)
- `occupation` (String)
- `income_level` (String)
- `latitude` (Float)
- `longitude` (Float)
- `created_at` (DateTime)
- `is_synced` (Boolean)

### MPR Table
- `id` (Primary Key)
- `household_id` (String)
- `purchase_date` (String)
- `textile_type` (String)
- `quantity` (Integer)
- `price` (Float)
- `purchase_location` (String)
- `latitude` (Float)
- `longitude` (Float)
- `created_at` (DateTime)
- `is_synced` (Boolean)

### FP Table
- `id` (Primary Key)
- `centre_name` (String)
- `centre_code` (String)
- `panel_size` (Integer)
- `mpr_collected` (Integer)
- `not_collected` (Integer)
- `with_purchase_data` (Integer)
- `nil_mprs` (Integer)
- `nil_serial_nos` (Integer)
- `latitude` (Float)
- `longitude` (Float)
- `created_at` (DateTime)
- `is_synced` (Boolean)

## Development

- **Swagger UI**: Visit `http://localhost:8000/docs` for interactive API documentation
- **ReDoc**: Visit `http://localhost:8000/redoc` for alternative documentation
- **Logging**: All API calls are logged with timestamp and client IP
- **Error Handling**: Comprehensive error handling with detailed error messages

## Production Deployment

1. **Environment Variables**: Set proper `DATABASE_URL` for production database
2. **CORS**: Configure `allow_origins` with specific domains
3. **Security**: Add authentication and authorization as needed
4. **Monitoring**: Add application monitoring and logging
5. **SSL**: Configure HTTPS for production

## Testing

Use the provided `test_api.py` script to test the API endpoints:

```bash
python test_api.py
```

This will test all endpoints and verify the API is working correctly. 