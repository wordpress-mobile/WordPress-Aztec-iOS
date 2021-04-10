import Foundation
import UIKit


// MARK: - Blockquote Formatter
//
class BlockquoteFormatter: ParagraphAttributeFormatter {

    typealias TextAttributes = [NSAttributedString.Key: Any]?
    
    /// Attributes to be added by default
    ///
    let typingAttributes: TextAttributes
    
    let defaultTextAttributes: TextAttributes
    let borderColors: [UIColor]?

    /// Tells if the formatter is increasing the depth of a blockquote or simple changing the current one if any
    let increaseDepth: Bool
    
    let currentDepth: Int
    
    /// Designated Initializer
    ///
    init(typingAttributes: TextAttributes = nil, defaultTextAttributes: TextAttributes = nil, borderColors: [UIColor]? = nil, increaseDepth: Bool = false, currentDepth: Int = 0) {
        self.typingAttributes = typingAttributes
        self.defaultTextAttributes = defaultTextAttributes
        self.borderColors = borderColors
        self.increaseDepth = increaseDepth
            
        self.currentDepth = typingAttributes?.paragraphStyle().blockquoteDepth ?? 0
    }
    
    private func colorForNext(depth: Int) -> UIColor {
        guard let colors = borderColors else { return UIColor.darkText }

        if increaseDepth {
            let index = min(depth+1, colors.count-1)
            return colors[index]
        } else {
            return colors[0]
        }
    }
    
    private func colorForPrev(depth: Int) -> UIColor {
        guard let colors = borderColors else { return UIColor.darkText }

        //increaseDepth is not used here as shift tab and pressing quote toggle button behave differently
        if depth > 0 {
            let positiveIndex = max(depth-1, 0)
            let index = min(positiveIndex, colors.count-1)
            return colors[index]
        } else {
            guard let att = defaultTextAttributes else { return UIColor.darkText }
            return att[.foregroundColor] as! UIColor
        }
    }

    // MARK: - Overwriten Methods

    func apply(to attributes: [NSAttributedString.Key: Any], andStore representation: HTMLRepresentation?) -> [NSAttributedString.Key: Any] {
        let newParagraphStyle = ParagraphStyle()
        
        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle {
            newParagraphStyle.setParagraphStyle(paragraphStyle)
        }
        
        let newQuote = Blockquote(with: representation)
        
        if newParagraphStyle.blockquotes.isEmpty || increaseDepth {
            newParagraphStyle.insertProperty(newQuote, afterLastOfType: Blockquote.self)
        } else {
            newParagraphStyle.replaceProperty(ofType: Blockquote.self, with: newQuote)
        }

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle
        resultingAttributes[.foregroundColor] = colorForNext(depth: currentDepth)
        
        
        return resultingAttributes
    }

    func remove(from attributes:[NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        guard let paragraphStyle = attributes[.paragraphStyle] as? ParagraphStyle,
            !paragraphStyle.blockquotes.isEmpty
        else {
            return attributes
        }

        let newParagraphStyle = ParagraphStyle()
        newParagraphStyle.setParagraphStyle(paragraphStyle)        
        newParagraphStyle.removeProperty(ofType: Blockquote.self)

        var resultingAttributes = attributes
        resultingAttributes[.paragraphStyle] = newParagraphStyle
        
        //remove quote color
        resultingAttributes.removeValue(forKey: .foregroundColor)
        
        resultingAttributes[.foregroundColor] = colorForPrev(depth: currentDepth)

                
        return resultingAttributes
    }

    func present(in attributes: [NSAttributedString.Key: Any]) -> Bool {
        guard let style = attributes[.paragraphStyle] as? ParagraphStyle else {
            return false
        }
        return !style.blockquotes.isEmpty
    }
    
    static func blockquotes(in attributes: [NSAttributedString.Key: Any]) -> [Blockquote] {
        let style = attributes[.paragraphStyle] as? ParagraphStyle
        return style?.blockquotes ?? []
    }
}
