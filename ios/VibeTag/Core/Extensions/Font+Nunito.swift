import SwiftUI

extension Font {
    static func nunito(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        let size: CGFloat
        switch style {
        case .largeTitle: size = 34
        case .title: size = 28
        case .title2: size = 22
        case .title3: size = 20
        case .headline: size = 17
        case .body: size = 17
        case .callout: size = 16
        case .subheadline: size = 15
        case .footnote: size = 13
        case .caption: size = 12
        case .caption2: size = 11
        @unknown default: size = 17
        }
        
        // Map SwiftUI weights to Nunito font names
        let fontName: String
        switch weight {
        case .bold, .heavy, .black:
            fontName = "Nunito-Bold"
        case .semibold:
            fontName = "Nunito-SemiBold"
        case .medium:
            fontName = "Nunito-Medium"
        default:
            fontName = "Nunito-Regular"
        }
        
        return .custom(fontName, size: size, relativeTo: style)
    }
    
    // Helper for specific sizes
    static func nunito(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let fontName: String
        switch weight {
        case .bold, .heavy, .black:
            fontName = "Nunito-Bold"
        case .semibold:
            fontName = "Nunito-SemiBold"
        case .medium:
            fontName = "Nunito-Medium"
        default:
            fontName = "Nunito-Regular"
        }
        return .custom(fontName, size: size)
    }
}
