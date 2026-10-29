import SwiftUI
import WebKit

struct BrowserView: View {
    @State private var address = ""
    @State private var currentURL: URL?
    @State private var webView: WKWebView?
    @State private var isLoading = false
    @State private var blocked = 0
    @State private var media: [DetectedMedia] = []
    @State private var showMedia = false
    @State private var selected: DetectedMedia?
    @State private var showPlayer = false
    @State private var showShield = false
    @State private var errorMessage: String?
    private let coordinator = BrowserCoordinator()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                WebView(url: $currentURL, webView: $webView, isLoading: $isLoading, blockedPopups: $blocked, coordinator: coordinator)
                    .ignoresSafeArea(edges: .bottom)

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button { webView?.goBack() } label: { Image(systemName: "chevron.left") }.buttonStyle(.glass)
                        TextField("Search or enter website", text: $address)
                            .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                            .onSubmit(load)
                            .padding(.horizontal, 14).padding(.vertical, 10)
                            .background(.thinMaterial, in: .capsule)
                        Button(action: load) { Image(systemName: "arrow.right") }.buttonStyle(.glass)
                    }.padding(.horizontal)

                    HStack(spacing: 8) {
                        Button(action: detect) {
                            Label(media.isEmpty ? "Detect" : "\(media.count) Media", systemImage: "play.rectangle.fill")
                        }.buttonStyle(.glassProminent)
                        Button { showShield = true } label: {
                            Label("Shield \(blocked)", systemImage: "checkmark.shield")
                        }.buttonStyle(.glass)
                        Spacer()
                        if isLoading { ProgressView().controlSize(.small) }
                        Button { webView?.reload() } label: { Image(systemName: "arrow.clockwise") }.buttonStyle(.glass)
                    }.padding(.horizontal).padding(.bottom, 8)
                }.background(.ultraThinMaterial)
            }
            .navigationTitle("StreamGlass")
            .navigationBarTitleDisplayMode(.inline)
            .alert("StreamGlass", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
            .sheet(isPresented: $showMedia) {
                List(media) { item in
                    Button {
                        selected = item
                        showMedia = false
                        showPlayer = true
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title).font(.headline)
                            Text(item.kind + (item.isLive ? " • Live" : "")).foregroundStyle(.secondary)
                            Text(item.url.absoluteString).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                        }.padding(.vertical, 4)
                    }
                }.navigationTitle("Detected Media").presentationDetents([.medium, .large])
            }
            .fullScreenCover(isPresented: $showPlayer) {
                if let selected { PlayerView(media: selected) }
            }
            .sheet(isPresented: $showShield) {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.shield.fill").font(.system(size: 48))
                    Text("Web Shield").font(.title2.bold())
                    Text("\(blocked) popup/new-window navigations blocked this session.").foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Text("StreamGlass blocks unwanted popup navigation and keeps media playback inside the app. It does not promise to remove every advertisement or bypass a website's access controls.")
                        .font(.footnote).multilineTextAlignment(.center).foregroundStyle(.secondary)
                }.padding().presentationDetents([.medium])
            }
        }
    }

    private func load() {
        var value = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        if !value.contains("://") { value = "https://" + value }
        guard let url = URL(string: value) else { errorMessage = "That address doesn't look valid."; return }
        address = url.absoluteString
        webView?.load(URLRequest(url: url))
    }

    private func detect() {
        guard let webView else { errorMessage = "The browser isn't ready yet."; return }
        MediaDetector.shared.detect(in: webView) { results in
            DispatchQueue.main.async {
                media = results
                guard !results.isEmpty else { errorMessage = "No compatible media URL was exposed by this page."; return }
                selected = results.sorted(by: Self.isBetterMedia).first
                if selected != nil { showPlayer = true } else { showMedia = true }
            }
        }
    }

    private static func isBetterMedia(_ lhs: DetectedMedia, _ rhs: DetectedMedia) -> Bool {
        func score(_ item: DetectedMedia) -> Int {
            var value = 0
            if item.isLive { value += 40 }
            if item.url.pathExtension.lowercased() == "m3u8" { value += 30 }
            if item.kind.localizedCaseInsensitiveContains("HTML5") { value += 10 }
            return value
        }
        return score(lhs) > score(rhs)
    }
}
