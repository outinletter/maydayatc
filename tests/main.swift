import Foundation
let raw = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
let catalog = try Catalog.decode(raw)
precondition(catalog.scenarios.count == 10 && catalog.references.count == 26)
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
print("PASS: bundled decode, 10 lessons, 26 references, schema, duplicate, empty, and size rejection")
