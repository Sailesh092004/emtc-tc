# Changelog

All notable changes to the eMTC project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-01-XX

### Added
- **🔐 Liaison Officer (LO) Access Control System**
  - OTP-based login system with phone number authentication
  - Mock OTP code "123456" for development
  - Session management using SharedPreferences
  - Secure logout functionality
  - Data isolation per LO using `lo_phone` field

- **📋 Enhanced List Views**
  - DPR List Screen (`dpr_list.dart`) for viewing all DPR entries
  - MPR List Screen (`mpr_list.dart`) for viewing all MPR entries
  - Edit functionality with permission checks
  - LO-specific data filtering
  - Visual sync status indicators

- **🔄 Advanced Data Synchronization**
  - PUT endpoints for updating existing records
  - GET endpoints for retrieving all records
  - Differentiation between new and updated records
  - Enhanced error handling and validation
  - Backend ID tracking for local records

- **📝 Form Enhancements**
  - Auto-fill functionality for MPR form from DPR data
  - Edit mode for existing DPR and MPR records
  - Pre-populated forms when editing
  - Enhanced form validation

- **📊 Database Schema Updates**
  - Added `lo_phone` column to DPR and MPR tables
  - Added `backend_id` column for tracking backend-assigned IDs
  - Database version incremented to 5
  - Automatic schema migration support

### Changed
- **🏗️ Project Architecture**
  - Updated main.dart with AuthWrapper for login flow
  - Enhanced database service with LO filtering methods
  - Improved API service with update support
  - Enhanced sync service with update handling

- **📱 User Interface**
  - Added login screen with phone and OTP inputs
  - Updated home screen with logout button and list view buttons
  - Enhanced form screens with edit capabilities
  - Improved navigation flow

- **🔧 Backend API**
  - Added PUT endpoints for DPR and MPR updates
  - Added GET endpoints for retrieving all records
  - Enhanced error handling and validation
  - Updated Pydantic models for update operations

### Fixed
- **🐛 Build Issues**
  - Resolved Gradle/Kotlin version conflicts
  - Fixed Android NDK version mismatches
  - Resolved file locking issues during builds
  - Optimized Flutter build performance

- **🐛 Database Issues**
  - Fixed HashMap casting errors for complex data
  - Resolved JSON serialization issues
  - Fixed database migration problems
  - Enhanced error handling for database operations

- **🐛 UI Issues**
  - Fixed scrolling problems with SingleChildScrollView
  - Added visible scrollbars to all forms
  - Resolved overflow issues
  - Improved responsive design

- **🐛 Sync Issues**
  - Fixed field name mismatches between Flutter and FastAPI
  - Resolved JSON serialization for complex objects
  - Enhanced error handling for network failures
  - Improved sync status tracking

### Removed
- **🧹 Code Cleanup**
  - Removed unused imports and variables
  - Cleaned up linter warnings
  - Removed deprecated sync dialog
  - Streamlined code structure

## [1.0.0] - 2024-01-XX

### Added
- **📱 Flutter Mobile App**
  - Basic DPR, MPR, and FP forms
  - Offline-first design with SQLite database
  - GPS location capture
  - Digital signature support
  - Mock OTP verification
  - Basic data synchronization

- **🖥️ FastAPI Backend**
  - RESTful API endpoints
  - SQLite database support
  - CORS configuration
  - Swagger UI documentation
  - Health check endpoints

- **📊 Dashboard**
  - Statistics display
  - Sync status monitoring
  - Basic charts and visualizations

- **🔄 Data Synchronization**
  - Offline data storage
  - Automatic sync when online
  - Manual sync option
  - Basic error handling

### Features
- **Form Types**
  - DPR (Demographic Purchase Return)
  - MPR (Monthly Purchase Return)
  - FP (Forwarding Performa)

- **Data Collection**
  - GPS location capture
  - Digital signatures
  - Form validation
  - Offline storage

- **Backend API**
  - POST endpoints for data submission
  - Database statistics
  - Health monitoring
  - API documentation

## Migration Guide

### From v1.0.0 to v2.0.0

1. **Database Migration**
   - The app will automatically migrate the database schema
   - New `lo_phone` and `backend_id` columns will be added
   - Existing data will be preserved

2. **Login System**
   - Users will need to log in with phone number and OTP
   - Use "123456" as the mock OTP code
   - Session will be maintained until logout

3. **Data Access**
   - Each LO will only see their own records
   - List views will show filtered data
   - Edit permissions are enforced

4. **API Updates**
   - New PUT endpoints for updates
   - New GET endpoints for data retrieval
   - Enhanced error handling

## Breaking Changes

- **Authentication Required**: All users must now log in before accessing the app
- **Data Isolation**: Users can only access their own records
- **Database Schema**: New columns added to existing tables
- **API Endpoints**: New endpoints added, existing ones enhanced

## Dependencies

### Flutter Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  location: ^6.0.0
  connectivity_plus: ^5.0.2
  http: ^1.1.0
  signature: ^5.4.0
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  fl_chart: ^0.66.0
```

### Python Dependencies
```txt
fastapi==0.104.1
uvicorn[standard]==0.24.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
python-dotenv==1.0.0
pydantic==2.5.0
python-multipart==0.0.6
```

## Contributors

- Development Team
- Textiles Committee, Government of India

## License

This project is developed for the Ministry of Textiles, India. 