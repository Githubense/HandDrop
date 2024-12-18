# HandDrop: Gesture-Powered Content Sharing App

Welcome to **HandDrop**, an innovative app that combines the power of **hand gestures** with Apple's **AirDrop** and **Handoff** technologies. Seamlessly share content between devices using real-time hand action recognition powered by ARKit and CoreML.

---

## Features

- **Gesture-Driven Sharing**: Use intuitive hand gestures to share text or photos between Apple devices.
- **AirDrop Integration**: Instantly transfer content to nearby devices using AirDrop.
- **Handoff Support**: Continue working on shared content across your Apple ecosystem.
- **Real-Time Hand Action Detection**: Accurate and responsive gesture recognition using the latest CoreML Hand Action Classifier.
- **Accessible Design**: User-friendly interface with comprehensive accessibility features.

---

## How It Works

1. **Hand Action Classifier**:
   - Detects and classifies gestures using a queue of 15 frames for real-time inference.
   - Trained on sequences of hand poses to recognize specific actions like "pinch."
2. **AirDrop and Handoff**:
   - Automatically invokes AirDrop for nearby devices when a share gesture is detected.
   - Enables Handoff for seamless continuation of tasks across devices.
3. **ARKit and Vision Integration**:
   - Captures live video feed to detect hand poses and process gesture data.
4. **CoreML Model**:
   - Processes gesture data to classify actions and trigger content-sharing workflows.

---

## Setup and Requirements

### Prerequisites
- **Xcode 15 or later**
- **iOS 17 or later**
- **Device with A12 Bionic chip or newer**

### Installation
1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/HandDrop.git
   ```
2. Open the project in Xcode:
   ```bash
   cd HandDrop
   open HandDrop.xcodeproj
   ```
3. Build and run the app on a physical device. (Hand tracking requires hardware support not available in the simulator.)

---

## Core Technologies

- **SwiftUI**: For a modern, adaptive user interface.
- **ARKit**: Provides real-time hand tracking and gesture detection.
- **Vision**: Analyzes video frames for hand pose data.
- **CoreML**: Powers the Hand Action Classifier to recognize gestures.
- **AirDrop**: Enables seamless content sharing between devices.
- **Handoff**: Supports continuity of work across the Apple ecosystem.

---

## How to Use

1. **Launch the App**:
   - Choose between **Text** or **Photo** mode.
2. **Perform a Gesture**:
   - Use the "pinch" gesture to initiate content sharing.
3. **Select a Target Device**:
   - AirDrop automatically detects nearby devices. Select the desired device to share content.
4. **Handoff**:
   - If enabled, pick up your task seamlessly on another device in your Apple ecosystem.

---

## Model Details

- **Training**:
  - Videos recorded at 30 fps, 0.5 seconds long, with a queue size of 15 frames for inference.
  - Data augmentation ensures robust gesture recognition.
- **Inference**:
  - Real-time classification optimized for low latency and high accuracy.

---

## Accessibility

HandDrop ensures accessibility by:
- Providing clear labels and hints for all interactive elements.
- Offering real-time feedback for gestures and sharing actions.

---

## Acknowledgments

HandDrop is inspired by the WWDC session ["Build an Action Classifier with Create ML"](https://developer.apple.com/videos/play/wwdc2021/10039). Special thanks to the Vision and CoreML teams for enabling gesture-powered interactions.

---

Elevate your content sharing experience with **HandDrop** — the future of gesture-based collaboration!
```

This README highlights the integration of **AirDrop** and **Handoff** while maintaining clarity about the app's functionality. Let me know if further adjustments are needed! 🚀
