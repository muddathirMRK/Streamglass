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
        let c=WKWebViewConfiguration()
        c.allowsInlineMediaPlayback=true
        c.allowsAirPlayForMediaPlayback=true
        c.allowsPictureInPictureMediaPlayback=true
        c.mediaTypesRequiringUserActionForPlayback=[]
        let w=WKWebView(frame:.zero,configuration:c)
        w.allowsBackForwardNavigationGestures=true
        coordinator.onURLChange={ u in DispatchQueue.main.async{url=u} }
        coordinator.onLoadingChange={ x in DispatchQueue.main.async{isLoading=x} }
        coordinator.onPopupBlocked={ DispatchQueue.main.async{blockedPopups += 1} }
        coordinator.configure(w)
        DispatchQueue.main.async{webView=w; w.load(URLRequest(url: URL(string:"https://www.example.com")!))}
        return w
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
