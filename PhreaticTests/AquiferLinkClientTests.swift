import XCTest
@testable import Phreatic

final class AquiferLinkClientTests: XCTestCase {
    override func tearDown() {
        MockLinkProtocol.storage.handler = nil
        super.tearDown()
    }

    func test_decodesIndexAndAcceptsNumericStringYear() async throws {
        MockLinkProtocol.storage.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "User-Agent"), AquiferUserAgent.value)
            let body = Data("""
            {"sources":[{"title":"Water in diet","publisher":"NIH MedlinePlus","url":"https://medlineplus.gov/ency/article/002471.htm","year":"2023"}]}
            """.utf8)
            return (200, body)
        }
        let client = AquiferLinkClient(session: MockLinkProtocol.session())
        let url = try XCTUnwrap(URL(string: "https://phreatic-well.pro/sources.json"))
        let citations = try await client.loadCitationIndex(from: url)
        let cached = await client.cachedCitations(for: url)
        XCTAssertEqual(citations.count, 1)
        XCTAssertEqual(citations.first?.year, 2023)
        XCTAssertEqual(citations.first?.publisher, "NIH MedlinePlus")
        XCTAssertEqual(cached?.count, 1)
    }

    func test_notFoundIsNotRetried() async {
        let hits = HitCounter()
        MockLinkProtocol.storage.handler = { _ in
            hits.increment()
            return (404, Data())
        }
        let client = AquiferLinkClient(session: MockLinkProtocol.session())
        guard let url = URL(string: "https://phreatic-well.pro/missing.json") else {
            XCTFail("expected url")
            return
        }
        do {
            _ = try await client.loadCitationIndex(from: url)
            XCTFail("expected notFound")
        } catch let error as AquiferLinkError {
            XCTAssertEqual(error, .notFound)
        } catch {
            XCTFail("unexpected error")
        }
        XCTAssertEqual(hits.value, 1)
    }

    func test_transportRetriesOnceThenFails() async {
        let hits = HitCounter()
        MockLinkProtocol.storage.handler = { _ in
            hits.increment()
            throw URLError(.networkConnectionLost)
        }
        let client = AquiferLinkClient(session: MockLinkProtocol.session())
        guard let url = URL(string: "https://phreatic-well.pro/sources.json") else {
            XCTFail("expected url")
            return
        }
        do {
            _ = try await client.loadCitationIndex(from: url)
            XCTFail("expected transport")
        } catch let error as AquiferLinkError {
            XCTAssertEqual(error, .transport)
        } catch {
            XCTFail("unexpected error")
        }
        XCTAssertEqual(hits.value, 2)
    }

    func test_malformedJSONIsAHandledError() async {
        MockLinkProtocol.storage.handler = { _ in
            (200, Data("{\"sources\":[".utf8))
        }
        let client = AquiferLinkClient(session: MockLinkProtocol.session())
        guard let url = URL(string: "https://phreatic-well.pro/sources.json") else {
            XCTFail("expected url")
            return
        }
        do {
            _ = try await client.loadCitationIndex(from: url)
            XCTFail("expected decoding")
        } catch let error as AquiferLinkError {
            XCTAssertEqual(error, .decoding)
        } catch {
            XCTFail("unexpected error")
        }
    }

    func test_bundledCitationsExistWithoutNetwork() {
        XCTAssertGreaterThanOrEqual(HydrationCitation.bundled.count, 2)
        XCTAssertTrue(HydrationCitation.bundled.contains(where: { $0.publisher.contains("MedlinePlus") }))
    }
}

/// Test double. URLProtocol callbacks hop threads; cases assign the handler
/// on one thread and do not overlap.
final class MockLinkStorage: @unchecked Sendable {
    var handler: (@Sendable (URLRequest) throws -> (Int, Data))?
}

final class HitCounter: @unchecked Sendable {
    private var hits = 0
    func increment() {
        hits += 1
    }
    var value: Int { hits }
}

final class MockLinkProtocol: URLProtocol, @unchecked Sendable {
    static let storage = MockLinkStorage()

    static func session() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockLinkProtocol.self]
        configuration.timeoutIntervalForRequest = 15
        return URLSession(configuration: configuration)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.storage.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (status, data) = try handler(request)
            let response = HTTPURLResponse(
                url: request.url ?? URL(fileURLWithPath: "/"),
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )
            if let response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
