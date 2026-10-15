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
                message = "Video list and learning dialogues updated."
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
    var body: some Scene {
        WindowGroup {
            MainView().environmentObject(library)
                .preferredColorScheme(.light)
                .tint(ArchiveTheme.accent)
                .foregroundStyle(ArchiveTheme.ink)
        }
    }
}

enum ArchiveTheme {
    static let accent = Color(red: 0.14, green: 0.31, blue: 0.42)
    static let ink = Color(red: 0.09, green: 0.13, blue: 0.17)
    static let secondaryInk = Color(red: 0.28, green: 0.32, blue: 0.37)
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
                                .font(.subheadline).foregroundStyle(ArchiveTheme.secondaryInk)
                        }
                        Spacer(minLength: 8)
                        Menu {
                            Button("All Categories") { category = "all" }
                            ForEach((library.catalog?.scenarios ?? []).filter { !$0.id.hasPrefix("video-") }) { item in
                                Button(item.title) { category = item.id }
                            }
                            Divider()
                            Toggle("Saved recordings only", isOn: $savedOnly)
                        } label: {
                            Label("Filter", systemImage: "line.3.horizontal.decrease").font(.subheadline.weight(.semibold)).padding(12)
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
                        Text(library.message).foregroundStyle(ArchiveTheme.secondaryInk)
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
                            Text("Mayday ATC").font(.title2.bold()).foregroundStyle(ArchiveTheme.ink)
                            Text("ARCHIVE").font(.subheadline.weight(.medium)).tracking(1).foregroundStyle(ArchiveTheme.secondaryInk)
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
                    Text(categoryTitle).font(.subheadline.weight(.semibold)).foregroundStyle(blue)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(ArchiveTheme.sky, in: RoundedRectangle(cornerRadius: 6))
                    Text(video.title).font(.title3.weight(.semibold)).foregroundStyle(ArchiveTheme.ink)
                        .lineSpacing(4).fixedSize(horizontal: false, vertical: true).multilineTextAlignment(.leading)
                }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
            }.buttonStyle(.plain)
            HStack {
                Text(video.channel).font(.subheadline.weight(.medium)).foregroundStyle(ArchiveTheme.secondaryInk)
                Spacer()
                if library.saved.contains(video.id) { Image(systemName: "bookmark.fill").foregroundStyle(blue).accessibilityLabel("Saved") }
                Link(destination: video.url) {
                    Label("Play", systemImage: "play.fill").font(.subheadline.weight(.semibold)).padding(.horizontal, 14).frame(minHeight: 44)
                        .background(ArchiveTheme.mint, in: Capsule())
                }
            }
        }
        .padding(20)
        .background(ArchiveTheme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(blue.opacity(0.12)))
    }
}

