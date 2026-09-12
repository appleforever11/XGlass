import Foundation
import ImageIO

/// A download uses only cookies belonging to its destination, including redirects.
final class XGlassImageDownload: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let cookies: [HTTPCookie]
    private let progress: @Sendable (Int) -> Void
    private var reportedPercent = -1
    init(cookies: [HTTPCookie], progress: @escaping @Sendable (Int) -> Void = { _ in }) {
        self.cookies = cookies
        self.progress = progress
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let percent = Int(min(100, Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100))
        if percent >= reportedPercent + 5 { reportedPercent = percent; progress(percent) }
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {}


    static func cookieHeader(for url: URL, cookies: [HTTPCookie], now: Date = Date()) -> String {
        let host = url.host?.lowercased() ?? ""
        let path = url.path.isEmpty ? "/" : url.path
        return cookies.filter { cookie in
            let domain = cookie.domain.lowercased()
            let bare = domain.hasPrefix(".") ? String(domain.dropFirst()) : domain
            let matchesHost = host == bare || (domain.hasPrefix(".") && host.hasSuffix("." + bare))
            let matchesPath = path == cookie.path || (path.hasPrefix(cookie.path) &&
                (cookie.path.hasSuffix("/") || path.dropFirst(cookie.path.count).hasPrefix("/")))
            return matchesHost && matchesPath && (!cookie.isSecure || url.scheme == "https") &&
                (cookie.expiresDate.map { $0 > now } ?? true)
        }.sorted { $0.path.count > $1.path.count }
            .map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        guard let url = request.url, url.scheme == "https" else { completionHandler(nil); return }
        var next = request
        next.setValue(Self.cookieHeader(for: url, cookies: cookies), forHTTPHeaderField: "Cookie")
        next.setValue(nil, forHTTPHeaderField: "Referer")
        completionHandler(next)
    }

    static func storeImage(at temporary: URL, to destination: URL) throws {
        guard let source = CGImageSourceCreateWithURL(temporary as CFURL, nil),
              CGImageSourceGetCount(source) > 0 else { throw URLError(.cannotDecodeContentData) }
        // Stage beside the approved destination so replacing an existing file is atomic.
        let staging = destination.deletingLastPathComponent().appendingPathComponent(".xglass-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: staging) }
        try FileManager.default.copyItem(at: temporary, to: staging)
        if FileManager.default.fileExists(atPath: destination.path) {
            _ = try FileManager.default.replaceItemAt(destination, withItemAt: staging)
        } else {
            try FileManager.default.moveItem(at: staging, to: destination)
        }
    }

    func save(_ url: URL, to destination: URL, userAgent: String?,
              completion: @escaping @Sendable (Result<Void, Error>) -> Void) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.httpCookieStorage = nil
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        var request = URLRequest(url: url)
        request.setValue(Self.cookieHeader(for: url, cookies: cookies), forHTTPHeaderField: "Cookie")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        session.downloadTask(with: request) { temporary, response, error in
            defer { session.finishTasksAndInvalidate() }
            do {
                if let error { throw error }
                guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode),
                      let temporary else { throw URLError(.badServerResponse) }
                try Self.storeImage(at: temporary, to: destination)
                completion(.success(()))
            } catch { completion(.failure(error)) }
        }.resume()
    }
}
