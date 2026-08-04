#!/bin/bash

# Configuration
LLM_MODEL="./models/gemma-4-E4B-it.litertlm"
DETECTOR_MODEL="./models/detector.tflite"
STREAM="rtmp://localhost:1935/live/cam"
TARGET="bicycle" # Change to "person", "car", etc.
PROMPT="A $TARGET has been detected in the security camera stream. Please describe its location, movement, and any other relevant details you see in the image."

# Activation of environment
# source detection_env/bin/activate
PYTHON_VENV="./detection_env/bin/python3"

echo "Starting Intelligent Vision Sentry..."
echo "Monitoring for: $TARGET"
echo "Stream: $STREAM"

while true; do
    # 1. Capture a low-res frame for detection (fast)
    ffmpeg -y -i "$STREAM" -frames:v 1 -q:v 5 ./models/snapshot_low.jpg > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        # 2. Run the Lite Detector (efficient)
        $PYTHON_VENV detect.py ./models/snapshot_low.jpg "$DETECTOR_MODEL" "$TARGET"
        
        if [ $? -eq 0 ]; then
            echo "[$(date +%H:%M:%S)] 🔔 ALERT: $TARGET detected! Triggering deep analysis..."
            
            # 3. Capture a high-res frame for the LLM
            ffmpeg -y -i "$STREAM" -frames:v 1 -q:v 2 ./models/snapshot_high.jpg > /dev/null 2>&1
            
            # 4. Run the high-fidelity Vision model
            RESPONSE=$(litert-lm run "$LLM_MODEL" \
                --attachment ./models/snapshot_high.jpg \
                --backend cpu \
                --vision-backend cpu \
                --max-num-tokens 2048 \
                --prompt "$PROMPT" 2>/dev/null)
            
            echo "----------------------------------------"
            echo "AI REPORT: $RESPONSE"
            echo "----------------------------------------"
            
            # Sleep a bit longer after an alert to avoid spamming
            sleep 30
        fi
    fi
    
    # Fast polling for detection (every 2 seconds)
    sleep 2
done
