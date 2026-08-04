import cv2
import time

RTMP_URL = "rtmp://localhost:1935/live/cam"
cap = cv2.VideoCapture(RTMP_URL)

if not cap.isOpened():
    print("Error: Could not open RTMP stream")
else:
    print("Successfully opened RTMP stream")
    ret, frame = cap.read()
    if ret:
        print(f"Captured frame: {frame.shape}")
    else:
        print("Failed to capture frame")

cap.release()
