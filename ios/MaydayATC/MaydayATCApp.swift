import SwiftUI

@MainActor
final class Library: ObservableObject {
    @Published private(set) var catalog: Catalog?
    @Published private(set) var syncing = false
    @Published var message = ""
    @Published private(set) var checked: Date?
    @Published private(set) var saved: Set<String>
    @Published private(set) var completed: Set<String>
    @Published var learningRole: LearningRole {
        didSet { defaults.set(learningRole.rawValue, forKey: "learningRole") }
    }
    @Published private(set) var practiceResults: [String: PracticeResult]
    private let defaults = UserDefaults.standard
    private let cache: URL
    static let feed = URL(string: "https://raw.githubusercontent.com/outinletter/maydayatc/main/content/catalog.json")!

    init() {
        learningRole = LearningRole(rawValue: UserDefaults.standard.string(forKey: "learningRole") ?? "pilot") ?? .pilot
        practiceResults = UserDefaults.standard.data(forKey: "practiceResults")
            .flatMap { try? JSONDecoder().decode([String: PracticeResult].self, from: $0) } ?? [:]
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
        if catalog == nil { message = L.text("The bundled lessons could not be opened. Please reinstall the app.") }
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
        practiceResults = [:]
        learningRole = .pilot
        for key in ["saved", "completed", "checked", "practiceResults", "learningRole"] { defaults.removeObject(forKey: key) }
        try? FileManager.default.removeItem(at: cache)
        catalog = Bundle.main.url(forResource: "catalog", withExtension: "json")
            .flatMap { try? Data(contentsOf: $0) }.flatMap { try? Catalog.decode($0) }
        message = L.text("Local data deleted. Bundled lessons restored.")
    }

    func record(_ question: DialogueQuestion, selected: Int) {
        guard question.options.indices.contains(selected) else { return }
        var result = practiceResults[question.id] ?? PracticeResult(attempts: 0, correct: 0, needsReview: false)
        result.attempts += 1
        if selected == question.correctIndex { result.correct += 1 }
        result.needsReview = selected != question.correctIndex
        practiceResults[question.id] = result
        if let data = try? JSONEncoder().encode(practiceResults) { defaults.set(data, forKey: "practiceResults") }
    }