struct VideoDetailView: View {
    @EnvironmentObject private var library: Library
    let video: VideoReference
    var scenario: Scenario? { library.catalog?.scenarios.first { $0.id == (video.lessonId ?? video.category) } }
    var body: some View {
        List {
            Section {
                if let scenario { Text(scenario.title).font(.subheadline.weight(.semibold)).foregroundStyle(.tint) }
                Text(video.title).font(.title2.bold()).lineSpacing(4).fixedSize(horizontal: false, vertical: true)
                Text(video.channel).foregroundStyle(ArchiveTheme.secondaryInk)
                Link(destination: video.url) {
                    Label("Watch on YouTube", systemImage: "play.rectangle.fill")
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
        .environment(\.defaultMinListRowHeight, 52)
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
                Text(scenario.summary).lineSpacing(6)
                Text("These category examples are independent of the video above. They are not its transcript, incident analysis, or an operational checklist.").font(.subheadline).foregroundStyle(ArchiveTheme.secondaryInk)
            }
            Section {
                Toggle("Rehearse pilot responses", isOn: $rehearsing)
                    .onChange(of: rehearsing) { _, _ in revealed = [] }
                if rehearsing { Text("Say a response in your own words, then reveal the example. No audio is recorded.").font(.subheadline).foregroundStyle(ArchiveTheme.secondaryInk) }
                ForEach(Array(scenario.dialogue.enumerated()), id: \.offset) { index, line in
                    DialogueBubble(isPilot: line.from == "PILOT", message: line.msg,
                                   hidden: rehearsing && line.from == "PILOT" && !revealed.contains(index)) {
                        revealed.insert(index)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(ArchiveTheme.background)
                }
            } header: { Text("Illustrative dialogue") }
            Section("Language reflection") { PracticeReadingView(text: scenario.practice) }
            Section {
                Button(library.completed.contains(scenario.id) ? "Practiced — practice again anytime" : "Mark as practiced", systemImage: "checkmark.circle") { library.finish(scenario.id) }
                ShareLink(item: "Mayday ATC — fictional English practice\n\(scenario.title)\n\(scenario.practice)\n\(AppInformation.disclaimer)") { Label("Share practice prompt", systemImage: "square.and.arrow.up") }
            }
        }
    }
}

struct DialogueBubble: View {
    let isPilot: Bool
    let message: String
    let hidden: Bool
    let reveal: () -> Void
    private var roleColor: Color { isPilot ? ArchiveTheme.accent : Color(red: 0.10, green: 0.34, blue: 0.27) }
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isPilot { Spacer(minLength: 20) }
            VStack(alignment: .leading, spacing: 12) {
                Label(isPilot ? "PILOT" : "ATC · CONTROLLER",
                      systemImage: isPilot ? "airplane" : "antenna.radiowaves.left.and.right")
                    .font(.subheadline.weight(.bold)).foregroundStyle(roleColor)
                if hidden {
                    Button("Reveal pilot response", action: reveal)
                        .font(.body.weight(.semibold)).frame(minHeight: 44)
                } else {
                    Text(message).font(.body).foregroundStyle(ArchiveTheme.ink)
                        .lineSpacing(6).fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
            .padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .background(isPilot ? ArchiveTheme.sky : ArchiveTheme.mint,
                        in: RoundedRectangle(cornerRadius: 16))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(roleColor).frame(width: 3).padding(.vertical, 16)
            }
            .accessibilityElement(children: .contain)
            if !isPilot { Spacer(minLength: 20) }
        }.padding(.vertical, 4)
    }
}

struct PracticeReadingView: View {
    let text: String
    var body: some View {
        ForEach(PracticeBlock.parse(text)) { block in
            blockView(block)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                .listRowBackground(ArchiveTheme.background)
        }
    }
    @ViewBuilder private func blockView(_ block: PracticeBlock) -> some View {
        switch block.kind {
        case .pilot, .controller:
            DialogueBubble(isPilot: block.kind == .pilot, message: block.text, hidden: false, reveal: {})
        case .step:
            Text(block.text).font(.title3.weight(.bold)).foregroundStyle(ArchiveTheme.ink)
                .lineSpacing(4).fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20).padding(.bottom, 4)
                .accessibilityAddTraits(.isHeader)
        case .paragraph:
            Text(block.text).font(.body).foregroundStyle(ArchiveTheme.ink).lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true).padding(.horizontal, 6).textSelection(.enabled)
        default:
            let stage = stageInfo(for: block.kind)
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Text(stage.number)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(stage.color, in: Circle())
                    Text(stage.title.uppercased())
                        .font(.caption.weight(.bold))
                        .tracking(0.8)
                        .foregroundStyle(stage.color)
                }
                Text(block.text).font(.body).foregroundStyle(ArchiveTheme.ink).lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
            }
            .padding(.vertical, 18).padding(.horizontal, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(stage.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3).fill(stage.color).frame(width: 4).padding(.vertical, 12)
            }
            .padding(.leading, stage.indent)
        }
    }
    private func stageInfo(for kind: PracticeBlock.Kind) -> (number: String, title: String, color: Color, indent: CGFloat) {
        switch kind {
        case .original: ("1", "Start with the idea", ArchiveTheme.accent, 0)
        case .corrected: ("2", "Make it precise", Color(red: 0.10, green: 0.34, blue: 0.27), 18)
        case .explanation: ("3", "Understand the change", Color(red: 0.38, green: 0.28, blue: 0.58), 36)
        case .alternative: ("4", "Try another option", Color(red: 0.68, green: 0.35, blue: 0.12), 18)
        default: ("", label(for: kind), ArchiveTheme.accent, 0)
        }
    }
    private func label(for kind: PracticeBlock.Kind) -> String {
        switch kind {
        case .original: "Original phrase"
        case .corrected: "Revised phrase"
        case .explanation: "Why this wording"
        case .alternative: "Alternative expression"
        default: "Practice"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var library: Library
    @Environment(\.dismiss) private var dismiss
    @State private var reset = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Content updates") {
                    Text("Download the latest published video list and learning dialogues. New material is prepared centrally; this button does not start collection or generation.").font(.subheadline)
                    Button { Task { await library.sync() } } label: {
                        Label(library.syncing ? "Updating content…" : "Update content now",
                              systemImage: library.syncing ? "arrow.triangle.2.circlepath" : "arrow.down.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.82, green: 0.91, blue: 0.93))
                    .foregroundStyle(ArchiveTheme.accent)
                    .disabled(library.syncing)
                    Text("Tap the button to download the latest published lessons from GitHub.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let date = library.checked { Text("Last checked: \(date.formatted())") }
                    if !library.message.isEmpty { Text(library.message).font(.subheadline) }
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
                    Text("App version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"))")
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
