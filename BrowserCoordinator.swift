import Foundation
import WebKit

@MainActor
final class BrowserCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    var onURLChange: ((URL?) -> Void)?
    var onLoadingChange: ((Bool) -> Void)?
    var onPopupBlocked: (() -> Void)?

    func configure(_ webView: WKWebView) {
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        onLoadingChange?(true)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onLoadingChange?(false)
        onURLChange?(webView.url)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onLoadingChange?(false)
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if action.targetFrame == nil {
            onPopupBlocked?()
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        onPopupBlocked?()
        return nil
    }
}
