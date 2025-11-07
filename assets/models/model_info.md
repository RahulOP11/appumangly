# Mock Emotion Detection Model

This is a mock TensorFlow Lite model for testing offline emotion detection:

- Input: 48x48x1 (grayscale image)
- Output: 7 emotion classes [angry, disgust, fear, happy, sad, surprise, neutral]
- Note: This is an untrained model for testing purposes only

## Usage:
1. Use this model to test the Flutter integration
2. Replace with a properly trained model for production use
3. The model expects normalized input values (0.0 to 1.0)

## Emotion Classes:
0: angry
1: disgust  
2: fear
3: happy
4: sad
5: surprise
6: neutral
