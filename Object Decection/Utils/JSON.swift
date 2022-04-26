import Foundation

class JSON {
    static func convertStringToJSON<T>(_ type: T.Type, from: String) throws -> T where T : Decodable {
        let json = try? JSONDecoder().decode(type, from: from.data(using: .utf8)!)
        return json!
    }
}
