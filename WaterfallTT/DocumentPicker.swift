//
//  DocumentPicker.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 14/07/2025.
//

import SwiftUI

struct DocumentPicker: UIViewControllerRepresentable {
    var completion: (URL?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.commaSeparatedText])
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .formSheet
        return picker
    }

    func updateUIViewController(_: UIDocumentPickerViewController, context _: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.completion(urls.first)
        }

        func documentPickerWasCancelled(_: UIDocumentPickerViewController) {
            parent.completion(nil)
        }
    }
}
