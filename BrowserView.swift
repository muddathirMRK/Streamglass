import SwiftUI
import WebKit

struct BrowserView: View {
    @State private var address=""
    @State private var currentURL:URL?
    @State private var webView:WKWebView?
    @State private var isLoading=false
    @State private var blocked=0
    @State private var media:[DetectedMedia]=[]
    @State private var showMedia=false
    @State private var selected:DetectedMedia?
    @State private var showPlayer=false
    @State private var showShield=false
    private let coordinator=BrowserCoordinator()

    var body: some View {
        NavigationStack{ZStack(alignment:.bottom){WebView(url:$currentURL,webView:$webView,isLoading:$isLoading,blockedPopups:$blocked,coordinator:coordinator).ignoresSafeArea(edges:.bottom)
            VStack(spacing:8){HStack{Button{webView?.goBack()}label:{Image(systemName:"chevron.left")}.buttonStyle(.glass);TextField("Search or enter website",text:$address).textInputAutocapitalization(.never).keyboardType(.URL).onSubmit(load).padding(.horizontal,14).padding(.vertical,10).background(.thinMaterial,in:.capsule);Button(action:load){Image(systemName:"arrow.right")}.buttonStyle(.glass)}.padding(.horizontal)
            HStack{Button{detect()}label:{Label("Detect",systemImage:"play.rectangle")}.buttonStyle(.glassProminent);Button{showShield=true}label:{Label("Shield \(blocked)",systemImage:"checkmark.shield")}.buttonStyle(.glass);Spacer();Button{webView?.reload()}label:{Image(systemName:"arrow.clockwise")}.buttonStyle(.glass)}.padding(.horizontal).padding(.bottom,8)}.background(.ultraThinMaterial)}.navigationTitle("StreamGlass").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented:$showMedia){List(media){m in Button{selected=m;showMedia=false;showPlayer=true}{VStack(alignment:.leading){Text(m.title).font(.headline);Text(m.kind+(m.isLive ? " • Live":"")).foregroundStyle(.secondary);Text(m.url.absoluteString).font(.caption).foregroundStyle(.secondary).lineLimit(2)}}}.navigationTitle("Detected Media").presentationDetents([.medium,.large])}
        .fullScreenCover(isPresented:$showPlayer){if let selected {PlayerView(media:selected)}}
        .sheet(isPresented:$showShield){VStack(spacing:16){Image(systemName:"checkmark.shield.fill").font(.system(size:48));Text("Web Shield").font(.title2.bold());Text("\(blocked) popup navigations blocked this session.").foregroundStyle(.secondary);Text("This first version blocks unwanted new-window/popup navigation. It does not promise to remove every advertisement on every website.").font(.footnote).multilineTextAlignment(.center).foregroundStyle(.secondary)}.padding().presentationDetents([.medium])}
        }
    }
    private func load(){var s=address.trimmingCharacters(in:.whitespacesAndNewlines);guard !s.isEmpty else{return};if !s.contains("://"){s="https://"+s};guard let u=URL(string:s) else{return};address=u.absoluteString;webView?.load(URLRequest(url:u))}
    private func detect(){guard let w=webView else{return};MediaDetector.shared.detect(in:w){r in media=r;showMedia=true}}
}
