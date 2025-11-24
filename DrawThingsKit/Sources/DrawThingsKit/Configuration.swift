import Foundation
import FlatBuffers

public struct LoRAConfig {
    public let file: String
    public let weight: Float
    public let mode: String  // "all", "base", or "refiner"

    public init(file: String, weight: Float = 1.0, mode: String = "all") {
        self.file = file
        self.weight = weight
        self.mode = mode
    }

    // Map mode string to FlatBuffer enum
    internal func modeEnum() -> LoRAMode {
        switch mode.lowercased() {
        case "base": return .base
        case "refiner": return .refiner
        default: return .all
        }
    }
}

public struct DrawThingsConfiguration {
    // Core parameters
    public let width: Int32
    public let height: Int32
    public let steps: Int32
    public let model: String
    public let sampler: String
    public let cfgScale: Float
    public let seed: Int64?
    public let clipSkip: Int32
    public let loras: [LoRAConfig]
    public let shift: Float

    // Batch parameters
    public let batchCount: Int32
    public let batchSize: Int32
    public let strength: Float

    // Guidance parameters
    public let imageGuidanceScale: Float
    public let clipWeight: Float
    public let guidanceEmbed: Float
    public let speedUpWithGuidanceEmbed: Bool

    // Mask/Inpaint parameters
    public let maskBlur: Float
    public let maskBlurOutset: Int32
    public let preserveOriginalAfterInpaint: Bool
    public let enableInpainting: Bool  // When true, adds inpaint control to enable mask-based inpainting

    // Quality parameters
    public let sharpness: Float
    public let stochasticSamplingGamma: Float
    public let aestheticScore: Float
    public let negativeAestheticScore: Float

    // Image prior parameters
    public let negativePromptForImagePrior: Bool
    public let imagePriorSteps: Int32

    // Crop/Size parameters
    public let cropTop: Int32
    public let cropLeft: Int32
    public let originalImageHeight: Int32
    public let originalImageWidth: Int32
    public let targetImageHeight: Int32
    public let targetImageWidth: Int32
    public let negativeOriginalImageHeight: Int32
    public let negativeOriginalImageWidth: Int32

    // Upscaler parameters
    public let upscalerScaleFactor: Int32

    // Text encoder parameters
    public let resolutionDependentShift: Bool
    public let t5TextEncoder: Bool
    public let separateClipL: Bool
    public let separateOpenClipG: Bool
    public let separateT5: Bool

    // Tiled parameters
    public let tiledDiffusion: Bool
    public let diffusionTileWidth: Int32
    public let diffusionTileHeight: Int32
    public let diffusionTileOverlap: Int32
    public let tiledDecoding: Bool
    public let decodingTileWidth: Int32
    public let decodingTileHeight: Int32
    public let decodingTileOverlap: Int32

    // HiRes Fix parameters
    public let hiresFix: Bool
    public let hiresFixWidth: Int32
    public let hiresFixHeight: Int32
    public let hiresFixStrength: Float

    // Stage 2 parameters
    public let stage2Steps: Int32
    public let stage2Cfg: Float
    public let stage2Shift: Float

    // TEA Cache parameters
    public let teaCache: Bool
    public let teaCacheStart: Int32
    public let teaCacheEnd: Int32
    public let teaCacheThreshold: Float
    public let teaCacheMaxSkipSteps: Int32

    // Causal inference parameters
    public let causalInferenceEnabled: Bool
    public let causalInference: Int32
    public let causalInferencePad: Int32

    // Video parameters
    public let fpsId: Int32
    public let motionBucketId: Int32
    public let condAug: Float
    public let startFrameCfg: Float
    public let numFrames: Int32

    // Refiner parameters
    public let refinerStart: Float
    public let zeroNegativePrompt: Bool

    // Seed mode
    public let seedMode: Int32

