import ExpoModulesCore
import AVFoundation
import Speech


class AudioRecorderManager: NSObject, AVAudioRecorderDelegate {
    private var recordingSession: AVAudioSession?
    private var audioRecorder: AVAudioRecorder?
    private let documentsPath: URL
    
    var onRecordingFinished: ((URL) -> Void)?
    var onError: ((String) -> Void)?
    
    override init() {
        self.documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        super.init()
    }
    
    func startRecording() {
        setupRecordingSession()
    }
    
    private func setupRecordingSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
            requestPermissionAndRecord()
        } catch {
            onError?("Failed to set up recording session")
        }
    }
    
    private func requestPermissionAndRecord() {
        recordingSession?.requestRecordPermission() { [weak self] allowed in
            DispatchQueue.main.async {
                if allowed {
                    self?.initializeRecorder()
                } else {
                    self?.onError?("Recording permission denied")
                }
            }
        }
    }
    
    private func initializeRecorder() {
        let audioFilename = documentsPath.appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch {
            onError?("Failed to start recording")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        let audioFilename = documentsPath.appendingPathComponent("recording.m4a")
        onRecordingFinished?(audioFilename)
        audioRecorder = nil
    }
    
    // AVAudioRecorderDelegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            onError?("Recording failed to complete successfully")
        }
    }
}

class SpeechRecognitionManager {
    private let recognizer: SFSpeechRecognizer?
    var onTranscriptionComplete: ((String) -> Void)?
    var onError: ((String) -> Void)?
    
    init() {
        recognizer = SFSpeechRecognizer()
    }
    
    
    
    func requestPermissionAndTranscribe(audioURL: URL) {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    self?.transcribeAudio(url: audioURL)
                } else {
                    self?.onError?("Transcription permission was declined")
                }
            }
        }
    }
    
    private func transcribeAudio(url: URL) {
        let request = SFSpeechURLRecognitionRequest(url: url)
        
        recognizer?.recognitionTask(with: request) { [weak self] (result, error) in
            guard let result = result else {
                self?.onError?("Transcription error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if result.isFinal {
                self?.onTranscriptionComplete?(result.bestTranscription.formattedString)
            }
        }
    }
}

public class MyModule: Module {
    
    private let audioRecorder = AudioRecorderManager()
    private let speechRecognizer = SpeechRecognitionManager()
    
    // Each module class must implement the definition function. The definition consists of components
    // that describes the module's functionality and behavior.
    // See https://docs.expo.dev/modules/module-api for more details about available components.
    public func definition() -> ModuleDefinition {
        
        OnCreate {
            setupCallbacks()
        }
        
        // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
        // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
        // The module will be accessible from `requireNativeModule('MyModule')` in JavaScript.
        Name("MyModule")
        
        // Sets constant properties on the module. Can take a dictionary or a closure that returns a dictionary.
        Constants([
            "PI": Double.pi
        ])
        
        // Defines event names that the module can send to JavaScript.
        Events("onChange")
        
        // Defines a JavaScript synchronous function that runs the native code on the JavaScript thread.
        Function("hello") {
            return "Hello world! 👋"
        }
        
        // Defines a JavaScript function that always returns a Promise and whose native code
        // is by default dispatched on the different thread than the JavaScript runtime runs on.
        AsyncFunction("setValueAsync") { (value: String) in
            // Send an event to JavaScript.
            self.sendEvent("onChange", [
                "value": value
            ])
        }
        
        // Enables the module to be used as a native view. Definition components that are accepted as part of the
        // view definition: Prop, Events.
        View(MyModuleView.self) {
            // Defines a setter for the `url` prop.
            Prop("url") { (view: MyModuleView, url: URL) in
                if view.webView.url != url {
                    view.webView.load(URLRequest(url: url))
                }
            }
            
            Events("onLoad")
        }
        
        AsyncFunction("startRecording") {
            audioRecorder.startRecording()
        }
        
        AsyncFunction("stopRecording") {
            audioRecorder.stopRecording()
        }
    }
    
    private func setupCallbacks() {
        audioRecorder.onRecordingFinished = { [weak self] audioURL in
            self?.speechRecognizer.requestPermissionAndTranscribe(audioURL: audioURL)
        }
        
        audioRecorder.onError = {  error in
            self.sendEvent("onChange", [
                "value": error
            ])
        }
        
        speechRecognizer.onTranscriptionComplete = {  transcription in
            self.sendEvent("onChange", [
                "value": transcription
            ])
        }
        
        speechRecognizer.onError = {  error in
            self.sendEvent("onChange", [
                "value": error
            ])
        }
    }
}
