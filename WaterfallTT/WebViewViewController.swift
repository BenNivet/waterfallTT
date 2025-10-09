//
//  WebViewViewController.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 30/09/2025.
//

import SwiftSoup
import SwiftUI
import UIKit
import WebKit

class WebViewViewController: UIViewController {
    var webView: WKWebView!
    weak var delegate: WebViewViewControllerRepresentable.Coordinator?
    var idClub: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        webView = WKWebView(frame: view.frame)
        webView.navigationDelegate = self
        view.addSubview(webView)

        if let idClub,
           let url = URL(string: "https://www.pingpocket.fr/app/fftt/clubs/\(idClub)/licencies?SORT=OFFICIAL_RANK") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}

// MARK: - WKNavigationDelegate
extension WebViewViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        let js = "document.documentElement.outerHTML.toString()"
        webView.evaluateJavaScript(js) { [weak self] result, _ in
            if let html = result as? String {
//                print("HTML: \(html)")

                var players: [(name: String, points: Int)] = []
                var clubName = ""
                do {
                    let document: Document = try SwiftSoup.parse(html)
                    if let doc = try document.getElementsByClass("edgetoedge").first {
                        let names = try doc.getElementsByClass("labels").compactMap { try $0.text() }
                        let counts = try doc.getElementsByClass("counter").compactMap { try $0.text() }
                        if names.count == counts.count {
                            for (name, count) in zip(names, counts).filter({ $0.1 != "L" }) {
                                players.append(contentsOf: [(name: name, points: Int(count) ?? 9999)])
                            }
                        }
                    }
                    if !players.isEmpty {
                        if let current = try document.getElementsByClass("current").first,
                           let toolbar = try current.getElementsByClass("toolbar").first,
                           let title = try? toolbar.select("h1").first {
                            clubName = try title.text()
                        }
                    }
                } catch {}
                self?.delegate?.dismiss(with: ImportResult(players: players,
                                                           clubName: clubName))
            }
        }
    }

    func webView(_: WKWebView, didFail _: WKNavigation!, withError _: Error) {
        delegate?.dismiss(with: ImportResult())
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError _: Error) {
        delegate?.dismiss(with: ImportResult())
    }
}

struct WebViewViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var idClub: String
    @Binding var results: ImportResult

    func makeUIViewController(context: Context) -> WebViewViewController {
        let viewController = WebViewViewController()
        viewController.delegate = context.coordinator
        viewController.idClub = idClub
        return viewController
    }

    func updateUIViewController(_: WebViewViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: WebViewViewControllerRepresentable

        init(_ parent: WebViewViewControllerRepresentable) {
            self.parent = parent
        }

        func dismiss(with results: ImportResult) {
            parent.results = results
            parent.idClub.removeAll()
        }
    }
}
