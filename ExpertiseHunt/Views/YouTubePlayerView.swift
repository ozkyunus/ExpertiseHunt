import SwiftUI
import WebKit

struct YouTubePlayerView: UIViewRepresentable {
    let videoID: String
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let htmlString = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body { margin: 0; }
                .video-container { position: relative; padding-bottom: 56.25%; height: 0; overflow: hidden; }
                .video-container iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
            </style>
        </head>
        <body>
            <div class="video-container">
                <iframe src="https://www.youtube.com/embed/\(videoID)" frameborder="0" allowfullscreen></iframe>
            </div>
        </body>
        </html>
        """
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }
}
