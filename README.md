# eMTC Project

A comprehensive mobile data collection system for the "Electronic Market for Textiles and Clothing (eMTC)" project by the Textiles Committee, Government of India. eMTC is a digital platform for textile consumption data collection across India, developed under the aegis of the Textiles Committee, Government of India. This project consists of a Flutter mobile app for Liaison Officers (LOs) and a FastAPI backend for data storage and synchronization.

## 🏗️ Project Architecture

```
eMTC Project/
├── 📱 Flutter Mobile App (lib/)
│   ├── models/          # Data models (DPR, MPR, FP)
│   ├── screens/         # UI screens (forms, lists, login)
│   ├── services/        # Business logic & API calls
│   └── main.dart        # App entry point with auth wrapper
├── 🖥️ FastAPI Backend (backend/)
│   ├── main.py          # FastAPI app entry point
│   ├── routes.py        # API endpoints (GET, POST, PUT)
│   ├── models.py        # Pydantic schemas
│   ├── crud.py          # Database operations
│   ├── database.py      # Database configuration
│   └── requirements.txt # Python dependencies
└── 📚 Documentation
    ├── README.md        # This file
    └── DEPLOYMENT.md    # Deployment guide
```

## 🔐 Liaison Officer (LO) Access Control

### Authentication System
- **OTP-Based Login**: Secure login using phone number and OTP
- **Mock OTP**: Development OTP code is "123456"
- **Session Management**: Phone number stored in SharedPreferences
- **Logout Functionality**: Secure logout with session clearing

### Data Isolation
- **LO-Specific Records**: Each LO can only view/edit their own records
- **Phone Number Tracking**: All records tagged with `lo_phone`
- **Permission Enforcement**: Prevents unauthorized editing of other LO's records
- **Filtered Views**: List screens show only current LO's data

## 📱 Flutter Mobile App

### Features

- **🔐 Secure Login System**: OTP-based authentication for Liaison Officers
- **📊 Offline-First Design**: Data collection works without internet
- **📝 Three Form Types**:
  - **DPR**: Demographic Purchase Return (annual per household)
  - **MPR**: Monthly Purchase Return (bi-monthly per household)
  - **FP**: Forwarding Performa (summary per location)
- **📍 GPS Location Capture**: Automatic latitude/longitude recording
- **✍️ Digital Signature**: Signature pad for DPR consent validation
- **🔄 Data Synchronization**: Automatic sync when internet is restored
- **📋 List Views**: View and edit all previously filled entries
- **📊 Dashboard**: Statistics and charts for data visualization
- **🔄 Auto-Fill**: MPR form auto-fills from DPR data using Centre Code and Return Number

### Form Fields

#### DPR Form Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| Name and Address | Text | ✅ | Household name and address |
| District | Text | ✅ | District name |
| State | Text | ✅ | State name |
| Family Size | Number | ✅ | Number of family members |
| Income Group | Dropdown | ✅ | Income category |
| Centre Code | Text | ✅ | Unique centre identifier |
| Return No | Text | ✅ | Return number |
| Month and Year | Text | ✅ | Period of data collection |
| Household Members | List | ✅ | Family member details |
| Location | GPS | ✅ | Auto-captured coordinates |
| OTP Code | Text | ✅ | Verification code |

#### MPR Form Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| Name and Address | Text | ✅ | Household name and address |
| District | Text | ✅ | District name |
| State | Text | ✅ | State name |
| Centre Code | Text | ✅ | Unique centre identifier |
| Return No | Text | ✅ | Return number |
| Month and Year | Text | ✅ | Period of data collection |
| Purchase Items | List | ✅ | Textile purchase details |
| Location | GPS | ✅ | Auto-captured coordinates |

#### FP Form Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| Centre Name | Text | ✅ | Name of the centre |
| Centre Code | Text | ✅ | Unique centre identifier |
| Panel Size | Number | ✅ | Total panel size |
| MPR Collected | Number | ✅ | Number of MPRs collected |
| Not Collected | Number | ✅ | Number of MPRs not collected |
| With Purchase Data | Number | ✅ | MPRs with purchase data |
| Nil MPRs | Number | ✅ | Number of nil MPRs |
| Nil Serial Nos | Number | ✅ | Number of nil serial numbers |
| Location | GPS | ✅ | Auto-captured coordinates |

### Database Schema

#### DPR Table
```sql
CREATE TABLE dpr (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name_and_address TEXT NOT NULL,
  district TEXT NOT NULL,
  state TEXT NOT NULL,
  family_size INTEGER NOT NULL,
  income_group TEXT NOT NULL,
  centre_code TEXT NOT NULL,
  return_no TEXT NOT NULL,
  month_and_year TEXT NOT NULL,
  household_members TEXT NOT NULL, -- JSON array
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  otp_code TEXT NOT NULL,
  created_at TEXT NOT NULL,
  is_synced INTEGER NOT NULL DEFAULT 0,
  backend_id INTEGER, -- Backend-assigned ID after sync
  lo_phone TEXT -- Liaison Officer phone number
);
```

