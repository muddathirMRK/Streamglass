import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    @Binding var url: URL?
    @Binding var webView: WKWebView?
    @Binding var isLoading: Bool
    @Binding var blockedPopups: Int
    let coordinator: BrowserCoordinator

    func makeCoordinator() -> BrowserCoordinator { coordinator }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let view = WKWebView(frame: .zero, configuration: configuration)
        view.allowsBackForwardNavigationGestures = true

        coordinator.onURLChange = { newURL in DispatchQueue.main.async { url = newURL } }
        coordinator.onLoadingChange = { loading in DispatchQueue.main.async { isLoading = loading } }
        coordinator.onPopupBlocked = { DispatchQueue.main.async { blockedPopups += 1 } }
        coordinator.configure(view)

        let start = URL(string: "https://duckduckgo.com/")!
        DispatchQueue.main.async {
            webView = view
            url = start
            view.load(URLRequest(url: start))
        }
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
