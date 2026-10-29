# StreamGlass

StreamGlass is a small iOS 26 SwiftUI browser/media player prototype.

## V1

- WKWebView browser
- popup/new-window blocking
- media URL detection for media exposed by the page
- automatic best-candidate selection
- AVPlayerLayer playback
- native AirPlay route picker
- Picture in Picture support
- Fit / Full / Zoom / Custom framing
- pinch + drag custom framing
- Liquid Glass UI
- GitHub Actions unsigned IPA build

The app is intended for media the user is authorized to access. It does not intentionally bypass website access controls or harvest unauthorized streams.

## Build

Open `StreamGlass.xcodeproj` in Xcode 26+ or run the included GitHub Actions workflow. The workflow packages an unsigned IPA as `StreamGlass-unsigned.ipa`.
