# bart-large-cnn_to_CoreML

This macOS SwiftUI app converts HuggingFace's `facebook/bart-large-cnn` model to a Core ML `.mlpackage` using `coremltools`.

### ✅ Features
- Loads BART model using `transformers`
- Traces with max-length=512 input
- Converts to Core ML with full `[1, 512, 50264]` logits output
- Saves model to Desktop

### 🛠 Requirements
- Python 3.9+
- `torch`, `transformers`, `coremltools`
- macOS 13+ (for ML Program models)

### 💻 Run Instructions
1. Clone the repo
2. Open `.xcodeproj` in Xcode
3. Build & Run the app
4. Click "Convert Model" — Core ML model appears on your Desktop

---
