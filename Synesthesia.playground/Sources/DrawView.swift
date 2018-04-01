import Cocoa

// Wrapper used to keep track of color
struct BezierPathWrapper {
    var path: NSBezierPath
    var color: NSColor
    
    public init() {
        path = NSBezierPath()
        color = .white
    }
    
    public init(color: NSColor) {
        path = NSBezierPath()
        self.color = color
    }
}

public class DrawView: NSView {
    public var brushSource: BrushProvider?
    var currentPathWrapper = BezierPathWrapper()
    var pathWrappers: [BezierPathWrapper] = []

    var cachedImage: NSImage?
    
    // Make sure brushWidth doesn't get bigger than 100.0
    var brushWidth: CGFloat {
        if let width = brushSource?.width {
            return min(width, 100.0)
        }
        return 1.0
    }
    
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        cachedImage?.draw(in: dirtyRect)
        for pathWrapper in pathWrappers {
            pathWrapper.color.set()
            pathWrapper.path.stroke()
        }
    }
    
    // Render strokes to an image to save on computation
    func renderToImage() {
        if cachedImage == nil {
            cachedImage = NSImage(size: self.frame.size)
        }
        autoreleasepool {
            cachedImage?.lockFocus()
            
            for pathWrapper in pathWrappers {
                pathWrapper.color.set()
                pathWrapper.path.stroke()
            }
            
            cachedImage?.unlockFocus()
        }
        pathWrappers.removeAll()
    }
    
    override public func mouseDown(with event: NSEvent) {
        currentPathWrapper = BezierPathWrapper(color: brushSource?.color ?? NSColor.white)
        currentPathWrapper.path.move(to: event.locationInWindow)
    }
    
    override public func mouseDragged(with event: NSEvent) {
        let point = event.locationInWindow
        currentPathWrapper.path.line(to: point)
        currentPathWrapper.path.lineWidth = brushWidth
        currentPathWrapper.path.lineCapStyle = .roundLineCapStyle
        currentPathWrapper.path.lineJoinStyle = .roundLineJoinStyle
        pathWrappers.append(currentPathWrapper)
        
        // If more than 10 segments, render to image
        if pathWrappers.count > 10 {
            renderToImage()
        }
        
        currentPathWrapper = BezierPathWrapper(color: brushSource?.color ?? NSColor.white)
        currentPathWrapper.path.move(to: point)
        needsDisplay = true
    }
    
    override public func mouseUp(with event: NSEvent) {
        renderToImage()
    }
}
