import XCTest

class HighPriorityIssuesTests: XCTestCase {
        
    private var app: XCUIApplication!
    private var richTextField: XCUIElement!
    
    override func setUp() {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIDevice.shared().orientation = .portrait
        app = XCUIApplication()
        app.launch()
        
        let tablesQuery = app.tables
        tablesQuery.staticTexts[elementStringIDs.emptyDemo].tap()
        
        let richTextField = app.textViews[elementStringIDs.richTextField]
        richTextField.tap()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // Github issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/385
    func testLongTitle() {
        //    Title line height is about 22px, so it might be useing for comparing the height difference should make it precise.
        //    But may be fragile due to different font sizes etc
        let titleLineHeight = 22
        
        let titleTextView = app.textViews[elementStringIDs.titleTextField]
        titleTextView.tap()
        
        let oneLineTitleHeight = Int(titleTextView.frame.height)
        
        titleTextView.typeText("very very very very very very long title in a galaxy not so far away")
        let twoLineTitleHeight = Int(titleTextView.frame.height)
        XCTAssert(twoLineTitleHeight - oneLineTitleHeight == titleLineHeight )
        //        XCTAssert(oneLineTitleHeight < twoLineTitleHeight)
    }
    
    func testNewlinesInTitle() {
        //    Title line height is about 22px, so it might be useing for comparing the height difference should make it precise.
        //    But may be fragile due to different font sizes etc
        let titleLineHeight = 22
        
        let titleTextView = app.textViews[elementStringIDs.titleTextField]
        titleTextView.tap()
        
        titleTextView.typeText("line 1")
        let oneLineTitleHeight = Int(titleTextView.frame.height)
        
        titleTextView.typeText("\nline 2")
        let twoLineTitleHeight = Int(titleTextView.frame.height)
        XCTAssert(twoLineTitleHeight - oneLineTitleHeight == titleLineHeight )
        //        XCTAssert(oneLineTitleHeight < twoLineTitleHeight)
        
        titleTextView.typeText("\nline 3")
        let threeLineTitleHeight = Int(titleTextView.frame.height)
        XCTAssert(threeLineTitleHeight - twoLineTitleHeight == titleLineHeight )
        //        XCTAssert(twoLineTitleHeight < threeLineTitleHeight)
    }
    
    // Github issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/675
    func testInfiniteLoopOnAssetDownload() {
        switchContentView()
        enterTextInHTML(text: "<img src=\"https://someinvalid.url/with-an-invalid-resource\">")
        switchContentView()
        gotoRootPage()
        
        let editorDemoButton = app.tables.staticTexts[elementStringIDs.emptyDemo]
        XCTAssert(editorDemoButton.exists, "Editor button not hittable. Are you on the right page?")
    }
    
    // Github issue https://github.com/wordpress-mobile/AztecEditor-iOS/issues/465
    func testTypeAfterInvalidHTML() {
        switchContentView()
        enterTextInHTML(text: "<qaz!>")
        switchContentView()
        
        let field = app.textViews[elementStringIDs.richTextField]
        // Some magic to move caret to end of the text
        let vector = CGVector(dx:field.frame.width, dy:field.frame.height - field.frame.minY)
        field.coordinate(withNormalizedOffset:CGVector.zero).withOffset(vector).tap()
        enterTextInField(text: "Some text after invalid HTML tag")

        let text = getHTMLContent()
        XCTAssertEqual(text, "<p><qaz></qaz>Some text after invalid HTML tag</p>")
    }
}


