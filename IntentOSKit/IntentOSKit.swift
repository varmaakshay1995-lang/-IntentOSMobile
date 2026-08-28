import Foundation
import SwiftUI
import UIKit
import AVFoundation
import Speech
import AppIntents
import CoreMedia
import CoreImage

#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

// MARK: - Public Configuration

public struct IntentOSConfiguration {
    public var backendURL: URL?
    public var bearerToken: String?
    public var useMockGateway: Bool

    public init(
        backendURL: URL? = nil,
        bearerToken: String? = nil,
        useMockGateway: Bool = true
    ) {
        self.backendURL = backendURL
        self.bearerToken = bearerToken
        self.useMockGateway = useMockGateway
    }
}

// MARK: - Shared Session State

@MainActor
public final class IntentOSSession: ObservableObject {
    public static let shared = IntentOSSession()

    @Published public var transcript: String = ""
    @Published public var assistantResponse: String = ""
    @Published public var latestScreenshot: UIImage?
    @Published public var isListening: Bool = false
    @Published public var isCapturing: Bool = false
    @Published public var isProcessing: Bool = false
    @Published public var lastDecision: IntentDecision?

    public var configuration = IntentOSConfiguration()

    public let speech = SpeechManager()
    public let screen = ScreenCaptureManager()
    public let executor = ActionExecutor()

    private init() {
        speech.onTranscript = { [weak self] text in
            Task { @MainActor in
                self?.transcript = text
            }
        }

        speech.onListeningStateChanged = { [weak self] listening in
            Task { @MainActor in
                self?.isListening = listening
            }
        }

        screen.onFrame = { [weak self] image in
            Task { @MainActor in
                self?.latestScreenshot = image
            }
        }

        screen.onCaptureStateChanged = { [weak self] active in
            Task { @MainActor in
                self?.isCapturing = active
            }
        }
    }

    public func requestPermissions() async {
        await speech.requestPermissions()
    }

    public func startListening() {
        do {
            try speech.startListening()
        } catch {
            assistantResponse = "Microphone start failed: \(error.localizedDescription)"
        }
    }

    public func stopListening() {
        speech.stopListening()
    }

    public func startScreenSharing() {
        screen.presentPicker()
    }

    public func sendCurrentIntent() async {
        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            assistantResponse = "Say or type what you want me to do."
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        let request = IntentRequest(
            text: text,
            screenshotBase64: latestScreenshot?.intentOSJPEGBase64(),
            platform: "iPhone / iOS",
            availableActions: executor.availableActionDescriptors
        )

        do {
            let gateway: IntentGateway
            if configuration.useMockGateway {
                gateway = MockIntentGateway()
            } else {
                guard let url = configuration.backendURL else {
                    assistantResponse = "Set IntentOSSession.shared.configuration.backendURL first."
                    return
                }
                gateway = BackendIntentGateway(url: url, bearerToken: configuration.bearerToken)
            }

            let decision = try await gateway.decide(request: request)
            lastDecision = decision

            switch decision.decision {
            case .execute:
                if decision.requiresConfirmation {
                    assistantResponse = decision.response + " Confirmation is required before execution."
                } else if let action = decision.action, let name = action.name {
                    try await executor.execute(name: name, parameters: action.parameters)
                    assistantResponse = decision.response.isEmpty ? "Done." : decision.response
                } else {
                    assistantResponse = "The model requested execution but did not provide a valid action."
                }

            case .guide, .ask, .block:
                assistantResponse = decision.response.isEmpty ? (decision.instruction ?? "") : decision.response
            }
        } catch {
            assistantResponse = "Intent processing failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Intent Data Models

public struct IntentRequest: Codable {
    public let text: String
    public let screenshotBase64: String?
    public let platform: String
    public let availableActions: [ActionDescriptor]
}

public struct ActionDescriptor: Codable {
    public let name: String
    public let description: String
    public let requiresConfirmation: Bool
}

public enum DecisionType: String, Codable {
    case execute = "EXECUTE"
    case guide = "GUIDE"
    case ask = "ASK"
    case block = "BLOCK"
}

public struct IntentDecision: Codable {
    public let decision: DecisionType
    public let intent: String
    public let confidence: Double
    public let target: String?
    public let instruction: String?
    public let action: ActionRequest?
    public let requiresConfirmation: Bool
    public let response: String
}

public struct ActionRequest: Codable {
    public let name: String?
    public let parameters: [String: String]
}

// MARK: - Speech

@MainActor
public final class SpeechManager: NSObject {
    public var onTranscript: ((String) -> Void)?
    public var onListeningStateChanged: ((Bool) -> Void)?

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    public func requestPermissions() async {
        _ = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        if #available(iOS 17.0, *) {
            _ = await AVAudioApplication.requestRecordPermission()
        } else {
            await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    public func startListening() throws {
        task?.cancel()
        task = nil

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        onListeningStateChanged?(true)

        task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                Task { @MainActor in self.onTranscript?(text) }
            }
            if error != nil {
                Task { @MainActor in self.stopListening() }
            }
        }
    }

    public func stopListening() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        onListeningStateChanged?(false)
    }
}

// MARK: - Screen Capture

@MainActor
public final class ScreenCaptureManager: NSObject {
    public var onFrame: ((UIImage) -> Void)?
    public var onCaptureStateChanged: ((Bool) -> Void)?

