import SwiftUI

struct DigitalTwinInputView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: DentalChartViewModel
    
    @State private var clinicalSummary: String = ""
    @State private var isProcessing: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Doctor's AI Summary")
                    .font(.largeTitle)
                    .bold()
                
                Text("Type or dictate a clinical summary. The AI will extract the conditions and generate a 3D digital twin automatically.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $clinicalSummary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .frame(minHeight: 200)
                
                Button(action: processSummary) {
                    HStack {
                        if isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "wand.and.stars")
                        }
                        Text(isProcessing ? "Processing NLP..." : "Generate Digital Twin")
                            .bold()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(clinicalSummary.isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(clinicalSummary.isEmpty || isProcessing)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func processSummary() {
        isProcessing = true
        
        // Simulate a slight network delay for the "AI" feel
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            viewModel.processClinicalSummary(text: clinicalSummary)
            isProcessing = false
            dismiss()
        }
    }
}
