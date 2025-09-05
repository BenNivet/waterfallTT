//
//  ShareSheet.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 26/06/2025.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems,
                                 applicationActivities: applicationActivities)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
