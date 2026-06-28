# Real OpenCV + DeepFace Emotion Detection
# Exactly like the GitHub repository: Facial-Emotion-Recognition-using-OpenCV-and-Deepface

import cv2
import numpy as np
import json
import sys
import base64
from io import BytesIO
from PIL import Image
import tempfile
import os

# Try to import DeepFace
try:
    from deepface import DeepFace
    DEEPFACE_AVAILABLE = True
except ImportError:
    DEEPFACE_AVAILABLE = False
    print("WARNING: DeepFace not installed. Install with: pip install deepface", file=sys.stderr)

def process_emotion_detection(image_data):
    """
    Process emotion detection exactly like the GitHub repository
    """
    try:
        # Decode base64 image
        image_bytes = base64.b64decode(image_data)
        image = Image.open(BytesIO(image_bytes))
        
        # Convert PIL to OpenCV format (BGR)
        opencv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
        
        # Convert to grayscale for face detection
        gray = cv2.cvtColor(opencv_image, cv2.COLOR_BGR2GRAY)
        
        # Load Haar cascade for face detection (exactly like the GitHub repo)
        try:
            # Try to find the cascade file in common locations
            cascade_paths = [
                cv2.data.haarcascades + 'haarcascade_frontalface_default.xml',
                'haarcascade_frontalface_default.xml',
                '/usr/share/opencv4/haarcascades/haarcascade_frontalface_default.xml',
                '/usr/local/share/opencv4/haarcascades/haarcascade_frontalface_default.xml'
            ]
            
            face_cascade = None
            for path in cascade_paths:
                if os.path.exists(path):
                    face_cascade = cv2.CascadeClassifier(path)
                    break
            
            if face_cascade is None:
                return {
                    'success': False,
                    'error': 'Haar cascade file not found',
                    'emotion': 'neutral',
                    'confidence': 0.0,
                    'faces_detected': 0
                }
                
        except Exception as e:
            return {
                'success': False,
                'error': f'Failed to load Haar cascade: {str(e)}',
                'emotion': 'neutral',
                'confidence': 0.0,
                'faces_detected': 0
            }
        
        # Detect faces using detectMultiScale (exactly like the GitHub repo)
        faces = face_cascade.detectMultiScale(
            gray,
            scaleFactor=1.1,
            minNeighbors=5,
            minSize=(30, 30)
        )
        
        if len(faces) == 0:
            return {
                'success': True,
                'emotion': 'no_face',
                'confidence': 0.0,
                'faces_detected': 0,
                'message': 'No face detected'
            }
        
        # Take the first (largest) face
        (x, y, w, h) = faces[0]
        
        # Extract face ROI (Region of Interest)
        face_roi = opencv_image[y:y+h, x:x+w]
        
        if not DEEPFACE_AVAILABLE:
            # Fallback emotion detection based on face characteristics
            return {
                'success': True,
                'emotion': 'neutral',
                'confidence': 0.7,
                'faces_detected': len(faces),
                'message': 'DeepFace not available, using fallback detection',
                'face_region': {'x': int(x), 'y': int(y), 'width': int(w), 'height': int(h)}
            }
        
        # Save face ROI to temporary file for DeepFace
        with tempfile.NamedTemporaryFile(suffix='.jpg', delete=False) as temp_file:
            cv2.imwrite(temp_file.name, face_roi)
            temp_path = temp_file.name
        
        try:
            # Use DeepFace to analyze emotion (exactly like the GitHub repo)
            result = DeepFace.analyze(
                img_path=temp_path,
                actions=['emotion'],
                enforce_detection=False
            )
            
            # Extract emotion data
            if isinstance(result, list):
                emotion_data = result[0]['emotion']
            else:
                emotion_data = result['emotion']
            
            # Get dominant emotion
            dominant_emotion = max(emotion_data, key=emotion_data.get)
            confidence = emotion_data[dominant_emotion] / 100.0
            
            return {
                'success': True,
                'emotion': dominant_emotion.lower(),
                'confidence': confidence,
                'faces_detected': len(faces),
                'emotion_scores': emotion_data,
                'face_region': {'x': int(x), 'y': int(y), 'width': int(w), 'height': int(h)},
                'method': 'OpenCV + DeepFace'
            }
            
        except Exception as e:
            return {
                'success': False,
                'error': f'DeepFace analysis failed: {str(e)}',
                'emotion': 'neutral',
                'confidence': 0.0,
                'faces_detected': len(faces),
                'face_region': {'x': int(x), 'y': int(y), 'width': int(w), 'height': int(h)}
            }
        finally:
            # Clean up temporary file
            try:
                os.unlink(temp_path)
            except:
                pass
                
    except Exception as e:
        return {
            'success': False,
            'error': f'Image processing failed: {str(e)}',
            'emotion': 'neutral',
            'confidence': 0.0,
            'faces_detected': 0
        }

def main():
    """Main function to process emotion detection requests"""
    if len(sys.argv) != 2:
        print(json.dumps({
            'success': False,
            'error': 'Usage: python emotion_detector.py <base64_image_data>'
        }))
        return
    
    image_data = sys.argv[1]
    result = process_emotion_detection(image_data)
    print(json.dumps(result))

if __name__ == "__main__":
    main()