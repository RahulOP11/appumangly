# FER2013 Emotion Model Information

This file provides information about the FER2013 emotion detection model used for TensorFlow Lite smile detection.

## Model Details

**Model Name**: FER2013 Emotion Recognition  
**Purpose**: Facial Expression Recognition for 7 emotions  
**Classes**: 
1. Angry
2. Disgust  
3. Fear
4. Happy (Smile Detection Target)
5. Sad
6. Surprise
7. Neutral

## Model Integration

The TensorFlow Lite model should be named: `fer2013_emotion_model.tflite`

### Model Download Instructions:

1. **Option 1: Pre-trained TensorFlow Hub Model**
   - Visit: https://tfhub.dev/google/lite-model/movenet/singlepose/lightning/tflite/float16/4
   - Download emotion recognition model
   - Convert to .tflite format if needed

2. **Option 2: Kaggle FER2013 Models**
   - Visit: https://www.kaggle.com/datasets/msambare/fer2013
   - Download pre-trained emotion models
   - Use TensorFlow Lite converter

3. **Option 3: Custom Training**
   - Use FER2013 dataset
   - Train CNN model for emotion recognition
   - Convert to TensorFlow Lite format

## Model Placement

Place the downloaded `fer2013_emotion_model.tflite` file in:
```
assets/models/fer2013_emotion_model.tflite
```

## Performance Characteristics

- **Input Size**: 48x48 grayscale images
- **Output**: 7-class probability distribution
- **Target Class**: Index 3 (Happy) for smile detection
- **Confidence Threshold**: 0.6+ for reliable smile detection
- **Processing Speed**: ~50-100ms on mobile devices

## Integration Notes

The TensorFlow Lite service (`tensorflow_smile_detection.dart`) includes:
- Automatic model loading from assets
- Image preprocessing (resize, normalize)
- Inference execution
- Post-processing for smile confidence
- Advanced multi-factor analysis for enhanced accuracy

## Fallback Behavior

If model file is not available, the service provides:
- Advanced image analysis using brightness, edges, contrast
- Motion detection for facial expressions
- Mathematical confidence calculations
- Gradual degradation to basic detection

This ensures the app remains functional while the model is being acquired.