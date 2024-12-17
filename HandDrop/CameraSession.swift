import SwiftUI
import ARKit
import Vision
import CoreML

// SwiftUI View for Camera Feed
struct CameraSession: UIViewControllerRepresentable {
    @Binding var isUsingFrontCamera: Bool
    @Binding var text: String

    func makeUIViewController(context: Context) -> ARViewController {
        ARViewController(isUsingFrontCamera: $isUsingFrontCamera, text: $text)
    }

    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
}

class ARViewController: UIViewController, ARSessionDelegate {
    var arView: ARSCNView!
    var handActionModel: HandDrop!
    var frameCounter = 0
    var queue = [MLMultiArray]()
    var queueSamplingCounter = 0
    let queueSize = 15
    let queueSamplingCount = 5
    let handPosePredictionInterval = 2
    let handActionConfidenceThreshold: Double = 0.75

    @Binding var isUsingFrontCamera: Bool
    @Binding var text: String

    init(isUsingFrontCamera: Binding<Bool>, text: Binding<String>) {
        self._isUsingFrontCamera = isUsingFrontCamera
        self._text = text
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        arView = ARSCNView(frame: view.bounds)
        arView.session.delegate = self
        view.addSubview(arView)

        configureARSession()

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
        handPoseRequest.maximumHandCount = 1
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try handler.perform([handPoseRequest])
        } catch {
            print("Failed to perform Hand Pose Request: \(error)")
            return
        }

        guard let handPoses = handPoseRequest.results, !handPoses.isEmpty else { return }

        frameCounter += 1

        if frameCounter % handPosePredictionInterval == 0 {
            for handObservation in handPoses {
                guard let keypointsMultiArray = try? handObservation.keypointsMultiArray() else { continue }

                if handObservation.chirality == .right {
                    queue.append(keypointsMultiArray)
                    queue = Array(queue.suffix(queueSize))
                    queueSamplingCounter += 1

                    if queue.count == queueSize && queueSamplingCounter % queueSamplingCount == 0 {
                        do {
                            let poses = MLMultiArray(concatenating: queue, axis: 0, dataType: .float32)
                            let prediction = try handActionModel.prediction(poses: poses)
                            let label = prediction.label
                            if let confidence = prediction.labelProbabilities[label],
                               confidence > handActionConfidenceThreshold {
                                DispatchQueue.main.async {
                                    self.renderHandPoseEffect(name: label)
                                    
                                    if prediction.label == "pinch" {
                                        UIPasteboard.general.string = self.text
                                        UIAccessibility.post(notification: .announcement, argument: "Text copied to clipboard")
                                    } else {
                                        UIAccessibility.post(notification: .announcement, argument: "Detected gesture: \(label)")
                                    }
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
        print("Detected Hand Action: \(name)")
    }
}

struct CameraSessionView: View {
    @State private var isUsingFrontCamera = true
    @State private var text: String = ""

    var body: some View {
        ZStack {
            CameraSession(isUsingFrontCamera: $isUsingFrontCamera, text: $text).ignoresSafeArea()
            Color.white.ignoresSafeArea()
            TextField("Text", text: $text)
                .accessibilityLabel("Text Input Field")
                .accessibilityHint("Enter the text to be copied to the clipboard.")
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
        }
    }
}
