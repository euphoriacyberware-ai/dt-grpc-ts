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
    
    /// Convert DTTensor format (from Draw Things server) to NSImage
    /// DTTensor format:
    /// - 68-byte header containing width, height, channels, compression flag
    /// - Float16 RGB data (optionally compressed)
    /// - Values in range [-1, 1] need to be converted to [0, 255]
    public static func nsImageToDTTensor(_ image: NSImage) throws -> Data {
        // Get the bitmap representation directly without TIFF conversion
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ImageError.invalidImage
        }

        let width = cgImage.width
        let height = cgImage.height

        // Create RGB-only bitmap in sRGB color space
        guard let rgbBitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 3,
            hasAlpha: false,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: width * 3,
            bitsPerPixel: 24
        ) else {
            throw ImageError.conversionFailed
        }

        // Draw the image into the RGB bitmap
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rgbBitmap)

        let drawRect = NSRect(x: 0, y: 0, width: width, height: height)
        if let context = NSGraphicsContext.current?.cgContext {
            context.draw(cgImage, in: drawRect)
        }

        NSGraphicsContext.restoreGraphicsState()

        let bitmap = rgbBitmap
        let channels = 3  // RGB

        print("🖼️ Converting image: \(width)x\(height), \(bitmap.samplesPerPixel) samples, bytesPerRow: \(bitmap.bytesPerRow)")

        // Debug: Check first few pixels
        if let bitmapData = bitmap.bitmapData {
            print("🔍 First 12 bytes (4 RGB pixels): ", terminator: "")
            for i in 0..<min(12, width * height * 3) {
                print(String(format: "%02x ", bitmapData[i]), terminator: "")
            }
            print()
        }

        // DTTensor format constants (from ccv_nnc)
        let CCV_TENSOR_CPU_MEMORY: UInt32 = 0x1
        let CCV_TENSOR_FORMAT_NHWC: UInt32 = 0x02
        let CCV_16F: UInt32 = 0x20000

        // Create header (17 uint32 values = 68 bytes, but we only use first 9)
        // Based on: struct.pack_into("<9I", image_bytes, 0, 0, CCV_TENSOR_CPU_MEMORY, CCV_TENSOR_FORMAT_NHWC, CCV_16F, 0, 1, height, width, channels)
        var header = [UInt32](repeating: 0, count: 17)
        header[0] = 0  // No compression (fpzip compression flag would be 1012247)
        header[1] = CCV_TENSOR_CPU_MEMORY
        header[2] = CCV_TENSOR_FORMAT_NHWC
        header[3] = CCV_16F
        header[4] = 0  // reserved
        header[5] = 1  // N dimension (batch size)
        header[6] = UInt32(height)  // H dimension
        header[7] = UInt32(width)   // W dimension
        header[8] = UInt32(channels) // C dimension

        var tensorData = Data(count: 68 + width * height * channels * 2)

        // Write header
        tensorData.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            let uint32Ptr = ptr.baseAddress!.assumingMemoryBound(to: UInt32.self)
            for i in 0..<9 {
                uint32Ptr[i] = header[i]
            }
        }

        // Convert bitmap to RGB float16 data in range [-1, 1]
        guard let bitmapData = bitmap.bitmapData else {
            throw ImageError.conversionFailed
        }

        tensorData.withUnsafeMutableBytes { (outPtr: UnsafeMutableRawBufferPointer) in
            let pixelDataPtr = outPtr.baseAddress!.advanced(by: 68)
            var debugPixelCount = 0

            for y in 0..<height {
                for x in 0..<width {
                    let bitmapIndex = y * bitmap.bytesPerRow + x * 3  // Always 3 bytes per pixel now
                    let tensorOffset = 68 + (y * width + x) * 6  // 6 bytes per pixel (3 channels * 2 bytes)

                    for c in 0..<3 {
                        let uint8Value = bitmapData[bitmapIndex + c]
                        // Convert from [0, 255] to [-1, 1]: v = pixel[c] / 255 * 2 - 1
                        let floatValue = (Float(uint8Value) / 255.0 * 2.0) - 1.0
                        let float16Value = Float16(floatValue)

                        // Debug first pixel
                        if debugPixelCount < 3 {
                            print("🔬 Pixel 0 channel \(c): uint8=\(uint8Value) -> float=\(floatValue) -> float16=\(float16Value)")
                            debugPixelCount += 1
                        }

                        // Write Float16 in little-endian format (matching Python's struct.pack "<e")
                        let bitPattern = float16Value.bitPattern
                        let byteOffset = tensorOffset - 68 + c * 2
                        pixelDataPtr.storeBytes(of: bitPattern.littleEndian, toByteOffset: byteOffset, as: UInt16.self)
                    }
                }
            }
        }

        print("✅ DTTensor created: \(tensorData.count) bytes")

        // Debug: Print first 100 bytes as hex
        let debugBytes = tensorData.prefix(100).map { String(format: "%02x", $0) }.joined(separator: " ")
        print("📊 First 100 bytes: \(debugBytes)")

        return tensorData
    }

    public static func dtTensorToNSImage(_ tensorData: Data) throws -> NSImage {
        guard tensorData.count >= 68 else {
            throw ImageError.invalidData
        }

        // Read header (17 uint32 values = 68 bytes)
        let headerData = tensorData.prefix(68)
        var header = [UInt32](repeating: 0, count: 17)
        headerData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            let uint32Ptr = ptr.bindMemory(to: UInt32.self)
            for i in 0..<17 {
                header[i] = uint32Ptr[i]
            }
        }

        // Extract metadata from header
        let compressionFlag = header[0]
        let height = Int(header[6])
        let width = Int(header[7])
        let channels = Int(header[8])

        print("📊 DTTensor: \(width)x\(height), \(channels) channels, compressed: \(compressionFlag == 1012247)")

        // Check for compression
        let isCompressed = (compressionFlag == 1012247)

        if isCompressed {
            print("⚠️ Image is compressed with fpzip - decompression not yet implemented")
            print("💡 Workaround: Disable compression in Draw Things server settings")
            throw ImageError.compressionNotSupported
        }

        guard channels == 3 || channels == 4 else {
            print("⚠️ Unsupported channel count: \(channels). Only RGB (3) and RGBA (4) are supported.")
            throw ImageError.conversionFailed
        }

        // Extract Float16 data (2 bytes per value)
        let pixelDataOffset = 68
        let pixelCount = width * height * channels
        let expectedDataSize = pixelDataOffset + (pixelCount * 2)

        guard tensorData.count >= expectedDataSize else {
            print("⚠️ Data size mismatch: got \(tensorData.count), expected \(expectedDataSize)")
            throw ImageError.invalidData
        }

        // Output will always be RGB (3 channels)
        var rgbData = Data(count: width * height * 3)

        tensorData.withUnsafeBytes { (rawPtr: UnsafeRawBufferPointer) in
            let basePtr = rawPtr.baseAddress!.advanced(by: pixelDataOffset)
            let float16Ptr = basePtr.assumingMemoryBound(to: UInt16.self)

            rgbData.withUnsafeMutableBytes { (outPtr: UnsafeMutableRawBufferPointer) in
                let uint8Ptr = outPtr.baseAddress!.assumingMemoryBound(to: UInt8.self)

                if channels == 4 {
                    // 4-channel latent space to RGB conversion (SDXL coefficients)
                    // Based on Draw Things ImageConverter.swift
                    for i in 0..<(width * height) {
                        let v0 = Float(Float16(bitPattern: float16Ptr[i * 4 + 0]))
                        let v1 = Float(Float16(bitPattern: float16Ptr[i * 4 + 1]))
                        let v2 = Float(Float16(bitPattern: float16Ptr[i * 4 + 2]))
                        let v3 = Float(Float16(bitPattern: float16Ptr[i * 4 + 3]))

                        let r = 47.195 * v0 - 29.114 * v1 + 11.883 * v2 - 38.063 * v3 + 141.64
                        let g = 53.237 * v0 - 1.4623 * v1 + 12.991 * v2 - 28.043 * v3 + 127.46
                        let b = 58.182 * v0 + 4.3734 * v1 - 3.3735 * v2 - 26.722 * v3 + 114.5

                        uint8Ptr[i * 3 + 0] = UInt8(clamping: Int(r))
                        uint8Ptr[i * 3 + 1] = UInt8(clamping: Int(g))
                        uint8Ptr[i * 3 + 2] = UInt8(clamping: Int(b))
                    }
                } else {
                    // 3-channel RGB: Convert from [-1, 1] to [0, 255]
                    for i in 0..<pixelCount {
                        let float16Bits = float16Ptr[i]
                        let float16Value = Float16(bitPattern: float16Bits)
                        let uint8Value = UInt8(clamping: Int((Float(float16Value) + 1.0) * 127.5))
                        uint8Ptr[i] = uint8Value
                    }
                }
            }
        }

        // Create NSImage from RGB data
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 3,
            hasAlpha: false,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: width * 3,
            bitsPerPixel: 24
        ) else {
            throw ImageError.conversionFailed
        }

        // Copy RGB data to bitmap
        rgbData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            if let bitmapData = bitmap.bitmapData {
                ptr.copyBytes(to: UnsafeMutableRawBufferPointer(start: bitmapData, count: rgbData.count))
            }
        }

        let image = NSImage(size: NSSize(width: width, height: height))
        image.addRepresentation(bitmap)

        return image
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
    case compressionNotSupported

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
        case .compressionNotSupported:
            return "Compressed image format not yet supported. Please disable compression in Draw Things server settings."
        }
    }
}