    #if canImport(ScreenCaptureKit)
    @available(iOS 27.0, *)
    private var stream: SCStream?
    #endif

    public override init() {
        super.init()
        #if canImport(ScreenCaptureKit)
        if #available(iOS 27.0, *) {
            SCContentSharingPicker.shared.add(self)
        }
        #endif
    }

    public func presentPicker() {
        #if canImport(ScreenCaptureKit)
        if #available(iOS 27.0, *) {
            var configuration = SCContentSharingPickerConfiguration()
            configuration.showsMicrophoneControl = false
            SCContentSharingPicker.shared.defaultConfiguration = configuration
            SCContentSharingPicker.shared.present()
        } else {
            print("ScreenCaptureKit full-display sharing requires iOS 27+ in this prototype.")
        }
        #else
        print("ScreenCaptureKit is unavailable in this SDK/toolchain.")
        #endif
    }

    #if canImport(ScreenCaptureKit)
    @available(iOS 27.0, *)
    private func startCapture(filter: SCContentFilter) async {
        let config = SCStreamConfiguration()
        config.width = Int(UIScreen.main.nativeBounds.width)
        config.height = Int(UIScreen.main.nativeBounds.height)
        config.minimumFrameInterval = CMTime(value: 1, timescale: 2) // ~2 fps

        let newStream = SCStream(filter: filter, configuration: config, delegate: nil)

        do {
            try newStream.addStreamOutput(
                self,
                type: .screen,
                sampleHandlerQueue: DispatchQueue(label: "IntentOS.ScreenCapture")
            )
            try await newStream.startCapture()
            stream = newStream
            onCaptureStateChanged?(true)
        } catch {
            print("IntentOS capture error: \(error)")
            onCaptureStateChanged?(false)
        }
    }
    #endif
}

#if canImport(ScreenCaptureKit)
@available(iOS 27.0, *)
extension ScreenCaptureManager: SCContentSharingPickerObserver {
    public nonisolated func contentSharingPicker(
        _ picker: SCContentSharingPicker,
        didUpdateWith filter: SCContentFilter,
        for stream: SCStream?
    ) {
        Task { @MainActor in
            await self.startCapture(filter: filter)
        }
    }

    public nonisolated func contentSharingPickerDidCancel(_ picker: SCContentSharingPicker) {
        Task { @MainActor in self.onCaptureStateChanged?(false) }
    }
}

@available(iOS 27.0, *)
extension ScreenCaptureManager: SCStreamOutput {
    public nonisolated func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .screen,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = UIImage(cgImage: cgImage)

        Task { @MainActor in
            self.onFrame?(image)
        }
    }
}
#endif

// MARK: - Safe Actions

public enum IntentOSError: LocalizedError {
    case invalidParameters
    case unsupportedAction
    case invalidResponse
    case badServerResponse

    public var errorDescription: String? {
        switch self {
        case .invalidParameters: return "Invalid action parameters."
        case .unsupportedAction: return "Unsupported action."
        case .invalidResponse: return "Invalid AI response."
        case .badServerResponse: return "The IntentOS backend returned an error."
        }
    }
}

