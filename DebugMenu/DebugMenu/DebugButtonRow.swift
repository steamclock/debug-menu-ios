//
//  SwiftUIView.swift
//  
//
//  Created by Alejandro Zielinsky on 2021-11-30.
//

import SwiftUI

struct DebugButtonRow: View {
    let title: String
    let action: () -> Void
    var showChevron: Bool = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                if showChevron {
                    Image(systemName: "chevron.right").foregroundColor(Color(.lightGray))
                }
            }
        }
        .foregroundColor(showChevron ? .black : .blue)
    }
}
