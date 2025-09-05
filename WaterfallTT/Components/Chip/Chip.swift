//
//  Chip.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin  on 23/10/2024.
//

import SwiftUI

public struct Chip: View {
    let model: ChipModel
    let sizeFont: CGFloat

    public init(model: ChipModel, sizeFont: CGFloat = 16) {
        self.model = model
        self.sizeFont = sizeFont
    }

    public var body: some View {
        HStack(spacing: CharterConstants.marginSmall) {
            Text(model.title)
                .font(.system(size: sizeFont, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .truncationMode(.middle)
                .multilineTextAlignment(.leading)
            if let deleteAction = model.deleteAction {
                Spacer()
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 1)
                    .padding(.vertical, CharterConstants.marginSmall)
                Button(role: .destructive) {
                    deleteAction()
                } label: {
                    Image(systemName: "trash.fill")
                }
            }
        }
        .padding(.horizontal, CharterConstants.margin)
        .padding(.vertical, CharterConstants.marginXSmall)
        .frame(minHeight: CharterConstants.marginBig)
        .frame(maxHeight: CharterConstants.marginHuge)
        .background(Capsule()
            .fill(backgroundColor)
            .shadow(color: .black.opacity(0.05), radius: CharterConstants.radius, x: 0, y: 0))
        .clipShape(Capsule())
        .onTapGesture {
            model.isActive.toggle()
        }
    }
}

private extension Chip {
    var backgroundColor: Color {
        if model.isActive {
            CharterConstants.mainBlue
        } else {
            CharterConstants.mainGray
        }
    }

    var foregroundColor: Color {
        .white
    }
}
