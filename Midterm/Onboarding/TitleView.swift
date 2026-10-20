//
//  TitleView.swift
//  Midterm
//
//  Created by Rumik He on 10/13/26.
//

import SwiftUI


struct TitleView: View {
    var body: some View {
        ZStack {

            PatternBackground()

            VStack(spacing: 24) {
                Image("FreshlingsCharacter")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 190)

                Image("FreshlingsWordmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 230)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Freshlings")
    }
}

#Preview {
    TitleView()
}
