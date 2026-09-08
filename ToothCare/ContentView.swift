import SwiftUI

struct ContentView: View {

    // MARK: - State

    @State private var zoomMultiplier: Float = 1.0
    @State private var viewModel = DentalChartViewModel()
    @State private var showingChart: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack {
            DentalModelView(zoomMultiplier: $zoomMultiplier, viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)

            VStack {
                Text(viewModel.selectedToothName)
                    .font(.title)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.top, 40)

                if viewModel.markerModeActive {
                    painLevelControl
                }

                Spacer()
                toolbar
            }
        }
        .sheet(isPresented: $showingChart) {
            chartSheet
        }
    }

    // MARK: - Subviews

    private var painLevelControl: some View {
        VStack {
            Text("Pain Level: \(Int(viewModel.currentPainLevel))")
                .font(.headline)
                .foregroundColor(.black)

            @Bindable var bindableViewModel = viewModel
            Slider(value: $bindableViewModel.currentPainLevel, in: 1...10, step: 1)
                .tint(Color(red: 1.0, green: 1.0 - (viewModel.currentPainLevel / 10.0), blue: 0.0))
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(10)
        .padding(.horizontal, 40)
    }

    private var toolbar: some View {
        HStack {
            Spacer()
            Button {
                zoomMultiplier *= 1.2
            } label: {
                toolbarIcon("plus.magnifyingglass")
            }
            Button {
                zoomMultiplier *= 0.8
            } label: {
                toolbarIcon("minus.magnifyingglass")
            }
            Button {
                viewModel.markerModeActive.toggle()
            } label: {
                toolbarIcon("pencil.circle", background: viewModel.markerModeActive ? .red : .white)
            }
            Button {
                viewModel.clearAllMarkers()
            } label: {
                toolbarIcon("trash.circle", foreground: .red)
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
                    HStack {
                        Text(summary.tooth)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Text("Pain: \(summary.painLevel)")
                            .fontWeight(.bold)
                            .foregroundColor(summary.painLevel > 5 ? .red : .orange)
                    }
                }
                .onDelete(perform: viewModel.deleteSummary)
            }
            .navigationTitle("Patient Pain Chart")
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
        foreground: Color = .black,
        background: Color = .white
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