    public init(
        width: Int32 = 512,
        height: Int32 = 512,
        steps: Int32 = 20,
        model: String = "sd_xl_base_1.0.safetensors",
        sampler: String = "dpm_2_a",
        cfgScale: Float = 7.0,
        seed: Int64? = nil,
        clipSkip: Int32 = 1,
        loras: [LoRAConfig] = [],
        shift: Float = 1.0,
        batchCount: Int32 = 1,
        batchSize: Int32 = 1,
        strength: Float = 1.0,
        imageGuidanceScale: Float = 1.5,
        clipWeight: Float = 1.0,
        guidanceEmbed: Float = 3.5,
        speedUpWithGuidanceEmbed: Bool = true,
        maskBlur: Float = 1.5,
        maskBlurOutset: Int32 = 0,
        preserveOriginalAfterInpaint: Bool = true,
        enableInpainting: Bool = false,
        sharpness: Float = 0.0,
        stochasticSamplingGamma: Float = 0.3,
        aestheticScore: Float = 6.0,
        negativeAestheticScore: Float = 2.5,
        negativePromptForImagePrior: Bool = true,
        imagePriorSteps: Int32 = 5,
        cropTop: Int32 = 0,
        cropLeft: Int32 = 0,
        originalImageHeight: Int32 = 0,
        originalImageWidth: Int32 = 0,
        targetImageHeight: Int32 = 0,
        targetImageWidth: Int32 = 0,
        negativeOriginalImageHeight: Int32 = 0,
        negativeOriginalImageWidth: Int32 = 0,
        upscalerScaleFactor: Int32 = 0,
        resolutionDependentShift: Bool = true,
        t5TextEncoder: Bool = true,
        separateClipL: Bool = false,
        separateOpenClipG: Bool = false,
        separateT5: Bool = false,
        tiledDiffusion: Bool = false,
        diffusionTileWidth: Int32 = 16,
        diffusionTileHeight: Int32 = 16,
        diffusionTileOverlap: Int32 = 2,
        tiledDecoding: Bool = false,
        decodingTileWidth: Int32 = 10,
        decodingTileHeight: Int32 = 10,
        decodingTileOverlap: Int32 = 2,
        hiresFix: Bool = false,
        hiresFixWidth: Int32 = 0,
        hiresFixHeight: Int32 = 0,
        hiresFixStrength: Float = 0.7,
        stage2Steps: Int32 = 10,
        stage2Cfg: Float = 1.0,
        stage2Shift: Float = 1.0,
        teaCache: Bool = false,
        teaCacheStart: Int32 = 5,
        teaCacheEnd: Int32 = -1,
        teaCacheThreshold: Float = 0.06,
        teaCacheMaxSkipSteps: Int32 = 3,
        causalInferenceEnabled: Bool = false,
        causalInference: Int32 = 3,
        causalInferencePad: Int32 = 0,
        fpsId: Int32 = 5,
        motionBucketId: Int32 = 127,
        condAug: Float = 0.02,
        startFrameCfg: Float = 1.0,
        numFrames: Int32 = 14,
        refinerStart: Float = 0.85,
        zeroNegativePrompt: Bool = false,
        seedMode: Int32 = 2
    ) {
        self.width = width
        self.height = height
        self.steps = steps
        self.model = model
        self.sampler = sampler
        self.cfgScale = cfgScale
        self.seed = seed
        self.clipSkip = clipSkip
        self.loras = loras
        self.shift = shift
        self.batchCount = batchCount
        self.batchSize = batchSize
        self.strength = strength
        self.imageGuidanceScale = imageGuidanceScale
        self.clipWeight = clipWeight
        self.guidanceEmbed = guidanceEmbed
        self.speedUpWithGuidanceEmbed = speedUpWithGuidanceEmbed
        self.maskBlur = maskBlur
        self.maskBlurOutset = maskBlurOutset
        self.preserveOriginalAfterInpaint = preserveOriginalAfterInpaint
        self.enableInpainting = enableInpainting
        self.sharpness = sharpness
        self.stochasticSamplingGamma = stochasticSamplingGamma
        self.aestheticScore = aestheticScore
        self.negativeAestheticScore = negativeAestheticScore
        self.negativePromptForImagePrior = negativePromptForImagePrior
        self.imagePriorSteps = imagePriorSteps
        self.cropTop = cropTop
        self.cropLeft = cropLeft
        self.originalImageHeight = originalImageHeight
        self.originalImageWidth = originalImageWidth
        self.targetImageHeight = targetImageHeight
        self.targetImageWidth = targetImageWidth
        self.negativeOriginalImageHeight = negativeOriginalImageHeight
        self.negativeOriginalImageWidth = negativeOriginalImageWidth
        self.upscalerScaleFactor = upscalerScaleFactor
        self.resolutionDependentShift = resolutionDependentShift
        self.t5TextEncoder = t5TextEncoder
        self.separateClipL = separateClipL
        self.separateOpenClipG = separateOpenClipG
        self.separateT5 = separateT5
        self.tiledDiffusion = tiledDiffusion
        self.diffusionTileWidth = diffusionTileWidth
        self.diffusionTileHeight = diffusionTileHeight
        self.diffusionTileOverlap = diffusionTileOverlap
        self.tiledDecoding = tiledDecoding
        self.decodingTileWidth = decodingTileWidth
        self.decodingTileHeight = decodingTileHeight
        self.decodingTileOverlap = decodingTileOverlap
        self.hiresFix = hiresFix
        self.hiresFixWidth = hiresFixWidth
        self.hiresFixHeight = hiresFixHeight
        self.hiresFixStrength = hiresFixStrength
        self.stage2Steps = stage2Steps
        self.stage2Cfg = stage2Cfg
        self.stage2Shift = stage2Shift
        self.teaCache = teaCache
        self.teaCacheStart = teaCacheStart
        self.teaCacheEnd = teaCacheEnd
        self.teaCacheThreshold = teaCacheThreshold
        self.teaCacheMaxSkipSteps = teaCacheMaxSkipSteps
        self.causalInferenceEnabled = causalInferenceEnabled
        self.causalInference = causalInference
        self.causalInferencePad = causalInferencePad
        self.fpsId = fpsId
        self.motionBucketId = motionBucketId
        self.condAug = condAug
        self.startFrameCfg = startFrameCfg
        self.numFrames = numFrames
        self.refinerStart = refinerStart
        self.zeroNegativePrompt = zeroNegativePrompt
        self.seedMode = seedMode
    }

