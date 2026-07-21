import Foundation

/// Parses `{date}`, `{time}`, `{clipboard}`, `{cursor}`, and `{fill:Label}`
/// tokens out of a snippet's expansion text.
struct SnippetTemplate {
    enum Token {
        case literal(String)
        case date
        case time
        case clipboard
        case cursor
        case fill(String)
    }

    let tokens: [Token]

    init(_ raw: String) {
        var tokens: [Token] = []
        var literal = ""
        var index = raw.startIndex

        while index < raw.endIndex {
            if raw[index] == "{", let closeIndex = raw[index...].firstIndex(of: "}") {
                let inner = String(raw[raw.index(after: index)..<closeIndex])
                if let token = SnippetTemplate.token(for: inner) {
                    if !literal.isEmpty {
                        tokens.append(.literal(literal))
                        literal = ""
                    }
                    tokens.append(token)
                    index = raw.index(after: closeIndex)
                    continue
                }
            }
            literal.append(raw[index])
            index = raw.index(after: index)
        }
        if !literal.isEmpty {
            tokens.append(.literal(literal))
        }
        self.tokens = tokens
    }

    private static func token(for inner: String) -> Token? {
        let trimmed = inner.trimmingCharacters(in: .whitespaces)
        switch trimmed.lowercased() {
        case "date": return .date
        case "time": return .time
        case "clipboard": return .clipboard
        case "cursor": return .cursor
        default:
            guard trimmed.lowercased().hasPrefix("fill:") else { return nil }
            let name = trimmed.dropFirst("fill:".count).trimmingCharacters(in: .whitespaces)
            return name.isEmpty ? nil : .fill(name)
        }
    }

    /// Distinct fill-in field names, in first-appearance order.
    var fillFieldNames: [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for token in tokens {
            if case .fill(let name) = token, !seen.contains(name) {
                seen.insert(name)
                ordered.append(name)
            }
        }
        return ordered
    }

    struct Rendered {
        let text: String
        /// Characters the caret should move left from the end, if `{cursor}` was used.
        let cursorOffsetFromEnd: Int?
    }

    func render(fillValues: [String: String], now: Date = Date(), clipboard: String?) -> Rendered {
        var output = ""
        var cursorPosition: Int?

        for token in tokens {
            switch token {
            case .literal(let text):
                output += text
            case .date:
                output += Self.dateFormatter.string(from: now)
            case .time:
                output += Self.timeFormatter.string(from: now)
            case .clipboard:
                output += clipboard ?? ""
            case .fill(let name):
                output += fillValues[name] ?? ""
            case .cursor:
                cursorPosition = output.count
            }
        }

        let cursorOffsetFromEnd = cursorPosition.map { output.count - $0 }
        return Rendered(text: output, cursorOffsetFromEnd: cursorOffsetFromEnd)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}
