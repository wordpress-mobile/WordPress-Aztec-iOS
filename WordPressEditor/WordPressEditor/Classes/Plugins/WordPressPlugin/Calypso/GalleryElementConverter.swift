import Aztec
import Foundation

/// Provides a representation for `<img>` element.
///
class GalleryElementConverter: AttachmentElementConverter {
    
    // MARK: - Supported Attributes
    
    private enum SupportedAttributeName: String {
        case columns = "columns"
        case ids = "ids"
        case order = "order"
        case orderBy = "orderBy"
    }
    
    // MARK: - AttachmentElementConverter
    
    typealias AttachmentType = GalleryAttachment
    
    func convert(
        _ element: ElementNode,
        inheriting attributes: [NSAttributedStringKey: Any],
        childrenSerializer serializeChildren: ChildrenSerializer) -> (attachment: GalleryAttachment, string: NSAttributedString) {
        
        let attachment = self.attachment(for: element)
        
        return (attachment, NSAttributedString(attachment: attachment, attributes: attributes))
    }
    
    // MARK: - Attachment Creation
    
    private func attachment(for element: ElementNode) -> GalleryAttachment {
        
        let gallery = GalleryAttachment(identifier: UUID().uuidString)
        
        loadAttributes(element.attributes, into: gallery)
        
        return gallery
    }
}

// MARK: - Retrieveing Supported Attributes

private extension GalleryElementConverter {
    
    private func loadAttributes(_ attributes: [Attribute], into gallery: GalleryAttachment) {
        gallery.columns = getColumns(from: attributes)
        gallery.ids = getIDs(from: attributes)
        gallery.order = getOrder(from: attributes)
        gallery.orderBy = getOrderBy(from: attributes)
        gallery.extraAttributes = getUnsupportedAttribute(attributes)
    }
    
    private func getColumns(from attributes: [Attribute]) -> Int? {
        return valueOfAttribute(.columns, in: attributes, withType: Int.self)
    }
    
    private func getIDs(from attributes: [Attribute]) -> [Int]? {
        return valueOfAttribute(.ids, in: attributes, withType: [Int].self)
    }
    
    private func getOrder(from attributes: [Attribute]) -> GalleryAttachment.Order? {
        return attribute(.order, in: attributes, withType: GalleryAttachment.Order.self)
    }
    
    private func getOrderBy(from attributes: [Attribute]) -> GalleryAttachment.OrderBy? {
        return attribute(.orderBy, in: attributes, withType: GalleryAttachment.OrderBy.self)
    }
    
    private func getUnsupportedAttribute(_ attributes: [Attribute]) -> [String: String] {
        
        var output = [String: String]()
        
        for attribute in attributes {
            guard !["columns", "ids", "order", "orderby"].contains(attribute.name),
                let value = attribute.value.toString() else {
                    continue
            }
            
            output[attribute.name] = value
        }
        
        return output
    }
}

// MARK: - Attribute Retrieval Logic

private extension GalleryElementConverter {
    
    /// Returns an attribute after mapping its value into a `RawRepresentable` type that has
    /// `String` as its `RawType`.
    ///
    private func attribute<T: RawRepresentable>(_ name: SupportedAttributeName, in attributes: [Attribute], withType type: T.Type) -> T? where T.RawValue == String {
        guard let attributeStringValue = valueOfAttribute(name, in: attributes, withType: String.self),
            let result = T.init(rawValue: attributeStringValue) else {
                return nil
        }
        
        return result
    }
    
    /// Maps a supported attribute to `[Int]?`.
    ///
    /// - Parameters:
    ///     - name: the name of the supported attribute.
    ///     - attributes: the list of attributes where the attribute should be searched.
    ///     - type: the output type.
    ///
    /// - Returns: the mapped attribute, or `nil` if not found.
    ///
    private func valueOfAttribute(_ name: SupportedAttributeName, in attributes: [Attribute], withType type: [Int].Type) -> [Int]? {
        guard let attributeStringValue = valueOfAttribute(name, in: attributes, withType: String.self) else {
            return nil
        }
        
        return attributeStringValue.split(separator: ",").compactMap { substring -> Int? in
            return Int(substring)
        }
    }
    
    /// Returns an attribute after mapping its value into a `RawRepresentable` type that has
    /// `String` as its `RawType`.
    ///
    private func valueOfAttribute(_ name: SupportedAttributeName, in attributes: [Attribute], withType type: Int.Type) -> Int? {
        guard let attributeStringValue = valueOfAttribute(name, in: attributes, withType: String.self),
            let attributeIntValue = Int(attributeStringValue) else {
                return nil
        }
        
        return attributeIntValue
    }
    
    /// Returns an attribute after mapping its value into a `RawRepresentable` type that has
    /// `String` as its `RawType`.
    ///
    private func valueOfAttribute(_ name: SupportedAttributeName, in attributes: [Attribute], withType type: String.Type) -> String? {
        guard let attribute = attributes.first(where: { $0.name == name.rawValue }),
            let attributeValue = attribute.value.toString() else {
                return nil
        }
        
        return attributeValue
    }
}
