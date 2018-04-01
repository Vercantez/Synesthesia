import PlaygroundSupport
import Foundation

// Use Render Markup mode to view the following markup
/*:
 # Synesthesia
 ## Draw with sound!
 Press play and draw on the canvas by click and dragging the mouse.
 The size and color of your brush are controlled by the microphone.
 The **louder** it hears sounds, the **bigger** the brush.
 The **color** changes with the loudest **pitch/frequency**.
 Try whistling, singing, and playing music while painting!
 
 ## Song Suggestions:
 * Suspicious Waveforms - Thank You Scientist
 * Drip - Tigran Hamasyan
 * Just Jammin' - Gramatik
 * The Great Gig in the Sky - Pink Floyd
 * Glitch (feat. ROM) - Chon
 
 ## Troubleshooting:
 * Please manually execute the playground. It will not automatically run.
 * If the brush size never changes, make sure you have either a built-in microphone or a microphone connected and reset the playground by pressing stop and then play. Sometimes (rarely) the audio fails to start.
 * If the microphone is not sensitive enough or too sensitive, adjust the microphoneSensitivity value directly below.
 */

// Microphone Sensitivity
let microphoneSensitivity: Float = 100.0

// Canvas Dimensions
let width: Int = 800
let height: Int = 1000


PlaygroundPage.current.needsIndefiniteExecution = true

let newView = DrawView(frame: NSRect(x: 0, y: 0, width: width, height: height))
newView.wantsLayer = true
newView.layer?.backgroundColor = CGColor.black

let audioColorManager = AudioColorManager()
audioColorManager.micSensitivity = microphoneSensitivity

newView.brushSource = audioColorManager

PlaygroundPage.current.liveView = newView

