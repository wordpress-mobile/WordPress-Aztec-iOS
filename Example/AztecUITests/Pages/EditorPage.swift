import Foundation
import XCTest

class EditorPage: BasePage {
    
    var textField: String!
    var type: String!
    var textView: XCUIElement

    private var titleTextField = "Title"
    private var richTextField = "richContentView"
    private var htmlTextField = "HTMLContentView"
    
    var mediaButton = XCUIApplication().buttons["formatToolbarInsertMedia"]
    var headerButton = XCUIApplication().buttons["formatToolbarSelectParagraphStyle"]
    var boldButton = XCUIApplication().buttons["formatToolbarToggleBold"]
    var italicButton = XCUIApplication().buttons["formatToolbarToggleItalic"]
    var underlineButton = XCUIApplication().buttons["formatToolbarToggleUnderline"]
    var strikethroughButton = XCUIApplication().buttons["formatToolbarToggleStrikethrough"]
    var blockquoteButton = XCUIApplication().buttons["formatToolbarToggleBlockquote"]
    var unorderedlistButton = XCUIApplication().buttons["formatToolbarToggleListUnordered"]
    var linkButton = XCUIApplication().buttons["formatToolbarInsertLink"]
    var horizontalrulerButton = XCUIApplication().buttons["formatToolbarInsertHorizontalRuler"]
    var sourcecodeButton = XCUIApplication().buttons["formatToolbarToggleHtmlView"]
    var moreButton = XCUIApplication().buttons["formatToolbarInsertMore"]

    init(type: String) {
        textField = ""
        self.type = type
        switch type {
        case "rich":
            textField = richTextField
        case "html":
            textField = htmlTextField
        default:
            textField = "invalid locator. check Editor.init type param"
        }
        textView = XCUIApplication().textViews[textField]
        super.init(element: textView)
      
        showOptionsStrip()
    }
    
    func showOptionsStrip() -> Void {
        textView.tap()
        expandOptionsSctrip()
    }
    
    func expandOptionsSctrip() -> Void {
        let expandButton = app.children(matching: .window).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).element
        let htmlButton = app.scrollViews.otherElements.buttons[elementStringIDs.sourcecodeButton]
        
        if expandButton.exists && expandButton.isHittable && !htmlButton.exists {
            expandButton.tap()
        }
    }
    
    func addList(type: String) -> EditorPage {
        toolbarButtonTap(locator: elementStringIDs.unorderedlistButton)
        var listType = ""
        if type == "ul" {
            listType = elementStringIDs.unorderedListOption
        } else if type == "ol" {
            listType = elementStringIDs.orderedListOption
        }
        app.tables.staticTexts[listType].tap()
        
        return self
    }
    
    func addListWithLines(type: String, lines: Array<String>) -> EditorPage {
        addList(type: type)

        let returnButton = app.buttons["Return"]
        for (index, line) in lines.enumerated() {
            enterText(text: line)
            if index != (lines.count - 1) {
                returnButton.tap()
            }
        }
        return self
    }
    
    /**
     Tapping on toolbar button. And swipes if needed.
     */
    func toolbarButtonTap(locator: String) -> EditorPage {
        let elementsQuery = app.scrollViews.otherElements
        let button = elementsQuery.buttons[locator]
        let swipeElement = elementsQuery.buttons[elementStringIDs.mediaButton].isHittable ? elementsQuery.buttons[elementStringIDs.mediaButton] : elementsQuery.buttons[elementStringIDs.linkButton]
        
        if !button.exists || !button.isHittable {
            swipeElement.swipeLeft()
        }
        button.tap()
        
        return self
    }
    
    /**
    Tapping in to textView by specific coordinate. Its always tricky to know what cooridnates to click.
     Here is a list of "known" coordinates:
     30:32 - first word in 2d indented line (list)
     30:72 - first word in 3d intended line (blockquote)
    */
    func tapByCordinates(x: Int, y: Int) -> EditorPage {
//        textView.coordinate(withNormalizedOffset:CGVector.zero).tap()
        let vector = CGVector(dx: textView.frame.minX + CGFloat(x), dy: textView.frame.minY + CGFloat(y))
        textView.coordinate(withNormalizedOffset:CGVector.zero).withOffset(vector).tap()
        sleep(1) // to make sure that "paste" manu wont show up.
        return self
    }
    
    /**
     Switches between Rich and HTML view.
     */
    func switchContentView() -> EditorPage {
        toolbarButtonTap(locator: elementStringIDs.sourcecodeButton)
        
        let newType = type == "rich" ? "html" : "rich"
        return EditorPage.init(type: newType)
    }
    
    /**
     Common method to type in different text fields
     */
    func enterText(text: String) -> EditorPage {
        textView.typeText(text)
        return self
    }
    
    /**
     Enters text into title field.
     - Parameter text: the test to enter into the title
     */
    func enterTextInTitle(text: String) -> Void {
        app.textViews[titleTextField].typeText(text)
    }
    
    func deleteText(chars: Int) -> EditorPage {
        for _ in 1...chars {
            app.keys["delete"].tap()
        }
        
        return self
    }
    
    func gotoRootPage() -> BlogsPage {
        app.navigationBars["AztecExample.EditorDemo"].buttons["Root View Controller"].tap()
        return BlogsPage.init()
    }
    
    func getViewContent() -> String {
        if  type == "rich" {
            return getTextContent()
        }
        
        return getHTMLContent()
    }
    
    /**
     Selects all entered text in provided textView element
     */
    func selectAllText() -> EditorPage {
        textView.tap()
        textView.coordinate(withNormalizedOffset:CGVector.zero).tap()

        textView.press(forDuration: 0.9)
        app.menuItems["Select All"].tap()
        
        return self
    }
    
    private func getHTMLContent() -> String {
        let text = textView.value as! String
        
        // Remove spaces between HTML tags.
        let regex = try! NSRegularExpression(pattern: ">\\s+?<", options: .caseInsensitive)
        let range = NSMakeRange(0, text.count)
        let strippedText = regex.stringByReplacingMatches(in: text, options: .reportCompletion, range: range, withTemplate: "><")
        
        return strippedText
    }
    
    private func getTextContent() -> String {
        let text = textView.value as! String
        return text
    }
}

