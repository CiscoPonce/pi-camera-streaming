# 🚀 Pi Camera Streaming - Deployment Guide & Status Record

This guide provides step-by-step instructions for deploying the Pi Camera Streaming system on a Raspberry Pi 5 with Camera Module 3 (imx708 sensor) and YOLO AI object detection.

---

## 📊 Live System Status Record

**Last Verified:** `2026-08-04` | **Host IP:** `192.168.1.232`

| Metric / Service | Record Value | Status | Description |
| :--- | :--- | :--- | :--- |
| **Hardware Platform** | Raspberry Pi 5 (16GB RAM) | 🟢 Active | Linux 6.8.0-1018-raspi (Ubuntu 24.04 LTS) |
| **Camera Sensor** | Sony IMX708 (Camera Module 3) | 🟢 Active | `/dev/media1` (RP1 CFE) + `/dev/media0` (PiSP ISP) |
| **libcamera Build** | v0.7.1+rpt (`/usr/local/bin`) | 🟢 Compiled | PiSP (`rpi/pisp`) hardware pipeline handler |
| **Video Pipeline** | 1280x720 @ 60 FPS (6 Mbps) | 🟢 Streaming | Streams to `rtmp://localhost:1935/live/cam` |
| **YOLO AI Service** | YOLO11 Nano (`yolo11n.pt`) | 🟢 Active | WebSocket server on `ws://0.0.0.0:8765` |
| **Web UI Frontend** | Nginx `cam-viewer` | 🟢 Active | Listening on `http://192.168.1.232/` (Port 80) |
| **SRS Engine** | SRS (Simple Realtime Server v5) | 🟢 Active | WebRTC (`1985`), RTMP (`1935`), FLV (`8081`) |
| **CPU Temp** | **57.85°C** | 🟢 Normal | Under 60 FPS streaming + AI inference load |
| **RAM Usage** | **1.7 GiB / 15.0 GiB** | 🟢 Minimal | >13.0 GiB RAM free |
| **System Test** | `./scripts/test-setup.sh` | 🟢 **7/7 Passed** | 100% verification rate |

---

## 📋 Prerequisites & Requirements

### Hardware
* **Raspberry Pi 5** (4GB+ RAM recommended)
* **Camera Module 3** (Standard or Wide imx708) with 22-pin Pi 5 CSI ribbon cable
* **Power Supply** (5V 5A USB-C)
* **Network** Ethernet or Wi-Fi

---

## 🔧 Installation & Deployment Steps

### 1. Install System Dependencies
```bash
sudo apt update && sudo apt install -y \
  build-essential git cmake meson ninja-build libboost-dev \
  libgnutls28-dev openssl libtiff-dev pybind11-dev python3-yaml python3-ply \
  libglib2.0-dev libgstreamer-plugins-base1.0-dev libdrm-dev libexif-dev \
  libepoxy-dev libjpeg-dev libpng-dev libpisp-common libpisp1 \
  python3-pip python3-opencv python3-websockets python3-numpy
```

### 2. Build Raspberry Pi 5 PiSP `libcamera` & `rpicam-apps`
*(Required on Ubuntu 24.04 to enable the Pi 5 RP1 PiSP hardware ISP driver)*

```bash
# 2.1 Clone & Build libcamera with PiSP support
git clone https://github.com/raspberrypi/libcamera.git /tmp/libcamera
cd /tmp/libcamera
meson setup build --buildtype=release -Dpipelines=rpi/vc4,rpi/pisp -Dipas=rpi/vc4,rpi/pisp -Dv4l2=true -Dpycamera=disabled -Dgstreamer=disabled -Ddocumentation=disabled
ninja -C build
sudo ninja -C build install
sudo ldconfig

# 2.2 Clone & Build rpicam-apps
git clone https://github.com/raspberrypi/rpicam-apps.git /tmp/rpicam-apps
cd /tmp/rpicam-apps
meson setup build --buildtype=release -Denable_libav=disabled -Denable_qt=disabled -Denable_opencv=disabled -Denable_tflite=disabled
ninja -C build
sudo ninja -C build install
sudo ldconfig
```

### 3. Install Python AI Vision Packages
```bash
pip3 install --break-system-packages ultralytics onnxruntime
```

### 4. Deploy Docker Containers
```bash
cd pi-camera-streaming
docker compose up -d
```

### 5. Launch Camera Streaming & YOLO AI Services
```bash
# Start 60 FPS Camera Pipeline
./scripts/start-camera.sh --profile low-latency &

# Start YOLO AI WebSocket Service
python3 ai_vision/yolo_service.py &
```

### 6. Verify System Health
```bash
./scripts/test-setup.sh
```

---

## 🌐 Network Access Endpoints

* **Web UI (Pi Camera Viewer):** `http://[PI_IP_ADDRESS]/` (Port 80)
* **YOLO AI WebSocket:** `ws://[PI_IP_ADDRESS]:8765`
* **SRS Console:** `http://[PI_IP_ADDRESS]:8081/`
* **HTTP-FLV Stream:** `http://[PI_IP_ADDRESS]:8081/live/cam.flv`
* **RTMP Endpoint:** `rtmp://[PI_IP_ADDRESS]:1935/live/cam`
