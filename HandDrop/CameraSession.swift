import SwiftUI
import ARKit
import Vision
import CoreML

// SwiftUI View for Camera Feed
struct CameraSession: UIViewControllerRepresentable {
    @Binding var isUsingFrontCamera: Bool

    func makeUIViewController(context: Context) -> ARViewController {
        ARViewController(isUsingFrontCamera: $isUsingFrontCamera)
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}

// AR View Controller with Hand Action Classifier
class ARViewController: UIViewController, ARSessionDelegate {
    var arView: ARSCNView!
    var handActionModel: HandDrop! // Replace with your CoreML model
    var frameCounter = 0
    var queue = [MLMultiArray]() // Queue for storing hand poses
    var queueSamplingCounter = 0
    let queueSize = 15 // Size of the queue
    let queueSamplingCount = 5 // Sampling interval
    let handPosePredictionInterval = 2
    let handActionConfidenceThreshold: Double = 0.8

    @Binding var isUsingFrontCamera: Bool

    init(isUsingFrontCamera: Binding<Bool>) {
        self._isUsingFrontCamera = isUsingFrontCamera
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup AR view
        arView = ARSCNView(frame: view.bounds)
        arView.session.delegate = self
        view.addSubview(arView)

        configureARSession()

        // Load Hand Action Model
        do {
            handActionModel = try HandDrop(configuration: MLModelConfiguration())
        } catch {
            fatalError("Failed to load Hand Action Model: \(error)")
        }
    }

    func configureARSession() {
        let configuration: ARConfiguration
        if isUsingFrontCamera {
            configuration = ARFaceTrackingConfiguration()
        } else {
            configuration = ARWorldTrackingConfiguration()
            (configuration as! ARWorldTrackingConfiguration).planeDetection = [.horizontal, .vertical]
        }
        arView.session.run(configuration)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let pixelBuffer = frame.capturedImage
        let handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest.maximumHandCount = 2 // Adjust for multi-hand detection

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([handPoseRequest])
        } catch {
            print("Failed to perform Hand Pose Request: \(error)")
            return
        }

        guard let handPoses = handPoseRequest.results, !handPoses.isEmpty else { return }

        // Increment frame counter
        frameCounter += 1

        // Skip frames for processing
        if frameCounter % handPosePredictionInterval == 0 {
            for handObservation in handPoses {
                guard let keypointsMultiArray = try? handObservation.keypointsMultiArray() else { continue }

                if handObservation.chirality == .right {
                    // Update the FIFO queue
                    queue.append(keypointsMultiArray)
                    queue = Array(queue.suffix(queueSize))
                    queueSamplingCounter += 1

                    // Perform prediction when the queue is ready
                    if queue.count == queueSize && queueSamplingCounter % queueSamplingCount == 0 {
                        do {
                            let poses = MLMultiArray(concatenating: queue, axis: 0, dataType: .float32)
                            let prediction = try handActionModel.prediction(poses: poses)

                            // Directly access the label (no optional binding needed)
                            let label = prediction.label
                            
                            // Safely unwrap the confidence value from labelProbabilities
                            if let confidence = prediction.labelProbabilities[label],
                               confidence > handActionConfidenceThreshold {
                                DispatchQueue.main.async {
                                    self.renderHandPoseEffect(name: label)
                                }
                            }
                        } catch {
                            print("Prediction failed: \(error)")
                        }
                    }
                }
            }
        }
    }

    func renderHandPoseEffect(name: String) {
        // Visual effect based on the hand action
        print("Detected Hand Action: \(name)")
    }
}

// SwiftUI Wrapper View
struct CameraSessionView: View {
    @State private var isUsingFrontCamera = true

    var body: some View {
        ZStack {
            CameraSession(isUsingFrontCamera: $isUsingFrontCamera)
        }
    }
}