#### MPR Table
```sql
CREATE TABLE mpr (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name_and_address TEXT NOT NULL,
  district TEXT NOT NULL,
  state TEXT NOT NULL,
  centre_code TEXT NOT NULL,
  return_no TEXT NOT NULL,
  month_and_year TEXT NOT NULL,
  items TEXT NOT NULL, -- JSON array
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  created_at TEXT NOT NULL,
  is_synced INTEGER NOT NULL DEFAULT 0,
  backend_id INTEGER, -- Backend-assigned ID after sync
  lo_phone TEXT -- Liaison Officer phone number
);
```

#### FP Table
```sql
CREATE TABLE fp (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  centre_name TEXT NOT NULL,
  centre_code TEXT NOT NULL,
  panel_size INTEGER NOT NULL,
  mpr_collected INTEGER NOT NULL,
  not_collected INTEGER NOT NULL,
  with_purchase_data INTEGER NOT NULL,
  nil_mprs INTEGER NOT NULL,
  nil_serial_nos INTEGER NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  created_at TEXT NOT NULL,
  is_synced INTEGER NOT NULL DEFAULT 0,
  backend_id INTEGER -- Backend-assigned ID after sync
);
```

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  # Database
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  # Location services
  location: ^6.0.0
  # Connectivity monitoring
  connectivity_plus: ^5.0.2
  # HTTP requests
  http: ^1.1.0
  # UI components
  signature: ^5.4.0
  # State management
  provider: ^6.1.1
  # Local storage
  shared_preferences: ^2.2.2
  # Charts
  fl_chart: ^0.66.0
```

## 🖥️ FastAPI Backend

### Features

- **RESTful API**: Clean REST endpoints for all form types
- **Database Support**: SQLite (default) and PostgreSQL support
- **CORS Enabled**: Cross-origin requests supported
- **Swagger UI**: Interactive API documentation at `/docs`
- **Comprehensive Logging**: All submissions logged with timestamps
- **Error Handling**: Detailed error responses
- **Health Checks**: API health monitoring endpoints
- **Update Support**: PUT endpoints for editing existing records

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/ping` | Health check |
| `POST` | `/api/v1/dpr` | Create DPR record |
| `PUT` | `/api/v1/dpr/{dpr_id}` | Update DPR record |
| `POST` | `/api/v1/mpr` | Create MPR record |
| `PUT` | `/api/v1/mpr/{mpr_id}` | Update MPR record |
| `POST` | `/api/v1/fp` | Create FP record |
| `GET` | `/api/v1/dpr` | Get all DPR records |
| `GET` | `/api/v1/mpr` | Get all MPR records |
| `GET` | `/api/v1/fp` | Get all FP records |
| `GET` | `/api/v1/stats` | Database statistics |

### Database Schema

#### DPR Table
- `id` (Primary Key)
- `name_and_address` (String)
- `district` (String)
- `state` (String)
- `family_size` (Integer)
- `income_group` (String)
- `centre_code` (String)
- `return_no` (String)
- `month_and_year` (String)
- `household_members` (JSON)
- `latitude` (Float)
- `longitude` (Float)
- `otp_code` (String)
- `created_at` (DateTime)
- `is_synced` (Boolean)

#### MPR Table
- `id` (Primary Key)
- `name_and_address` (String)
- `district` (String)
- `state` (String)
- `centre_code` (String)
- `return_no` (String)
- `month_and_year` (String)
- `items` (JSON)
- `latitude` (Float)
- `longitude` (Float)
- `created_at` (DateTime)
- `is_synced` (Boolean)

#### FP Table
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

### Dependencies

```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
python-dotenv==1.0.0
pydantic==2.5.0
python-multipart==0.0.6
```

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: 3.0 or higher
- **Python**: 3.8 or higher
- **Android Studio** / **VS Code**: For development
- **Git**: For version control

### Backend Setup

1. **Navigate to backend directory**:
   ```bash
   cd backend
   ```

2. **Install Python dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure environment** (optional):
   ```bash
   # Edit config.env to customize settings
   cp config.env.example config.env
   ```

4. **Start the backend server**:
   ```bash
   python start_server.py
   ```
   
   Or using uvicorn directly:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

5. **Test the API**:
   ```bash
   python test_api.py
   ```

6. **Access API documentation**:
   - Swagger UI: http://localhost:8000/docs
   - ReDoc: http://localhost:8000/redoc

### Mobile App Setup

1. **Install Flutter dependencies**:
   ```bash
   flutter pub get
   ```

