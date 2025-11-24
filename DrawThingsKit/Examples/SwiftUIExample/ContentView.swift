import SwiftUI
import DrawThingsKit

struct ContentView: View {
    @StateObject private var client: DrawThingsClient
    @State private var prompt = "A beautiful sunset over mountains"
    @State private var negativePrompt = "low quality, blurry"
    @State private var generatedImages: [NSImage] = []
    @State private var isGenerating = false
    @State private var errorMessage: String?
    
    init() {
        do {
            let client = try DrawThingsClient(address: "localhost:7859", useTLS: true)
            _client = StateObject(wrappedValue: client)
        } catch {
            fatalError("Failed to create DrawThings client: \(error)")
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            headerView
            inputSection
            progressSection
            imageSection
            Spacer()
        }
        .padding()
        .task {
            await client.connect()
        }
    }
    
    private var headerView: some View {
        VStack {
            Text("DrawThings SwiftUI Client")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            HStack {
                Circle()
                    .fill(client.isConnected ? .green : .red)
                    .frame(width: 12, height: 12)
                Text(client.isConnected ? "Connected" : "Disconnected")
                    .foregroundColor(client.isConnected ? .green : .red)
            }
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Image Generation")
                .font(.headline)
            
            VStack(alignment: .leading) {
                Text("Prompt:")
                TextField("Enter your prompt here...", text: $prompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading) {
                Text("Negative Prompt:")
                TextField("Enter negative prompt (optional)...", text: $negativePrompt)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Button("Generate Image") {
                Task {
                    await generateImage()
                }
            }
            .disabled(!client.isConnected || isGenerating || prompt.isEmpty)
            .buttonStyle(.borderedProminent)
        }
    }
    
    @ViewBuilder
    private var progressSection: some View {
        if let progress = client.currentProgress {
            VStack {
                Text(progress.stage.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }
    
    private var imageSection: some View {
        VStack(alignment: .leading) {
            if !generatedImages.isEmpty {
                Text("Generated Images:")
                    .font(.headline)
                
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(Array(generatedImages.enumerated()), id: \.offset) { index, image in
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 256, height: 256)
                                .clipped()
                                .cornerRadius(8)
                                .onTapGesture {
                                    saveImage(image, index: index)
                                }
                        }
                    }
                    .padding()
                }
            }
            
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
    
    private func generateImage() async {
        guard !prompt.isEmpty else { return }
        
        isGenerating = true
        errorMessage = nil
        
        do {
            let config = DrawThingsConfiguration(
                width: 512,
                height: 512,
                steps: 20,
                model: "sd_xl_base_1.0.safetensors",
                sampler: SamplerType.dpm2a.rawValue,
                cfgScale: 7.0
            )
            
            let images = try await client.generateImage(
                prompt: prompt,
                negativePrompt: negativePrompt,
                configuration: config
            )
            
            generatedImages = images
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isGenerating = false
    }
    
    private func saveImage(_ image: NSImage, index: Int) {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "generated_image_\(index + 1).png"
        
        if savePanel.runModal() == .OK, let url = savePanel.url {
            do {
                let data = try ImageHelpers.convertImageToData(image, format: .png)
                try data.write(to: url)
            } catch {
                errorMessage = "Failed to save image: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    ContentView()
}
