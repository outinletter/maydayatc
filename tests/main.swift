import Foundation
let raw = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
let catalog = try Catalog.decode(raw)
precondition(catalog.scenarios.count >= 10 && !catalog.references.isEmpty)
var object = try JSONSerialization.jsonObject(with: raw) as! [String: Any]
func rejects(_ value: [String: Any]) throws {
    let data = try JSONSerialization.data(withJSONObject: value)
    do { _ = try Catalog.decode(data); fatalError("Accepted invalid catalog") }
    catch { }
}
object["schemaVersion"] = 2
try rejects(object)
object["schemaVersion"] = 1
var scenarios = object["scenarios"] as! [[String: Any]]
scenarios[1]["id"] = scenarios[0]["id"]
object["scenarios"] = scenarios
try rejects(object)
object["scenarios"] = []
try rejects(object)
do { _ = try Catalog.decode(Data(repeating: 0, count: 1_000_001)); fatalError("Accepted oversized catalog") } catch {}
print("PASS: bundled decode, bundled lessons and references, schema, duplicate, empty, and size rejection")
let sample = """
STEP 1: Conversation
    PILOT: First pilot message.
    A continued sentence.
    ATC: Controller response.

STEP 2: Corrections
Original: Old phrase
Corrected: Revised phrase
Explanation: Reason
"""
let blocks = PracticeBlock.parse(sample)
precondition(blocks.map(\.kind) == [.step, .pilot, .controller, .step, .original, .corrected, .explanation])
precondition(blocks[1].text == "First pilot message. A continued sentence.")
precondition(blocks[2].text == "Controller response.")
for scenario in catalog.scenarios {
    let parsed = PracticeBlock.parse(scenario.practice)
    let lines = scenario.practice.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces).uppercased() }
    precondition(parsed.filter { $0.kind == .pilot }.count == lines.filter { $0.hasPrefix("PILOT:") }.count)
    precondition(parsed.filter { $0.kind == .controller }.count == lines.filter { $0.hasPrefix("ATC:") }.count)
    precondition(parsed.filter { $0.kind == .step }.count == 3)
}
print("PASS: speaker boundaries, multiline messages, step/correction groups in all scenarios")
