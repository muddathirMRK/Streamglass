import SwiftUI
import AVKit
import AVFoundation

private struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.tintColor = .white
        picker.activeTintColor = .white
        return picker
    }
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

private final class PiPManager {
    static let shared = PiPManager()
    private var controller: AVPictureInPictureController?
    func configure(layer: AVPlayerLayer) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else { return }
        controller = AVPictureInPictureController(playerLayer: layer)
        controller?.canStartPictureInPictureAutomaticallyFromInline = false
    }
    func toggle() {
        guard let controller else { return }
        if controller.isPictureInPictureActive { controller.stopPictureInPicture() }
        else if controller.isPictureInPicturePossible { controller.startPictureInPicture() }
    }
    func clear() { controller?.stopPictureInPicture(); controller = nil }
}

private struct PlayerSurface: UIViewRepresentable {
    let player: AVPlayer
    let gravity: AVLayerVideoGravity
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = gravity
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        context.coordinator.layer = layer
        PiPManager.shared.configure(layer: layer)
        return view
    }
    func updateUIView(_ view: UIView, context: Context) {
        context.coordinator.layer?.player = player
        context.coordinator.layer?.videoGravity = gravity
        context.coordinator.layer?.frame = view.bounds
    }
    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { weak var layer: AVPlayerLayer? }
    static func dismantleUIView(_ view: UIView, coordinator: Coordinator) { PiPManager.shared.clear() }
}

struct PlayerView: View {
    let media: DetectedMedia
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer
    @State private var mode: Mode = .fit
    @State private var zoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var baseZoom: CGFloat = 1
    @State private var baseOffset: CGSize = .zero
    @State private var showModes = false

    enum Mode: String, CaseIterable { case fit = "Fit", fill = "Full", zoom = "Zoom", custom = "Custom" }

    init(media: DetectedMedia) {
        self.media = media
        let avPlayer = AVPlayer(url: media.url)
        avPlayer.allowsExternalPlayback = true
        avPlayer.usesExternalPlaybackWhileExternalScreenIsActive = true
        _player = State(initialValue: avPlayer)
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            PlayerSurface(player: player, gravity: videoGravity)
                .scaleEffect(mode == .custom ? zoom : (mode == .zoom ? 1.18 : 1))
                .offset(mode == .custom ? offset : .zero)
                .gesture(customMagnify)
                .simultaneousGesture(customDrag)
            VStack {
                HStack(spacing: 10) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }.buttonStyle(.glass)
                    Spacer()
                    AirPlayButton().frame(width: 34, height: 34).background(.thinMaterial, in: .circle)
                    Button { PiPManager.shared.toggle() } label: { Image(systemName: "pip.enter") }.buttonStyle(.glass)
                    Button { showModes = true } label: { Image(systemName: "arrow.up.left.and.arrow.down.right") }.buttonStyle(.glass)
                }.padding()
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(media.title).font(.headline).lineLimit(1)
                        Text(media.isLive ? "Live" : media.kind).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(mode.rawValue).font(.caption.bold())
                }
                .padding(.horizontal, 14).padding(.vertical, 10)
                .glassEffect(.regular, in: .rect(cornerRadius: 18)).padding()
            }
        }
        .task {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try? AVAudioSession.sharedInstance().setActive(true)
            player.play()
        }
        .onDisappear {
            player.pause(); PiPManager.shared.clear(); try? AVAudioSession.sharedInstance().setActive(false)
        }
        .confirmationDialog("Video Display", isPresented: $showModes) {
            ForEach(Mode.allCases, id: \.self) { item in
                Button(item.rawValue) {
                    mode = item
                    if item != .custom { zoom = 1; offset = .zero; baseZoom = 1; baseOffset = .zero }
                }
            }
            Button("Reset Custom") { zoom = 1; offset = .zero; baseZoom = 1; baseOffset = .zero }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var videoGravity: AVLayerVideoGravity {
        switch mode { case .fit: return .resizeAspect; case .fill, .zoom, .custom: return .resizeAspectFill }
    }
    private var customMagnify: some Gesture {
        MagnifyGesture().onChanged { value in
            guard mode == .custom else { return }
            zoom = min(max(baseZoom * value.magnification, 1), 4)
        }.onEnded { _ in baseZoom = zoom }
    }
    private var customDrag: some Gesture {
        DragGesture().onChanged { value in
            guard mode == .custom else { return }
            offset = CGSize(width: baseOffset.width + value.translation.width, height: baseOffset.height + value.translation.height)
        }.onEnded { _ in baseOffset = offset }
    }
}
