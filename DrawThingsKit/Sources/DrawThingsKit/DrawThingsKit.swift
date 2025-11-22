import Foundation
import SwiftUI
import Combine

@MainActor
public class DrawThingsClient: ObservableObject {
    private let service: DrawThingsService
    
    @Published public var isConnected = false
    @Published public var currentProgress: ImageGenerationProgress?
    @Published public var lastError: Error?
    
    public init(address: String, useTLS: Bool = true) throws {
        self.service = try DrawThingsService(address: address, useTLS: useTLS)
    }
    
    public func connect() async {
        do {
            _ = try await service.echo()
            isConnected = true
            lastError = nil
        } catch {
            isConnected = false
            lastError = error
        }
    }
    
    public func generateImage(
        prompt: String,
        negativePrompt: String = "",
        configuration: DrawThingsConfiguration = DrawThingsConfiguration(),
        image: NSImage? = nil,
        mask: NSImage? = nil
    ) async throws -> [NSImage] {
        
        currentProgress = ImageGenerationProgress()
        
        let configData = try configuration.toFlatBufferData()
        
        var imageData: Data?
        var maskData: Data?
        
        if let image = image {
            imageData = try ImageHelpers.convertImageToData(image)
        }
        
        if let mask = mask {
            maskData = try ImageHelpers.convertImageToData(mask)
        }
        
        let resultData = try await service.generateImage(
            prompt: prompt,
            negativePrompt: negativePrompt,
            configuration: configData,
            image: imageData,
            mask: maskData,
            progressHandler: { [weak self] signpost in
                await MainActor.run {
                    self?.updateProgress(signpost)
                }
            }
        )
        
        currentProgress = nil
        
        return try resultData.map { try ImageHelpers.dataToNSImage($0) }
    }
    
    private func updateProgress(_ signpost: ImageGenerationSignpostProto?) {
        guard let signpost = signpost else { return }
        
        switch signpost.signpost {
        case .textEncoded:
            currentProgress?.stage = .textEncoding
        case .imageEncoded:
            currentProgress?.stage = .imageEncoding
        case .sampling(let sampling):
            currentProgress?.stage = .sampling(step: Int(sampling.step))
        case .imageDecoded:
            currentProgress?.stage = .imageDecoding
        case .secondPassImageEncoded:
            currentProgress?.stage = .secondPassImageEncoding
        case .secondPassSampling(let sampling):
            currentProgress?.stage = .secondPassSampling(step: Int(sampling.step))
        case .secondPassImageDecoded:
            currentProgress?.stage = .secondPassImageDecoding
        case .faceRestored:
            currentProgress?.stage = .faceRestoration
        case .imageUpscaled:
            currentProgress?.stage = .imageUpscaling
        default:
            break
        }
    }
}

public class ImageGenerationProgress: ObservableObject {
    @Published public var stage: GenerationStage = .textEncoding
    
    public init() {}
}

public enum GenerationStage {
    case textEncoding
    case imageEncoding
    case sampling(step: Int)
    case imageDecoding
    case secondPassImageEncoding
    case secondPassSampling(step: Int)
    case secondPassImageDecoding
    case faceRestoration
    case imageUpscaling
    
    public var description: String {
        switch self {
        case .textEncoding:
            return "Encoding text prompt..."
        case .imageEncoding:
            return "Encoding input image..."
        case .sampling(let step):
            return "Generating image (step \(step))..."
        case .imageDecoding:
            return "Decoding generated image..."
        case .secondPassImageEncoding:
            return "Preparing second pass..."
        case .secondPassSampling(let step):
            return "Second pass generation (step \(step))..."
        case .secondPassImageDecoding:
            return "Processing second pass..."
        case .faceRestoration:
            return "Restoring faces..."
        case .imageUpscaling:
            return "Upscaling image..."
        }
    }
}