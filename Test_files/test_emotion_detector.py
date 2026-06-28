import base64
import json
import subprocess
import sys

# Create a minimal test image (1x1 PPM)
test_image_data = b'P6\n1 1\n255\n\x80\x80\x80'  # 1x1 gray pixel
base64_image = base64.b64encode(test_image_data).decode('utf-8')

# Test the Python emotion detector
try:
    result = subprocess.run([
        'python', 'python_emotion_detector.py', base64_image
    ], capture_output=True, text=True, timeout=30)
    
    print("Exit code:", result.returncode)
    print("Stdout:", result.stdout)
    print("Stderr:", result.stderr)
    
    if result.returncode == 0:
        try:
            response = json.loads(result.stdout.strip())
            print("Parsed response:", response)
        except json.JSONDecodeError as e:
            print("Failed to parse JSON:", e)
    
except subprocess.TimeoutExpired:
    print("Process timed out")
except Exception as e:
    print("Error:", e)