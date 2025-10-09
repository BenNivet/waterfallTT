//
//  PrimaryButtonStyle.swift
//  WaterfallTT
//
//  Created by CANTE Benjamin  on 24/10/2024.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .frame(maxWidth: .infinity)
            .frame(height: CharterConstants.buttonSize)
            .foregroundStyle(.white)
            .font(.system(size: 18, weight: .semibold))
            .background(CharterConstants.mainColor)
            .clipShape(RoundedRectangle(cornerRadius: CharterConstants.radius))
            .opacity(!isEnabled || configuration.isPressed ? CharterConstants.disabledOpacity : 1)
            .contentShape(Rectangle())
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .frame(maxWidth: .infinity)
            .frame(height: CharterConstants.buttonSize)
            .foregroundStyle(.white)
            .font(.system(size: 18, weight: .regular))
            .background(CharterConstants.mainGray)
            .clipShape(RoundedRectangle(cornerRadius: CharterConstants.radius))
            .opacity(configuration.isPressed ? CharterConstants.disabledOpacity : 1)
            .contentShape(Rectangle())
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .frame(maxWidth: .infinity)
            .frame(height: CharterConstants.buttonSize)
            .foregroundStyle(.white)
            .font(.system(size: 18, weight: .semibold))
            .background(CharterConstants.mainRed)
            .clipShape(RoundedRectangle(cornerRadius: CharterConstants.radius))
            .opacity(configuration.isPressed ? CharterConstants.disabledOpacity : 1)
            .contentShape(Rectangle())
    }
}
