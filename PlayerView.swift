import SwiftUI
import AVKit

struct PlayerView: View {
    let media: DetectedMedia
    @Environment(\.dismiss) private var dismiss
    @State private var player=AVPlayer()
    @State private var mode:Mode=.fit
    @State private var zoom:CGFloat=1
    @State private var offset:CGSize=.zero
    @State private var showModes=false
    enum Mode:String,CaseIterable { case fit="Fit", fill="Fill", zoom="Zoom", custom="Custom" }

    var body: some View {
        ZStack{ Color.black.ignoresSafeArea()
            VideoPlayer(player:player)
                .aspectRatio(contentMode: mode == .fit ? .fit : .fill)
                .scaleEffect(mode == .custom ? zoom : (mode == .zoom ? 1.22 : 1))
                .offset(mode == .custom ? offset : .zero)
                .gesture(MagnifyGesture().onChanged{v in if mode == .custom { zoom=min(max(v.magnification,1),4) }})
                .simultaneousGesture(DragGesture().onChanged{v in if mode == .custom { offset=v.translation }})
            VStack{HStack{Button{dismiss()}label:{Image(systemName:"xmark").font(.title2)};Spacer();Button{showModes=true}label:{Image(systemName:"arrow.up.left.and.arrow.down.right")}.buttonStyle(.glass)}.padding();Spacer();Text(media.title).lineLimit(1).padding().glassEffect(.regular,in:.rect(cornerRadius:18)).padding()}
        }
        .task{player.replaceCurrentItem(with:AVPlayerItem(url:media.url));player.play()}
        .onDisappear{player.pause()}
        .confirmationDialog("Video Display",isPresented:$showModes){ForEach(Mode.allCases,id:\.self){m in Button(m.rawValue){mode=m;if m != .custom {zoom=1;offset=.zero}}};Button("Reset Custom"){zoom=1;offset=.zero};Button("Cancel",role:.cancel){}}
    }
}
