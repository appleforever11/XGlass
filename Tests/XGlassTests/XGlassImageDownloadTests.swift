import XCTest
@testable import XGlass

final class XGlassImageDownloadTests: XCTestCase {
    func testCookiesRespectHostPathSecureAndExpiry() throws {
        func cookie(_ name: String, _ domain: String, _ path: String = "/", secure: Bool = false,
                    expires: Date = .distantFuture) -> HTTPCookie {
            var properties: [HTTPCookiePropertyKey: Any] = [
                .name: name, .value: "test", .domain: domain, .path: path, .expires: expires
            ]
            if secure { properties[.secure] = "TRUE" }
            return HTTPCookie(properties: properties)!
        }
        let cookies = [cookie("account", "x.com"), cookie("media", ".twimg.com"),
                       cookie("secure", ".twimg.com", secure: true),
                       cookie("private", ".twimg.com", "/private"),
                       cookie("expired", ".twimg.com", expires: .distantPast)]
        let media = URL(string: "https://pbs.twimg.com/media/image")!
        XCTAssertEqual(XGlassImageDownload.cookieHeader(for: media, cookies: cookies), "media=test; secure=test")
        XCTAssertEqual(XGlassImageDownload.cookieHeader(for: URL(string: "http://pbs.twimg.com/privately")!, cookies: cookies), "media=test")
        XCTAssertEqual(XGlassImageDownload.cookieHeader(for: URL(string: "https://eviltwimg.com/")!, cookies: cookies), "")
        XCTAssertEqual(XGlassImageDownload.cookieHeader(for: URL(string: "https://sub.x.com/")!, cookies: cookies), "")
    }

    func testInvalidDownloadPreservesExistingFileAndValidImageReplacesIt() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let source = directory.appendingPathComponent("download")
        let destination = directory.appendingPathComponent("photo.png")
        let original = Data("original".utf8)
        try original.write(to: destination)
        try Data("<html>Sign in</html>".utf8).write(to: source)
        XCTAssertThrowsError(try XGlassImageDownload.storeImage(at: source, to: destination))
        XCTAssertEqual(try Data(contentsOf: destination), original)
        let png = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aOuoAAAAASUVORK5CYII=")!
        try png.write(to: source)
        try XGlassImageDownload.storeImage(at: source, to: destination)
        XCTAssertEqual(try Data(contentsOf: destination), png)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted(), ["download", "photo.png"])
    }

    @MainActor
    func testXImageFormatQueryDeterminesExtension() {
        XCTAssertTrue(XImageSaveCoordinator.defaultFilename(for: URL(string: "https://pbs.twimg.com/media/abc?format=png&name=orig")!).hasSuffix(".png"))
        XCTAssertTrue(XImageSaveCoordinator.defaultFilename(for: URL(string: "https://pbs.twimg.com/media/abc?format=html")!).hasSuffix(".jpg"))
        XCTAssertTrue(XImageSaveCoordinator.defaultFilename(for: URL(string: "https://pbs.twimg.com/image.webp")!).hasSuffix(".webp"))
    }
}
