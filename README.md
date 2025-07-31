# eMTC Project

A comprehensive mobile data collection system for the "Electronic Market for Textiles and Clothing (eMTC)" project by the Textiles Committee, Government of India. eMTC is a digital platform for textile consumption data collection across India, developed under the aegis of the Textiles Committee, Government of India. This project consists of a Flutter mobile app for Liaison Officers (LOs) and a FastAPI backend for data storage and synchronization.

## 🏗️ Project Architecture

```
eMTC Project/
├── 📱 Flutter Mobile App (lib/)
│   ├── models/          # Data models (DPR, MPR, FP)
│   ├── screens/         # UI screens
│   ├── services/        # Business logic & API calls
│   └── main.dart        # App entry point
├── 🖥️ FastAPI Backend (backend/)
│   ├── main.py          # FastAPI app entry point
│   ├── routes.py        # API endpoints
│   ├── models.py        # Pydantic schemas
│   ├── crud.py          # Database operations
│   ├── database.py      # Database configuration
│   └── requirements.txt # Python dependencies
└── 📚 Documentation
    └── README.md        # This file
```

## 📱 Flutter Mobile App

### Features

- **Offline-First Design**: Data collection works without internet
- **Three Form Types**:
  - **DPR**: Demographic Purchase Return (annual per household)
  - **MPR**: Monthly Purchase Return (bi-monthly per household)
  - **FP**: Forwarding Performa (summary per location)
- **GPS Location Capture**: Automatic latitude/longitude recording
- **Digital Signature**: Signature pad for DPR consent validation
- **Mock OTP Verification**: Simulated verification for development
- **Data Synchronization**: Automatic sync when internet is restored
- **Dashboard**: Statistics and charts for data visualization

### Form Fields

#### DPR Form Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| Household ID | Text | ✅ | Unique household identifier |
| Respondent Name | Text | ✅ | Name of the respondent |
| Age | Number | ✅ | Age of the respondent |
| Gender | Dropdown | ✅ | Gender selection |
| Education | Dropdown | ✅ | Education level |
| Occupation | Text | ✅ | Current occupation |
| Income Level | Dropdown | ✅ | Monthly income category |
| Location | GPS | ✅ | Auto-captured coordinates |
| OTP Verification | Code | ✅ | Mock verification |
| Digital Signature | Signature | ✅ | Consent validation |

#### MPR Form Fields
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| Household ID | Text | ✅ | Unique household identifier |
| Purchase Date | Date | ✅ | Date of purchase |
| Textile Type | Dropdown | ✅ | Type of textile purchased |
| Quantity | Number | ✅ | Quantity purchased |
| Price | Number | ✅ | Price per unit |
| Purchase Location | Text | ✅ | Where purchase was made |
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
  householdId TEXT NOT NULL,
  householdHeadName TEXT NOT NULL,
  address TEXT NOT NULL,
  phoneNumber TEXT NOT NULL,
  familySize INTEGER NOT NULL,
  monthlyIncome REAL NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  otpCode TEXT NOT NULL,
  signaturePath TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  isSynced INTEGER NOT NULL DEFAULT 0
);
```

#### MPR Table
```sql
CREATE TABLE mpr (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  householdId TEXT NOT NULL,
  purchaseDate TEXT NOT NULL,
  textileType TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  price REAL NOT NULL,
  purchaseLocation TEXT NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  createdAt TEXT NOT NULL,
  isSynced INTEGER NOT NULL DEFAULT 0
);
```

#### FP Table
```sql
CREATE TABLE fp (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  centreName TEXT NOT NULL,
  centreCode TEXT NOT NULL,
  panelSize INTEGER NOT NULL,
  mprCollected INTEGER NOT NULL,
  notCollected INTEGER NOT NULL,
  withPurchaseData INTEGER NOT NULL,
  nilMPRs INTEGER NOT NULL,
  nilSerialNos INTEGER NOT NULL,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  createdAt TEXT NOT NULL,
  isSynced INTEGER NOT NULL DEFAULT 0
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

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/v1/ping` | Health check |
| `POST` | `/api/v1/dpr` | Create DPR record |
| `POST` | `/api/v1/mpr` | Create MPR record |
| `POST` | `/api/v1/fp` | Create FP record |
| `GET` | `/api/v1/stats` | Database statistics |

### Database Schema

#### DPR Table
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

#### MPR Table
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

### Sync Process

1. **Data Collection**: Forms are saved locally with `isSynced = false`
2. **Connectivity Check**: App monitors internet connection
3. **Batch Sync**: Unsynced records are sent to backend
4. **Status Update**: Successfully synced records are marked `isSynced = true`
5. **Error Handling**: Failed syncs are retried automatically

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

## 📱 Screenshots

### Home Screen
- Navigation cards for DPR, MPR, FP forms
- Database statistics display
- Sync status indicator

### Form Screens
- Clean, intuitive form interfaces
- GPS location capture
- Digital signature pad (DPR)
- Mock OTP verification (DPR)

### Dashboard Screen
- Statistics overview
- Line chart for MPR submissions
- Last sync time display

## 🔧 Development

### Code Structure

```
lib/
├── main.dart              # App entry point
├── models/               # Data models
│   ├── dpr.dart         # DPR data model
│   ├── mpr.dart         # MPR data model
│   └── fp.dart          # FP data model
├── screens/             # UI screens
│   ├── home_screen.dart # Main navigation
│   ├── dpr_form.dart   # DPR form
│   ├── mpr_form.dart   # MPR form
│   ├── fp_form.dart    # FP form
│   └── dashboard_screen.dart # Statistics dashboard
└── services/           # Business logic
    ├── db_service.dart # Database operations
    ├── api_service.dart # API communication
    └── sync_service.dart # Sync management
```

### Key Features

- **Modular Architecture**: Clean separation of concerns
- **Provider Pattern**: State management
- **Offline Support**: Works without internet
- **Location Services**: GPS coordinate capture
- **Data Validation**: Form input validation
- **Error Handling**: Comprehensive error management

## 🚀 Deployment

### Backend Deployment

1. **Production Database**: Configure PostgreSQL
2. **Environment Variables**: Set production settings
3. **CORS Configuration**: Restrict origins
4. **SSL Certificate**: Configure HTTPS
5. **Monitoring**: Add application monitoring

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