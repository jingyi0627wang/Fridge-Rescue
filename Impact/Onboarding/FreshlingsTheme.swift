//
//  FreshlingsTheme.swift
//  Midterm
//
//  Created by Rumik He on 10/13/26.
//

import SwiftUI
import UIKit

/// Freshlings 的颜色和字体。Title、Login、Onboarding 都从这里取。
enum FreshlingsTheme {

    // MARK: - 颜色（从 Figma 设计稿取样）

    static let green       = hex(0x8DE969)   // 角色、Login 卡片
    static let orange      = hex(0xFFAA01)   // Freshlings 字
    static let patternLine = hex(0xDCFEAB)   // 背景线框
    static let field       = hex(0xEEF9DC)   // 输入框、社交按钮底色
    static let placeholder = hex(0xB9C98A)   // 输入框提示文字和图标
    static let deepGreen   = hex(0x6EA702)   // 主按钮、进度条（目前页）、社交图标
    static let linkGreen   = hex(0x578B20)   // Forgot Password、Sign up
    static let barIdle     = hex(0xAFFC41)   // 进度条（其他页）
    static let ctaGreen    = hex(0x7CCB4C)   // "Add your first freshling"
    static let brown       = hex(0x795340)   // Onboarding 大标题
    static let skipGray    = hex(0xD9D9D9)   // Skip
    static let errorRed    = hex(0x9E1C1C)   // 错误提示（在绿色卡片上也看得清）



    static let displayFontName: String? = nil
    static let headingFontName: String? = nil
    static let bodyFontName: String? = nil

    static func display(_ size: CGFloat) -> Font {
        font(displayFontName, size, .black)
    }

    static func heading(_ size: CGFloat) -> Font {
        font(headingFontName, size, .bold)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        font(bodyFontName, size, weight)
    }

    private static func font(_ name: String?, _ size: CGFloat, _ weight: Font.Weight) -> Font {
        if let name, UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight, design: .rounded)
    }

    private static func hex(_ value: UInt32) -> Color {
        Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}


struct PatternBackground: View {
    var body: some View {
        GeometryReader { geo in
            Image("TitlePattern")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .background(Color.white)
        .ignoresSafeArea()
    }
}
