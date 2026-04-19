import SwiftUI

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
            .custom(serifName, size: size).weight(weight)
        }
        static func sans(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }
        static func mono(_ size: CGFloat) -> SwiftUI.Font {
            .system(size: size, design: .monospaced)
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