    public func toFlatBufferData() throws -> Data {
        // Create GenerationConfigurationT object
        let configT = GenerationConfigurationT()

        // Convert width/height to units of 64 pixels as per FlatBuffer schema
        configT.startWidth = UInt16(width / 64)
        configT.startHeight = UInt16(height / 64)

        // Core generation parameters
        configT.steps = UInt32(steps)
        configT.model = model
        configT.sampler = mapSamplerToEnum(sampler)
        configT.guidanceScale = cfgScale
        configT.clipSkip = UInt32(clipSkip)
        configT.shift = shift

        // Seed handling
        if let seed = seed, seed >= 0 {
            configT.seed = UInt32(seed)
        } else {
            configT.seed = arc4random()
        }

        configT.seedMode = mapSeedModeToEnum(seedMode)

        // Batch parameters
        configT.id = 0
        configT.batchCount = UInt32(batchCount)
        configT.batchSize = UInt32(batchSize)
        configT.strength = strength

        // Guidance parameters
        configT.imageGuidanceScale = imageGuidanceScale
        configT.clipWeight = clipWeight
        configT.guidanceEmbed = guidanceEmbed
        configT.speedUpWithGuidanceEmbed = speedUpWithGuidanceEmbed

        // Mask/Inpaint parameters
        configT.maskBlur = maskBlur
        configT.maskBlurOutset = Int32(maskBlurOutset)
        configT.preserveOriginalAfterInpaint = preserveOriginalAfterInpaint

        // Quality parameters
        configT.sharpness = sharpness
        configT.stochasticSamplingGamma = stochasticSamplingGamma
        configT.aestheticScore = aestheticScore
        configT.negativeAestheticScore = negativeAestheticScore

        // Image prior parameters
        configT.negativePromptForImagePrior = negativePromptForImagePrior
        configT.imagePriorSteps = UInt32(imagePriorSteps)

        // Crop/Size parameters
        configT.cropTop = Int32(cropTop)
        configT.cropLeft = Int32(cropLeft)
        configT.originalImageHeight = UInt32(originalImageHeight > 0 ? originalImageHeight : height)
        configT.originalImageWidth = UInt32(originalImageWidth > 0 ? originalImageWidth : width)
        configT.targetImageHeight = UInt32(targetImageHeight > 0 ? targetImageHeight : height)
        configT.targetImageWidth = UInt32(targetImageWidth > 0 ? targetImageWidth : width)
        configT.negativeOriginalImageHeight = UInt32(negativeOriginalImageHeight > 0 ? negativeOriginalImageHeight : height)
        configT.negativeOriginalImageWidth = UInt32(negativeOriginalImageWidth > 0 ? negativeOriginalImageWidth : width)

        // Upscaler parameters
        configT.upscalerScaleFactor = UInt8(upscalerScaleFactor)

        // Text encoder parameters
        configT.resolutionDependentShift = resolutionDependentShift
        configT.t5TextEncoder = t5TextEncoder
        configT.separateClipL = separateClipL
        configT.separateOpenClipG = separateOpenClipG
        configT.separateT5 = separateT5

        // Tiled parameters
        configT.tiledDiffusion = tiledDiffusion
        configT.diffusionTileWidth = UInt16(diffusionTileWidth)
        configT.diffusionTileHeight = UInt16(diffusionTileHeight)
        configT.diffusionTileOverlap = UInt16(diffusionTileOverlap)
        configT.tiledDecoding = tiledDecoding
        configT.decodingTileWidth = UInt16(decodingTileWidth)
        configT.decodingTileHeight = UInt16(decodingTileHeight)
        configT.decodingTileOverlap = UInt16(decodingTileOverlap)

        // HiRes Fix parameters
        configT.hiresFix = hiresFix
        configT.hiresFixStartWidth = UInt16(hiresFixWidth / 64)
        configT.hiresFixStartHeight = UInt16(hiresFixHeight / 64)
        configT.hiresFixStrength = hiresFixStrength

        // Stage 2 parameters
        configT.stage2Steps = UInt32(stage2Steps)
        configT.stage2Cfg = stage2Cfg
        configT.stage2Shift = stage2Shift

        // TEA Cache parameters
        configT.teaCache = teaCache
        configT.teaCacheStart = Int32(teaCacheStart)
        configT.teaCacheEnd = Int32(teaCacheEnd)
        configT.teaCacheThreshold = teaCacheThreshold
        configT.teaCacheMaxSkipSteps = Int32(teaCacheMaxSkipSteps)

        // Causal inference parameters
        configT.causalInferenceEnabled = causalInferenceEnabled
        configT.causalInference = Int32(causalInference)
        configT.causalInferencePad = Int32(causalInferencePad)

        // Video parameters
        configT.fpsId = UInt32(fpsId)
        configT.motionBucketId = UInt32(motionBucketId)
        configT.condAug = condAug
        configT.startFrameCfg = startFrameCfg
        configT.numFrames = UInt32(numFrames)

        // Refiner parameters
        configT.refinerStart = refinerStart
        configT.zeroNegativePrompt = zeroNegativePrompt

        // Add inpaint control if enabled
        if enableInpainting {
            let inpaintControl = ControlT()
            inpaintControl.inputOverride = .inpaint
            inpaintControl.weight = 1.0
            inpaintControl.guidanceStart = 0.0
            inpaintControl.guidanceEnd = 1.0
            inpaintControl.noPrompt = false
            inpaintControl.globalAveragePooling = true
            inpaintControl.downSamplingRate = 1.0
            inpaintControl.controlMode = .balanced
            inpaintControl.targetBlocks = []
            inpaintControl.file = ""  // Empty file - mask is sent separately
            configT.controls = [inpaintControl]
            print("🎭 Added inpaint control to configuration")
        } else {
            configT.controls = []
        }

        // Add LoRAs
        configT.loras = loras.map { lora in
            let loraT = LoRAT()
            loraT.file = lora.file
            loraT.weight = lora.weight
            loraT.mode = lora.modeEnum()
            return loraT
        }

        // Pack into FlatBuffer
        var builder = FlatBufferBuilder(initialSize: 1024)
        var mutableConfigT = configT
        let offset = GenerationConfiguration.pack(&builder, obj: &mutableConfigT)
        builder.finish(offset: offset)

        // Return as Data
        let bufferPointer = builder.sizedByteArray
        return Data(bufferPointer)
    }

