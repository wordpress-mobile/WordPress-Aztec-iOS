import Foundation
import XCTest
@testable import Aztec


class TextStorageTests: XCTestCase
{

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: - Test Traits

    func testFontTraitExistsAtIndex() {
        let attributes = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 10)
        ]
        let mockDelegate = MockAttachmentsDelegate()
        let storage = TextStorage()
        storage.attachmentsDelegate = mockDelegate
        storage.append(NSAttributedString(string: "foo"))
        storage.append(NSAttributedString(string: "bar", attributes: attributes))
        storage.append(NSAttributedString(string: "baz"))

        // Foo
        XCTAssert(!storage.fontTrait(.traitBold, existsAtIndex: 0))
        XCTAssert(!storage.fontTrait(.traitBold, existsAtIndex: 2))
        // Bar
        XCTAssert(storage.fontTrait(.traitBold, existsAtIndex: 3))
        XCTAssert(storage.fontTrait(.traitBold, existsAtIndex: 4))
        XCTAssert(storage.fontTrait(.traitBold, existsAtIndex: 5))
        // Baz
        XCTAssert(!storage.fontTrait(.traitBold, existsAtIndex: 6))
        XCTAssert(!storage.fontTrait(.traitBold, existsAtIndex: 8))
    }

    func testFontTraitSpansRange() {
        let attributes = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 10)
        ]
        let mockDelegate = MockAttachmentsDelegate()
        let storage = TextStorage()
        storage.attachmentsDelegate = mockDelegate
        storage.append(NSAttributedString(string: "foo"))
        storage.append(NSAttributedString(string: "bar", attributes: attributes))
        storage.append(NSAttributedString(string: "baz"))

        XCTAssert(storage.fontTrait(.traitBold, spansRange: NSRange(location: 3, length: 3)))
        XCTAssert(!storage.fontTrait(.traitBold, spansRange: NSRange(location: 0, length: 9)))

    }

    func testToggleTraitInRange() {
        let attributes = [
            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 10)
        ]
        let mockDelegate = MockAttachmentsDelegate()
        let storage = TextStorage()
        storage.attachmentsDelegate = mockDelegate
        storage.append(NSAttributedString(string: "foo"))
        storage.append(NSAttributedString(string: "bar", attributes: attributes))
        storage.append(NSAttributedString(string: "baz"))

        let range = NSRange(location: 3, length: 3)

        // Confirm the trait exists
        XCTAssert(storage.fontTrait(.traitBold, spansRange: range))

        // Toggle it.
        storage.toggle(.traitBold, inRange: range)

        // Confirm the trait does not exist.
        XCTAssert(!storage.fontTrait(.traitBold, spansRange: range))

        // Toggle it again.
        storage.toggle(.traitBold, inRange: range)

        // Confirm the trait was restored
        XCTAssert(storage.fontTrait(.traitBold, spansRange: range))
    }

    func testDelegateCallbackWhenAttachmentRemoved() {
        let mockDelegate = MockAttachmentsDelegate()
        let storage = TextStorage()
        storage.attachmentsDelegate = mockDelegate

        let attachment = storage.insertImage(sourceURL: URL(string:"test://")!, atPosition: 0, placeHolderImage: UIImage())

        storage.replaceCharacters(in: NSRange(location: 0, length: 1) , with: NSAttributedString(string:""))

        XCTAssertTrue(mockDelegate.deletedAttachmendIDCalledWithString == attachment.identifier)
    }

    class MockAttachmentsDelegate: TextStorageAttachmentsDelegate {

        var deletedAttachmendIDCalledWithString: String?

        func storage(_ storage: TextStorage, deletedAttachmentWith attachmentID: String) {
            deletedAttachmendIDCalledWithString = attachmentID
        }

        func storage(_ storage: TextStorage, urlFor imageAttachment: ImageAttachment) -> URL {
            return URL(string:"test://")!
        }

        func storage(_ storage: TextStorage, missingImageFor attachment: NSTextAttachment) -> UIImage {
            return UIImage()
        }

        func storage(_ storage: TextStorage, attachment: NSTextAttachment, imageFor url: URL, onSuccess success: @escaping (UIImage) -> (), onFailure failure: @escaping () -> ()) -> UIImage {
            return UIImage()
        }

        func storage(_ storage: TextStorage, boundsFor attachment: NSTextAttachment, with lineFragment: CGRect) -> CGRect {
            return .zero
        }

        func storage(_ storage: TextStorage, imageFor attachment: NSTextAttachment, with size: CGSize) -> UIImage? {
            return UIImage()
        }
    }

    func testRemovalOfAttachment() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        let attachment = storage.insertImage(sourceURL: URL(string:"test://")!, atPosition: 0, placeHolderImage: UIImage())

        storage.remove(attachmentID: attachment.identifier)

        XCTAssertTrue(mockDelegate.deletedAttachmendIDCalledWithString == attachment.identifier)
    }

    func testInsertImage() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        let attachment = storage.insertImage(sourceURL: URL(string: "https://wordpress.com")!, atPosition: 0, placeHolderImage: UIImage())
        let html = storage.getHTML()

        XCTAssertEqual(attachment.url, URL(string: "https://wordpress.com"))
        XCTAssertEqual(html, "<img src=\"https://wordpress.com\">")
    }

    func testUpdateImage() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate
        let url = URL(string: "https://wordpress.com")!
        let attachment = storage.insertImage(sourceURL: url, atPosition: 0, placeHolderImage: UIImage())
        storage.update(attachment: attachment, alignment: .left, size: .medium, url: url)
        let html = storage.getHTML()

        XCTAssertEqual(attachment.url, url)
        XCTAssertEqual(html, "<img src=\"https://wordpress.com\" class=\"alignleft size-medium\">")
    }

    func testUpdateHtmlAttachmentEffectivelyUpdatesTheDom() {
        let initialHTML = "<unknown>html</unknown>"
        let updatedHTML = "<updated>NEW HTML</updated>"
        let finalHTML = "<updated>NEW HTML</updated>"

        // Setup
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        storage.setHTML(initialHTML, withDefaultFontDescriptor: UIFont.systemFont(ofSize: 10).fontDescriptor)

        // Find the Attachment
        var theAttachment: HTMLAttachment!
        storage.enumerateAttachmentsOfType(HTMLAttachment.self, range: nil) { (attachment, _, _) in
            theAttachment = attachment
        }

        // Update
        XCTAssertNotNil(theAttachment)
        storage.update(attachment: theAttachment, html: updatedHTML)

        // Verify
        XCTAssertEqual(storage.getHTML(), finalHTML)
    }

    func testBlockquoteToggle1() {
        let mockDelegate = MockAttachmentsDelegate()
        let storage = TextStorage()
        storage.attachmentsDelegate = mockDelegate
        storage.append(NSAttributedString(string: "Apply a blockquote"))
        let blockquoteFormatter = BlockquoteFormatter()
        storage.toggle(formatter: blockquoteFormatter, at: storage.rangeOfEntireString)

        var html = storage.getHTML()

        XCTAssertEqual(html, "<blockquote>Apply a blockquote</blockquote>")

        storage.toggle(formatter: blockquoteFormatter, at: storage.rangeOfEntireString)

        html = storage.getHTML()

        XCTAssertEqual(html, "Apply a blockquote")
    }

    func testBlockquoteToggle2() {
        let mockDelegate = MockAttachmentsDelegate()
        let storage = TextStorage()
        storage.attachmentsDelegate = mockDelegate
        storage.append(NSAttributedString(string: "Hello 🌎!\nApply a blockquote!"))
        let blockquoteFormatter = BlockquoteFormatter()

        let range = NSRange(location: 9, length: 19)
        let utf16Range = storage.string.utf16NSRange(from: range)

        storage.toggle(formatter: blockquoteFormatter, at: utf16Range)

        let html = storage.getHTML()

        XCTAssertEqual(html, "Hello &#x1F30E;!<br><blockquote>Apply a blockquote!</blockquote>")
    }

    func testLinkInsert() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        storage.append(NSAttributedString(string: "Apply a link"))
        let linkFormatter = LinkFormatter()
        linkFormatter.attributeValue = URL(string: "www.wordpress.com")!
        storage.toggle(formatter: linkFormatter, at: storage.rangeOfEntireString)

        var html = storage.getHTML()

        XCTAssertEqual(html, "<a href=\"www.wordpress.com\">Apply a link</a>")

        storage.toggle(formatter:linkFormatter, at: storage.rangeOfEntireString)

        html = storage.getHTML()

        XCTAssertEqual(html, "Apply a link")
    }

    func testHeaderToggle() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate
        
        storage.append(NSAttributedString(string: "Apply a header"))
        let formatter = HeaderFormatter(headerLevel: .h1)
        storage.toggle(formatter: formatter, at: storage.rangeOfEntireString)

        var html = storage.getHTML()

        XCTAssertEqual(html, "<h1>Apply a header</h1>")

        storage.toggle(formatter:formatter, at: storage.rangeOfEntireString)

        html = storage.getHTML()

        XCTAssertEqual(html, "Apply a header")
    }

    /// This test ensures that when applying a header style on top of another style the replacement occurs correctly.
    ///
    func testSwitchHeaderStyleToggle() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        storage.append(NSAttributedString(string: "Apply a header"))
        let formatterH1 = HeaderFormatter(headerLevel: .h1)
        let formatterH2 = HeaderFormatter(headerLevel: .h2)
        storage.toggle(formatter: formatterH1, at: storage.rangeOfEntireString)

        var html = storage.getHTML()

        XCTAssertEqual(html, "<h1>Apply a header</h1>")

        storage.toggle(formatter:formatterH2, at: storage.rangeOfEntireString)

        html = storage.getHTML()

        XCTAssertEqual(html, "<h2>Apply a header</h2>")
    }


    /// This test check if the insertion of two images one after the other works correctly and to img tag are inserted
    ///
    func testInsertOneImageAfterTheOther() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        let firstAttachment = storage.insertImage(sourceURL: URL(string: "https://wordpress.com")!, atPosition: 0, placeHolderImage: UIImage())
        let secondAttachment = storage.insertImage(sourceURL: URL(string: "https://wordpress.org")!, atPosition: 1, placeHolderImage: UIImage())
        let html = storage.getHTML()

        XCTAssertEqual(firstAttachment.url, URL(string: "https://wordpress.com"))
        XCTAssertEqual(secondAttachment.url, URL(string: "https://wordpress.org"))
        XCTAssertEqual(html, "<img src=\"https://wordpress.com\"><img src=\"https://wordpress.org\">")
    }

    /// This test check if the insertion of two images one after the other works correctly and to img tag are inserted
    ///
    func testInsertSameImageAfterTheOther() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        let firstAttachment = storage.insertImage(sourceURL: URL(string: "https://wordpress.com")!, atPosition: 0, placeHolderImage: UIImage())
        let secondAttachment = storage.insertImage(sourceURL: URL(string: "https://wordpress.com")!, atPosition: 1, placeHolderImage: UIImage())
        let html = storage.getHTML()

        XCTAssertEqual(firstAttachment.url, URL(string: "https://wordpress.com"))
        XCTAssertEqual(secondAttachment.url, URL(string: "https://wordpress.com"))
        XCTAssertEqual(html, "<img src=\"https://wordpress.com\"><img src=\"https://wordpress.com\">")
    }

    /// This test verifies if the `removeTextAttachements` call effectively nukes all of the TextAttachments present
    /// in the storage.
    ///
    func testRemoveAllTextAttachmentsNukeTextAttachmentInstances() {
        // Mockup Storage
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        let sample = NSMutableAttributedString(string: "Some string here")
        storage.append(sample)

        // New string with 10 attachments
        var identifiers = [String]()
        let count = 10

        for _ in 0 ..< count {
            let sourceURL = URL(string:"test://")!
            let attachment = storage.insertImage(sourceURL: sourceURL, atPosition: 0, placeHolderImage: UIImage())

            identifiers.append(attachment.identifier)
        }


        // Verify the attachments are there
        for identifier in identifiers {
            XCTAssertNotNil(storage.attachment(withId: identifier))
        }

        // Nuke
        storage.removeMediaAttachments()

        // Verify the attachments are there
        for identifier in identifiers {
            XCTAssertNil(storage.attachment(withId: identifier))
        }
    }

    /// This test check if the insertion of an horizontal ruler works correctly and the hr tag is inserted
    ///
    func testReplaceRangeWithHorizontalRuler() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        storage.replaceRangeWithHorizontalRuler(.zero)
        let html = storage.getHTML()

        XCTAssertEqual(html, "<hr>")
    }

    /// This test check if the insertion of antwo horizontal ruler works correctly and the hr tag(s) are inserted
    ///
    func testReplaceRangeWithHorizontalRulerGeneratesExpectedHTMLWhenExecutedSequentially() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        storage.replaceRangeWithHorizontalRuler(.zero)
        storage.replaceRangeWithHorizontalRuler(.zero)
        let html = storage.getHTML()

        XCTAssertEqual(html, "<hr><hr>")
    }

    /// This test check if the insertion of an horizontal ruler over an image attachment works correctly and the hr tag is inserted
    ///
    func testReplaceRangeWithHorizontalRulerRulerOverImage() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        let _ = storage.insertImage(sourceURL: URL(string: "https://wordpress.com")!, atPosition: 0, placeHolderImage: UIImage())
        storage.replaceRangeWithHorizontalRuler(NSRange(location: 0, length:1))
        let html = storage.getHTML()

        XCTAssertEqual(html, "<hr>")
    }

    /// This test check if the insertion of a Comment Attachment works correctly and the expected tag gets inserted
    ///
    func testReplaceRangeWithCommentAttachmentGeneratesExpectedHTMLComment() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        storage.replaceRangeWithCommentAttachment(.zero, text: "more", attributes: [:])
        let html = storage.getHTML()

        XCTAssertEqual(html, "<!--more-->")
    }

    /// This test check if the insertion of a Comment Attachment works correctly and the expected tag gets inserted
    ///
    func testReplaceRangeWithCommentAttachmentDoNotCrashTheEditorWhenCalledSequentially() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate

        storage.replaceRangeWithCommentAttachment(.zero, text: "more", attributes: [:])
        storage.replaceRangeWithCommentAttachment(.zero, text: "some other comment should go here", attributes: [:])

        let html = storage.getHTML()

        XCTAssertEqual(html, "<!--some other comment should go here--><!--more-->")
    }

    /// This test verifies if we can delete all the content from a storage object that has html with a comment
    ///
    func testDeleteAllSelectionWhenContentHasComments() {
        let storage = TextStorage()
        let mockDelegate = MockAttachmentsDelegate()
        storage.attachmentsDelegate = mockDelegate
        
        let commentString = "This is a comment"
        let html = "<!--\(commentString)-->"
        storage.setHTML(html, withDefaultFontDescriptor: UIFont.systemFont(ofSize: 14).fontDescriptor)
        storage.replaceCharacters(in: NSRange(location: 0, length: 1), with: NSAttributedString(string: ""))

        let resultHTML = storage.getHTML()

        XCTAssertEqual(String(), resultHTML)
    }
}