    var activeQuestions: [DialogueQuestion] {
        (catalog?.scenarios ?? []).flatMap { DialogueQuestion.make(scenario: $0, role: learningRole) }
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
                message = L.text("Content is up to date.")
            } else {
                try FileManager.default.createDirectory(at: cache.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: cache, options: .atomic)
                catalog = next
                message = L.text("Video list and learning dialogues updated.")
            }
            checked = Date()
            defaults.set(checked, forKey: "checked")
        } catch {
            message = (error as? ContentError)?.localizedDescription ?? L.text("Could not check GitHub. Offline lessons are still available. Try again later.")
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
        library.catalog?.scenarios.first { $0.id == category }?.displayTitle ?? L.text("All Categories")
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    NavigationLink {
                        RolePracticeLibraryView()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(L.format("%@ practice", library.learningRole.title)).font(.headline)
                                Text("Read a dialogue · choose a response · review mistakes")
                                    .font(.subheadline).foregroundStyle(ArchiveTheme.secondaryInk)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }.padding(18).background(ArchiveTheme.mint, in: RoundedRectangle(cornerRadius: 16))
                    }.buttonStyle(.plain).accessibilityIdentifier("role-practice")
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
                            Text(L.format("%lld emergency recordings", videos.count) + (savedOnly ? " · " + L.text("Saved") : ""))
                                .font(.subheadline).foregroundStyle(ArchiveTheme.secondaryInk)
                        }
                        Spacer(minLength: 8)
                        Menu {
                            Button("All Categories") { category = "all" }
                            ForEach((library.catalog?.scenarios ?? []).filter { !$0.id.hasPrefix("video-") }) { item in
                                Button(item.displayTitle) { category = item.id }
                            }
                            Divider()
                            Toggle("Saved recordings only", isOn: $savedOnly)
                        } label: {
                            Label("Filter", systemImage: "line.3.horizontal.decrease").font(.subheadline.weight(.semibold)).padding(12)
                                .foregroundStyle(blue).background(blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }.padding(.vertical, 8)
                    ForEach(videos) { video in
                        ArchiveCard(video: video, categoryTitle: library.catalog?.scenarios.first { $0.id == video.category }?.displayTitle ?? L.text("Other"))
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
                if let scenario { Text(scenario.displayTitle).font(.subheadline.weight(.semibold)).foregroundStyle(.tint) }
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
            Button(L.text(library.saved.contains(video.id) ? "Unsave recording" : "Save recording"), systemImage: library.saved.contains(video.id) ? "bookmark.fill" : "bookmark") { library.toggleSaved(video.id) }
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
                Text(scenario.displaySummary).lineSpacing(6)
                Text("Fictional language examples only. Not video transcripts, incident analyses, or operational guidance.").font(.subheadline).foregroundStyle(ArchiveTheme.secondaryInk)
            }
            Section {
                Toggle(L.format("Rehearse %@ responses", library.learningRole.responseTitle), isOn: $rehearsing)
                    .accessibilityIdentifier("rehearsal")
                    .onChange(of: rehearsing) { _, _ in revealed = [] }
                    .onChange(of: library.learningRole) { _, _ in revealed = [] }
                if rehearsing { Text("Say a response in your own words, then reveal the example. No audio is recorded.").font(.subheadline).foregroundStyle(ArchiveTheme.secondaryInk) }
                ForEach(Array(scenario.dialogue.enumerated()), id: \.offset) { index, line in
                    DialogueBubble(isPilot: line.from == "PILOT", message: line.msg,
                                   hidden: rehearsing && line.from == library.learningRole.speaker && !revealed.contains(index),
                                   canToggle: rehearsing && line.from == library.learningRole.speaker) {
                        if revealed.contains(index) { revealed.remove(index) }
                        else { revealed.insert(index) }
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(ArchiveTheme.background)
                }
            } header: { Text("Illustrative dialogue") }
            RoleQuizView(scenario: scenario).id(scenario.id + library.learningRole.rawValue)
            Section("Language reflection") { PracticeReadingView(text: scenario.practice) }
            Section {
                Button(L.text(library.completed.contains(scenario.id) ? "Practiced — practice again anytime" : "Mark as practiced"), systemImage: "checkmark.circle") { library.finish(scenario.id) }
                ShareLink(item: scenario.shareText) { Label("Share practice prompt", systemImage: "square.and.arrow.up") }
            }
        }
    }
}

struct DialogueBubble: View {
    let isPilot: Bool
    let message: String
    let hidden: Bool
    var canToggle: Bool = false
    let reveal: () -> Void
    private var roleColor: Color { isPilot ? ArchiveTheme.accent : Color(red: 0.10, green: 0.34, blue: 0.27) }
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if isPilot { Spacer(minLength: 20) }
            VStack(alignment: .leading, spacing: 12) {
                Label(L.text(isPilot ? "PILOT" : "ATC · CONTROLLER"),
                      systemImage: isPilot ? "airplane" : "antenna.radiowaves.left.and.right")
                    .font(.subheadline.weight(.bold)).foregroundStyle(roleColor)
                if hidden {
                    Button(L.text(isPilot ? "Reveal pilot response" : "Reveal controller response"), action: reveal)
                        .font(.body.weight(.semibold)).frame(minHeight: 44)
                } else {
                    if canToggle {
                        Button(L.text(isPilot ? "Hide pilot response" : "Hide controller response"), action: reveal)
                            .font(.body.weight(.semibold)).frame(minHeight: 44)
                    }
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
            Text(block.displayText).font(.title3.weight(.bold)).foregroundStyle(ArchiveTheme.ink)
                .lineSpacing(4).fixedSize(horizontal: false, vertical: true)
                .padding(.top, 20).padding(.bottom, 4)
                .accessibilityAddTraits(.isHeader)
        case .paragraph:
            Text(block.displayText).font(.body).foregroundStyle(ArchiveTheme.ink).lineSpacing(6)
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
                Text(block.displayText).font(.body).foregroundStyle(ArchiveTheme.ink).lineSpacing(6)
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
        case .original: ("1", NSLocalizedString("Start with the idea", comment: "Learning stage"), ArchiveTheme.accent, 0)
        case .corrected: ("2", NSLocalizedString("Make it precise", comment: "Learning stage"), Color(red: 0.10, green: 0.34, blue: 0.27), 18)
        case .explanation: ("3", NSLocalizedString("Understand the change", comment: "Learning stage"), Color(red: 0.38, green: 0.28, blue: 0.58), 36)
        case .alternative: ("4", NSLocalizedString("Try another option", comment: "Learning stage"), Color(red: 0.68, green: 0.35, blue: 0.12), 18)
        default: ("", label(for: kind), ArchiveTheme.accent, 0)
        }
    }
    private func label(for kind: PracticeBlock.Kind) -> String {
        switch kind {
        case .original: NSLocalizedString("Original phrase", comment: "Learning stage")
        case .corrected: NSLocalizedString("Revised phrase", comment: "Learning stage")
        case .explanation: NSLocalizedString("Why this wording", comment: "Learning stage")
        case .alternative: NSLocalizedString("Alternative expression", comment: "Learning stage")
        default: L.text("Practice")
        }
    }
}

