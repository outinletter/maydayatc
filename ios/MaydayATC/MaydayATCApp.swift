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
                .task { if automaticUpdates { await library.sync() } }
        }
    }
}

struct MainView: View {
    @EnvironmentObject private var library: Library
    @State private var query = ""
    @State private var savedOnly = false
    @State private var settings = false
    var lessons: [Scenario] {
        (library.catalog?.scenarios ?? []).filter {
            (!savedOnly || library.saved.contains($0.id)) &&
            (query.isEmpty || ($0.title + " " + $0.summary).localizedCaseInsensitiveContains(query))
        }
    }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Aviation English practice", systemImage: "waveform")
                        .font(.title2.bold()).foregroundStyle(.blue)
                    Text("10 offline situations · Dialogue rehearsal · Personal progress")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text(AppInformation.disclaimer).font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Toggle("Saved lessons only", isOn: $savedOnly)
                    if lessons.isEmpty { Text("No lessons found. Try another search or turn off the saved filter.").foregroundStyle(.secondary) }
                    ForEach(lessons) { scenario in
                        NavigationLink(value: scenario) {
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(scenario.title).font(.headline)
                                    Text(library.completed.contains(scenario.id) ? "Practiced" : "Ready to practice")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if library.saved.contains(scenario.id) { Image(systemName: "bookmark.fill").foregroundStyle(.blue).accessibilityLabel("Saved") }
                            }.padding(.vertical, 6)
                        }
                    }
                } header: { Text("Lessons") }
                Section {
                    Text("Original archive links open YouTube. Fictional lessons above are separate exercises, not transcripts or analyses of these recordings.").font(.footnote).foregroundStyle(.secondary)
                    ForEach((library.catalog?.references ?? []).filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }) { video in
                        Link(destination: video.url) {
                            VStack(alignment: .leading, spacing: 5) {
                                Label(video.title, systemImage: "play.rectangle")
                                Text(video.channel).font(.caption).foregroundStyle(.secondary)
                            }.padding(.vertical, 4)
                        }
                    }
                } header: { Text("ATC video archive · YouTube") }
                if !library.message.isEmpty {
                    Section("Content status") { Text(library.message).font(.footnote).accessibilityAddTraits(.updatesFrequently) }
                }
            }
            .navigationTitle("Mayday ATC")
            .searchable(text: $query, prompt: "Search lessons")
            .navigationDestination(for: Scenario.self) { LessonView(scenario: $0) }
            .toolbar { Button("Settings", systemImage: "gearshape") { settings = true } }
            .sheet(isPresented: $settings) { SettingsView() }
            .refreshable { await library.sync() }
            .overlay { if library.catalog == nil { ContentUnavailableView("Lessons unavailable", systemImage: "exclamationmark.triangle", description: Text(library.message)) } }
        }
    }
}

struct LessonView: View {
    @EnvironmentObject private var library: Library
    let scenario: Scenario
    @State private var rehearsing = false
    @State private var revealed: Set<Int> = []
    var body: some View {
        List {
            Section("Fictional language exercise") {
                Text(scenario.summary)
                Text("Examples below are invented for language practice and are not a transcript or operational checklist.").font(.footnote).foregroundStyle(.secondary)
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
        .navigationTitle(scenario.title).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button(library.saved.contains(scenario.id) ? "Unsave lesson" : "Save lesson", systemImage: library.saved.contains(scenario.id) ? "bookmark.fill" : "bookmark") { library.toggleSaved(scenario.id) }
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
                    Text("App version 1.0 (1)")
                }
            }
            .navigationTitle("Settings")
            .toolbar { Button("Done") { dismiss() } }
            .confirmationDialog("Delete saved lessons, progress, and downloaded content?", isPresented: $reset, titleVisibility: .visible) {
                Button("Delete local data", role: .destructive) { library.reset() }
            }
        }
    }
}
