import Foundation

/// A tappable 1.4.1 source for the 33 ml per kilogram figure. Bundled so the
/// product works with no remote catalog. The link client may refresh an index.
struct HydrationCitation: Identifiable, Hashable, Sendable, Equatable {
    let id: String
    let title: String
    let publisher: String
    let url: URL
    let year: Int?

    static let bundled: [HydrationCitation] = makeBundled()

    private static func makeBundled() -> [HydrationCitation] {
        let rows: [(String, String, String, String, Int)] = [
            ("medlineplus-water", "Water in diet", "NIH MedlinePlus", "https://medlineplus.gov/ency/article/002471.htm", 2023),
            ("nap-dri-water", "Dietary Reference Intakes for Water", "National Academies Press", "https://www.ncbi.nlm.nih.gov/books/NBK56068/", 2005),
        ]
        return rows.compactMap { id, title, publisher, raw, year in
            guard let url = URL(string: raw) else { return nil }
            return HydrationCitation(id: id, title: title, publisher: publisher, url: url, year: year)
        }
    }
}

/// JSON shape for an optional citation index. Mirrors the payload exactly.
struct CitationIndexDTO: Decodable, Sendable, Equatable {
    let sources: [CitationDTO]
}

struct CitationDTO: Decodable, Sendable, Equatable {
    let title: String
    let publisher: String
    let url: String
    let year: Int?

    enum CodingKeys: String, CodingKey {
        case title
        case publisher
        case url
        case year
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        publisher = try container.decode(String.self, forKey: .publisher)
        url = try container.decode(String.self, forKey: .url)
        year = try Self.decodeFlexibleInt(container, forKey: .year)
    }

    init(title: String, publisher: String, url: String, year: Int?) {
        self.title = title
        self.publisher = publisher
        self.url = url
        self.year = year
    }

    private static func decodeFlexibleInt(
        _ container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Int? {
        if container.contains(key) == false {
            return nil
        }
        if try container.decodeNil(forKey: key) {
            return nil
        }
        if let number = try? container.decode(Int.self, forKey: key) {
            return number
        }
        if let number = try? container.decode(Double.self, forKey: key) {
            return Int(number)
        }
        if let text = try? container.decode(String.self, forKey: key) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return nil }
            return Int(trimmed)
        }
        return nil
    }

    func mapped() -> HydrationCitation? {
        guard let parsed = URL(string: url) else { return nil }
        return HydrationCitation(
            id: parsed.absoluteString,
            title: title,
            publisher: publisher,
            url: parsed,
            year: year
        )
    }
}
