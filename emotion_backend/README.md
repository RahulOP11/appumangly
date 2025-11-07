# Emotion Detection Backend

## Setup Instructions

1. **Install Dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Run the Server:**
   ```bash
   python app.py
   ```

3. **Test the API:**
   - Health check: GET http://localhost:5000/
   - Emotion analysis: POST http://localhost:5000/analyze

## API Endpoints

### GET / (Health Check)
Returns server status information.

### POST /analyze (Emotion Analysis)
Analyzes emotion from an uploaded image.

**Input Options:**
1. **Multipart form data:** Upload image file with key 'image'
2. **JSON with base64:** Send base64 encoded image in 'image_data' field

**Response:**
```json
{
  "success": true,
  "emotion": "happy",
  "confidence": 0.85,
  "faces_detected": 1,
  "emotion_scores": {
    "happy": 0.85,
    "neutral": 0.10,
    "sad": 0.05
  },
  "message": "Successfully detected happy emotion"
}
```

## Network Configuration

For mobile app connection:
- Find your PC's IP address: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
- Use `http://YOUR_IP:5000/analyze` in Flutter app
- Ensure both devices are on the same WiFi network

## Supported Emotions

- angry
- disgust  
- fear
- happy
- sad
- surprise
- neutral