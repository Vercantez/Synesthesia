import Cocoa

public protocol BrushProvider {
    var color: NSColor {
        get
    }
    
    var width: CGFloat {
        get
    }
}
