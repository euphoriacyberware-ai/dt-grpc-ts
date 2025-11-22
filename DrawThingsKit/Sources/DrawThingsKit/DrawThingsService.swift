import Foundation
import GRPC
import NIO
import NIOSSL
import SwiftProtobuf

public actor DrawThingsService {
    private let client: ImageGenerationServiceClient
    private let group: EventLoopGroup
    private let channel: GRPCChannel
    private var models: MetadataOverride?

    public init(address: String, useTLS: Bool = true) throws {
        let components = address.components(separatedBy: ":")
        let host = components.first ?? "localhost"
        let port = Int(components.last ?? "7859") ?? 7859
        
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        let builder = ClientConnection.usingPlatformAppropriateTLS(for: group)
            .connect(host: host, port: port)
        
        self.channel = builder
        self.client = ImageGenerationServiceClient(channel: channel)
    }
    
    deinit {
        try? channel.close().wait()
        try? group.syncShutdownGracefully()
    }
    
    public func echo(name: String = "Swift-Client") async throws -> EchoReply {
        let request = EchoRequest.with {
            $0.name = name
        }

        let call = client.echo(request)
        let response = try await call.response.get()

        // Cache the models metadata for future requests
        if response.hasOverride {
            self.models = response.override
        }

        return response
    }
    
    public func generateImage(
        prompt: String,
        negativePrompt: String = "",
        configuration: Data,
        image: Data? = nil,
        mask: Data? = nil,
        hints: [HintProto] = [],
        contents: [Data] = [],
        override: MetadataOverride? = nil,
        progressHandler: @escaping (ImageGenerationSignpostProto?) async -> Void = { _ in }
    ) async throws -> [Data] {
        
        // Ensure we have models metadata
        if self.models == nil {
            _ = try await echo()
        }
        
        let request = ImageGenerationRequest.with {
            $0.scaleFactor = 1
            $0.user = ProcessInfo.processInfo.hostName
            $0.device = .laptop
            $0.prompt = prompt
            $0.negativePrompt = negativePrompt
            $0.configuration = configuration
            
            if let image = image {
                $0.image = image
            }
            
            if let mask = mask {
                $0.mask = mask
            }
            
            $0.hints = hints
            $0.contents = contents
            
            if let override = override {
                $0.override = override
            } else if let cachedModels = self.models {
                $0.override = cachedModels
            }
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var generatedImages: [Data] = []
            var error: Error?

            let call = client.generateImage(request) { response in
                // Handle progress updates
                if response.hasCurrentSignpost {
                    Task {
                        await progressHandler(response.currentSignpost)
                    }
                }

                // Collect generated images
                generatedImages.append(contentsOf: response.generatedImages)
            }

            call.status.whenComplete { result in
                switch result {
                case .success:
                    continuation.resume(returning: generatedImages)
                case .failure(let err):
                    continuation.resume(throwing: err)
                }
            }
        }
    }
    
    public func checkFilesExist(files: [String], filesWithHash: [String] = []) async throws -> FileExistenceResponse {
        let request = FileListRequest.with {
            $0.files = files
            $0.filesWithHash = filesWithHash
        }

        let call = client.filesExist(request)
        return try await call.response.get()
    }
}