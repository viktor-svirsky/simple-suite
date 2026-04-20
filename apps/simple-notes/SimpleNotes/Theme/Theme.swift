import SwiftUI
import UIKit

enum Theme {
    enum Color {
        static let bg       = SwiftUI.Color("ThemeBg",       bundle: .main, fallback: .init(light: 0xFAFAFA, dark: 0x0A0A0A))
        static let surface  = SwiftUI.Color("ThemeSurface",  bundle: .main, fallback: .init(light: 0xFFFFFF, dark: 0x141414))
        static let text     = SwiftUI.Color("ThemeText",     bundle: .main, fallback: .init(light: 0x0A0A0A, dark: 0xF5F5F5))
        static let muted    = SwiftUI.Color("ThemeMuted",    bundle: .main, fallback: .init(light: 0x737373, dark: 0xA3A3A3))
        static let accent   = SwiftUI.Color("ThemeAccent",   bundle: .main, fallback: .init(light: 0x0A0A0A, dark: 0xFAFAFA))
        static let hairline = SwiftUI.Color("ThemeHairline", bundle: .main, fallback: .init(light: 0xE5E5E5, dark: 0x262626))
    }

    enum Font {
        static let serifName = "New York"
        static let sansName  = "SF Pro Text"
        static let monoName  = "SF Mono"

        static func serif(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .custom(serifName, size: size, relativeTo: textStyle(for: size)).weight(weight)
        }
        static func sans(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(textStyle(for: size), design: .default, weight: weight)
        }
        static func mono(_ size: CGFloat) -> SwiftUI.Font {
            .system(textStyle(for: size), design: .monospaced)
        }

        static func textStyle(for size: CGFloat) -> SwiftUI.Font.TextStyle {
            switch size {
            case ..<12:  return .caption2
            case ..<13:  return .caption
            case ..<14:  return .footnote
            case ..<16:  return .subheadline
            case ..<17:  return .callout
            case ..<20:  return .body
            case ..<22:  return .title3
            case ..<28:  return .title2
            case ..<34:  return .title
            default:     return .largeTitle
            }
        }
    }

    enum Metric {
        static let radius: CGFloat = 8
        static let padding: CGFloat = 16
        static let hairline: CGFloat = 0.5
    }
}

private struct HexPair {
    let light: UInt32
    let dark: UInt32
}

private extension SwiftUI.Color {
    init(_ assetName: String, bundle: Bundle, fallback: HexPair) {
        if UIColor(named: assetName, in: bundle, compatibleWith: nil) != nil {
            self = SwiftUI.Color(assetName, bundle: bundle)
        } else {
            self = SwiftUI.Color(UIColor { trait in
                let hex = trait.userInterfaceStyle == .dark ? fallback.dark : fallback.light
                return UIColor(
                    red:   CGFloat((hex >> 16) & 0xFF) / 255.0,
                    green: CGFloat((hex >> 8)  & 0xFF) / 255.0,
                    blue:  CGFloat(hex         & 0xFF) / 255.0,
                    alpha: 1.0
                )
            })
        }
    }
}
