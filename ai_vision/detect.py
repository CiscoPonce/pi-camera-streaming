import cv2
import numpy as np
import tflite_runtime.interpreter as tflite
import sys
import time

def detect_objects(image_path, model_path, target_class="bicycle", min_conf=0.4):
    # Load the TFLite model and allocate tensors
    interpreter = tflite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()

    # Get input and output details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    height = input_details[0]['shape'][1]
    width = input_details[0]['shape'][2]

    # Load and preprocess the image
    img = cv2.imread(image_path)
    img_rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img_resized = cv2.resize(img_rgb, (width, height))
    input_data = np.expand_dims(img_resized, axis=0)

    # Run inference
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()

    # Retrieve detection results
    # EfficientDet-Lite0 outputs: [detection_boxes, detection_classes, detection_scores, num_detections]
    boxes = interpreter.get_tensor(output_details[0]['index'])[0]
    classes = interpreter.get_tensor(output_details[1]['index'])[0]
    scores = interpreter.get_tensor(output_details[2]['index'])[0]

    # Common COCO labels (EfficientDet uses COCO)
    # bicycle is typically index 1 (0: person, 1: bicycle, 2: car, 3: motorcycle...)
    labels = {0: "person", 1: "bicycle", 2: "car", 3: "motorcycle", 5: "bus", 7: "truck"}

    detected = False
    for i in range(len(scores)):
        if scores[i] > min_conf:
            class_id = int(classes[i])
            label = labels.get(class_id, "unknown")
            if label == target_class:
                print(f"DETECTED: {label} with confidence {scores[i]:.2f}")
                detected = True
                break
    
    return detected

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python detect.py <image_path> <model_path> [target_class]")
        sys.exit(1)
    
    image = sys.argv[1]
    model = sys.argv[2]
    target = sys.argv[3] if len(sys.argv) > 3 else "bicycle"
    
    if detect_objects(image, model, target):
        sys.exit(0) # Success (Trigger)
    else:
        sys.exit(1) # No detection
