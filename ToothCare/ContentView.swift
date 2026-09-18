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
        HStack {
            Spacer()
            Button {
                viewModel.resetCamera()
            } label: {
                toolbarIcon("arrow.counterclockwise")
            }
            Button {
                viewModel.isXRayMode.toggle()
            } label: {
                toolbarIcon("viewfinder", background: viewModel.isXRayMode ? .blue : .white, foreground: viewModel.isXRayMode ? .white : .black)
            }
            Button {
                viewModel.markerModeActive.toggle()
            } label: {
                toolbarIcon("pencil.circle", background: viewModel.markerModeActive ? .red : .white, foreground: viewModel.markerModeActive ? .white : .black)
            }
            Button {
                viewModel.clearAllMarkers()
            } label: {
                toolbarIcon("trash.circle", foreground: .red)
            }
            Button {
                showingPatientDirectory = true
            } label: {
                toolbarIcon("person.2", foreground: .green)
            }
            Button {
                showingAIInput = true
            } label: {
                toolbarIcon("wand.and.stars.inverse", foreground: .purple)
            }
            Button {
                showingChart = true
            } label: {
                toolbarIcon("list.clipboard", foreground: .blue)
            }
        }
        .padding()
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
        background: Color = .white,
        foreground: Color = .black
    ) -> some View {
        Image(systemName: systemName)
            .font(.title2)
            .foregroundColor(foreground)
            .padding()
            .background(background)
            .clipShape(Circle())
            .shadow(radius: 5)
    }
}

#Preview {
    ContentView()
}
