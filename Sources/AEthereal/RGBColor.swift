// See README.md for licensing information.

public struct RGBColor: Hashable {
    
    public init(r: UInt16, g: UInt16, b: UInt16) {
        self.r = r
        self.g = g
        self.b = b
    }
    
    public var r, g, b: UInt16
    
}
