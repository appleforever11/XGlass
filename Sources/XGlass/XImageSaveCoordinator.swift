import AppKit
import WebKit

@MainActor
final class XImageSaveCoordinator: NSObject, WKDownloadDelegate {
    var statusHandler: ((String) -> Void)?

    private weak var webView: WKWebView?

    func attach(to webView: XGlassWebView) {
        self.webView = webView
        webView.saveImageHandler = { [weak self, weak webView] location in
            guard let self, let webView else { return }
            self.saveImage(at: location, in: webView)
        }
    }

    func useAsDelegate(for download: WKDownload, from webView: WKWebView) {
        self.webView = webView
        download.delegate = self
    }

    static func defaultFilename(
        for imageURL: URL,
        now: Date = Date(),
        uuid: UUID = UUID()
    ) -> String {
        let fileExtension = imageURL.pathExtension.isEmpty
            ? "jpg"
            : imageURL.pathExtension.lowercased()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss-SSS"
        let timestamp = formatter.string(from: now)
        let uniqueSuffix = String(uuid.uuidString.prefix(8)).lowercased()
        return "XGlass Image \(timestamp)-\(uniqueSuffix).\(fileExtension)"
    }

    private func saveImage(at location: NSPoint, in webView: XGlassWebView) {
        if let imageURL = webView.contextImageURL,
           ["http", "https"].contains(imageURL.scheme?.lowercased()) {
            presentSavePanel(for: imageURL, in: webView)
            return
        }

        let viewportX = max(0, location.x)
        let viewportY = max(0, webView.bounds.height - location.y)
        let script = """
        (() => {
          const node = document.elementFromPoint(\(viewportX), \(viewportY));
          const image = node?.closest?.('img') || (node?.tagName === 'IMG' ? node : null);
          return image?.currentSrc || image?.src || null;
        })();
        """

        webView.evaluateJavaScript(script) { [weak self, weak webView] result, error in
            Task { @MainActor in
                guard let self, let webView else { return }
                guard error == nil,
                      let urlString = result as? String,
                      let imageURL = URL(string: urlString),
                      ["http", "https"].contains(imageURL.scheme?.lowercased()) else {
                    self.statusHandler?("XGlass could not find an image at that location.")
                    return
                }

                self.presentSavePanel(for: imageURL, in: webView)
            }
        }
    }

    private func presentSavePanel(for imageURL: URL, in webView: XGlassWebView) {
        let panel = NSSavePanel()
        panel.title = "Save Image"
        panel.prompt = "Save"
        panel.canCreateDirectories = true
        panel.directoryURL = FileManager.default.urls(
            for: .downloadsDirectory,
            in: .userDomainMask
        ).first
        panel.nameFieldStringValue = Self.defaultFilename(for: imageURL)

        let save: (NSApplication.ModalResponse) -> Void = { [weak self, weak webView] response in
            guard response == .OK, let destinationURL = panel.url, let webView else { return }
            self?.fetchImage(imageURL, to: destinationURL, using: webView)
        }

        guard let window = webView.window else {
            save(panel.runModal())
            return
        }

        panel.beginSheetModal(for: window, completionHandler: save)
    }

    private func fetchImage(_ imageURL: URL, to destinationURL: URL, using webView: XGlassWebView) {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        let referer = webView.url?.absoluteString ?? XRoute.home.url.absoluteString
        let userAgent = webView.customUserAgent

        cookieStore.getAllCookies { [weak self] cookies in
            var request = URLRequest(url: imageURL)
            request.setValue(referer, forHTTPHeaderField: "Referer")
            if let userAgent {
                request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            }
            let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
            if !cookieHeader.isEmpty {
                request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
            }

            URLSession.shared.dataTask(with: request) { data, response, error in
                let result: Result<Void, Error>
                if let error {
                    result = .failure(error)
                } else if let httpResponse = response as? HTTPURLResponse,
                          !(200..<300).contains(httpResponse.statusCode) {
                    result = .failure(URLError(.badServerResponse))
                } else if let data {
                    do {
                        try data.write(to: destinationURL, options: .atomic)
                        result = .success(())
                    } catch {
                        result = .failure(error)
                    }
                } else {
                    result = .failure(URLError(.zeroByteResource))
                }

                let message: String
                switch result {
                case .success:
                    message = "Image saved to \(destinationURL.lastPathComponent)."
                case .failure(let error):
                    message = "XGlass could not save the image: \(error.localizedDescription)"
                }
                Task { @MainActor in
                    self?.statusHandler?(message)
                }
            }.resume()
        }
    }

    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping @MainActor @Sendable (URL?) -> Void
    ) {
        let isImage = response.mimeType?.hasPrefix("image/") == true
        let suggestedURL = URL(fileURLWithPath: suggestedFilename)
        let fallbackURL = response.url ?? suggestedURL
        let filename: String
        if isImage {
            filename = Self.defaultFilename(for: fallbackURL)
        } else {
            filename = suggestedFilename.isEmpty ? "XGlass Download" : suggestedFilename
        }

        let panel = NSSavePanel()
        panel.title = isImage ? "Save Image" : "Save Download"
        panel.prompt = "Save"
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = filename
        panel.directoryURL = FileManager.default.urls(
            for: .downloadsDirectory,
            in: .userDomainMask
        ).first

        guard let window = webView?.window else {
            completionHandler(panel.runModal() == .OK ? panel.url : nil)
            return
        }

        panel.beginSheetModal(for: window) { response in
            completionHandler(response == .OK ? panel.url : nil)
        }
    }
}
