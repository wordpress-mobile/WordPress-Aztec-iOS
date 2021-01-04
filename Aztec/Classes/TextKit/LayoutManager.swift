import Foundation
import UIKit
import QuartzCore


// MARK: - Aztec Layout Manager
//
class LayoutManager: NSLayoutManager {

    /// Blockquote's Left Border Color
    /// Set the array with how many colors you like, they appear in the order they are set in the array.
    var blockquoteBorderColors = [UIColor.systemGray]

    /// Blockquote's Background Color
    ///
    var blockquoteBackgroundColor: UIColor? = UIColor(red: 0.91, green: 0.94, blue: 0.95, alpha: 1.0)

    /// HTML Pre Background Color
    ///
    var preBackgroundColor: UIColor? = UIColor(red: 243.0/255.0, green: 246.0/255.0, blue: 248.0/255.0, alpha: 1.0)

    /// Closure that is expected to return the TypingAttributes associated to the Extra Line Fragment
    ///
    var extraLineFragmentTypingAttributes: (() -> [NSAttributedString.Key: Any])?

    /// Blockquote's Left Border width
    ///
    var blockquoteBorderWidth: CGFloat = 2


    /// Draws the background, associated to a given Text Range
    ///
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        drawBlockquotes(forGlyphRange: glyphsToShow, at: origin)
        drawHTMLPre(forGlyphRange: glyphsToShow, at: origin)
        drawLists(forGlyphRange: glyphsToShow, at: origin)
    }
}


// MARK: - Blockquote Helpers
//
private extension LayoutManager {

    /// Draws a Blockquote associated to a Range + Graphics Origin.
    ///
    func drawBlockquotes(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage = textStorage else {
            return
        }

        guard let context = UIGraphicsGetCurrentContext() else {
            preconditionFailure("When drawBackgroundForGlyphRange is called, the graphics context is supposed to be set by UIKit")
        }

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        // Draw: Blockquotes
        textStorage.enumerateAttribute(.paragraphStyle, in: characterRange, options: []) { (object, range, stop) in
            guard let paragraphStyle = object as? ParagraphStyle, !paragraphStyle.blockquotes.isEmpty else {
                return
            }
                        
            let blockquoteGlyphRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)

            enumerateLineFragments(forGlyphRange: blockquoteGlyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
                
                let startIndent = paragraphStyle.indentToFirst(Blockquote.self) - Metrics.listTextIndentation

                let lineRange = self.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
                let lineCharacters = textStorage.attributedSubstring(from: lineRange).string
                let lineEndsParagraph = lineCharacters.isEndOfParagraph(before: lineCharacters.endIndex)
                let blockquoteRect = self.blockquoteRect(origin: origin, lineRect: rect, blockquoteIndent: startIndent, lineEndsParagraph: lineEndsParagraph)

                self.drawBlockquoteBackground(in: blockquoteRect.integral, with: context)
                
                let nestDepth = paragraphStyle.blockquoteNestDepth
                for index in 0...nestDepth {
                    let indent = paragraphStyle.indent(to: index, of: Blockquote.self) - Metrics.listTextIndentation

                    let nestRect = self.blockquoteRect(origin: origin, lineRect: rect, blockquoteIndent: indent, lineEndsParagraph: lineEndsParagraph)

                    self.drawBlockquoteBorder(in: nestRect.integral, with: context, at: index)
                }
            
            }
        }

        // Draw: Extra Line Fragment
        guard extraLineFragmentRect.height != 0,
            let typingAttributes = extraLineFragmentTypingAttributes?() else {
                return
        }

        guard let paragraphStyle = typingAttributes[.paragraphStyle] as? ParagraphStyle,
            !paragraphStyle.blockquotes.isEmpty else {
                return
        }

        let extraIndent = paragraphStyle.indentToLast(Blockquote.self)
        let extraRect = blockquoteRect(origin: origin, lineRect: extraLineFragmentRect, blockquoteIndent: extraIndent, lineEndsParagraph: false)

