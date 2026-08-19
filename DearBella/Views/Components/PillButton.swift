import SwiftUI

/// The app's button system.
///
/// Every screen had been hand-rolling its own capsule — 41 of them across 24
/// files — which is why the app looked assembled rather than designed. Three
/// levels, defined once:
///
/// - `primary` — the one thing this screen wants you to do. Cyan, bold, wide.
/// - `secondary` — a real alternative, present but quieter.
/// - `tertiary` — an escape hatch. Text only; it shouldn't compete.
///
/// Weight and padding are deliberately heavier than the old ad-hoc pills.
/// Confident, chunky, fully-rounded buttons are most of what makes an app feel
/// finished rather than sketched, and the press state gives every tap a
/// physical response instead of a flash.
struct PillButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case tertiary
    }

    let kind: Kind
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .foregroundStyle(foreground)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, kind == .tertiary ? 12 : 22)
            .padding(.vertical, verticalPadding)
            .background(background)
            .clipShape(Capsule())
            .overlay(border)
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private var font: Font {
        switch kind {
        case .primary:   return .inter(16, weight: .bold)
        case .secondary: return .inter(15, weight: .semibold)
        case .tertiary:  return .inter(15, weight: .medium)
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary:   return Theme.ink
        case .secondary: return Theme.cream
        case .tertiary:  return Theme.cream.opacity(0.7)
        }
    }

    private var verticalPadding: CGFloat {
        switch kind {
        case .primary:   return 16
        case .secondary: return 14
        case .tertiary:  return 12
        }
    }

    @ViewBuilder
    private var background: some View {
        switch kind {
        case .primary:   Theme.cyan
        case .secondary: Color.white.opacity(0.08)
        case .tertiary:  Color.clear
        }
    }

    @ViewBuilder
    private var border: some View {
        if kind == .secondary {
            Capsule().stroke(Theme.cream.opacity(0.16), lineWidth: 1)
        }
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    /// Full-width by default: on a phone, a primary action that doesn't span
    /// the screen reads as optional.
    static func pill(_ kind: PillButtonStyle.Kind, fullWidth: Bool = true) -> PillButtonStyle {
        PillButtonStyle(kind: kind, fullWidth: fullWidth)
    }
}
