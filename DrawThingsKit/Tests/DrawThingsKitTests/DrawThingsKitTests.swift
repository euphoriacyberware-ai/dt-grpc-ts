import XCTest
@testable import DrawThingsKit

final class DrawThingsKitTests: XCTestCase {
    
    func testConfigurationCreation() throws {
        let config = DrawThingsConfiguration(
            width: 512,
            height: 512,
            steps: 20,
            model: "sd_xl_base_1.0.safetensors",
            cfgScale: 7.0
        )
        
        XCTAssertEqual(config.width, 512)
        XCTAssertEqual(config.height, 512)
        XCTAssertEqual(config.steps, 20)
        XCTAssertEqual(config.cfgScale, 7.0)
    }
    
    func testSamplerTypes() {
        XCTAssertEqual(SamplerType.ddim.rawValue, "ddim")
        XCTAssertEqual(SamplerType.dpm2a.rawValue, "dpm_2_a")
        XCTAssertEqual(SamplerType.eulerA.rawValue, "euler_a")
    }
    
    func testGenerationStageDescriptions() {
        XCTAssertEqual(GenerationStage.textEncoding.description, "Encoding text prompt...")
        XCTAssertEqual(GenerationStage.sampling(step: 5).description, "Generating image (step 5)...")
        XCTAssertEqual(GenerationStage.imageDecoding.description, "Decoding generated image...")
    }
}