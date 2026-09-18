import SwiftUI

struct PatientDirectoryView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: DentalChartViewModel
    
    @State private var showingAddPatient = false
    @State private var newName = ""
    @State private var newAge = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.patients) { patient in
                    Button {
                        viewModel.switchPatient(to: patient.id)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(patient.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Age: \(patient.age) • Last Visit: \(patient.lastVisit.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if viewModel.currentPatientId == patient.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deletePatient(id: viewModel.patients[index].id)
                    }
                }
            }
            .navigationTitle("Patients")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPatient = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .alert("Add New Patient", isPresented: $showingAddPatient) {
                TextField("Full Name", text: $newName)
                TextField("Age", text: $newAge)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) {
                    newName = ""
                    newAge = ""
                }
                Button("Add") {
                    guard !newName.isEmpty else { return }
                    viewModel.addPatient(name: newName, age: newAge)
                    newName = ""
                    newAge = ""
                }
            }
        }
    }
}
