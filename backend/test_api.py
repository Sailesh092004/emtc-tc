#!/usr/bin/env python3
"""
Test script for eMTC API
Run this script to test all API endpoints
"""

import requests
import json
import time
from datetime import datetime

# API base URL
BASE_URL = "http://localhost:8000/api/v1"

def test_health_check():
    """Test the health check endpoint"""
    print("Testing health check...")
    try:
        response = requests.get(f"{BASE_URL}/ping")
        if response.status_code == 200:
            print("✅ Health check passed")
            print(f"   Response: {response.json()}")
        else:
            print(f"❌ Health check failed: {response.status_code}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Health check error: {e}")
        return False

def test_dpr_endpoint():
    """Test the DPR endpoint"""
    print("\nTesting DPR endpoint...")
    
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
            f"{BASE_URL}/dpr",
            json=dpr_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            print("✅ DPR endpoint passed")
            result = response.json()
            print(f"   Message: {result.get('message')}")
            print(f"   Data: {result.get('data')}")
        else:
            print(f"❌ DPR endpoint failed: {response.status_code}")
            print(f"   Error: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ DPR endpoint error: {e}")
        return False

def test_mpr_endpoint():
    """Test the MPR endpoint"""
    print("\nTesting MPR endpoint...")
    
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
            f"{BASE_URL}/mpr",
            json=mpr_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            print("✅ MPR endpoint passed")
            result = response.json()
            print(f"   Message: {result.get('message')}")
            print(f"   Data: {result.get('data')}")
        else:
            print(f"❌ MPR endpoint failed: {response.status_code}")
            print(f"   Error: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ MPR endpoint error: {e}")
        return False

def test_fp_endpoint():
    """Test the FP endpoint"""
    print("\nTesting FP endpoint...")
    
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
            f"{BASE_URL}/fp",
            json=fp_data,
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            print("✅ FP endpoint passed")
            result = response.json()
            print(f"   Message: {result.get('message')}")
            print(f"   Data: {result.get('data')}")
        else:
            print(f"❌ FP endpoint failed: {response.status_code}")
            print(f"   Error: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ FP endpoint error: {e}")
        return False

def test_stats_endpoint():
    """Test the stats endpoint"""
    print("\nTesting stats endpoint...")
    
    try:
        response = requests.get(f"{BASE_URL}/stats")
        
        if response.status_code == 200:
            print("✅ Stats endpoint passed")
            result = response.json()
            print(f"   Message: {result.get('message')}")
            print(f"   Data: {result.get('data')}")
        else:
            print(f"❌ Stats endpoint failed: {response.status_code}")
            print(f"   Error: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Stats endpoint error: {e}")
        return False

def test_root_endpoint():
    """Test the root endpoint"""
    print("\nTesting root endpoint...")
    
    try:
        response = requests.get("http://localhost:8000/")
        
        if response.status_code == 200:
            print("✅ Root endpoint passed")
            print(f"   Response: {response.json()}")
        else:
            print(f"❌ Root endpoint failed: {response.status_code}")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Root endpoint error: {e}")
        return False

def main():
    """Run all tests"""
    print("🚀 Starting eMTC API Tests")
    print("=" * 50)
    
    # Wait a moment for server to start
    time.sleep(2)
    
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
        print("🎉 All tests passed! API is working correctly.")
        print("\n📖 You can now:")
        print("   - Visit http://localhost:8000/docs for Swagger UI")
        print("   - Visit http://localhost:8000/redoc for ReDoc")
        print("   - Use the API endpoints in your mobile app")
    else:
        print("❌ Some tests failed. Please check the server logs.")
    
    return passed == total

if __name__ == "__main__":
    main() 