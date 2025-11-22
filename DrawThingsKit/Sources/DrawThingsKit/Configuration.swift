import Foundation

public struct DrawThingsConfiguration {
    public let width: Int32
    public let height: Int32
    public let steps: Int32
    public let model: String
    public let sampler: String
    public let cfgScale: Float
    public let seed: Int64?
    public let clipSkip: Int32
    
    public init(
        width: Int32 = 512,
        height: Int32 = 512,
        steps: Int32 = 20,
        model: String = "sd_xl_base_1.0.safetensors",
        sampler: String = "dpm_2_a",
        cfgScale: Float = 7.0,
        seed: Int64? = nil,
        clipSkip: Int32 = 1
    ) {
        self.width = width
        self.height = height
        self.steps = steps
        self.model = model
        self.sampler = sampler
        self.cfgScale = cfgScale
        self.seed = seed
        self.clipSkip = clipSkip
    }
    
    public func toFlatBufferData() throws -> Data {
        // This would need FlatBuffer implementation
        // For now, return a placeholder that matches the TypeScript implementation structure
        // You'll need to implement FlatBuffer serialization based on the config.fbs file
        
        // Placeholder implementation - replace with actual FlatBuffer serialization
        var configDict: [String: Any] = [
            "width": width,
            "height": height,
            "steps": steps,
            "model": model,
            "sampler": sampler,
            "cfgScale": cfgScale,
            "clipSkip": clipSkip
        ]
        
        if let seed = seed {
            configDict["seed"] = seed
        }
        
        return try JSONSerialization.data(withJSONObject: configDict)
    }
}

public enum SamplerType: String, CaseIterable {
    case ddim = "ddim"
    case ddpm = "ddpm"
    case dpm2 = "dpm_2"
    case dpm2a = "dpm_2_a"
    case dpmpp2m = "dpmpp_2m"
    case dpmpp2mKarras = "dpmpp_2m_karras"
    case dpmpp2sSde = "dpmpp_2s_sde"
    case dpmpp2sSdeKarras = "dpmpp_2s_sde_karras"
    case dpmppSde = "dpmpp_sde"
    case dpmppSdeKarras = "dpmpp_sde_karras"
    case eulerA = "euler_a"
    case euler = "euler"
    case heun = "heun"
    case lms = "lms"
    case pndm = "pndm"
    case unipc = "unipc"
    case lcm = "lcm"
}