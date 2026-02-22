import XCTest
@testable import UIPredicateEditor

final class UIPredicateEditorTests: XCTestCase {
    
  @MainActor
  func testRowOrdering() {
    let controller = PredicateController()
    
    // 1. Add a root row
    let rootRow = UIPredicateEditorRowTemplate(compoundTypes: [.and, .or, .not])
    rootRow.ID = UUID()
    controller.addRowTemplate(rootRow)
    
    // 2. Add a child to root
    let leftExpr = [NSExpression(forKeyPath: "name")]
    let child1 = UIPredicateEditorRowTemplate(leftExpressions: leftExpr, rightExpressions: [], modifier: .direct, operators: [.equalTo], options: [])
    child1.parentTemplateID = rootRow.ID
    child1.indentationLevel = 1
    controller.addRowTemplate(child1)
    
    // 3. Add another child to root (should go after child1 and its descendants)
    let child2 = UIPredicateEditorRowTemplate(leftExpressions: leftExpr, rightExpressions: [], modifier: .direct, operators: [.equalTo], options: [])
    child2.parentTemplateID = rootRow.ID
    child2.indentationLevel = 1
    controller.addRowTemplate(child2)
    
    // Current Order: [Root, Child1, Child2]
    XCTAssertEqual(controller.requiredRowTemplates.count, 3)
    XCTAssertEqual(controller.requiredRowTemplates[0], rootRow)
    XCTAssertEqual(controller.requiredRowTemplates[1], child1)
    XCTAssertEqual(controller.requiredRowTemplates[2], child2)
    
    // 4. Add a sub-child to child1
    let subChild1 = UIPredicateEditorRowTemplate(leftExpressions: leftExpr, rightExpressions: [], modifier: .direct, operators: [.equalTo], options: [])
    child1.ID = UUID() // Give child1 an ID so it can be a parent
    subChild1.parentTemplateID = child1.ID
    subChild1.indentationLevel = 2
    controller.addRowTemplate(subChild1)
    
    // Expected Order: [Root, Child1, SubChild1, Child2]
    XCTAssertEqual(controller.requiredRowTemplates.count, 4)
    XCTAssertEqual(controller.requiredRowTemplates[0], rootRow)
    XCTAssertEqual(controller.requiredRowTemplates[1], child1)
    XCTAssertEqual(controller.requiredRowTemplates[2], subChild1)
    XCTAssertEqual(controller.requiredRowTemplates[3], child2)
    
    // 5. Add another sub-child to child1 (should go after subChild1)
    let subChild2 = UIPredicateEditorRowTemplate(leftExpressions: leftExpr, rightExpressions: [], modifier: .direct, operators: [.equalTo], options: [])
    subChild2.parentTemplateID = child1.ID
    subChild2.indentationLevel = 2
    controller.addRowTemplate(subChild2)
    
    // Expected Order: [Root, Child1, SubChild1, SubChild2, Child2]
    XCTAssertEqual(controller.requiredRowTemplates.count, 5)
    XCTAssertEqual(controller.requiredRowTemplates[0], rootRow)
    XCTAssertEqual(controller.requiredRowTemplates[1], child1)
    XCTAssertEqual(controller.requiredRowTemplates[2], subChild1)
    XCTAssertEqual(controller.requiredRowTemplates[3], subChild2)
    XCTAssertEqual(controller.requiredRowTemplates[4], child2)
  }
}
