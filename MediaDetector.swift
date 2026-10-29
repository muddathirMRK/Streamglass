import Foundation
import WebKit

final class MediaDetector {
    static let shared = MediaDetector()
    private init() {}

    func detect(in webView: WKWebView, completion: @escaping ([DetectedMedia]) -> Void) {
        let js = #"""
        (() => {
          const out=[]; const seen=new Set();
          function add(u,t,k){ if(!u||seen.has(u)||!/^https?:/i.test(u)) return; seen.add(u); out.push({url:u,title:t||document.title||'Detected video',kind:k||'Web media',isLive:/\.m3u8($|\?)/i.test(u)||/live|stream/i.test(u)}); }
          document.querySelectorAll('video').forEach((v,i)=>{add(v.currentSrc||v.src,'Video '+(i+1),'HTML5 video');v.querySelectorAll('source').forEach(s=>add(s.src,'Video '+(i+1),'HTML5 source'));});
          document.querySelectorAll('audio').forEach((a,i)=>add(a.currentSrc||a.src,'Audio '+(i+1),'HTML5 audio'));
          document.querySelectorAll('a[href]').forEach(a=>{if(/\.(m3u8|mp4|m4v|mov|webm)(\?|$)/i.test(a.href)) add(a.href,a.innerText.trim()||'Media link','Direct media');});
          return out;
        })();
        """
        webView.evaluateJavaScript(js) { result, _ in
            guard let rows = result as? [[String:Any]] else { completion([]); return }
            completion(rows.compactMap { row in
                guard let s=row["url"] as? String, let u=URL(string:s) else { return nil }
                return DetectedMedia(title: row["title"] as? String ?? "Detected video", url:u, kind:row["kind"] as? String ?? "Web media", isLive:row["isLive"] as? Bool ?? false)
            })
        }
    }
}
