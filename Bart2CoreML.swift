//
//  ContentView.swift
// Bart2CoreML
//
//  Created by Isaac Eng Gian Khor on 14/05/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var logText = "✅ Ready to convert facebook/bart-large-cnn to Core ML.\nClick 'Convert Model' to start."
    @State private var isConverting = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Core ML Model Converter")
                .font(.title)
                .padding()

            Button(action: convertModel) {
                Text(isConverting ? "Converting..." : "Convert Model")
                    .frame(minWidth: 200)
                    .padding()
                    .background(isConverting ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isConverting)

            ScrollView {
                Text(logText)
                    .frame(minWidth: 400, minHeight: 300)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .frame(width: 500, height: 500)
        .padding()
    }

    private func convertModel() {
        isConverting = true
        logText += "\n▶️ Starting conversion process..."

        let pythonScript = """
        import torch
        from transformers import BartForConditionalGeneration, BartTokenizer
        import coremltools as ct
        from pathlib import Path

        model_name = "facebook/bart-large-cnn"
        print(f"📦 Loading model: {model_name}")
        tokenizer = BartTokenizer.from_pretrained(model_name)
        model = BartForConditionalGeneration.from_pretrained(model_name)

        device = torch.device("cpu")
        model = model.to(device)
        model.eval()

        sample_text = "This is a sample text to trace the model."
        inputs = tokenizer(sample_text, return_tensors="pt", max_length=512, truncation=True, padding="max_length")
        inputs = {k: v.to(device) for k, v in inputs.items()}

        class BartWrapper(torch.nn.Module):
            def __init__(self, model):
                super().__init__()
                self.model = model

            def forward(self, input_ids, attention_mask):
                outputs = self.model(input_ids=input_ids, attention_mask=attention_mask, return_dict=True)
                return outputs.logits

        wrapped_model = BartWrapper(model)

        with torch.no_grad():
            print("🔧 Tracing model...")
            traced_model = torch.jit.trace(wrapped_model, (inputs["input_ids"], inputs["attention_mask"]))
        print("✅ Model tracing successful.")

        print("🧠 Converting to Core ML...")
        mlmodel = ct.convert(
            traced_model,
            inputs=[
                ct.TensorType(name="input_ids", shape=[1, 512], dtype=int),
                ct.TensorType(name="attention_mask", shape=[1, 512], dtype=int)
            ],
            convert_to="mlprogram",
            minimum_deployment_target=ct.target.iOS16
        )
        print("✅ Core ML model conversion successful.")

        output_path = str(Path.home() / "Desktop" / "BartLargeCNN.mlpackage")
        mlmodel.save(output_path)
        print(f"📁 Model saved to: {output_path}")
        """

        let tempDir = FileManager.default.temporaryDirectory
        let scriptPath = tempDir.appendingPathComponent("convert_model.py")
        do {
            try pythonScript.write(to: scriptPath, atomically: true, encoding: .utf8)
            logText += "\n📄 Python script written to: \(scriptPath.path)"
        } catch {
            logText += "\n❌ Error writing script: \(error.localizedDescription)"
            isConverting = false
            return
        }

        // Use the user's system Python
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["python3", scriptPath.path]

        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = outputPipe

        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            if let output = String(data: handle.availableData, encoding: .utf8), !output.isEmpty {
                DispatchQueue.main.async {
                    logText += "\n" + output.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }

        task.terminationHandler = { _ in
            DispatchQueue.main.async {
                isConverting = false
            }
        }

        do {
            try task.run()
        } catch {
            logText += "\n❌ Error running Python script: \(error.localizedDescription)"
            isConverting = false
        }
    }
}
