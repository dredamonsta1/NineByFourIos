import Testing

/// Every suite that uses StubURLProtocol nests in here. The stub server is
/// one shared, static table, and Swift Testing runs separate suites in
/// parallel: two suites stubbing and resetting it at once wipe each other's
/// responses. `.serialized` on this parent runs all of them one at a time.
@MainActor
@Suite(.serialized)
enum StubServerSuites {}
