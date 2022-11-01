//
//  LoadingIndicatorModifier.swift
//  
//
//  Created by Alejandro Zielinsky on 2022-11-01.
//

import Foundation

struct LoadingIndicatorModifier: ViewModifier {
    let isLoading: Bool

    func body(content: Content) -> some View {
        if isLoading {
            content
                .blur(radius: 3.0)
                .overlay(
                    ProgressView(label: {
                        Text("Loading...")
                    })
                )
        } else {
            content
        }
    }
}

extension View {
    func loadingIndicator(_ isLoading: Bool) -> some View {
        modifier(LoadingIndicatorModifier(isLoading: isLoading))
    }
}
