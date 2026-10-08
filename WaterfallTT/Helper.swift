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

    func string(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    func updateString(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .year)
            ? "d MMM"
            : "d MMM yyyy"
        return dateFormatter.string(from: date)
    }

    func date(from string: String) -> Date? {
        dateFormatter.date(from: string)
    }

    private func isMatched(_ word: String, array: [String]) -> Bool {
        array.contains { word.compare($0, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
    }
}
