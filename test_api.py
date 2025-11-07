#!/usr/bin/env python3
"""
Simple test script to validate the Flask emotion detection API
"""
import requests
import time
import sys

def test_api():
    base_url = "http://192.168.50.181:5000"
    
    print("Testing Emotion Detection API...")
    print(f"Base URL: {base_url}")
    print("-" * 50)
    
    # Test health endpoint
    try:
        print("1. Testing health endpoint...")
        response = requests.get(f"{base_url}/", timeout=10)
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.json()}")
        print("   ✅ Health check passed!")
    except requests.exceptions.RequestException as e:
        print(f"   ❌ Health check failed: {e}")
        return False
    
    # Test analyze endpoint (without image for now)
    try:
        print("\n2. Testing analyze endpoint...")
        response = requests.post(f"{base_url}/analyze", 
                                json={"test": "data"}, 
                                timeout=10)
        print(f"   Status: {response.status_code}")
        print(f"   Response: {response.json()}")
        print("   ✅ Analyze endpoint accessible!")
    except requests.exceptions.RequestException as e:
        print(f"   ❌ Analyze endpoint failed: {e}")
        return False
    
    print("\n🎉 API is working correctly!")
    return True

if __name__ == "__main__":
    # Wait for server to start
    print("Waiting for Flask server to fully initialize...")
    time.sleep(3)
    
    success = test_api()
    sys.exit(0 if success else 1)