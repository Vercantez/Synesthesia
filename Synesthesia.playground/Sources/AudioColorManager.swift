import Cocoa
import AVFoundation
import Accelerate

public class AudioColorManager: BrushProvider {
    
    let audioEngine = AVAudioEngine()
    
    let micInput: AVAudioInputNode
    let micFormat: AVAudioFormat
    public var micSensitivity: Float = 100.0
    
    var maxAmp: Float = 0.0
    
    // DFT setup
    let dftSetup = vDSP_DFT_zrop_CreateSetup(nil, vDSP_Length(2048), .FORWARD)
    
    // Setup vectors for DFT
    var inputR = [Float](repeatElement(0.0, count: 2048))
    var inputI = [Float](repeatElement(0.0, count: 2048))
    var outputR = [Float](repeatElement(0.0, count: 2048/2))
    var outputI = [Float](repeatElement(0.0, count: 2048/2))
    var inputComplex: DSPSplitComplex
    
    var midPassFilter = [Float](repeatElement(0.0, count: 2048/2))
    
    let midRange = 30..<80
    
    var midFreqs = [Float](repeatElement(0.0, count: 2048/2))
    
    var maxVec: Float = 0.0
    var maxIndex = vDSP_Length(0)
    
    var window = [Float](repeatElement(0.0, count: 2048))
    
    public init() {
        
        // Initialize microphone
        micInput = audioEngine.inputNode
        micFormat = micInput.inputFormat(forBus: 0)
        
        // Initialize filter
        for i in midRange {
            midPassFilter[i] = 1.0
        }
        
        // Initialize hann window
        vDSP_hann_window(&window, vDSP_Length(window.count), Int32(vDSP_HANN_NORM))
        
        // Initialize complex audio buffer
        inputComplex = DSPSplitComplex(realp: &inputR, imagp: &inputI)
        
        // Start audio processing
        processAudioInput()
        startAudio()
    }
    
    func processAudioInput() {
        micInput.installTap(onBus: 0, bufferSize: AVAudioFrameCount(2048), format: micInput.outputFormat(forBus: 0), block: {
            buffer, _ in
            
            // Get volume/amplitude from microphone input data
            vDSP_maxmgv(buffer.floatChannelData!.pointee, 1, &self.maxAmp, 2048)
            
            // Windowing to reduce errors of DFT
            vDSP_vmul(buffer.floatChannelData!.pointee, 1, &self.window, 1, buffer.floatChannelData!.pointee, 1, 2048)
            
            // Setup data for DFT
            buffer.floatChannelData!.pointee.withMemoryRebound(to: DSPComplex.self, capacity: 2048, { (intertwined) in
                vDSP_ctoz(intertwined, 2, &self.inputComplex, 1, 2048)
            })
            
            // Compute a Discreet Fourier Transform to get loudest pitch
            vDSP_DFT_Execute(self.dftSetup!, self.inputComplex.realp, self.inputComplex.realp, &self.outputR, &self.outputI)
            
            // Very janky filtering
            vDSP_vmul(self.outputR, 1, &self.midPassFilter, 1, &self.midFreqs, 1, vDSP_Length(2048/2))
            
            // Store index of loudest pitch in maxIndex
            vDSP_maxmgvi(&self.midFreqs, 1, &self.maxVec, &self.maxIndex, vDSP_Length(2048/2))
        })
    }
    
    public var color: NSColor {
        // Calculate hue based on the loudest pitch/frequency
        // This works like a color wheel, the higher the pitch, the further around the wheel it goes
        let hue = CGFloat((1.0/Double(midRange.count))*Double(maxIndex - vDSP_Length(midRange.first!)))
        return NSColor(deviceHue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }
    
    public var width: CGFloat {
        return CGFloat(maxAmp * micSensitivity)
    }
    
    public var amplitude: Float {
        return maxAmp
    }
    
    func startAudio() {
        audioEngine.prepare()
        do {
            try audioEngine.start()
        }
        catch {
            print("error")
        }
    }
}
