//
//  PDFReportBuilder.swift
//  TimeToSkill
//
//  Minimal cross-platform PDF canvas built on Core Graphics + Core Text.
//  The iOS build keeps using `UIGraphicsPDFRenderer`; macOS uses this builder
//  so the report export keeps working on both platforms.
//

import Foundation
import CoreGraphics
import CoreText

func platformCGColor(_ color: PlatformColor) -> CGColor {
    color.cgColor
}

/// Draws text and filled bars onto a paginated PDF document.
/// All drawing helpers take coordinates with a **top-left** origin (y grows downwards),
/// matching the layout math used by the UIKit implementation.
final class PDFReportBuilder {
    let pageSize: CGSize
    private let data = NSMutableData()
    private var consumer: CGDataConsumer?
    private var context: CGContext?

    init(pageSize: CGSize) {
        self.pageSize = pageSize
    }

    func begin() {
        guard let consumer = CGDataConsumer(data: data) else { return }
        self.consumer = consumer
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
    }

    func newPage() {
        context?.beginPDFPage(nil)
    }

    func finish() -> Data {
        context?.closePDF()
        return data as Data
    }

    /// Draws a single line of text with its top-left corner at `origin`.
    func drawText(_ text: String,
                  topLeft origin: CGPoint,
                  fontName: String,
                  fontSize: CGFloat,
                  color: PlatformColor) {
        guard let context else { return }
        let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
        let baselineY = pageSize.height - origin.y - CTFontGetAscent(font)
        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorAttributeName: platformCGColor(color)
        ]
        guard let attributed = CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary) else { return }
        let line = CTLineCreateWithAttributedString(attributed)
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: origin.x, y: baselineY)
        CTLineDraw(line, context)
    }

    /// Draws a filled (optionally rounded) rectangle. `rect` uses top-left origin coordinates.
    func drawBar(rect: CGRect, cornerRadius: CGFloat, color: PlatformColor) {
        guard let context else { return }
        let flipped = CGRect(x: rect.minX,
                             y: pageSize.height - rect.maxY,
                             width: rect.width,
                             height: rect.height)
        let path = CGPath(roundedRect: flipped,
                          cornerWidth: cornerRadius,
                          cornerHeight: cornerRadius,
                          transform: nil)
        context.saveGState()
        context.addPath(path)
        context.setFillColor(platformCGColor(color))
        context.fillPath()
        context.restoreGState()
    }
}
