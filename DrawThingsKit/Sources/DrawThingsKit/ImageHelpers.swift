import Foundation
import Cocoa

public struct ImageHelpers {
    
    public static func convertImageToData(_ image: NSImage, format: NSBitmapImageRep.FileType = .png) throws -> Data {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw ImageError.invalidImage
        }
        
        guard let data = bitmap.representation(using: format, properties: [:]) else {
            throw ImageError.conversionFailed
        }
        
        return data
    }
    
    public static func loadImageData(from url: URL) throws -> Data {
        guard let image = NSImage(contentsOf: url) else {
            throw ImageError.invalidImage
        }
        
        return try convertImageToData(image)
    }
    
    public static func loadImageData(from path: String) throws -> Data {
        let url = URL(fileURLWithPath: path)
        return try loadImageData(from: url)
    }
    
    public static func dataToNSImage(_ data: Data) throws -> NSImage {
        guard let image = NSImage(data: data) else {
            throw ImageError.invalidData
        }
        return image
    }
    
    public static func resizeImage(_ image: NSImage, to size: CGSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size))
        newImage.unlockFocus()
        return newImage
    }
    
    public static func createMaskFromImage(_ image: NSImage, threshold: Float = 0.5) throws -> Data {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            throw ImageError.invalidImage
        }
        
        // Convert to grayscale and create binary mask
        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        
        let maskImage = NSImage(size: NSSize(width: width, height: height))
        maskImage.lockFocus()
        
        for y in 0..<height {
            for x in 0..<width {
                if let color = bitmap.colorAt(x: x, y: y) {
                    let gray = Float(color.redComponent * 0.299 + color.greenComponent * 0.587 + color.blueComponent * 0.114)
                    let maskValue = gray > threshold ? 1.0 : 0.0
                    NSColor(white: CGFloat(maskValue), alpha: 1.0).setFill()
                    NSRect(x: x, y: y, width: 1, height: 1).fill()
                }
            }
        }
        
        maskImage.unlockFocus()
        
        return try convertImageToData(maskImage)
    }
}

public enum ImageError: Error, LocalizedError {
    case invalidImage
    case invalidData
    case conversionFailed
    case fileNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format or corrupted image"
        case .invalidData:
            return "Invalid image data"
        case .conversionFailed:
            return "Failed to convert image to desired format"
        case .fileNotFound:
            return "Image file not found"
        }
    }
}