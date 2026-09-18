import SwiftUI

struct ContentView: View {

    // MARK: - State

    @State private var viewModel = DentalChartViewModel()
    @State private var showingChart: Bool = false
    @State private var showingAIInput: Bool = false
    @State private var showingPatientDirectory: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack {
            DentalModelView(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)

            VStack {
                VStack(spacing: 4) {
                    if let patient = viewModel.activePatient {
                        Text(patient.name)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Text(viewModel.selectedToothName)
                        .font(.title)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
                .padding(.top, 40)

                if viewModel.markerModeActive {
                    markerControlPanel
                }

                Spacer()
                toolbar
            }
        }
        .sheet(isPresented: $showingPatientDirectory) {
            PatientDirectoryView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingChart) {
            chartSheet
        }
        .sheet(isPresented: $showingAIInput) {
            DigitalTwinInputView(viewModel: viewModel)
        }
    }

    // MARK: - Subviews

    private var markerControlPanel: some View {
        VStack(alignment: .leading, spacing: 15) {
            @Bindable var bindableViewModel = viewModel
            
            Picker("Diagnosis", selection: $bindableViewModel.currentDiagnosis) {
                ForEach(DiagnosisType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)

            if viewModel.currentDiagnosis == .pain {
                VStack {
                    Text("Pain Level: \(Int(viewModel.currentPainLevel))")
                        .font(.subheadline)
                        .foregroundColor(.black)
                    Slider(value: $bindableViewModel.currentPainLevel, in: 1...10, step: 1)
                        .tint(Color(red: 1.0, green: 1.0 - (viewModel.currentPainLevel / 10.0), blue: 0.0))
                }
            }

            TextField("Add clinical note (optional)", text: $bindableViewModel.currentNote)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
                
            Text("Tap on a tooth to apply diagnosis")
                .font(.caption)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .cornerRadius(15)
        .shadow(radius: 10)
        .padding(.horizontal, 20)
    }

    private var toolbar: some View {
        HStack(spacing: 14) {
            Button {
                viewModel.resetCamera()
            } label: {
                toolbarIcon("arrow.counterclockwise", colors: [.white, Color(white: 0.95)], foreground: .primary)
            }
            Button {
                viewModel.isXRayMode.toggle()
            } label: {
                toolbarIcon("viewfinder", colors: viewModel.isXRayMode ? [.blue, .cyan] : [.white, Color(white: 0.95)], foreground: viewModel.isXRayMode ? .white : .primary)
            }
            Button {
                viewModel.markerModeActive.toggle()
            } label: {
                toolbarIcon("pencil.circle", colors: viewModel.markerModeActive ? [.red, .orange] : [.white, Color(white: 0.95)], foreground: viewModel.markerModeActive ? .white : .primary)
            }
            Button {
                viewModel.clearAllMarkers()
            } label: {
                toolbarIcon("trash.circle", colors: [.white, Color(white: 0.95)], foreground: .red)
            }
            
            Divider()
                .frame(height: 30)
            
            Button {
                showingPatientDirectory = true
            } label: {
                toolbarIcon("person.2.fill", colors: [.green, .teal], foreground: .white)
            }
            Button {
                showingAIInput = true
            } label: {
                toolbarIcon("wand.and.stars.inverse", colors: [.purple, .indigo], foreground: .white)
            }
            Button {
                showingChart = true
            } label: {
                toolbarIcon("list.clipboard.fill", colors: [.blue, .mint], foreground: .white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
        .padding(.bottom, 20)
    }

    private var chartSheet: some View {
        NavigationView {
            List {
                ForEach(viewModel.chartSummaries) { summary in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(summary.tooth)
                                .font(.headline)
                                .foregroundColor(.primary)
                            if !summary.note.isEmpty {
                                Text(summary.note)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Text("Suggested: \(summary.diagnosis.suggestedTreatment)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(summary.diagnosis.rawValue)
                                .fontWeight(.bold)
                                .foregroundColor(summary.diagnosis.color)
                            
                            if summary.diagnosis == .pain {
                                Text("Level: \(summary.painLevel)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(summary.painLevel > 5 ? .red : .orange)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: viewModel.deleteSummary)
            }
            .navigationTitle("Patient Chart")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let pdfURL = viewModel.generatePDF() {
                        ShareLink(item: pdfURL) {
                            Label("Export PDF", systemImage: "square.and.arrow.up")
                                .font(.headline)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Helper Methods

    private func toolbarIcon(
        _ systemName: String,
        colors: [Color] = [.white, Color(white: 0.95)],
        foreground: Color = .black
    ) -> some View {
        Image(systemName: systemName)
            .font(.title3.weight(.bold))
            .foregroundColor(foreground)
            .frame(width: 44, height: 44)
            .background(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    ContentView()
}
