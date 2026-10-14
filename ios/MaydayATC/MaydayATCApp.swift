import SwiftUI

@MainActor
final class Library: ObservableObject {
    @Published private(set) var catalog: Catalog?
    @Published private(set) var syncing = false
    @Published var message = ""
    @Published private(set) var checked: Date?
    @Published private(set) var saved: Set<String>
    @Published private(set) var completed: Set<String>
    private let defaults = UserDefaults.standard
    private let cache: URL
    static let feed = URL(string: "https://raw.githubusercontent.com/outinletter/maydayatc/main/content/catalog.json")!

    init() {
        saved = Set(defaults.stringArray(forKey: "saved") ?? [])
        completed = Set(defaults.stringArray(forKey: "completed") ?? [])
        checked = defaults.object(forKey: "checked") as? Date
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        cache = folder.appendingPathComponent("catalog.json")
        let bundled = Bundle.main.url(forResource: "catalog", withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) }.flatMap { try? Catalog.decode($0) }
        let downloaded = (try? Data(contentsOf: cache)).flatMap { try? Catalog.decode($0) }
        if let downloaded, downloaded.revision >= (bundled?.revision ?? 0) {
            catalog = downloaded
        } else { catalog = bundled }
        if catalog == nil { message = "The bundled lessons could not be opened. Please reinstall the app." }
    }

    func toggleSaved(_ id: String) {
        if saved.contains(id) { saved.remove(id) } else { saved.insert(id) }
        defaults.set(Array(saved), forKey: "saved")
    }

    func finish(_ id: String) {
        completed.insert(id)
        defaults.set(Array(completed), forKey: "completed")
    }

    func reset() {
        saved = []; completed = []; checked = nil
        for key in ["saved", "completed", "checked"] { defaults.removeObject(forKey: key) }
        try? FileManager.default.removeItem(at: cache)
        catalog = Bundle.main.url(forResource: "catalog", withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) }.flatMap { try? Catalog.decode($0) }
        message = "Local data deleted. Bundled lessons restored."
    }

    func sync() async {
        guard !syncing else { return }
        syncing = true
        defer { syncing = false }
        do {
            var request = URLRequest(url: Self.feed, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            let config = URLSessionConfiguration.ephemeral
            config.httpShouldSetCookies = false
            let session = URLSession(configuration: config)
            defer { session.invalidateAndCancel() }
            let (bytes, response) = try await session.bytes(for: request)
            guard let response = response as? HTTPURLResponse, response.statusCode == 200,
                  response.url == Self.feed, response.expectedContentLength <= 1_000_000 else { throw ContentError.response }
            var data = Data()
            for try await byte in bytes {
                guard data.count < 1_000_000 else { throw ContentError.invalid }
                data.append(byte)
            }
            let next = try Catalog.decode(data)
            guard next.revision >= (catalog?.revision ?? 0) else { throw ContentError.rollback }
            if next.revision == catalog?.revision {
                message = "Content is up to date."
            } else {
                try FileManager.default.createDirectory(at: cache.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: cache, options: .atomic)
                catalog = next
                message = "New lessons downloaded."
            }
            checked = Date()
            defaults.set(checked, forKey: "checked")
        } catch {
            message = (error as? ContentError)?.localizedDescription ?? "Could not check GitHub. Offline lessons are still available. Try again later."
        }
    }
}

@main
struct MaydayATCApp: App {
    @StateObject private var library = Library()
    @AppStorage("automaticUpdates") private var automaticUpdates = true
    var body: some Scene {
        WindowGroup {
            MainView().environmentObject(library)
                .preferredColorScheme(.light)
                .tint(ArchiveTheme.accent)
                .foregroundStyle(ArchiveTheme.ink)
                .task { if automaticUpdates { await library.sync() } }
        }
    }
}

enum ArchiveTheme {
    static let accent = Color(red: 0.29, green: 0.48, blue: 0.59)
    static let ink = Color(red: 0.20, green: 0.30, blue: 0.37)
    static let background = Color(red: 0.95, green: 0.97, blue: 0.98)
    static let card = Color(red: 1.0, green: 0.99, blue: 0.97)
    static let sky = Color(red: 0.86, green: 0.93, blue: 0.97)
    static let mint = Color(red: 0.87, green: 0.95, blue: 0.91)
}

