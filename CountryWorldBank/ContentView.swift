//
//  ContentView.swift
//  CountryWorldBank
//
//  Created by Tatiana Kornilova on 28.01.2025.
//


// version with Map working
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CountryViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.loadingState {
                case .loading:
                    ProgressView("Loading countries...")
                case .loaded:
                    List {
                        ForEach(viewModel.groupedCountries.keys.sorted(), id: \.self) { region in
                            Section(header: Text(region).foregroundStyle(Color.blue).bold()) {
                                ForEach(viewModel.groupedCountries[region] ?? []) { country in
                                    CountryRow(country: country)
                                }
                            }
                        }
                    }
                case .error(let message):
                    Text(message)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("World Countries")
        }
        .task {
            await viewModel.fetchAllData()
        }
    }
}

//  ----- MAP ----
import SwiftUI
import MapKit

struct CountryDetailView: View {
    let country: Country
    @StateObject private var viewModel: CountryDetailViewModel
    
    init(country: Country) {
        self.country = country
        self._viewModel = StateObject(wrappedValue: CountryDetailViewModel(country: country))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                mapSection
                detailsSection
            }
            .padding()
        }
        .navigationTitle(country.name)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if viewModel.isLoading {
                ProgressView("Locating country...")
            }
        }
        .alert("Location Error", isPresented: $viewModel.showGeocodingError) {
            Button("OK") { }
        } message: {
            Text("Could not find location for \(country.name)")
        }
    }
    
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text(country.flag)
                    .font(.system(size: 48))
                Text(country.iso2Code)
                    .font(.title2)
                    .bold()
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(country.capitalCity)
                    .font(.title3)
                    .bold()
                Text("Capital City")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var mapSection: some View {
        Group {
            if let region = viewModel.region, let coordinate = viewModel.coordinate {
                Map(position: .constant(.region(region))) {
                    // Map content here
              //    Marker(country.name, coordinate: region.center)
                    // Custom annotation version
                    Annotation(country.capitalCity, coordinate: coordinate) {
                        Text(country.flag)
                            .font(.system(size: 34))
                   }

                }
               .mapControls {
                    MapCompass()
                    MapScaleView()
                }
                .frame(height: 400)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            if let population = country.population {
                DetailRow(label: "Population", value: population.formatted(), systemImage: "person.2")
            }
            
            if let gdp = country.gdp {
                DetailRow(label: "GDP", value: gdp.formatted(.currency(code: "USD")), systemImage: "dollarsign.circle")
            }
        }
    }
}

@MainActor
class CountryDetailViewModel: ObservableObject {
    let country: Country
    @Published var region: MKCoordinateRegion?
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var isLoading = false
    @Published var showGeocodingError = false
    
    // Add this computed property for MapKit
    var mapCameraPosition: MapCameraPosition? {
            guard let region else { return nil }
            return .region(region)
        }
    
