# Raspberry Pi 5: Vision & Streaming Integration Report

## 🎯 Achievement Overview
Successfully demonstrated a "Multi-Tasking Edge AI" workload on a Raspberry Pi 5 (16GB), running a high-definition video stream and a 4-billion parameter Vision-Language Model (Gemma 4B) simultaneously.

## 📊 Performance Metrics
| Metric | During Streaming | During AI Inference |
|--------|------------------|---------------------|
| CPU Usage | ~45% | 100% (Short Spikes) |
| RAM Usage | ~1.6GB | ~4.2GB |
| Temperature| ~55°C | ~66°C |
| Video Latency| < 500ms | Stable (No drops) |

## 🛠️ How It Was Achieved

### 1. High-Performance Streaming
We utilized the Raspberry Pi 5's hardware-accelerated `h264_v4l2m2m` encoder via `libav` to minimize CPU load during 720p30 streaming.

**Command:**
```bash
rpicam-vid -t 0 --nopreview --width 1280 --height 720 --framerate 30 \
  -g 60 -b 6000000 --codec libav --libav-video-codec h264_v4l2m2m \
  --libav-format flv -o rtmp://localhost:1935/live/cam
```

### 2. Live Frame Capture
To "feed" the AI without stopping the camera, we tapped into the local RTMP stream using `ffmpeg` to extract a single high-quality frame.

**Command:**
```bash
ffmpeg -i rtmp://localhost:1935/live/cam -frames:v 1 -q:v 2 snapshot.jpg
```

### 3. Vision-Language Inference
We employed Google's **Gemma 4B E4B** model via the **LiteRT-LM** (formerly TFLite) orchestration layer. This allowed us to use the CPU (XNNPack) efficiently for multimodal tasks.

**Command:**
```bash
litert-lm run ./gemma-4-E4B-it.litertlm \
  --attachment snapshot.jpg \
  --vision-backend cpu \
  --prompt "Describe what you see in this image."
```

## 🏗️ System Architecture
1. **Camera Module 3** captures raw video.
2. **rpicam-vid** encodes using Pi 5 hardware and sends to **SRS (Simple Realtime Server)**.
3. **SRS** distributes the stream via **WebRTC** to the browser and **RTMP** for local processing.
4. **LiteRT-LM** processes snapshots on demand to provide "Vision" capabilities.

## 🤖 AI Vision Tools

Two specialized scripts are available in this directory:

### 1. Continuous Vision Loop (`continuous_vision.sh`)
Analyzes a frame from the stream every 15 seconds (configurable) and provides a text description. Use this for general stream monitoring.

**Run:** `./continuous_vision.sh`

### 2. Intelligent Vision Sentry (`intelligent_sentry.sh`)
Uses a lightweight object detector (EfficientDet) to monitor the stream for specific targets (default: `bicycle`). Only triggers the heavy LLM analysis when the target is detected.

**Run:** `./intelligent_sentry.sh`

---
*Created during the Pi Camera Streaming & AI Integration session.*
