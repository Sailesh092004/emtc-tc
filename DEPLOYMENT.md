# 🚀 Deployment Guide - eMTC Backend to Render

This guide will help you deploy your FastAPI backend to Render in just a few steps.

## 📋 Prerequisites

- GitHub account
- Render account (free tier available)
- Your code pushed to GitHub

## 🎯 Quick Deployment Steps

### Step 1: Push to GitHub

```bash
# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit changes
git commit -m "Add eMTC FastAPI backend with deployment config"

# Add remote (replace with your GitHub repo URL)
git remote add origin https://github.com/your-username/emtc

# Push to GitHub
git push -u origin main
```

### Step 2: Deploy to Render

1. **Go to [Render Dashboard](https://dashboard.render.com/)**
2. **Click "New +" → "Web Service"**
3. **Connect your GitHub repository**
4. **Configure the service:**
   - **Name**: `emtc-backend`
   - **Environment**: `Docker`
   - **Region**: Choose closest to your users
   - **Branch**: `main`
   - **Root Directory**: Leave empty (or `backend/` if you prefer)
   - **Dockerfile Path**: `backend/Dockerfile`

5. **Environment Variables** (optional - can be set later):
   ```
   DATABASE_URL=sqlite:///./mtc_nanna.db
   API_HOST=0.0.0.0
   API_PORT=8000
   DEBUG=false
   LOG_LEVEL=INFO
   ```

6. **Click "Create Web Service"**

### Step 3: Wait for Deployment

- Render will automatically build and deploy your app
- You can monitor the build logs in real-time
- Once deployed, you'll get a URL like: `https://emtc-backend.onrender.com`

## 🔧 Configuration Options

### Using PostgreSQL (Recommended for Production)

1. **Create a PostgreSQL database on Render:**
   - Go to Render Dashboard
   - Click "New +" → "PostgreSQL"
   - Configure and create the database

2. **Update environment variables:**
   ```
   DATABASE_URL=postgresql://user:password@host:port/dbname
   ```

3. **Update your app to use PostgreSQL:**
   - The code already supports PostgreSQL
   - Just change the `DATABASE_URL` environment variable

### Using SQLite (Default)

- SQLite is configured by default
- Data will persist between deployments
- Good for development and small-scale production

## 🌐 API Endpoints After Deployment

Once deployed, your API will be available at:

- **Base URL**: `https://your-app-name.onrender.com`
- **Health Check**: `https://your-app-name.onrender.com/api/v1/ping`
- **DPR Endpoints**:
  - `POST /api/v1/dpr` - Create DPR record
  - `PUT /api/v1/dpr/{dpr_id}` - Update DPR record
  - `GET /api/v1/dpr` - Get all DPR records
- **MPR Endpoints**:
  - `POST /api/v1/mpr` - Create MPR record
  - `PUT /api/v1/mpr/{mpr_id}` - Update MPR record
  - `GET /api/v1/mpr` - Get all MPR records
- **FP Endpoints**:
  - `POST /api/v1/fp` - Create FP record
  - `GET /api/v1/fp` - Get all FP records
- **Stats**: `https://your-app-name.onrender.com/api/v1/stats`
- **Swagger UI**: `https://your-app-name.onrender.com/docs`

## 📱 Update Mobile App Configuration

Update your Flutter app's API service to use the deployed URL:

```dart
// In lib/services/api_service.dart
static const String _baseUrl = 'https://your-app-name.onrender.com/api/v1';
```

## 🔍 Testing Your Deployment

### 1. Health Check
```bash
curl https://your-app-name.onrender.com/api/v1/ping
```

### 2. Test DPR Endpoint
```bash
curl -X POST https://your-app-name.onrender.com/api/v1/dpr \
  -H "Content-Type: application/json" \
  -d '{
    "name_and_address": "John Doe, 123 Main St",
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

### 3. Test MPR Endpoint
```bash
curl -X POST https://your-app-name.onrender.com/api/v1/mpr \
  -H "Content-Type: application/json" \
  -d '{
    "name_and_address": "John Doe, 123 Main St",
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
    "longitude": 72.8777
  }'
```

### 4. Test Update Endpoint
```bash
curl -X PUT https://your-app-name.onrender.com/api/v1/dpr/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name_and_address": "John Doe Updated, 123 Main St",
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

### 5. Check Swagger UI
Visit: `https://your-app-name.onrender.com/docs`

## 🚨 Troubleshooting

### Common Issues

1. **Build Fails**
   - Check the build logs in Render dashboard
   - Ensure all dependencies are in `requirements.txt`
   - Verify Dockerfile syntax

2. **App Won't Start**
   - Check environment variables
   - Verify port configuration
   - Look at application logs

3. **Database Issues**
   - Ensure `DATABASE_URL` is correct
   - Check database permissions
   - Verify SQLAlchemy configuration

4. **CORS Issues**
   - Check CORS configuration in `main.py`
   - Verify allowed origins

### Debug Commands

```bash
# Check if app is running
curl https://your-app-name.onrender.com/api/v1/ping

# View logs in Render dashboard
# Go to your service → Logs tab

# Test all endpoints
curl https://your-app-name.onrender.com/api/v1/stats

# Test GET endpoints
curl https://your-app-name.onrender.com/api/v1/dpr
curl https://your-app-name.onrender.com/api/v1/mpr
curl https://your-app-name.onrender.com/api/v1/fp
```

## 🔄 Auto-Deployment

- Render automatically deploys when you push to your main branch
- You can disable auto-deploy in the service settings
- Manual deployments are also available

## 📊 Monitoring

- **Logs**: Available in Render dashboard
- **Metrics**: Basic metrics provided by Render
- **Health Checks**: Automatic health monitoring
- **Uptime**: 99.9% uptime SLA on paid plans

## 🔒 Security Considerations

1. **Environment Variables**: Never commit sensitive data
2. **CORS**: Configure allowed origins for production
3. **Rate Limiting**: Consider adding rate limiting
4. **Authentication**: Add authentication for production use
5. **HTTPS**: Automatically provided by Render

## 💰 Cost Optimization

- **Free Tier**: 750 hours/month, auto-sleep after 15 minutes
- **Paid Plans**: Start at $7/month for always-on service
- **Database**: PostgreSQL starts at $7/month

## 🆕 New Features in Current Deployment

### Updated API Endpoints
- **PUT Endpoints**: Support for updating existing DPR and MPR records
- **GET Endpoints**: Retrieve all records for viewing in backend
- **Enhanced Error Handling**: Better error messages and validation

### Database Schema Updates
- **LO Phone Tracking**: All records now include `lo_phone` field
- **Backend ID Tracking**: Local records track backend-assigned IDs
- **JSON Storage**: Complex data stored as JSON strings

### Mobile App Features
- **LO Access Control**: OTP-based login system
- **Data Isolation**: Each LO sees only their own records
- **List Views**: View and edit all previous entries
- **Auto-Fill**: MPR form auto-fills from DPR data
- **Permission Enforcement**: Only record owners can edit

## 🎉 Success!

Once deployed, your eMTC backend will be:
- ✅ **Live and accessible** from anywhere
- ✅ **Automatically scaled** by Render
- ✅ **Monitored** for health and performance
- ✅ **Secure** with HTTPS and proper isolation
- ✅ **Easy to update** with git push
- ✅ **Supporting updates** with PUT endpoints
- ✅ **Supporting data retrieval** with GET endpoints

Your mobile app can now sync data to your deployed backend with full LO access control! 🚀 