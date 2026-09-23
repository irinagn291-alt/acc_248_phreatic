import Foundation

/// Bayer ordered-dither helpers. Maps a 0...1 luminance through a 4x4
/// threshold matrix so a gradient can be rasterized as visible checker
/// texture at runtime scale.
public enum OrderedDither {
    public static let matrixWidth = 4

    public static let bayer4x4: [UInt8] = [
        0, 8, 2, 10,
        12, 4, 14, 6,
        3, 11, 1, 9,
        15, 7, 13, 5,
    ]

    public static func threshold(x: Int, y: Int) -> Double {
        let column = ((x % matrixWidth) + matrixWidth) % matrixWidth
        let row = ((y % matrixWidth) + matrixWidth) % matrixWidth
        let index = row * matrixWidth + column
        let raw = bayer4x4[index]
        return (Double(raw) + 0.5) / 16.0
    }

    public static func quantize(value: Double, x: Int, y: Int, levels: Int) -> Double {
        let clamped = value.isFinite ? min(1, max(0, value)) : 0
        let steps = max(2, levels)
        let dithered = min(1, max(0, clamped + (threshold(x: x, y: y) - 0.5) / Double(steps)))
        let quanta = Double(steps - 1)
        return (dithered * quanta).rounded() / quanta
    }
}
