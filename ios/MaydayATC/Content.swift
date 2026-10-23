import Foundation

enum L {
    static func text(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }
    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: text(key), locale: Locale.current, arguments: arguments)
    }
}

struct PracticeBlock: Identifiable, Equatable {
    enum Kind: Equatable {
        case step, pilot, controller, original, corrected, explanation, alternative, paragraph
    }
    let id: Int
    let kind: Kind
    var text: String
    var displayText: String { L.text(text) }

    static func parse(_ text: String) -> [PracticeBlock] {
        var blocks: [PracticeBlock] = []
        var continuing = false
        let prefixes: [(String, Kind)] = [
            ("PILOT:", .pilot), ("ATC:", .controller), ("CONTROLLER:", .controller),
            ("ORIGINAL:", .original), ("CORRECTED:", .corrected),
            ("EXPLANATION:", .explanation), ("ALTERNATIVE:", .alternative)
        ]
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "^#{1,6}\\s+", with: "", options: .regularExpression)
            guard !line.isEmpty else { continuing = false; continue }
            if line.uppercased().hasPrefix("STEP ") {
                blocks.append(PracticeBlock(id: blocks.count, kind: .step, text: line))
                continuing = false
            } else if let (prefix, kind) = prefixes.first(where: { line.uppercased().hasPrefix($0.0) }) {
                blocks.append(PracticeBlock(id: blocks.count, kind: kind,
                    text: String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)))
                continuing = true
            } else if continuing, !blocks.isEmpty {
                blocks[blocks.count - 1].text += " " + line
            } else {
                blocks.append(PracticeBlock(id: blocks.count, kind: .paragraph, text: line))
            }
        }
        return blocks
    }
}

struct Exchange: Codable, Hashable {
    let from: String
    let msg: String
}

struct Scenario: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let pilotRoles: [String]
    let atcRoles: [String]
    let dialogue: [Exchange]
    let practice: String
    var displayTitle: String {
        let parts = title.components(separatedBy: " · ")
        if parts.count == 2, parts[1].hasPrefix("Training ") {
            return L.text(parts[0]) + " · " + L.format("Training %@", String(parts[1].dropFirst(9)))
        }
        return L.text(title)
    }
    var displaySummary: String { L.text(summary) }
    var shareText: String {
        let body = PracticeBlock.parse(practice).map { block -> String in
            let label: String
            switch block.kind {
            case .pilot: label = L.text("Pilot")
            case .controller: label = L.text("Controller")
            case .original: label = L.text("Original phrase")
            case .corrected: label = L.text("Revised phrase")
            case .explanation: label = L.text("Why this wording")
            case .alternative: label = L.text("Alternative expression")
            default: return block.displayText
            }
            return label + ": " + block.displayText
        }.joined(separator: "\n\n")
        return "Mayday ATC — " + L.text("Fictional English practice") + "\n" + displayTitle
            + "\n\n" + body + "\n\n" + AppInformation.disclaimer
    }
}

enum LearningRole: String, CaseIterable, Identifiable {
    case pilot, controller
    var id: String { rawValue }
    var title: String { NSLocalizedString(self == .pilot ? "Pilot" : "Controller", comment: "Learning role") }
    var responseTitle: String { L.text(rawValue) }
    var speaker: String { self == .pilot ? "PILOT" : "ATC" }
}

/// Reading comprehension of the supplied fictional exchange, not a judgement
/// about the operational suitability of a clearance or response.
struct DialogueQuestion: Identifiable {
    let id: String
    let cue: Exchange
    let options: [String]
    let correctIndex: Int
    let explanation: String

    func feedback(for selected: Int) -> String {
        guard options.indices.contains(selected) else { return L.text("Choose an example to read its explanation.") }
        if selected == correctIndex {
            return L.text("This example is the next response in the supplied dialogue.")
                + "\n\n" + L.text("Preceding message") + ": " + cue.msg
                + "\n\n" + L.text("Next response") + ": " + options[selected]
                + "\n\n" + L.text("This checks reading comprehension, not operational suitability.")
        }
        return L.text("This example belongs to a different turn of the dialogue.")
            + "\n\n" + L.text("Selected example") + ": " + options[selected]
            + "\n\n" + L.text("The dialogue instead continues with") + ": " + options[correctIndex]
            + "\n\n" + L.text("Compare the preceding message, then select the other example to read its explanation.")
    }

