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

struct PlayerNumber {
    var name: String
    var points: Int
    var licenceNumber: String?
}

class WebViewViewController: UIViewController {
    var webView: WKWebView!
    weak var delegate: WebViewViewControllerRepresentable.Coordinator?
    var idClub: String?
    var tmpPlayers: [PlayerNumber] = []

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
            guard let self else { return }
            if let html = result as? String {
//                print("HTML: \(html)")

                if webView.url?.absoluteString.contains("clubs") ?? false {
                    var players: [PlayerNumber] = []
                    var clubName = ""
                    do {
                        let document: Document = try SwiftSoup.parse(html)
                        if let doc = try document.getElementsByClass("edgetoedge").first {
                            let links = try doc.select("a[href*=licencies]").compactMap { try $0.attr("href") }
                            let names = try doc.getElementsByClass("labels").compactMap { try $0.text() }
                            let counts = try doc.getElementsByClass("counter").compactMap { try $0.text() }
                            if names.count == counts.count {
                                for (name, count, link) in zip3(names, counts, links).filter({ $0.1 != "L" }) {
                                    players.append(contentsOf: [
                                        PlayerNumber(name: name,
                                                     points: Int(count) ?? 9999,
                                                     licenceNumber: extractLicenceNumer(link))
                                    ])
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
                    managePlayers(players: players, clubName: clubName)
                } else if webView.url?.absoluteString.contains("licence") ?? false {
                    guard let licenceNumber = extractLicenceNumer(webView.url?.absoluteString ?? ""),
                          let index = tmpPlayers.firstIndex(where: { $0.licenceNumber == licenceNumber })
                    else { return }
                    do {
                        let document: Document = try SwiftSoup.parse(html)
                        let items = try document.getElementsByClass("item-container")
                        for item in items {
                            let label = try item.getElementsByClass("labels").text()
                            if label == "Points officiels" {
                                let pointsString = try item.getElementsByClass("counter").text()
                                if let points = Int(pointsString) {
                                    tmpPlayers[index].points = points
                                    break
                                }
                            }
                        }
                    } catch {}
                }
            }
        }
    }

    func extractLicenceNumer(_ link: String) -> String? {
        link.replacingOccurrences(of: "https://www.pingpocket.fr", with: "")
            .replacingOccurrences(of: "/app/fftt/licencies/", with: "")
            .replacingOccurrences(of: "/licence", with: "")
            .components(separatedBy: "?")[0]
    }

    func managePlayers(players: [PlayerNumber], clubName: String) {
        tmpPlayers = players
        let numberPlayers = players.filter { $0.points == 9999 }
        Task {
            for player in numberPlayers {
                if let licenceNumber = player.licenceNumber,
                   let url = URL(string: "https://www.pingpocket.fr/app/fftt/licencies/\(licenceNumber)/licence") {
                    let request = URLRequest(url: url)
                    webView.load(request)
                    try await Task.sleep(for: .seconds(2))
                }
            }
            delegate?.dismiss(with: ImportResult(players: tmpPlayers.map { (name: $0.name, points: $0.points) },
                                                 clubName: clubName))
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

private extension WebViewViewController {
    func zip3<A, B, C>(_ a: [A], _ b: [B], _ c: [C]) -> [(A, B, C)] {
        let minCount = min(a.count, b.count, c.count)
        return (0 ..< minCount).map { (a[$0], b[$0], c[$0]) }
    }
}
