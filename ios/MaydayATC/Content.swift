import Foundation

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
    var url: URL { URL(string: "https://www.youtube.com/watch?v=" + id)! }
}

enum ContentError: LocalizedError {
    case invalid, response, rollback
    var errorDescription: String? {
        switch self {
        case .invalid: "The content file is invalid. Your existing lessons are unchanged."
        case .response: "GitHub is unavailable. Your downloaded lessons remain available offline."
        case .rollback: "An older content revision was ignored. Your lessons are unchanged."
        }
    }
}

enum AppInformation {
    static let disclaimer = "Fictional aviation English practice only. Not real ATC transcripts, operational instructions, emergency guidance, or an accredited ICAO course. Never use during flight operations. Follow approved training, aircraft procedures, and official ATC instructions."
    static let privacy = "Lessons, saved items, practice progress, and preferences stay on this device. No account, advertising, analytics, microphone, or location access is used. Automatic content checks send a normal HTTPS request to GitHub, which receives network information such as your IP address and may retain logs under its privacy policy. No bookmarks or practice history are sent. You can disable automatic checks in Settings; manual checks still contact GitHub. Opening video links uses YouTube and its privacy practices; no video is downloaded or embedded by this app. Opening support or GitHub privacy links uses your browser and those services’ policies. Reset local data in Settings to delete saved items, progress, and downloaded lessons. Device backups may retain app data until you delete those backups. Support is available through the repository’s GitHub Issues page; posting there requires a GitHub account and is public."
}
