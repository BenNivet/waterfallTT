//
//  ChipModel.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin  on 23/10/2024.
//

import SwiftUI

public enum ChipMode {
    case normal
    case error
}

public struct ChipModel: Identifiable {
    public let id = UUID()
    @Binding var isActive: Bool
    let title: String
    let mode: ChipMode
    let deleteAction: (() -> Void)?

    public init(isActive: Binding<Bool>,
                title: String,
                mode: ChipMode = .normal,
                deleteAction: (() -> Void)? = nil) {
        _isActive = isActive
        self.title = title
        self.mode = mode
        self.deleteAction = deleteAction
    }
}