    static func make(scenario: Scenario, role: LearningRole) -> [DialogueQuestion] {
        scenario.dialogue.indices.compactMap { index in
            guard index > 0, scenario.dialogue[index].from == role.speaker,
                  scenario.dialogue[index - 1].from != role.speaker else { return nil }
            let answer = scenario.dialogue[index].msg
            // Distractors come from another turn by the same speaker in this
            // lesson. They are not fabricated aviation instructions.
            guard let other = scenario.dialogue.indices.first(where: {
                $0 != index && scenario.dialogue[$0].from == role.speaker && scenario.dialogue[$0].msg != answer
            }) else { return nil }
            let correctIndex = (index / 2) % 2
            var options = [scenario.dialogue[other].msg, scenario.dialogue[other].msg]
            options[correctIndex] = answer
            let cue = scenario.dialogue[index - 1]
            return DialogueQuestion(
                id: scenario.id + "|" + role.rawValue + "|" + cue.msg + "|" + answer,
                cue: cue, options: options, correctIndex: correctIndex,
                explanation: "In this fictional dialogue, the next \(role.title.lowercased()) message is: \(answer)\n\nThe other example belongs to a different turn. Compare the request, acknowledgement and information in the preceding message. This checks the lesson sequence, not operational correctness."
            )
        }
    }
}

struct PracticeResult: Codable {
    var attempts: Int
    var correct: Int
    var needsReview: Bool
}

struct Catalog: Codable {
    let schemaVersion: Int
    let revision: Int
    let scenarios: [Scenario]
    let references: [VideoReference]

    static func decode(_ data: Data) throws -> Catalog {
        guard data.count <= 1_000_000 else { throw ContentError.invalid }
        let value = try JSONDecoder().decode(Catalog.self, from: data)
        func valid(_ s: String, _ max: Int) -> Bool {
            !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && s.count <= max
        }
        guard value.schemaVersion == 1, value.revision > 0,
              (1...100).contains(value.scenarios.count),
              Set(value.scenarios.map(\.id)).count == value.scenarios.count,
              value.references.count <= 100,
              Set(value.references.map(\.id)).count == value.references.count,
              value.references.allSatisfy({ v in
                  v.id.range(of: "^[A-Za-z0-9_-]{11}$", options: .regularExpression) != nil
                  && valid(v.title, 200) && valid(v.channel, 120)
                  && value.scenarios.contains { $0.id == v.category }
                  && (v.lessonId == nil || value.scenarios.contains { $0.id == v.lessonId })
              }),
              value.scenarios.allSatisfy({ s in
                  valid(s.id, 64) && s.id.range(of: "^[a-z0-9-]+$", options: .regularExpression) != nil
                  && valid(s.title, 120) && valid(s.summary, 4000) && valid(s.practice, 12000)
                  && (1...20).contains(s.pilotRoles.count) && s.pilotRoles.allSatisfy { valid($0, 1000) }
                  && (1...20).contains(s.atcRoles.count) && s.atcRoles.allSatisfy { valid($0, 1000) }
                  && (2...40).contains(s.dialogue.count)
                  && s.dialogue.allSatisfy { ["PILOT", "ATC"].contains($0.from) && valid($0.msg, 2000) }
              }) else { throw ContentError.invalid }
        return value
    }
}

struct VideoReference: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let channel: String
    let category: String
    let lessonId: String?
    var url: URL { URL(string: "https://www.youtube.com/watch?v=" + id)! }
}

enum ContentError: LocalizedError {
    case invalid, response, rollback
    var errorDescription: String? {
        switch self {
        case .invalid: L.text("The content file is invalid. Your existing lessons are unchanged.")
        case .response: L.text("GitHub is unavailable. Your downloaded lessons remain available offline.")
        case .rollback: L.text("An older content revision was ignored. Your lessons are unchanged.")
        }
    }
}

enum AppInformation {
    static let disclaimer = L.text("Fictional aviation English practice only. Not real ATC transcripts, operational instructions, emergency guidance, or an accredited ICAO course. Never use during flight operations. Follow approved training, aircraft procedures, and official ATC instructions.")
    static let privacy = L.text("Lessons, saved items, practice progress, and preferences stay on this device. No account, advertising, analytics, microphone, or location access is used. Manual content updates send a normal HTTPS request to GitHub, which receives network information such as your IP address and may retain logs under its privacy policy. No bookmarks or practice history are sent. Content is requested only when you tap Update content or pull to refresh. Opening video links uses YouTube and its privacy practices; no video is downloaded or embedded by this app. Opening support or GitHub privacy links uses your browser and those services’ policies. Reset local data in Settings to delete saved items, progress, and downloaded lessons. Device backups may retain app data until you delete those backups. Support is available through the repository’s GitHub Issues page; posting there requires a GitHub account and is public.")
}