        drawBlockquoteBackground(in: extraRect.integral, with: context)
        drawBlockquoteBorder(in: extraRect.integral, with: context, at: 0)
    }


    /// Returns the Rect in which the Blockquote should be rendered.
    ///
    /// - Parameters:
    ///     - origin: Origin of coordinates
    ///     - lineRect: Line Fragment's Rect
    ///     - blockquoteIndent: Blockquote Indentation Level for the current lineFragment
    ///     - lineEndsParagraph: Indicates if the current blockquote line is the end of a Paragraph
    ///
    /// - Returns: Rect in which we should render the blockquote.
    ///
    private func blockquoteRect(origin: CGPoint, lineRect: CGRect, blockquoteIndent: CGFloat, lineEndsParagraph: Bool) -> CGRect {
        var blockquoteRect = lineRect.offsetBy(dx: origin.x, dy: origin.y)
        
        let paddingWidth = blockquoteIndent
        blockquoteRect.origin.x += paddingWidth
        blockquoteRect.size.width -= paddingWidth

        // Ref. Issue #645: Cheking if we this a middle line inside a blockquote paragraph
        if lineEndsParagraph {
            blockquoteRect.size.height -= Metrics.paragraphSpacing * 0.5
        }

        return blockquoteRect
    }
    
    private func drawBlockquoteBorder(in rect: CGRect, with context: CGContext, at depth: Int) {
        let quoteCount = blockquoteBorderColors.count
        let index = min(depth, quoteCount-1)
        
        guard quoteCount > 0 && index < quoteCount else {
            return            
        }
        
        let borderColor = blockquoteBorderColors[index]
        let borderRect = CGRect(origin: rect.origin, size: CGSize(width: blockquoteBorderWidth, height: rect.height))
        borderColor.setFill()
        context.fill(borderRect)
    }

    /// Draws a single Blockquote Line Fragment, in the specified Rectangle, using a given Graphics Context.
    ///
    private func drawBlockquoteBackground(in rect: CGRect, with context: CGContext) {
        guard let color = blockquoteBackgroundColor else {return}
        
        color.setFill()
        context.fill(rect)
    }
}


// MARK: - PreFormatted Helpers
//
private extension LayoutManager {

    /// Draws a HTML Pre associated to a Range + Graphics Origin.
    ///
    func drawHTMLPre(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage = textStorage else {
            return
        }

        guard let context = UIGraphicsGetCurrentContext() else {
            preconditionFailure("When drawBackgroundForGlyphRange is called, the graphics context is supposed to be set by UIKit")
        }

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        //draw html pre paragraphs
        textStorage.enumerateAttribute(.paragraphStyle, in: characterRange, options: []){ (object, range, stop) in
            guard let paragraphStyle = object as? ParagraphStyle, paragraphStyle.htmlPre != nil else {
                return
            }

            let preGlyphRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)

            enumerateLineFragments(forGlyphRange: preGlyphRange) { (rect, usedRect, textContainer, glyphRange, stop) in
                let lineRect = rect.offsetBy(dx: origin.x, dy: origin.y)
                self.drawHTMLPre(in: lineRect.integral, with: context)
            }
        }

    }


    /// Draws a single HTML Pre Line Fragment, in the specified Rectangle, using a given Graphics Context.
    ///
    private func drawHTMLPre(in rect: CGRect, with context: CGContext) {
        guard let preBackgroundColor = preBackgroundColor else {
            return
        }
        preBackgroundColor.setFill()
        context.fill(rect)
    }
}

// MARK: - Lists Helpers
//
private extension LayoutManager {

    /// Draws a TextList associated to a Range + Graphics Origin.
    ///
    func drawLists(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage = textStorage else {
            return
        }

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        textStorage.enumerateParagraphRanges(spanning: characterRange) { (range, enclosingRange) in

            guard textStorage.string.isStartOfNewLine(atUTF16Offset: enclosingRange.location),
                let paragraphStyle = textStorage.attribute(.paragraphStyle, at: enclosingRange.location, effectiveRange: nil) as? ParagraphStyle,
                let list = paragraphStyle.lists.last
            else {
                return
            }
            let attributes = textStorage.attributes(at: enclosingRange.location, effectiveRange: nil)
            let glyphRange = self.glyphRange(forCharacterRange: enclosingRange, actualCharacterRange: nil)
            let markerRect = rectForItem(range: glyphRange, origin: origin, paragraphStyle: paragraphStyle)
            var markerNumber = textStorage.itemNumber(in: list, at: enclosingRange.location)
            var start = list.start ?? 1
            if list.reversed {
                markerNumber = -markerNumber
                if list.start == nil {
                    start = textStorage.numberOfItems(in: list, at: enclosingRange.location)
                }
            }
            markerNumber += start
            let markerString = list.style.markerText(forItemNumber: markerNumber)
            drawItem(markerString, in: markerRect, styled: attributes, at: enclosingRange.location)
        }
    }


    /// Returns the Rect for the MarkerItem at the specified Range + Origin, within a given ParagraphStyle.
    ///
    /// - Parameters:
    ///     - range: List Item's Range
    ///     - origin: List Origin
    ///     - paragraphStyle: Container Style
    ///
    /// - Returns: CGRect in which we should render the MarkerItem.
    ///
    private func rectForItem(range: NSRange, origin: CGPoint, paragraphStyle: ParagraphStyle) -> CGRect {
        var paddingY = CGFloat(0)
        var effectiveLineRange = NSRange.zero

        // Since only the first line in a paragraph can have a bullet, we only need the first line fragment.
        let lineFragmentUsedRect = self.lineFragmentUsedRect(forGlyphAt: range.location, effectiveRange: &effectiveLineRange)

        // Whenever we're rendering an Item with multiple lines, within a Blockquote, we need to account for the
        // paragraph spacing. Otherwise the Marker will show up slightly off.
        //
        // Ref. #645
        //
        if effectiveLineRange.length < range.length && paragraphStyle.blockquotes.isEmpty == false {
            paddingY = Metrics.paragraphSpacing
        }

        return CGRect(origin: CGPoint(x: origin.x, y: origin.y + lineFragmentUsedRect.origin.y + paddingY), size: lineFragmentUsedRect.size)
    }