struct RolePracticeLibraryView: View {
    @EnvironmentObject private var library: Library
    @State private var reviewOnly = false
    var body: some View {
        List {
            Section {
                Picker("Practice as", selection: $library.learningRole) {
                    ForEach(LearningRole.allCases) { role in Text(role.title).tag(role) }
                }
                Text("Read the dialogue and choose the next response. Compare both examples and their explanations.")
                Toggle("Only lessons with mistakes to review", isOn: $reviewOnly)
            }
            Section("Fictional dialogue lessons") {
                ForEach(library.catalog?.scenarios ?? []) { scenario in
                    let questions = DialogueQuestion.make(scenario: scenario, role: library.learningRole)
                    let pending = questions.filter { library.practiceResults[$0.id]?.needsReview == true }.count
                    if !questions.isEmpty && (!reviewOnly || pending > 0) {
                        NavigationLink {
                            List { ScenarioContent(scenario: scenario) }
                                .scrollContentBackground(.hidden)
                                .background(ArchiveTheme.background)
                                .navigationTitle(scenario.displayTitle)
                                .navigationBarTitleDisplayMode(.inline)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(scenario.displayTitle).font(.headline)
                                Text(L.format("%lld questions · %lld to review", questions.count, pending))
                                    .font(.subheadline).foregroundStyle(ArchiveTheme.secondaryInk)
                            }.padding(.vertical, 6)
                        }.accessibilityIdentifier("lesson-" + scenario.id)
                    }
                }
                if reviewOnly && !library.activeQuestions.contains(where: { library.practiceResults[$0.id]?.needsReview == true }) {
                    Text("No mistakes to review for this role. Choose a lesson to start practicing.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(ArchiveTheme.background)
        .navigationTitle("Role practice")
    }
}

struct RoleQuizView: View {
    @EnvironmentObject private var library: Library
    let scenario: Scenario
    @State private var selections: [String: Int] = [:]
    @State private var reviewOnly = false
    private var questions: [DialogueQuestion] { DialogueQuestion.make(scenario: scenario, role: library.learningRole) }
    var body: some View {
        Section {
            Text(L.format("Choose the next %@ response", library.learningRole.responseTitle))
                .font(.title3.bold())
            Text("Read the dialogue first. This checks reading comprehension, not operational decisions.")
                .font(.subheadline).foregroundStyle(ArchiveTheme.secondaryInk)
            Text(L.format("%lld of %lld answered this round", selections.count, questions.count))
                .font(.subheadline.weight(.semibold))
            Text("Only your first answer counts. You may compare both explanations. Start a new round to answer again.")
                .font(.subheadline).foregroundStyle(ArchiveTheme.secondaryInk)
            Toggle("Review mistakes only", isOn: $reviewOnly)
            ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                if !reviewOnly || library.practiceResults[question.id]?.needsReview == true || selections[question.id] != nil {
                    questionCard(question, number: index + 1)
                        .listRowSeparator(.hidden)
                        .listRowBackground(ArchiveTheme.background)
                }
            }
            if reviewOnly && !questions.contains(where: { library.practiceResults[$0.id]?.needsReview == true }) && selections.isEmpty {
                Text("No mistakes to review in this lesson for your role.")
            }
            Button("Start a new round", systemImage: "arrow.clockwise") { selections = [:] }
                .disabled(selections.isEmpty)
        } header: { Text(L.text("Role practice") + " · " + library.learningRole.title) }
    }

    private func questionCard(_ question: DialogueQuestion, number: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L.format("QUESTION %lld", number)).font(.caption.bold()).foregroundStyle(ArchiveTheme.accent)
            DialogueBubble(isPilot: question.cue.from == "PILOT", message: question.cue.msg, hidden: false, reveal: {})
            Text("Which example comes next in this dialogue?").font(.headline)
            ForEach(question.options.indices, id: \.self) { option in
                Button {
                    let firstAnswer = selections[question.id] == nil
                    selections[question.id] = option
                    if firstAnswer { library.record(question, selected: option) }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Text(option == 0 ? "A" : "B").font(.headline)
                        Text(question.options[option]).lineSpacing(5).frame(maxWidth: .infinity, alignment: .leading)
                        if selections[question.id] == option { Image(systemName: "checkmark.circle.fill") }
                    }
                    .padding(16).foregroundStyle(ArchiveTheme.ink)
                    .background(selections[question.id] == option ? ArchiveTheme.sky : ArchiveTheme.card,
                                in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(ArchiveTheme.accent.opacity(0.25)))
                    .contentShape(Rectangle())
                }.buttonStyle(.plain)
                .accessibilityValue(L.text(selections[question.id] == option ? "Selected. Explanation shown below." : "Select to see this example’s explanation"))
                .accessibilityIdentifier("answer-\(number)-\(option)")
            }
            if let selected = selections[question.id] {
                VStack(alignment: .leading, spacing: 10) {
                    Label(L.text(selected == question.correctIndex ? "Correct — follows this dialogue" : "Incorrect — belongs to another turn"),
                          systemImage: selected == question.correctIndex ? "checkmark.circle" : "arrow.uturn.backward.circle")
                        .font(.headline)
                    Text(question.feedback(for: selected)).lineSpacing(5)
                    Text(L.format("Correct example: %@", question.correctIndex == 0 ? "A" : "B"))
                        .font(.subheadline.bold())
                }.padding(16).background(selected == question.correctIndex ? ArchiveTheme.mint : ArchiveTheme.sky, in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityIdentifier("feedback-\(number)")
            }
        }.padding(.vertical, 10)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var library: Library
    @Environment(\.dismiss) private var dismiss
    @State private var reset = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Your learning role") {
                    Picker("Practice as", selection: $library.learningRole) {
                        ForEach(LearningRole.allCases) { role in Text(role.title).tag(role) }
                    }.accessibilityIdentifier("learning-role")
                    Text("Choose your role. You can still read both sides of every dialogue.")
                        .font(.subheadline).foregroundStyle(ArchiveTheme.secondaryInk)
                }
                Section("Content updates") {
                    Text("Download published videos and lessons. Collection and generation run centrally.").font(.subheadline)
                    Button { Task { await library.sync() } } label: {
                        Label(L.text(library.syncing ? "Updating content…" : "Update content now"),
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
                    if let date = library.checked { Text(L.format("Last checked: %@", date.formatted())) }
                    if !library.message.isEmpty { Text(library.message).font(.subheadline) }
                }
                Section("Progress") {
                    let questions = library.activeQuestions
                    Text(L.format("%lld of %lld %@ questions attempted", questions.filter { library.practiceResults[$0.id] != nil }.count, questions.count, library.learningRole.responseTitle))
                    Text(L.format("%lld questions to review", questions.filter { library.practiceResults[$0.id]?.needsReview == true }.count))
                    Text(L.format("%lld of %lld lessons practiced", (library.catalog?.scenarios ?? []).filter { library.completed.contains($0.id) }.count, library.catalog?.scenarios.count ?? 0))
                    Button("Delete local data", role: .destructive) { reset = true }
                }
                Section("Privacy policy") {
                    Text(AppInformation.privacy)
                    Link("GitHub privacy statement", destination: URL(string: "https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement")!)
                }
                Section("About and support") {
                    Text("Created by a pilot for pilots and air traffic controllers to practice aviation English outside operational duties.")
                    Text(AppInformation.disclaimer)
                    Text("Independent learning aid. No affiliation with or endorsement by ICAO, FAA, Apple, airlines, or ATC authorities.")
                    Link("Support / report a content issue", destination: URL(string: "https://github.com/outinletter/maydayatc/issues")!)
                    Text(L.format("App version %@ (%@)", Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0", Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"))
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
