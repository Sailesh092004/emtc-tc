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
- **DPR Endpoint**: `https://your-app-name.onrender.com/api/v1/dpr`
- **MPR Endpoint**: `https://your-app-name.onrender.com/api/v1/mpr`
- **FP Endpoint**: `https://your-app-name.onrender.com/api/v1/fp`
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
    "household_id": "HH001",
    "respondent_name": "John Doe",
    "age": 35,
    "gender": "Male",
    "education": "Graduate",
    "occupation": "Engineer",
    "income_level": "Middle",
    "latitude": 28.6139,
    "longitude": 77.2090
  }'
```

### 3. Check Swagger UI
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

### Debug Commands

```bash
# Check if app is running
curl https://your-app-name.onrender.com/api/v1/ping

# View logs in Render dashboard
# Go to your service → Logs tab

# Test all endpoints
curl https://your-app-name.onrender.com/api/v1/stats
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

## 🎉 Success!

Once deployed, your eMTC backend will be:
- ✅ **Live and accessible** from anywhere
- ✅ **Automatically scaled** by Render
- ✅ **Monitored** for health and performance
- ✅ **Secure** with HTTPS and proper isolation
- ✅ **Easy to update** with git push

Your mobile app can now sync data to your deployed backend! 🚀 