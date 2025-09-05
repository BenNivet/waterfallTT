//
//  ChipModel.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin  on 23/10/2024.
//

import SwiftUI

public struct ChipModel: Identifiable {
    public let id = UUID()
    @Binding var isActive: Bool
    let title: String
    let deleteAction: (() -> Void)?

    public init(isActive: Binding<Bool>,
                title: String,
                deleteAction: (() -> Void)? = nil) {
        _isActive = isActive
        self.title = title
        self.deleteAction = deleteAction
    }
}