    // Map seed mode to FlatBuffer enum
    private func mapSeedModeToEnum(_ mode: Int32) -> SeedMode {
        switch mode {
        case 0: return .legacy
        case 1, 2: return .torchcpucompatible
        default: return .torchcpucompatible
        }
    }

    // Map sampler string to FlatBuffer enum value (using the generated SamplerType from config_generated.swift)
    private func mapSamplerToEnum(_ sampler: String) -> SamplerType {
        switch sampler.lowercased().replacingOccurrences(of: "_", with: "") {
        case "dpmpp2mkarras":
            return .dpmpp2mkarras
        case "eulera":
            return .eulera
        case "ddim":
            return .ddim
        case "pndm", "plms":
            return .plms
        case "dpmppsdekarras":
            return .dpmppsdekarras
        case "unipc":
            return .unipc
        case "lcm":
            return .lcm
        case "eulerasubstep":
            return .eulerasubstep
        case "dpmppsdesubstep":
            return .dpmppsdesubstep
        case "tcd":
            return .tcd
        case "euleratrailing":
            return .euleratrailing
        case "dpmppsdetrailing":
            return .dpmppsdetrailing
        case "dpmpp2mays":
            return .dpmpp2mays
        case "euleraays":
            return .euleraays
        case "dpmppsdeays":
            return .dpmppsdeays
        case "dpmpp2mtrailing":
            return .dpmpp2mtrailing
        case "ddimtrailing":
            return .ddimtrailing
        case "unipctrailing":
            return .unipctrailing
        case "unipcays":
            return .unipcays
        default:
            return .dpmpp2mkarras  // Default to DPMPP2MKarras
        }
    }
}
