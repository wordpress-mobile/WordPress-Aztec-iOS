import Foundation
import UIKit


// MARK: - UIFont Traits Helpers
//
extension UIFont {

    /// Returns a new instance of the current font with its SymbolicTraits Updated.
    ///
    /// - Parameters:
    ///     - traits: Traits to be updated
    ///     - enable: Boolean indicating whether we should insert or remove the specified trait.
    ///
    /// - Returns: A new UIFont with the same descriptors as the current instance, but with its traits updated, as specified.
    ///
    func modifyTraits(_ traits: UIFontDescriptor.SymbolicTraits, enable: Bool) -> UIFont {
        let descriptor = fontDescriptor
        var newTraits = descriptor.symbolicTraits

        if enable {
            newTraits.insert(traits)
        } else {
            newTraits.remove(traits)
        }

        let familyDescriptor = descriptor.withFamily(familyName)
        guard let newDescriptor = familyDescriptor.withSymbolicTraits(newTraits) else {
            // A nil descriptor can be returned whenever the requested font cannot be found.
            // This is a very viable scenario, and our default handling mechanism for it is to
            // return the original, unmodified font.
            //
            
            // MARK: Fix oblique type for Chinese
            if newTraits.contains(.traitItalic) && familyDescriptor.postscriptName.hasPrefix(".PingFangSC") {
                newTraits.remove(.traitItalic)
                if let newDescriptor = familyDescriptor.withSymbolicTraits(newTraits) {
                    return UIFont(descriptor: newDescriptor, size: pointSize)
                }
            }
            
            return self
        }

        return UIFont(descriptor: newDescriptor, size: pointSize)
    }


    /// Returns a boolean indicating if the specified trait is present in the font's descriptor
    ///
    /// - Parameters traits: Traits to be checked.
    ///
    /// - Returns: True if the specified trait was found.
    ///
    func containsTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> Bool {
        return fontDescriptor.symbolicTraits.contains(traits)
    }
}