struct MainView: View {
    @EnvironmentObject private var library: Library
    @State private var query = ""
    @State private var category = "all"
    @State private var savedOnly = false
    @State private var showSearch = false
    @State private var settings = false
    private let blue = ArchiveTheme.accent
    var videos: [VideoReference] {
        (library.catalog?.references ?? []).filter {
            (category == "all" || $0.category == category) &&
            (!savedOnly || library.saved.contains($0.id)) &&
            (query.isEmpty || ($0.title + " " + $0.channel).localizedCaseInsensitiveContains(query))
        }
    }
    var categoryTitle: String {
        library.catalog?.scenarios.first { $0.id == category }?.title ?? "All Categories"
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if showSearch {
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundStyle(blue)
                            TextField("Search recordings or channels", text: $query)
                                .textInputAutocapitalization(.never).autocorrectionDisabled()
                            if !query.isEmpty { Button("Clear", systemImage: "xmark.circle.fill") { query = "" }.labelStyle(.iconOnly) }
                        }.padding().background(.background, in: RoundedRectangle(cornerRadius: 12))
                    }
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(categoryTitle).font(.title2.bold())
                            Text("\(videos.count) emergency recordings\(savedOnly ? " · Saved" : "")")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Menu {
                            Button("All Categories") { category = "all" }
                            ForEach(library.catalog?.scenarios ?? []) { item in
                                Button(item.title) { category = item.id }
                            }
                            Divider()
                            Toggle("Saved recordings only", isOn: $savedOnly)
                        } label: {
                            Text("FILTER").font(.subheadline.bold()).padding(12)
                                .foregroundStyle(blue).background(blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }.padding(.vertical, 8)
                    ForEach(videos) { video in
                        ArchiveCard(video: video, categoryTitle: library.catalog?.scenarios.first { $0.id == video.category }?.title ?? "Other")
                    }
                    if videos.isEmpty {
                        ContentUnavailableView("No matching recordings", systemImage: "magnifyingglass", description: Text("Try another category or search, or turn off the saved filter."))
                    }
                    if library.catalog == nil {
                        Text(library.message).foregroundStyle(.secondary)
                    }
                }.padding(16)
            }
            .background(ArchiveTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Search archive", systemImage: "magnifyingglass") { showSearch.toggle() }.labelStyle(.iconOnly)
                }
                ToolbarItem(placement: .principal) {
                    Button { category = "all"; query = ""; savedOnly = false } label: {
                        VStack(spacing: 1) {
                            Text("Mayday ATC").font(.system(size: 27, weight: .heavy)).foregroundStyle(ArchiveTheme.ink)
                            Text("ARCHIVE").font(.caption.weight(.semibold)).tracking(1).foregroundStyle(.secondary)
                        }
                    }.buttonStyle(.plain).accessibilityLabel("Mayday ATC, show all recordings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Settings", systemImage: "gearshape") { settings = true }.labelStyle(.iconOnly)
                }
            }
            .toolbarBackground(ArchiveTheme.card, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(blue)
            .navigationDestination(for: VideoReference.self) { VideoDetailView(video: $0) }
            .sheet(isPresented: $settings) { SettingsView() }
            .refreshable { await library.sync() }
        }
    }
}

struct ArchiveCard: View {
    @EnvironmentObject private var library: Library
    let video: VideoReference
    let categoryTitle: String
    private let blue = ArchiveTheme.accent
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(value: video) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(categoryTitle).font(.caption.bold()).foregroundStyle(blue)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(ArchiveTheme.sky, in: RoundedRectangle(cornerRadius: 6))
                    Text(video.title).font(.headline).foregroundStyle(ArchiveTheme.ink).multilineTextAlignment(.leading)
                }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(.plain)
            HStack {
                Text(video.channel).font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                if library.saved.contains(video.id) { Image(systemName: "bookmark.fill").foregroundStyle(blue).accessibilityLabel("Saved") }
                Link(destination: video.url) {
                    Label("PLAY", systemImage: "play.fill").font(.caption.bold()).padding(.horizontal, 14).frame(minHeight: 44)
                        .background(ArchiveTheme.mint, in: Capsule())
                }
            }
        }
        .padding(18)
        .background(ArchiveTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(blue.opacity(0.12)))
    }
}

struct VideoDetailView: View {
    @EnvironmentObject private var library: Library
    let video: VideoReference
    var scenario: Scenario? { library.catalog?.scenarios.first { $0.id == video.category } }
    var body: some View {
        List {
            Section {
                if let scenario { Text(scenario.title).font(.caption.bold()).foregroundStyle(.tint) }
                Text(video.title).font(.title2.bold())
                Text(video.channel).foregroundStyle(.secondary)
                Link(destination: video.url) {
                    Label("WATCH REAL ATC VIDEO", systemImage: "play.rectangle.fill")
                        .font(.headline).frame(maxWidth: .infinity, minHeight: 44)
                }
            }
            if let scenario { ScenarioContent(scenario: scenario) }
            Section {
                ShareLink(item: video.url) { Label("Share video", systemImage: "square.and.arrow.up") }
            }
        }
        .scrollContentBackground(.hidden)
        .background(ArchiveTheme.background)
        .listRowBackground(ArchiveTheme.card)
        .navigationTitle("ATC Archive").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(library.saved.contains(video.id) ? "Unsave recording" : "Save recording", systemImage: library.saved.contains(video.id) ? "bookmark.fill" : "bookmark") { library.toggleSaved(video.id) }
        }
    }
}

