# 📡 API Documentation

This document describes the APIs and endpoints available in the Pi Camera Streaming system.

## 🌐 Web Interface API

### Stream Endpoints

| Endpoint | Protocol | Description |
|----------|----------|-------------|
| `/` | HTTP | Main web interface |
| `/live/cam.flv` | HTTP-FLV | Direct FLV stream |
| `/rtc/v1/play/` | WebRTC | WebRTC streaming API |

### WebRTC API

#### Play Stream
```http
POST http://[PI_IP]:1985/rtc/v1/play/
Content-Type: application/json

{
  "api": "http://[PI_IP]:1985/rtc/v1/play/",
  "streamurl": "webrtc://[PI_IP]/live/cam",
  "sdp": "[SDP_OFFER]"
}
```

**Response**:
```json
{
  "code": 0,
  "sdp": "[SDP_ANSWER]"
}
```

## 📊 SRS Server API

### Stream Information

#### Get Active Streams
```http
GET http://[PI_IP]:1985/api/v1/streams/
```

**Response**:
```json
{
  "code": 0,
  "server": "vid-446h329",
  "service": "19r0m513",
  "pid": "1",
  "streams": [
    {
      "id": "vid-ii671sl",
      "name": "cam",
      "vhost": "vid-xn5qd67",
      "app": "live",
      "tcUrl": "rtmp://[PI_IP]:1935/live",
      "url": "/live/cam",
      "live_ms": 1756925547701,
      "clients": 1,
      "frames": 7211,
      "send_bytes": 4292,
      "recv_bytes": 186355594,
      "kbps": {
        "recv_30s": 11894,
        "send_30s": 0
      },
      "publish": {
        "active": true,
        "cid": "8j822yz7"
      },
      "video": {
        "codec": "H264",
        "profile": "High",
        "level": "4.1",
        "width": 1280,
        "height": 720
      },
      "audio": null
    }
  ]
}
```

#### Get Stream Statistics
```http
GET http://[PI_IP]:1985/api/v1/streams/[STREAM_ID]
```

#### Get Server Information
```http
GET http://[PI_IP]:1985/api/v1/summaries
```

## 🎥 Camera Control API

### Script Parameters

The `start-camera.sh` script accepts the following parameters:

#### Command Line Options

| Option | Description | Example |
|--------|-------------|---------|
| `--profile` | Use predefined performance profile | `--profile day` |
| `--width` | Set video width | `--width 1920` |
| `--height` | Set video height | `--height 1080` |
| `--fps` | Set framerate | `--fps 30` |
| `--bitrate` | Set bitrate in bps | `--bitrate 8000000` |
| `--gop` | Set GOP size | `--gop 60` |
| `--verbose` | Enable verbose logging | `--verbose` |

#### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `STREAM_NAME` | `cam` | Stream identifier |
| `CAMERA_WIDTH` | `1280` | Video width |
| `CAMERA_HEIGHT` | `720` | Video height |
| `CAMERA_FPS` | `30` | Frames per second |
| `CAMERA_BITRATE` | `6000000` | Bitrate in bps |
| `GOP_SIZE` | `60` | GOP size in frames |
| `SRS_HOST` | `localhost` | SRS server hostname |
| `SRS_PORT` | `1935` | SRS server port |

### Performance Profiles

#### Day Profile
```bash
./scripts/start-camera.sh --profile day
```
- Resolution: 1920×1080
- Framerate: 25 fps
- Bitrate: 8 Mbps
- GOP: 120 frames

#### Night Profile
```bash
./scripts/start-camera.sh --profile night
```
- Resolution: 1280×720
- Framerate: 30 fps
- Bitrate: 4 Mbps
- GOP: 60 frames

#### Low-Latency Profile
```bash
./scripts/start-camera.sh --profile low-latency
```
- Resolution: 1280×720
- Framerate: 60 fps
- Bitrate: 6 Mbps
- GOP: 30 frames

## 🔧 Docker API

### Container Management

#### Start Services
```bash
docker compose up -d
```

#### Stop Services
```bash
docker compose down
```

#### Restart Services
```bash
docker compose restart
```

#### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f srs
docker compose logs -f cam-viewer
```

#### Check Status
```bash
docker compose ps
```

### Service Configuration

#### SRS Server
- **Port**: 1935 (RTMP), 1985 (API), 8081 (HTTP)
- **Image**: `ossrs/srs:5`
- **Config**: `config/srs.conf`

#### Web Viewer
- **Port**: 80 (HTTP)
- **Image**: `nginx:alpine`
- **Config**: `config/nginx.conf`

## 📱 WebRTC Configuration

### ICE Servers
```javascript
const iceServers = [
  { urls: 'stun:stun.l.google.com:19302' },
  { urls: 'stun:stun1.l.google.com:19302' }
];
```

### Connection Parameters
- **Protocol**: WebRTC
- **Codec**: H.264
- **Transport**: UDP
- **ICE**: STUN servers configured

## 🔍 Monitoring Endpoints

### Health Checks

#### SRS Server Health
```http
GET http://[PI_IP]:1985/api/v1/summaries
```

#### Stream Health
```http
GET http://[PI_IP]:1985/api/v1/streams/
```

#### Web Interface Health
```http
GET http://[PI_IP]/
```

### Performance Metrics

#### Stream Statistics
- **Frames**: Total frames processed
- **Bytes**: Data transferred
- **Kbps**: Bandwidth usage
- **Clients**: Active connections
- **Latency**: Stream delay

#### System Metrics
- **CPU Usage**: Process utilization
- **Memory**: RAM consumption
- **Network**: Bandwidth utilization
- **Temperature**: System temperature

## 🛠️ Development API

### Testing Endpoints

#### Test Camera
```bash
./scripts/test-setup.sh
```

#### Test Stream
```bash
# Test FLV stream
curl -I http://[PI_IP]:8081/live/cam.flv

# Test WebRTC API
curl -X POST http://[PI_IP]:1985/rtc/v1/play/ \
  -H "Content-Type: application/json" \
  -d '{"api":"http://[PI_IP]:1985/rtc/v1/play/","streamurl":"webrtc://[PI_IP]/live/cam","sdp":"test"}'
```

### Debug Mode

#### Enable Verbose Logging
```bash
./scripts/start-camera.sh --verbose
```

#### View System Logs
```bash
# Docker logs
docker compose logs -f

# System logs
sudo journalctl -u pi-camera-streaming -f

# Camera logs
dmesg | grep -i camera
```

## 📋 Error Codes

### SRS API Error Codes

| Code | Description |
|------|-------------|
| 0 | Success |
| 400 | Bad Request |
| 404 | Not Found |
| 500 | Internal Server Error |

### Common Error Responses

#### Stream Not Found
```json
{
  "code": 404,
  "message": "Stream not found"
}
```

#### Server Error
```json
{
  "code": 500,
  "message": "Internal server error"
}
```

---

*For more information, refer to the main README.md or create an issue on GitHub.*