@MainActor
public final class ActionExecutor {
    public let availableActionDescriptors: [ActionDescriptor] = [
        .init(name: "open_url", description: "Open an approved URL or deep link", requiresConfirmation: false),
        .init(name: "copy_text", description: "Copy text to the system clipboard", requiresConfirmation: false)
    ]

    public func execute(name: String, parameters: [String: String]) async throws {
        switch name {
        case "open_url":
            guard let raw = parameters["url"], let url = URL(string: raw) else {
                throw IntentOSError.invalidParameters
            }
            await UIApplication.shared.open(url)

        case "copy_text":
            guard let text = parameters["text"] else {
                throw IntentOSError.invalidParameters
            }
            UIPasteboard.general.string = text

        default:
            throw IntentOSError.unsupportedAction
        }
    }
}

// MARK: - AI Gateways

public protocol IntentGateway {
    func decide(request: IntentRequest) async throws -> IntentDecision
}

public final class MockIntentGateway: IntentGateway {
    public init() {}

    public func decide(request: IntentRequest) async throws -> IntentDecision {
        let lower = request.text.lowercased()

        if lower.contains("copy") {
            return IntentDecision(
                decision: .guide,
                intent: "copy visible content",
                confidence: 0.70,
                target: "visible content",
                instruction: "Tell me the exact text you want copied, or connect the live vision backend.",
                action: nil,
                requiresConfirmation: false,
                response: "Mock mode is active. Connect your backend for live screen understanding."
            )
        }

        return IntentDecision(
            decision: .guide,
            intent: request.text,
            confidence: 0.50,
            target: nil,
            instruction: "Connect the IntentOS backend to analyze the current screenshot.",
            action: nil,
            requiresConfirmation: false,
            response: "Screen capture and voice are ready. Mock AI mode is currently enabled."
        )
    }
}

public final class BackendIntentGateway: IntentGateway {
    private let url: URL
    private let bearerToken: String?

    public init(url: URL, bearerToken: String? = nil) {
        self.url = url
        self.bearerToken = bearerToken
    }

    public func decide(request: IntentRequest) async throws -> IntentDecision {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let bearerToken, !bearerToken.isEmpty {
            urlRequest.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw IntentOSError.badServerResponse
        }
        return try JSONDecoder().decode(IntentDecision.self, from: data)
    }
}

// MARK: - Screenshot Compression

public extension UIImage {
    func intentOSJPEGBase64(maxDimension: CGFloat = 1280, quality: CGFloat = 0.55) -> String? {
        let scale = min(1.0, maxDimension / max(size.width, size.height))
        let target = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)?.base64EncodedString()
    }
}

// MARK: - App Intent / Shortcut

public struct AskIntentOSIntent: AppIntent {
    public static var title: LocalizedStringResource = "Ask IntentOS"
    public static var description = IntentDescription("Open IntentOS so you can ask about your current screen.")
    public static var openAppWhenRun: Bool = true

    public init() {}

    public func perform() async throws -> some IntentResult {
        return .result()
    }
}

public struct IntentOSShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskIntentOSIntent(),
            phrases: [
                "Ask \(.applicationName)",
                "Help me with \(.applicationName)"
            ],
            shortTitle: "Ask IntentOS",
            systemImageName: "sparkles"
        )
    }
}

// MARK: - Drop-in SwiftUI Control Panel

public struct IntentOSControlPanel: View {
    @StateObject private var session = IntentOSSession.shared
    @State private var typedText = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button(session.isCapturing ? "Screen Connected" : "Share Full Screen") {
                            session.startScreenSharing()
                        }
                        .buttonStyle(.borderedProminent)

                        Button(session.isListening ? "Stop" : "Talk") {
                            if session.isListening {
                                session.stopListening()
                            } else {
                                session.startListening()
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    TextField("What do you want to do?", text: $typedText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: typedText) { _, newValue in
                            session.transcript = newValue
                        }

                    if !session.transcript.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("You")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(session.transcript)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    Button(session.isProcessing ? "Thinking…" : "Send to IntentOS") {
                        Task { await session.sendCurrentIntent() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(session.isProcessing)

                    if !session.assistantResponse.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("IntentOS")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(session.assistantResponse)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }

                    if let image = session.latestScreenshot {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.secondary.opacity(0.25))
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("IntentOS")
            .task {
                await session.requestPermissions()
            }
        }
    }
}
