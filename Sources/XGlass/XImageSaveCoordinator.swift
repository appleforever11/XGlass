import AppKit
import WebKit

@MainActor
final class XImageSaveCoordinator: NSObject, WKDownloadDelegate {
    var progressHandler: ((String?) -> Void)?
    private var activeDownloads: [UUID: String] = [:]

    private func publishProgress() {
        progressHandler?(activeDownloads.isEmpty ? nil : activeDownloads.count == 1 ? activeDownloads.values.first : "Saving \(activeDownloads.count) images…")
    }

    var statusHandler: ((String) -> Void)?

    private weak var webView: WKWebView?
    private var imageDownloadDestinations: [ObjectIdentifier: URL] = [:]
    private static let imageDirectoryKey = "XGlass.lastImageSaveDirectory"

    private var imageSaveDirectory: URL? {
        let files = FileManager.default
        let remembered = UserDefaults.standard.string(forKey: Self.imageDirectoryKey)
            .map { URL(fileURLWithPath: $0, isDirectory: true) }
        let photos = files.urls(for: .desktopDirectory, in: .userDomainMask).first?
            .appendingPathComponent("X photos", isDirectory: true)
        let downloads = files.urls(for: .downloadsDirectory, in: .userDomainMask).first
        return [remembered, photos, downloads].compactMap { $0 }.first { url in
            var isDirectory: ObjCBool = false
            return files.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
        }
    }

    private func rememberImageDirectory(for destination: URL) {
        UserDefaults.standard.set(destination.deletingLastPathComponent().path, forKey: Self.imageDirectoryKey)
    }

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
        let queryFormat = URLComponents(url: imageURL, resolvingAgainstBaseURL: false)?
            .queryItems?.first { $0.name == "format" }?.value?.lowercased()
        let supported = ["jpg", "jpeg", "png", "gif", "webp", "heic", "avif", "tiff"]
        let candidate = queryFormat ?? imageURL.pathExtension.lowercased()
        let fileExtension = supported.contains(candidate) ? candidate : "jpg"
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
        panel.directoryURL = imageSaveDirectory
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
        let userAgent = webView.customUserAgent
        let downloadID = UUID()
        activeDownloads[downloadID] = "Saving image…"
        publishProgress()
        cookieStore.getAllCookies { [weak self] cookies in
            XGlassImageDownload(cookies: cookies, progress: { percent in
                Task { @MainActor in
                    guard self?.activeDownloads[downloadID] != nil else { return }
                    self?.activeDownloads[downloadID] = "Saving image: \(percent)%"
                    self?.publishProgress()
                }
            }).save(imageURL, to: destinationURL, userAgent: userAgent) { result in
                Task { @MainActor in
                    self?.activeDownloads.removeValue(forKey: downloadID)
                    self?.publishProgress()
                    switch result {
                    case .success:
                        self?.rememberImageDirectory(for: destinationURL)
                        self?.statusHandler?("Image saved to \(destinationURL.lastPathComponent).")
                    case .failure(let error):
                        self?.statusHandler?("XGlass could not save the image: \(error.localizedDescription)")
                    }
                }
            }
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
        panel.directoryURL = isImage ? imageSaveDirectory : FileManager.default.urls(
            for: .downloadsDirectory, in: .userDomainMask
        ).first

        let finish: @MainActor (NSApplication.ModalResponse) -> Void = { [weak self] response in
            let destination = response == .OK ? panel.url : nil
            if isImage, let destination {
                self?.imageDownloadDestinations[ObjectIdentifier(download)] = destination
            }
            completionHandler(destination)
        }
        guard let window = webView?.window else {
            finish(panel.runModal())
            return
        }
        panel.beginSheetModal(for: window, completionHandler: finish)
    }

    func downloadDidFinish(_ download: WKDownload) {
        if let destination = imageDownloadDestinations.removeValue(forKey: ObjectIdentifier(download)) {
            rememberImageDirectory(for: destination)
        }
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        imageDownloadDestinations.removeValue(forKey: ObjectIdentifier(download))
    }
}
