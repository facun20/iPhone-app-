import SwiftUI
import MapKit

/// Search and pick a location for the "Show Up" unlock condition
struct LocationPickerView: View {
    @Binding var locationName: String
    @Binding var latitude: Double?
    @Binding var longitude: Double?
    @Environment(\.dismiss) var dismiss
    @StateObject private var locationService = LocationService()
    @State private var searchText = ""
    @State private var results: [LocationSearchResult] = []
    @State private var selectedResult: LocationSearchResult?
    @State private var isSearching = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search for a place...", text: $searchText)
                        .onSubmit { search() }
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding()

                // Quick presets
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        presetButton("Gym", icon: "dumbbell.fill")
                        presetButton("Library", icon: "book.fill")
                        presetButton("School", icon: "graduationcap.fill")
                        presetButton("Office", icon: "building.2.fill")
                        presetButton("Church", icon: "cross.fill")
                        presetButton("Park", icon: "leaf.fill")
                        presetButton("Coffee Shop", icon: "cup.and.saucer.fill")
                    }
                    .padding(.horizontal)
                }

                Divider().padding(.vertical, 8)

                // Results
                if isSearching {
                    ProgressView()
                        .padding(40)
                    Spacer()
                } else if results.isEmpty && !searchText.isEmpty {
                    Text("No results found")
                        .foregroundColor(.gray)
                        .padding(40)
                    Spacer()
                } else {
                    List(results) { result in
                        Button(action: { selectResult(result) }) {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.purple)
                                    .font(.title3)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.name)
                                        .font(.subheadline.bold())
                                        .foregroundColor(.primary)
                                    if !result.address.isEmpty {
                                        Text(result.address)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if selectedResult?.id == result.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Pick a Place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(selectedResult == nil)
                }
            }
            .onAppear {
                locationService.requestAuthorization()
            }
        }
    }

    // MARK: - Helpers

    private func presetButton(_ text: String, icon: String) -> some View {
        Button(action: {
            searchText = text
            search()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.caption)
                Text(text).font(.caption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.purple.opacity(0.3))
            .clipShape(Capsule())
        }
    }

    private func search() {
        guard !searchText.isEmpty else { return }
        isSearching = true
        Task {
            results = await locationService.searchPlaces(query: searchText)
            isSearching = false
        }
    }

    private func selectResult(_ result: LocationSearchResult) {
        selectedResult = result
    }

    private func save() {
        guard let result = selectedResult else { return }
        locationName = result.name
        latitude = result.latitude
        longitude = result.longitude
        dismiss()
    }
}