struct ScenarioContent: View {
    @EnvironmentObject private var library: Library
    let scenario: Scenario
    @State private var rehearsing = false
    @State private var revealed: Set<Int> = []
    var body: some View {
        Group {
            Section("Category language practice · fictional") {
                Text(scenario.summary)
                Text("These category examples are independent of the video above. They are not its transcript, incident analysis, or an operational checklist.").font(.footnote).foregroundStyle(.secondary)
            }
            Section("Pilot communication goals") { ForEach(scenario.pilotRoles, id: \.self) { Text($0) } }
            Section("Controller communication goals") { ForEach(scenario.atcRoles, id: \.self) { Text($0) } }
            Section {
                Toggle("Rehearse pilot responses", isOn: $rehearsing)
                    .onChange(of: rehearsing) { _, _ in revealed = [] }
                if rehearsing { Text("Say a response in your own words, then reveal the example. No audio is recorded.").font(.footnote).foregroundStyle(.secondary) }
                ForEach(Array(scenario.dialogue.enumerated()), id: \.offset) { index, line in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(line.from).font(.caption.bold()).foregroundStyle(line.from == "PILOT" ? .blue : .secondary)
                        if rehearsing && line.from == "PILOT" && !revealed.contains(index) {
                            Button("Reveal pilot example") { revealed.insert(index) }
                        } else { Text(line.msg).textSelection(.enabled) }
                    }.padding(.vertical, 6)
                }
            } header: { Text("Illustrative dialogue") }
            Section("Language reflection") { Text(scenario.practice).textSelection(.enabled) }
            Section {
                Button(library.completed.contains(scenario.id) ? "Practiced — practice again anytime" : "Mark as practiced", systemImage: "checkmark.circle") { library.finish(scenario.id) }
                ShareLink(item: "Mayday ATC — fictional English practice\n\(scenario.title)\n\(scenario.practice)\n\(AppInformation.disclaimer)") { Label("Share practice prompt", systemImage: "square.and.arrow.up") }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var library: Library
    @Environment(\.dismiss) private var dismiss
    @AppStorage("automaticUpdates") private var automaticUpdates = true
    @State private var reset = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Content updates") {
                    Toggle("Check GitHub on app launch", isOn: $automaticUpdates)
                    Text("Downloads lesson text only. New app features and app versions are delivered through the App Store.").font(.footnote)
                    Button { Task { await library.sync() } } label: {
                        HStack { Text("Check for lesson updates"); if library.syncing { ProgressView() } }
                    }.disabled(library.syncing)
                    Text("Content revision: \(library.catalog?.revision ?? 0)")
                    if let date = library.checked { Text("Last checked: \(date.formatted())") }
                    if !library.message.isEmpty { Text(library.message).font(.footnote) }
                }
                Section("Progress") {
                    Text("\((library.catalog?.scenarios ?? []).filter { library.completed.contains($0.id) }.count) of \(library.catalog?.scenarios.count ?? 0) lessons practiced")
                    Button("Delete local data", role: .destructive) { reset = true }
                }
                Section("Privacy policy") {
                    Text(AppInformation.privacy)
                    Link("GitHub privacy statement", destination: URL(string: "https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement")!)
                }
                Section("About and support") {
                    Text(AppInformation.disclaimer)
                    Text("Independent learning aid. No affiliation with or endorsement by ICAO, FAA, Apple, airlines, or ATC authorities.")
                    Link("Support / report a content issue", destination: URL(string: "https://github.com/outinletter/maydayatc/issues")!)
                    Text("App version 1.0 (3)")
                }
            }
            .scrollContentBackground(.hidden)
            .background(ArchiveTheme.background)
            .navigationTitle("Settings")
            .toolbar { Button("Done") { dismiss() } }
            .confirmationDialog("Delete saved lessons, progress, and downloaded content?", isPresented: $reset, titleVisibility: .visible) {
                Button("Delete local data", role: .destructive) { library.reset() }
            }
        }
    }
}
