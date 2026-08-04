#!/usr/bin/env python3
import os
os.environ["OPENCV_FFMPEG_READ_ATTEMPTS"] = "10000"

import asyncio
import json
import logging
import cv2
import numpy as np
import websockets
from ultralytics import YOLO

# Setup logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")

STREAM_URL = "rtmp://localhost:1935/live/cam"
MODEL_PATH = "yolo11s_openvino_model"
HOST = "0.0.0.0"
PORT = 8765

CONNECTED_CLIENTS = set()
LATEST_DETECTIONS = {"boxes": []}

def run_detection_loop(loop):
    global LATEST_DETECTIONS
    logging.info(f"Loading OpenVINO Accelerated YOLO model ({MODEL_PATH})...")
    model = YOLO(MODEL_PATH, task="detect")  # OpenVINO FP16 Accelerated Model for Pi 5
    logging.info("OpenVINO YOLO model loaded successfully!")

    cap = cv2.VideoCapture(STREAM_URL)
    if not cap.isOpened():
        logging.error(f"Failed to open video stream: {STREAM_URL}")
        while not cap.isOpened():
            cv2.waitKey(1000)
            cap = cv2.VideoCapture(STREAM_URL)

    logging.info("Connected to live camera RTMP stream. Starting OpenVINO inference loop...")
    
    frame_count = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            logging.warning("Stream frame drop. Retrying stream connection...")
            cap.release()
            cv2.waitKey(500)
            cap = cv2.VideoCapture(STREAM_URL)
            continue

        frame_count += 1
        
        # Run OpenVINO accelerated inference
        results = model.predict(frame, conf=0.35, verbose=False, imgsz=640)
        
        boxes_list = []
        if results and len(results) > 0:
            r = results[0]
            if r.boxes:
                for box in r.boxes:
                    coords = box.xyxyn[0].tolist()  # Normalized [x1, y1, x2, y2]
                    cls_id = int(box.cls[0].item())
                    conf = float(box.conf[0].item())
                    label = model.names.get(cls_id, f"class_{cls_id}")
                    
                    boxes_list.append({
                        "box": [round(c, 4) for c in coords],
                        "label": label,
                        "conf": round(conf, 2)
                    })

        LATEST_DETECTIONS = {"boxes": boxes_list}
        
        # Broadcast to WebSockets if connected clients exist
        if CONNECTED_CLIENTS:
            message = json.dumps(LATEST_DETECTIONS)
            asyncio.run_coroutine_threadsafe(broadcast_detections(message), loop)

async def broadcast_detections(message):
    if CONNECTED_CLIENTS:
        await asyncio.gather(
            *[client.send(message) for client in CONNECTED_CLIENTS if client.open],
            return_exceptions=True
        )

async def handler(websocket):
    logging.info(f"Client connected to YOLO OpenVINO WebSocket: {websocket.remote_address}")
    CONNECTED_CLIENTS.add(websocket)
    try:
        await websocket.send(json.dumps(LATEST_DETECTIONS))
        async for message in websocket:
            pass
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        logging.info(f"Client disconnected: {websocket.remote_address}")
        CONNECTED_CLIENTS.remove(websocket)

async def main():
    loop = asyncio.get_running_loop()
    loop.run_in_executor(None, run_detection_loop, loop)
    
    async with websockets.serve(handler, HOST, PORT):
        logging.info(f"YOLO OpenVINO WebSocket service listening on ws://{HOST}:{PORT}")
        await asyncio.Future()

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logging.info("YOLO Service stopped.")
