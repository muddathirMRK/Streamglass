import Foundation
import WebKit

final class MediaDetector {
    static let shared = MediaDetector()
    private init() {}

    func detect(in webView: WKWebView, completion: @escaping ([DetectedMedia]) -> Void) {
        let javascript = #"""
        (() => {
          const out = [];
          const seen = new Set();
          function add(raw, title, kind) {
            if (!raw) return;
            let u = raw;
            try { u = new URL(raw, location.href).href; } catch (_) { return; }
            if (!/^https?:/i.test(u) || seen.has(u)) return;
            seen.add(u);
            const live = /\.m3u8(?:$|\?)/i.test(u) || /live|stream/i.test(u);
            out.push({url:u,title:title||document.title||"Detected video",kind:kind||"Web media",isLive:live});
          }
          document.querySelectorAll("video").forEach((v,i)=>{
            add(v.currentSrc||v.src,"Video "+(i+1),"HTML5 video");
            v.querySelectorAll("source").forEach(s=>add(s.src,"Video "+(i+1),"HTML5 source"));
          });
          document.querySelectorAll("audio").forEach((a,i)=>add(a.currentSrc||a.src,"Audio "+(i+1),"HTML5 audio"));
          document.querySelectorAll("a[href]").forEach(a=>{
            if (/\.(m3u8|mp4|m4v|mov|webm)(?:\?|$)/i.test(a.href)) add(a.href,(a.innerText||"").trim()||"Media link","Direct media");
          });
          return out;
        })();
        """#

        webView.evaluateJavaScript(javascript) { result, _ in
            guard let rows = result as? [[String: Any]] else { completion([]); return }
            completion(rows.compactMap { row in
                guard let stringURL = row["url"] as? String, let url = URL(string: stringURL) else { return nil }
                return DetectedMedia(
                    title: row["title"] as? String ?? "Detected video",
                    url: url,
                    kind: row["kind"] as? String ?? "Web media",
                    isLive: row["isLive"] as? Bool ?? false
                )
            })
        }
    }
}