    init(country: Country) {
        self.country = country
        Task {
           await  geocodeCountry()
        }
    }
    
    
    nonisolated func geocodeCountry() async {
        let geocoder = CLGeocoder()
        await MainActor.run {
            isLoading = true
        }
        defer { Task { @MainActor in isLoading = false } }
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(country.capitalCity)
            guard let location = placemarks.first?.location else {
                await MainActor.run {
                    showGeocodingError = true
                }
                return
            }
            
            let newCoordinate = location.coordinate
            await MainActor.run {
                coordinate = newCoordinate
                region = MKCoordinateRegion(
                    center: newCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
                )
            }
        } catch {
            await MainActor.run {
                showGeocodingError = true
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let systemImage: String
    
    var body: some View {
        HStack {
            Label(label, systemImage: systemImage)
            Spacer()
            Text(value)
                .font(.body.monospacedDigit())
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// Update your existing CountryListView navigation
// In CountryRow, add NavigationLink:
struct CountryRow: View {
    let country: Country
    
    var body: some View {
        NavigationLink {
            CountryDetailView(country: country)
        } label: {
            // Keep existing row content
            HStack(spacing: 12) {
                Text(country.flag)
                    .font(.system(size: 60))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(country.name)
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        Label(country.capitalCity, systemImage: "building.2")
                        Text(country.iso2Code)
                            .monospaced()
                    }
                    .font(.body)
                    
                    HStack(spacing: 5) {
                        if let population = country.population {
                            Label(population.formatted() + " people", systemImage: "person.2")
                        }
                        if let gdp = country.gdp {
                            Label("$" + gdp.formatted(), systemImage: "dollarsign.circle")
                        }
                    }
                    .font(.caption)
                }
            }
        }
    } // body
} // CountryRow
//-----------------MAP
struct Country: Decodable, Identifiable {
    let id: String
    let iso2Code: String
    let name: String
    let capitalCity: String
    let region: Region
    var population: Int?
    var gdp: Double?
    
    var flag: String {
        iso2Code.unicodeScalars
            .map { 127397 + $0.value }
            .compactMap(UnicodeScalar.init)
            .map(String.init)
            .joined()
    }
    
    struct Region: Decodable {
        let id: String
        let value: String
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, region
        case iso2Code = "iso2Code"
        case capitalCity = "capitalCity"
    }
}

@MainActor
class CountryViewModel: ObservableObject {
    enum LoadingState {
        case loading, loaded, error(String)
    }
    
    @Published var loadingState: LoadingState = .loading
    @Published var groupedCountries: [String: [Country]] = [:]
    
    private let countryURL = "https://api.worldbank.org/v2/country?format=json&per_page=300"
    private let populationURL = "https://api.worldbank.org/v2/country/all/indicator/SP.POP.TOTL?format=json&date=2022&per_page=300"
    private let gdpURL = "https://api.worldbank.org/v2/country/all/indicator/NY.GDP.MKTP.CD?format=json&date=2022&per_page=300"
    
    func fetchAllData() async {
        do {
            async let countries = fetchCountries()
            async let populationData = fetchIndicatorData(url: populationURL)
            async let gdpData = fetchIndicatorData(url: gdpURL)
            
            var finalCountries = try await countries
            let populationDict = try await populationData
            let gdpDict = try await gdpData
            
            // Merge economic data
            finalCountries = finalCountries.map { country in
                var modified = country
                modified.population = Int(populationDict[country.iso2Code] ?? 0)
              //  modified.population = Int(populationDict[country.id] ?? 0)
                modified.gdp = gdpDict[country.iso2Code]
              //  modified.gdp = gdpDict[country.id]
                return modified
            }
            
            let filtered = finalCountries.filter {
                !$0.region.value.lowercased().contains("aggregate") &&
                $0.region.id != "NA" &&
                $0.capitalCity != ""
            }
            
            let grouped = Dictionary(grouping: filtered) {
                $0.region.value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
           // await MainActor.run {
                groupedCountries = grouped
                loadingState = .loaded
          //  }
        } catch {
            await MainActor.run {
                loadingState = .error("Failed to load data: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated private func fetchCountries() async throws -> [Country] {
        struct WorldBankResponse: Decodable {
            let countries: [Country]
            
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                _ = try container.decode(CountryResponseMetadata.self)
                countries = try container.decode([Country].self)
            }
        }
        
        let (data, _) = try await URLSession.shared.data(from: URL(string: countryURL)!)
        return try JSONDecoder().decode(WorldBankResponse.self, from: data).countries
    }
    
    nonisolated private func fetchIndicatorData(url: String) async throws -> [String: Double] {
        
        struct IndicatorResponse: Decodable {
            let entries: [Entry]
            
            init(from decoder: Decoder) throws {
                var container = try decoder.unkeyedContainer()
                _ = try container.decode(IndicatorResponseMetadata.self)
                entries = try container.decode([Entry].self)
            }
            
            struct Entry: Decodable {
                let country: CountryInd
                let countryiso3code: String?
                let value: Double?
                
                struct CountryInd: Decodable {
                    let id: String  // This is the ISO2 code
                }
            }
        }
       
        do {
        let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
        let response = try JSONDecoder().decode(IndicatorResponse.self, from: data)
        
        let dictionary: [String: Double] = response.entries.reduce(into: [:]) { dict, entry in
            guard let value = entry.value else { return }
            dict[entry.country.id] = value
       //     guard let value = entry.value, let iso3 = entry.countryiso3code else { return }
       //     dict[iso3] = value
        }
        
        return dictionary
        } catch {
            print("Error in Indicator fetching: \(error)")
            return [:]
        }
    }
}

// Separate metadata structures for different endpoints
struct CountryResponseMetadata: Decodable {
    let page: Int
    let pages: Int
    let perPage: String // String in country endpoint
    let total: Int
    
    enum CodingKeys: String, CodingKey {
        case page, pages, total
        case perPage = "per_page"
    }
}

struct IndicatorResponseMetadata: Decodable {
    let page: Int
    let pages: Int
    let perPage: Int     // Indicator endpoint uses Int
    let total: Int
    let lastUpdated: String
    
    enum CodingKeys: String, CodingKey {
        case page, pages, total
        case perPage = "per_page"
        case lastUpdated = "lastupdated"
    }
}

#Preview {
    ContentView()
}
