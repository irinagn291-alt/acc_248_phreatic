import Foundation

/// Optional citation-index fetch. This product has no remote catalog; the
/// bundled sources keep Settings honest when the network is down.
enum AquiferLinkError: Error, Equatable, Sendable {
    case notFound
    case transport
    case decoding
    case cancelled
}

enum AquiferUserAgent {
    static let value = "Phreatic/1.0 (iOS; +https://phreatic-well.pro)"
}

actor AquiferLinkClient {
    private let session: URLSession
    private var cache: [URL: [HydrationCitation]]
    private var inFlight: Task<[HydrationCitation], Error>?
    private var inFlightURL: URL?

    init(session: URLSession) {
        self.session = session
        self.cache = [:]
    }

    static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        configuration.httpAdditionalHeaders = ["User-Agent": AquiferUserAgent.value]
        return URLSession(configuration: configuration)
    }

    func cachedCitations(for url: URL) -> [HydrationCitation]? {
        cache[url]
    }

    func cancelInFlight() {
        inFlight?.cancel()
        inFlight = nil
        inFlightURL = nil
    }

    func loadCitationIndex(from url: URL) async throws -> [HydrationCitation] {
        if inFlightURL != url {
            inFlight?.cancel()
            inFlight = nil
        }
        if let existing = inFlight, inFlightURL == url {
            return try await existing.value
        }
        let task = Task { [session] in
            try await Self.fetchIndex(from: url, session: session)
        }
        inFlight = task
        inFlightURL = url
        do {
            let citations = try await task.value
            cache[url] = citations
            inFlight = nil
            inFlightURL = nil
            return citations
        } catch is CancellationError {
            inFlight = nil
            inFlightURL = nil
            throw AquiferLinkError.cancelled
        } catch let error as AquiferLinkError {
            inFlight = nil
            inFlightURL = nil
            throw error
        } catch {
            inFlight = nil
            inFlightURL = nil
            throw AquiferLinkError.transport
        }
    }

    private static func fetchIndex(
        from url: URL,
        session: URLSession
    ) async throws -> [HydrationCitation] {
        try Task.checkCancellation()
        do {
            return try await perform(url: url, session: session)
        } catch AquiferLinkError.notFound {
            throw AquiferLinkError.notFound
        } catch AquiferLinkError.decoding {
            throw AquiferLinkError.decoding
        } catch is CancellationError {
            throw AquiferLinkError.cancelled
        } catch {
            try Task.checkCancellation()
            do {
                return try await perform(url: url, session: session)
            } catch AquiferLinkError.notFound {
                throw AquiferLinkError.notFound
            } catch AquiferLinkError.decoding {
                throw AquiferLinkError.decoding
            } catch is CancellationError {
                throw AquiferLinkError.cancelled
            } catch {
                throw AquiferLinkError.transport
            }
        }
    }

    private static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }

    private static func perform(
        url: URL,
        session: URLSession
    ) async throws -> [HydrationCitation] {
        var request = URLRequest(url: url)
        request.setValue(AquiferUserAgent.value, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw AquiferLinkError.cancelled
        } catch let error as URLError where error.code == .cancelled {
            throw AquiferLinkError.cancelled
        } catch {
            throw AquiferLinkError.transport
        }
        guard let http = response as? HTTPURLResponse else {
            throw AquiferLinkError.transport
        }
        if http.statusCode == 404 {
            throw AquiferLinkError.notFound
        }
        guard (200..<300).contains(http.statusCode) else {
            throw AquiferLinkError.transport
        }
        let dto: CitationIndexDTO
        do {
            dto = try makeDecoder().decode(CitationIndexDTO.self, from: data)
        } catch {
            throw AquiferLinkError.decoding
        }
        return dto.sources.compactMap { $0.mapped() }
    }
}
