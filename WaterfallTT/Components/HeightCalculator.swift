//
//  HeightCalculator.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin on 22/02/2024.
//

import SwiftUI

private struct HeightCalculator: ViewModifier {
    @Binding var height: CGFloat
    @Binding var width: CGFloat

    init(height: Binding<CGFloat> = .constant(0), width: Binding<CGFloat> = .constant(0)) {
        _width = width
        _height = height
    }

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { reader in
                    Color.clear
                        .onAppear {
                            width = reader.size.width
                            height = reader.size.height
                        }
                }
            )
    }
}

public extension View {
    func saveWidth(in width: Binding<CGFloat>) -> some View {
        modifier(HeightCalculator(width: width))
    }

    func saveHeight(in height: Binding<CGFloat>) -> some View {
        modifier(HeightCalculator(height: height))
    }
}
