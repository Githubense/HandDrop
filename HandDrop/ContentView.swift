import SwiftUI
import ARKit
import Vision
import CoreML
import PhotosUI
import UIKit

struct ContentView: View {
    @State private var selectedMode: Mode = .text
    @State private var text: String = ""
    @State private var selectedPhoto: UIImage?
    @State private var isPhotoPickerPresented = false

    var body: some View {
        VStack {
            HStack {
                Text("HandDrop")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(alignment: .leading)
                    .padding(.leading)
                    .accessibilityIdentifier("title")
                    .accessibilityLabel("HandDrop app")
                
                Spacer()
                
                Button() {
                    
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .fontWeight(.bold)
                        .frame(alignment: .trailing)
                        .padding(.trailing)
                        .accessibilityLabel("Settings")
                        .accessibilityHint("Opens settings")
                }
            }
            
            Picker("Select Mode", selection: $selectedMode) {
                Label("Text", systemImage: "textformat")
                    .tag(Mode.text)
                Label("Photos", systemImage: "photo")
                    .tag(Mode.photos)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            .accessibilityLabel("Select Mode")
            .accessibilityHint("Select either text or photos mode")
            
            ZStack {
                CameraSessionView(mode: $selectedMode, text: $text, selectedPhoto: $selectedPhoto).opacity(0)
                
                if selectedMode == .text {
                    VStack {
                        TextField("Enter text to copy", text: $text)
                            .padding()
                            .background(.regularMaterial)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                            .font(.title3)
                            .padding(.horizontal)
                            .accessibilityLabel("Text Input")
                            .accessibilityHint("Enter the text to be copied")
                    }
                } else if selectedMode == .photos {
                    VStack {
                        if let photo = selectedPhoto {
                            VStack {
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 300)
                                    .accessibilityLabel("Selected Photo")
                                    .accessibilityHint("This is the selected photo")

                                Button(action: {
                                    isPhotoPickerPresented.toggle()
                                }) {
                                    Text("Select Photo")
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .accessibilityLabel("Select Photo Button")
                                .accessibilityHint("Tap to select a photo")
                            }
                        } else {
                            Button(action: {
                                isPhotoPickerPresented.toggle()
                            }) {
                                Text("Select Photo")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .accessibilityLabel("Select Photo Button")
                            .accessibilityHint("Tap to select a photo")
                        }
                    }
                    .sheet(isPresented: $isPhotoPickerPresented) {
                        PhotoPicker(selectedPhoto: $selectedPhoto)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .padding()
    }

    enum Mode: String {
        case text, photos
    }
}

struct CameraSessionView: View {
    @State private var isUsingFrontCamera = true
    @Binding var mode: ContentView.Mode
    @Binding var text: String
    @Binding var selectedPhoto: UIImage?

    var body: some View {
        ZStack {
            CameraSession(isUsingFrontCamera: $isUsingFrontCamera, mode: $mode, text: $text, selectedPhoto: $selectedPhoto)
        }
    }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedPhoto: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadObject(ofClass: UIImage.self) { object, _ in
                DispatchQueue.main.async {
                    self.parent.selectedPhoto = object as? UIImage
                    UIAccessibility.post(notification: .announcement, argument: "Photo selected")
                }
            }
        }
    }
}

struct CameraSession: UIViewControllerRepresentable {
    @Binding var isUsingFrontCamera: Bool
    @Binding var mode: ContentView.Mode
    @Binding var text: String
    @Binding var selectedPhoto: UIImage?

    func makeUIViewController(context: Context) -> ARViewController {
        ARViewController(isUsingFrontCamera: $isUsingFrontCamera, mode: $mode, text: $text, selectedPhoto: $selectedPhoto)
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
    @Binding var mode: ContentView.Mode
    @Binding var text: String
    @Binding var selectedPhoto: UIImage?

    init(isUsingFrontCamera: Binding<Bool>, mode: Binding<ContentView.Mode>, text: Binding<String>, selectedPhoto: Binding<UIImage?>) {
        self._isUsingFrontCamera = isUsingFrontCamera
        self._mode = mode
        self._text = text
        self._selectedPhoto = selectedPhoto
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
                                    self.handleGestureDetection(label: label)
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

    func handleGestureDetection(label: String) {
        if label == "pinch" {
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()

            if mode == .text {
                UIPasteboard.general.string = text
                UIAccessibility.post(notification: .announcement, argument: "Text copied to clipboard")
            } else if mode == .photos, let photo = selectedPhoto {
                UIPasteboard.general.image = photo
                UIAccessibility.post(notification: .announcement, argument: "Photo copied to clipboard")
            }
        }
    }
}

#Preview {
    ContentView()
}