    /// Draws the specified List Item Number, at a given location.
    ///
    /// - Parameters:
    ///     - markerText: Marker String of the item to be drawn
    ///     - rect: Visible Rect in which the Marker should be rendered
    ///     - styled: Paragraph attributes associated to the list
    ///     - location: Text Location that should get the marker rendered.
    ///
    private func drawItem(_ markerText: String, in rect: CGRect, styled paragraphAttributes: [NSAttributedString.Key: Any], at location: Int) {
        guard let style = paragraphAttributes[.paragraphStyle] as? ParagraphStyle else {
            return
        }
        let markerAttributes = markerAttributesBasedOnParagraph(attributes: paragraphAttributes)
        let markerAttributedText = NSAttributedString(string: markerText, attributes: markerAttributes)

        let markerWidth = markerAttributedText.size().width * 1.5
        let markerHeight = markerAttributedText.size().height
        let yOffset = CGFloat(rect.size.height / 2.0 - markerHeight / 2.0)
        var xOffset = CGFloat(0)
        let indentWidth = style.indentToLast(TextList.self)

        // If the marker width is larger than the indent available let's offset the area to draw to the left
        if markerWidth > indentWidth {
            xOffset = indentWidth - markerWidth
        }

        var markerRect = rect.offsetBy(dx: xOffset, dy: yOffset)

        markerRect.size.width = max(indentWidth, markerWidth)
        markerRect.size.height = markerHeight

        markerAttributedText.draw(in: markerRect)
    }


    /// Returns the Marker Text Attributes, based on a collection that defines Regular Text Attributes.
    ///
    private func markerAttributesBasedOnParagraph(attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var resultAttributes = attributes
        let indent: CGFloat = CGFloat(Metrics.tabStepInterval)

        resultAttributes[.paragraphStyle] = markerParagraphStyle(indent: indent)
        resultAttributes.removeValue(forKey: .underlineStyle)
        resultAttributes.removeValue(forKey: .strikethroughStyle)
        resultAttributes.removeValue(forKey: .link)

        if let font = resultAttributes[.font] as? UIFont {
            resultAttributes[.font] = fixFontForMarkerAttributes(font: font)
        }

        return resultAttributes
    }


    /// Returns the Marker Paragraph Attributes
    ///
    private func markerParagraphStyle(indent: CGFloat) -> NSParagraphStyle {

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .right
        paragraphStyle.tailIndent = -indent
        paragraphStyle.lineBreakMode = .byClipping

        return paragraphStyle
    }


    /// Fixes a UIFont Instance for List Marker Usage:
    ///
    /// - Emoji Font is replaced by the System's font, of matching size
    /// - Bold and Italic styling is neutralized
    ///
    private func fixFontForMarkerAttributes(font: UIFont) -> UIFont {
        guard !font.isAppleEmojiFont else {
            return UIFont.systemFont(ofSize: font.pointSize)
        }

        var traits = font.fontDescriptor.symbolicTraits
        traits.remove(.traitBold)
        traits.remove(.traitItalic)

        if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: descriptor, size: font.pointSize)
        } else {
            // Don't touch the font if we cannot remove the symbolic traits.
            return font
        }
    }
}

extension LayoutManager {

    override func underlineGlyphRange(_ glyphRange: NSRange, underlineType underlineVal: NSUnderlineStyle, lineFragmentRect lineRect: CGRect, lineFragmentGlyphRange lineGlyphRange: NSRange, containerOrigin: CGPoint) {
        guard let textStorage = textStorage else {
            return
        }
        let underlinedString = textStorage.attributedSubstring(from: glyphRange).string
        var updatedGlyphRange = glyphRange
        if glyphRange.endLocation == lineGlyphRange.endLocation,
            underlinedString.hasSuffix(String.init(.paragraphSeparator)) || underlinedString.hasSuffix(String.init(.lineSeparator)) || underlinedString.hasSuffix(String.init(.carriageReturn)) || underlinedString.hasSuffix(String.init(.lineFeed))
        {
            updatedGlyphRange = NSRange(location: glyphRange.location, length: glyphRange.length - 1)
        }
        drawUnderline(forGlyphRange: updatedGlyphRange, underlineType: underlineVal, baselineOffset: 0, lineFragmentRect: lineRect, lineFragmentGlyphRange: lineGlyphRange, containerOrigin: containerOrigin)
    }
}