2. **Configure API endpoint** (if needed):
   ```dart
   // In lib/services/api_service.dart
   static const String _baseUrl = 'http://localhost:8000/api/v1';
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

## 📱 App Screens

### Login Screen
- **Phone Number Input**: Enter LO's phone number
- **OTP Verification**: Enter mock OTP (123456)
- **Session Storage**: Stores LO phone in SharedPreferences
- **Navigation**: Redirects to Home Screen after login

### Home Screen
- **Navigation Cards**: DPR, MPR, FP forms
- **List View Buttons**: View all DPR and MPR entries
- **Logout Button**: Secure logout functionality
- **Statistics Display**: Database statistics

### Form Screens
- **DPR Form**: Complete demographic data collection
- **MPR Form**: Purchase data with auto-fill from DPR
- **FP Form**: Summary data collection
- **GPS Integration**: Automatic location capture
- **Validation**: Comprehensive form validation

### List Screens
- **DPR List**: View all DPR entries for current LO
- **MPR List**: View all MPR entries for current LO
- **Edit Functionality**: Tap edit icon to modify entries
- **Permission Checks**: Only owner can edit records
- **Sync Status**: Visual indicators for sync status

## 📊 Dashboard Screen

The dashboard provides:

- **Statistics Cards**: Total and pending counts for DPR, MPR, and FP forms
- **Sync Status**: Last sync time and current connectivity status
- **Line Chart**: MPR submissions over the past 6 months
- **Refresh Functionality**: Pull-to-refresh for real-time updates

## 🔄 Data Synchronization

### Offline-First Architecture

1. **Local Storage**: All form data is stored locally in SQLite
2. **Connectivity Monitoring**: Real-time internet status detection
3. **Automatic Sync**: Data syncs when internet is restored
4. **Manual Sync**: Force sync option available
5. **Conflict Resolution**: Handles sync conflicts gracefully
6. **Update Support**: PUT requests for editing existing records

### Sync Process

1. **Data Collection**: Forms are saved locally with `isSynced = false`
2. **Connectivity Check**: App monitors internet connection
3. **Batch Sync**: Unsynced records are sent to backend
4. **Status Update**: Successfully synced records are marked `isSynced = true`
5. **Error Handling**: Failed syncs are retried automatically
6. **Update Handling**: Differentiates between new and updated records

## 🧪 Testing

### Backend Testing

```bash
cd backend
python test_api.py
```

### Mobile App Testing

```bash
flutter test
```

### API Testing

```bash
# Test deployed API
python test_deployed_api.py
```

## 📱 Screenshots

### Login Screen
- Clean login interface with phone and OTP inputs
- Mock OTP verification (123456)
- Session management

### Home Screen
- Navigation cards for DPR, MPR, FP forms
- List view buttons for viewing entries
- Logout functionality
- Database statistics display

### Form Screens
- Clean, intuitive form interfaces
- GPS location capture
- Digital signature pad (DPR)
- Mock OTP verification (DPR)
- Auto-fill functionality (MPR from DPR)

### List Screens
- Comprehensive list of all entries
- Edit functionality with permission checks
- Sync status indicators
- LO-specific data filtering

### Dashboard Screen
- Statistics overview
- Line chart for MPR submissions
- Last sync time display
- Real-time data updates

## 🔧 Development

### Code Structure

```
lib/
├── main.dart              # App entry point with AuthWrapper
├── models/               # Data models
│   ├── dpr.dart         # DPR data model with loPhone
│   ├── mpr.dart         # MPR data model with loPhone
│   └── fp.dart          # FP data model
├── screens/             # UI screens
│   ├── login_screen.dart # OTP-based login
│   ├── home_screen.dart # Main navigation with logout
│   ├── dpr_form.dart   # DPR form with editing
│   ├── mpr_form.dart   # MPR form with auto-fill
│   ├── fp_form.dart    # FP form
│   ├── dpr_list.dart   # DPR list with edit functionality
│   ├── mpr_list.dart   # MPR list with edit functionality
│   └── dashboard_screen.dart # Statistics dashboard
└── services/           # Business logic
    ├── db_service.dart # Database operations with LO filtering
    ├── api_service.dart # API communication with update support
    └── sync_service.dart # Sync management with update handling
```

### Key Features

- **🔐 Authentication**: OTP-based login system
- **📱 Offline Support**: Works without internet
- **📍 Location Services**: GPS coordinate capture
- **📝 Data Validation**: Comprehensive form validation
- **🔄 Sync Management**: Automatic and manual sync
- **📋 List Views**: View and edit all entries
- **🔒 Permission Control**: LO-specific data access
- **📊 Statistics**: Real-time data visualization
- **🔄 Auto-Fill**: MPR form auto-fills from DPR data

## 🚀 Deployment

### Backend Deployment

The backend is deployed on Render with:
- **Automatic Deployment**: Git push triggers deployment
- **Health Monitoring**: Automatic health checks
- **HTTPS Support**: Secure connections
- **Database Persistence**: SQLite with PostgreSQL option
- **API Documentation**: Swagger UI available

### Mobile App Deployment

1. **Build APK**: `flutter build apk`
2. **Build iOS**: `flutter build ios`
3. **App Store**: Upload to Google Play/App Store
4. **Backend URL**: Update API endpoint for production

## 📝 License

This project is developed for the Ministry of Textiles, India.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📞 Support

For technical support or questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation at `/docs`

---

**eMTC Project** - Modernizing data collection for the Textiles Committee, Government of India. 

**Current Status**: ✅ Fully functional with LO access control, offline-first design, and comprehensive data synchronization. 