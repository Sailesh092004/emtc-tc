#!/usr/bin/env python3
"""
Test script for deployed eMTC API
Replace YOUR_RENDER_URL with your actual Render URL
"""

import requests
import json
import sys
from datetime import datetime

# Replace with your actual Render URL
RENDER_URL = "https://your-app-name.onrender.com"
API_BASE_URL = f"{RENDER_URL}/api/v1"

def test_health_check():
    """Test the health check endpoint"""
    print("🏥 Testing health check...")
    try:
        response = requests.get(f"{API_BASE_URL}/ping", timeout=10)
        if response.status_code == 200:
            print("✅ Health check passed")
            print(f"   Response: {response.json()}")
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

def test_dpr_endpoint():
    """Test the DPR endpoint"""
    print("\n📝 Testing DPR endpoint...")
    
    dpr_data = {
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
    
    try:
        response = requests.post(
            f"{API_BASE_URL}/dpr",
            json=dpr_data,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        if response.status_code == 200:
            print("✅ DPR endpoint passed")
            result = response.json()
            print(f"   Message: {result.get('message')}")
            print(f"   Data: {result.get('data')}")
            return True
        else:
            print(f"❌ DPR endpoint failed: {response.status_code}")
            print(f"   Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ DPR endpoint error: {e}")
        return False

def test_mpr_endpoint():
    """Test the MPR endpoint"""
    print("\n🛍️ Testing MPR endpoint...")
    
    mpr_data = {
        "household_id": "HH001",
        "purchase_date": "2024-01-15",
        "textile_type": "Cotton",
        "quantity": 2,
        "price": 1500.0,
        "purchase_location": "Local Market",
        "latitude": 28.6139,
        "longitude": 77.2090
    }
    
    try:
        response = requests.post(
            f"{API_BASE_URL}/mpr",
            json=mpr_data,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        if response.status_code == 200:
            print("✅ MPR endpoint passed")
            result = response.json()
            print(f"   Message: {result.get('message')}")
            print(f"   Data: {result.get('data')}")
            return True
        else:
            print(f"❌ MPR endpoint failed: {response.status_code}")
            print(f"   Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ MPR endpoint error: {e}")
        return False

def test_fp_endpoint():
    """Test the FP endpoint"""
    print("\n📊 Testing FP endpoint...")
    
    fp_data = {
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
    
    try:
        response = requests.post(
            f"{API_BASE_URL}/fp",
            json=fp_data,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        if response.status_code == 200:
            print("✅ FP endpoint passed")
            result = response.json()
            print(f"   Message: {result.get('message')}")
            print(f"   Data: {result.get('data')}")
            return True
        else:
            print(f"❌ FP endpoint failed: {response.status_code}")
            print(f"   Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ FP endpoint error: {e}")
        return False

def test_stats_endpoint():
    """Test the stats endpoint"""
    print("\n📈 Testing stats endpoint...")
    
    try:
        response = requests.get(f"{API_BASE_URL}/stats", timeout=10)
        
        if response.status_code == 200:
            print("✅ Stats endpoint passed")
            result = response.json()
            print(f"   Message: {result.get('message')}")
            print(f"   Data: {result.get('data')}")
            return True
        else:
            print(f"❌ Stats endpoint failed: {response.status_code}")
            print(f"   Error: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Stats endpoint error: {e}")
        return False

def test_root_endpoint():
    """Test the root endpoint"""
    print("\n🏠 Testing root endpoint...")
    
    try:
        response = requests.get(RENDER_URL, timeout=10)
        
        if response.status_code == 200:
            print("✅ Root endpoint passed")
            print(f"   Response: {response.json()}")
            return True
        else:
            print(f"❌ Root endpoint failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Root endpoint error: {e}")
        return False

def main():
    """Run all tests"""
    print("🚀 Testing Deployed eMTC API")
    print("=" * 50)
    print(f"🌐 Testing URL: {RENDER_URL}")
    print(f"⏰ Test Time: {datetime.now()}")
    print("=" * 50)
    
    # Check if URL is configured
    if "your-app-name" in RENDER_URL:
        print("⚠️  Please update RENDER_URL in this script with your actual Render URL")
        print("   Example: RENDER_URL = 'https://emtc-backend.onrender.com'")
        return False
    
    tests = [
        test_root_endpoint,
        test_health_check,
        test_dpr_endpoint,
        test_mpr_endpoint,
        test_fp_endpoint,
        test_stats_endpoint
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        if test():
            passed += 1
    
    print("\n" + "=" * 50)
    print(f"📊 Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! Your deployed API is working correctly.")
        print("\n📖 Your API is ready for use:")
        print(f"   - Swagger UI: {RENDER_URL}/docs")
        print(f"   - ReDoc: {RENDER_URL}/redoc")
        print(f"   - Health Check: {API_BASE_URL}/ping")
        print("\n📱 Update your mobile app with this URL:")
        print(f"   static const String _baseUrl = '{API_BASE_URL}';")
    else:
        print("❌ Some tests failed. Please check your deployment.")
        print("   - Check Render dashboard for logs")
        print("   - Verify environment variables")
        print("   - Ensure the service is running")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 