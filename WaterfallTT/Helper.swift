//
//  Helper.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 21/11/2023.
//

import SwiftUI

final class Helper {
    static let shared = Helper()

    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    var creationDate: String {
        dateFormatter.string(from: Date())
    }

    private func isMatched(_ word: String, array: [String]) -> Bool {
        array.contains { word.compare($0, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
    }
}
