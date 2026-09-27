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
}
