//
//  PlatformSupport.swift
//  TimeToSkill
//
//  Cross-platform (iOS / macOS) abstractions so shared UI code compiles on both.
//

import SwiftUI
import Foundation

#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformImage = NSImage
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
#endif

extension Image {
    /// Creates a SwiftUI `Image` from the platform-native image type (`UIImage`/`NSImage`).
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #elseif canImport(AppKit)
        self.init(nsImage: platformImage)
        #endif
    }
}

/// Platform-neutral helpers for loading, encoding and resizing images.
enum PlatformImageLoader {
    /// Loads an image either from a file path (custom images saved by the user)
    /// or from an asset/symbol name in the bundle.
    static func image(namedOrPath name: String) -> PlatformImage? {
        if FileManager.default.fileExists(atPath: name) {
            #if canImport(UIKit)
            return UIImage(contentsOfFile: name)
            #elseif canImport(AppKit)
            return NSImage(contentsOfFile: name)
            #endif
        }
        #if canImport(UIKit)
        return UIImage(named: name)
        #elseif canImport(AppKit)
        return NSImage(named: name)
        #endif
    }

    static func image(data: Data) -> PlatformImage? {
        #if canImport(UIKit)
        return UIImage(data: data)
        #elseif canImport(AppKit)
        return NSImage(data: data)
        #endif
    }

    /// PNG encoded representation of the given image.
    static func pngData(from image: PlatformImage) -> Data? {
        #if canImport(UIKit)
        return image.pngData()
        #elseif canImport(AppKit)
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
        #endif
    }

    /// Whether an SF Symbol with the given name exists on this platform.
    static func systemSymbolExists(_ name: String) -> Bool {
        #if canImport(UIKit)
        return UIImage(systemName: name) != nil
        #elseif canImport(AppKit)
        return NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
        #endif
    }

    /// Returns a resized copy of the image.
    static func resized(_ image: PlatformImage, to targetSize: CGSize) -> PlatformImage {
        #if canImport(UIKit)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        #elseif canImport(AppKit)
        let result = NSImage(size: targetSize)
        result.lockFocus()
        image.draw(in: CGRect(origin: .zero, size: targetSize),
                   from: CGRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        result.unlockFocus()
        return result
        #endif
    }
}

// MARK: - Haptics

enum HapticStyle {
    case light
    case medium
    case rigid
}

/// Triggers a light haptic/feedback impulse where supported.
func triggerHaptic(_ style: HapticStyle = .medium) {
    #if canImport(UIKit)
    let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
    switch style {
    case .light: uiStyle = .light
    case .medium: uiStyle = .medium
    case .rigid: uiStyle = .rigid
    }
    UIImpactFeedbackGenerator(style: uiStyle).impactOccurred()
    #elseif canImport(AppKit)
    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    #endif
}

// MARK: - Cross-platform view modifiers

extension View {
    /// Applies the numeric keypad keyboard type on iOS; no-op elsewhere.
    @ViewBuilder func numberPadKeyboard() -> some View {
        #if canImport(UIKit)
        self.keyboardType(.numberPad)
        #else
        self
        #endif
    }

    @ViewBuilder func asciiCapableKeyboard() -> some View {
        #if canImport(UIKit)
        self.keyboardType(.asciiCapable)
        #else
        self
        #endif
    }

    @ViewBuilder func numbersAndPunctuationKeyboard() -> some View {
        #if canImport(UIKit)
        self.keyboardType(.numbersAndPunctuation)
        #else
        self
        #endif
    }

    @ViewBuilder func neverAutocapitalization() -> some View {
        #if canImport(UIKit)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    /// Inline navigation title on iOS; no-op elsewhere.
    @ViewBuilder func inlineNavigationBarTitle() -> some View {
        #if canImport(UIKit)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Medium/large sheet detents on iOS; no-op elsewhere.
    @ViewBuilder func mediumLargePresentationDetents() -> some View {
        #if canImport(UIKit)
        self.presentationDetents([.medium, .large])
        #else
        self
        #endif
    }

    /// Hides the navigation bar on iOS; no-op elsewhere.
    @ViewBuilder func hiddenNavigationBar() -> some View {
        #if canImport(UIKit)
        self.navigationBarHidden(true)
        #else
        self
        #endif
    }

    // MARK: - macOS layout helpers

    /// Caps the content width on macOS so text and cards keep a readable,
    /// Mac-like measure instead of stretching across a very wide window.
    /// No-op on iOS, where the viewport is already phone sized.
    @ViewBuilder func macOSContentWidth(_ maxWidth: CGFloat) -> some View {
        #if os(macOS)
        self.frame(maxWidth: maxWidth)
        #else
        self
        #endif
    }

    /// Gives a macOS sheet a comfortable minimum size so it does not open as a
    /// tiny phone-sized panel. No-op on iOS.
    @ViewBuilder func macOSSheetMinSize(width: CGFloat, height: CGFloat) -> some View {
        #if os(macOS)
        self.frame(minWidth: width, minHeight: height)
        #else
        self
        #endif
    }

    /// Adds pointer hover feedback to custom-drawn controls (cards, floating
    /// buttons, gradient buttons) that have no system hover appearance of their
    /// own. No-op on iOS.
    @ViewBuilder func macOSHoverFeedback(scale: CGFloat = 1.012) -> some View {
        #if os(macOS)
        modifier(MacHoverFeedbackModifier(scale: scale))
        #else
        self
        #endif
    }

    /// Adds a native macOS toolbar action (with an optional keyboard shortcut).
    /// No-op on iOS, where the same action is offered in-content.
    @ViewBuilder func macOSToolbarAction(
        title: LocalizedStringKey,
        systemImage: String,
        shortcut: KeyboardShortcut? = nil,
        action: @escaping () -> Void
    ) -> some View {
        #if os(macOS)
        self.toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: action) {
                    Label(title, systemImage: systemImage)
                }
                .help(title)
                .modifier(OptionalKeyboardShortcut(shortcut: shortcut))
            }
        }
        #else
        self
        #endif
    }

    /// Renders a text-only action as a macOS link-style button (blue text with
    /// hover feedback). No-op on iOS.
    @ViewBuilder func macOSLinkButtonStyle() -> some View {
        #if os(macOS)
        self.buttonStyle(.link)
        #else
        self
        #endif
    }
}

extension Scene {
    /// Opens the macOS window at a comfortable size instead of the tiny default.
    /// No-op on iOS.
    @SceneBuilder func macOSDefaultWindowSize(width: CGFloat, height: CGFloat) -> some Scene {
        #if os(macOS)
        self.defaultSize(width: width, height: height)
        #else
        self
        #endif
    }
}

#if os(macOS)
/// macOS-only hover highlight used by custom-drawn controls.
private struct MacHoverFeedbackModifier: ViewModifier {
    let scale: CGFloat

    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovering ? scale : 1)
            .shadow(
                color: .black.opacity(isHovering ? 0.18 : 0),
                radius: isHovering ? 8 : 0,
                y: 2
            )
            .animation(.easeOut(duration: 0.12), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

/// Applies a keyboard shortcut only when one was provided.
private struct OptionalKeyboardShortcut: ViewModifier {
    let shortcut: KeyboardShortcut?

    func body(content: Content) -> some View {
        if let shortcut {
            content.keyboardShortcut(shortcut)
        } else {
            content
        }
    }
}
#endif
