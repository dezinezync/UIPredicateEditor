//
//  PredicateController.swift
//  
//
//  Created by Nikhil Nigade on 17/08/22.
//

#if os(iOS)
import Foundation
import Observation

public extension Notification.Name {
  /// Notified when the predicate of the `UIPredicateEditor`will change.
  ///
  /// The `object` on the `Notification` will be the editor.
  static let predicateWillChange = Notification.Name(rawValue: "UIPredicateEditor.predicateWillChange")
  
  /// Notified when the predicate of the `UIPredicateEditor` changes.
  ///
  /// The `object` on the `Notification` will be the editor.
  static let predicateDidChange = Notification.Name(rawValue: "UIPredicateEditor.predicateDidChange")
}

/// Concrete final class that manages predicates, row templates, updating and notifying of predicate changes to its managing view.
///
/// The `UIPRedicateEditorViewController` class uses it internally for its predicate operations.
///
/// You may choose to write your own view and use the `PredicateController` as its driving model.
@MainActor
@Observable
public final class PredicateController {
  /// contains the predicate evaluated by the editor.
  ///
  /// If one or more parts cannot be queried from the row templates, the property evaluates to `nil`.
  /// Should be set on initialization to pre-populate initial rows.
  public var predicate: NSPredicate?
  
  /// Row templates to be used by the receiver.
  ///
  /// These should correspond to the predicate the editor is currently editing.
  /// The number of row templates should match the number of options available to the user.
  /// These are never used directly, and instead copies are maintained.
  public var rowTemplates: [UIPredicateEditorRowTemplate] = []
  
  /// The formatting dictionary for the rule editor.
  ///
  /// If you assign a new the formatting dictionary to this property, it sets the current to formatting strings file name to `nil`.
  public var formattingDictionary: [String: String]?
  
  /// The name of the rule editor’s strings file.
  ///
  /// The `UIPredicateEditor` class looks for a strings file with the given name in the main bundle. If it finds a strings file resource with the given name, `UIPredicateEditor` loads it and sets it as the formatting dictionary for the receiver. You can obtain the resulting dictionary using the `formattingDictionary` property.
  ///
  /// If you assign a new dictionary to the `formattingDictionary` property, it sets the current to formatting strings file name to `nil`.
  public var formattingStringsFilename: String? {
    didSet {
      if let filename = formattingStringsFilename,
         let url = Bundle.main.url(forResource: filename, withExtension: "strings"),
         let dict = NSDictionary(contentsOf: url) as? [String: String] {
        self.formattingDictionary = dict
      }
    }
  }
  
  /// Internal copy of row templates, which will be used to populate the  view.
  ///
  /// Each row will have its own predicate which is used to form the predicate on the `UIPredicateEditor`.
  public var requiredRowTemplates: [UIPredicateEditorRowTemplate] = []
  
  /// Created on-demand everytime as the formatting dictionary may change during runtime
  internal var formattingHelper: FormattingDictionaryHelper {
    FormattingDictionaryHelper(formattingDictionary: formattingDictionary ?? [:])
  }
  
  // MARK: Public
  
  /// check if the formatting dictionary is setup, match localization formats to the predicate. If we get a primary match, extract all partial matches and set it up on the row template
  /// - Parameters:
  ///   - rowTemplate: the row template to update
  ///   - predicate: the predicate to match with
  public func setFormattingDictionary(on rowTemplate: UIPredicateEditorRowTemplate, predicate: NSPredicate) {
    if let comparison = predicate as? NSComparisonPredicate,
       let formattingDictionary = formattingDictionary {
      
      let lhsComparison = comparison.leftExpression
      let rhsComparison = comparison.rightExpression
      let comparisonOp = comparison.predicateOperatorType
      
      if let lhsKey = lhsComparison.stringValue,
         var rhsKey = rhsComparison.stringValue {
        
        if comparisonOp == .in || comparisonOp == .contains {
          rhsKey = "(%@)"
        }
        else {
          rhsKey = "%[\(rhsKey)]@"
        }
        
        let keyToMatch = "%[\(lhsKey)]@ %[\(comparisonOp.title)]@ \(rhsKey)"
        
        if let matchedLocalization = formattingDictionary.first(where: { (key: String, value: String) in
          key == keyToMatch
        }) {
          
          // the partial key only matches the left expression. The formatting
          // dictionary may have strings for multiple operators and right expression
          // combinations. This makes a gross assumption that all partial key matches
          // are valid for this row template.
          let partialKeyToMatch = "%[\(lhsKey)]@"
          
          let allPartialMatches = formattingDictionary.filter { (key, value) in
            return key.contains(partialKeyToMatch)
          }
          
          #if DEBUG
          print("PredicateController: localization matches for predicate: \(comparison), firstMatch: \(matchedLocalization), all partial matches: \(allPartialMatches)")
          #endif
          
          rowTemplate.formattingDictionary = allPartialMatches
        }
      }
    }
  }
  
  /// Instructs the receiver to regenerate its predicate by invoking the corresponding internal methods.
  ///
  /// You typically invoke this method because something has changed (for example, a view's value).
  ///
  /// When predicates of row templates change, this is invoked automatically.
  public func reloadPredicate() {
    guard let predicate = self.predicate else {
      self.requiredRowTemplates = []
      return
    }
    
    // We treat the top-level predicate as the root of our recursive structure.
    // If it's a compound predicate, we build the tree.
    // If it's a simple predicate, we wrap it or handle it as a single row.
    
    // The existing logic assumed subpredicates property existed on PredicateController
    // which extracted subpredicates from self.predicate.
    
    // Let's rebuild the rows from scratch based on the current predicate.
    self.requiredRowTemplates = rowTemplates(for: predicate)
  }
  
  /// Notifies the receiver that the logical type for its predicate has changed.
  ///
  /// The receiver internally updates the derived predicate and notifies subscribers.
  /// - Parameter logicalType: logical type of the predicate.
  public func updatePredicate(for logicalType: NSCompoundPredicate.LogicalType) {
    Task { @MainActor in
      notifyPredicateWillChange()
    }
    
    // We assume the first row is the root container if available.
    // If we have no rows, we have no predicate.
    guard let rootRow = requiredRowTemplates.first else {
      self.predicate = nil
      Task { @MainActor in
        notifyPredicateDidChange()
      }
      return
    }
    
    // Recursively rebuild the predicate starting from the root row.
    self.predicate = buildRecursivePredicate(from: rootRow)
    
    Task { @MainActor in
      notifyPredicateDidChange()
    }
  }
  
  /// Add a new row template on the receiver for the given LHS expression title.
  ///
  /// The expression title may be a localized variant, corresponding to a label in the formatting dictionary.
  /// - Parameter leftExpressionTitle: the LHS expression title to look up
  /// - Returns: `true` if the row template was found and added, `false` otherwise.
  @discardableResult public func addRowTemplate(for leftExpressionTitle: String, for parentRow: UIPredicateEditorRowTemplate? = nil) -> Bool {
    var title = leftExpressionTitle
    
    // check if this a localized title
    if let matchedTitle = formattingHelper.lhsReverseMatch(for: title) {
      title = matchedTitle
    }
    
    // find the associated row template
    guard let matchedTemplate = rowTemplates.first(where: { template in
      template.leftExpressions.first(where: { expression in
        expression.stringValue == title
      }) != nil
    }) else {
      return false
    }
    
    let templateCopy = matchedTemplate.copy() as! UIPredicateEditorRowTemplate
    
    if let parentRow {
      templateCopy.parentTemplateID = parentRow.ID
      templateCopy.indentationLevel = parentRow.indentationLevel + 1
    }
    
    if let predicate = matchedTemplate.predicateForCurrentState() {
      setFormattingDictionary(on: templateCopy, predicate: predicate)
      templateCopy.setPredicate(predicate)
    }
    
    addRowTemplate(templateCopy)
    
    return true
  }
  
  public func addRowTemplate(_ rowTemplate: UIPredicateEditorRowTemplate) {
    if let parentID = rowTemplate.parentTemplateID,
       let parentIndex = requiredRowTemplates.firstIndex(where: { $0.ID == parentID }) {
      
      let parentIndentation = requiredRowTemplates[parentIndex].indentationLevel
      var insertionIndex = parentIndex + 1
      
      // Find the end of the parent's subtree by looking for the next item
      // with an indentation level less than or equal to the parent.
      while insertionIndex < requiredRowTemplates.count &&
            requiredRowTemplates[insertionIndex].indentationLevel > parentIndentation {
        insertionIndex += 1
      }
      
      requiredRowTemplates.insert(rowTemplate, at: insertionIndex)
    } else {
      // If no parent, append to the end as per NSPredicateEditor behavior.
      requiredRowTemplates.append(rowTemplate)
    }
    
    // If we added a row, we should probably update the predicate to include it.
    if let rootRow = requiredRowTemplates.first, !rootRow.compoundTypes.isEmpty {
      updatePredicate(for: rootRow.logicalTypeForCurrentState())
    }
  }
  
  /// Deletes the row template at the specified index.
  ///
  /// If the row template is a Parent row, all its child row templates are also deleted recursively.
  ///
  /// Call `updatePredicate(for:)` to update the predicate after deleting a row.
  /// - Parameter index: the index of the row template
  public func deleteRowTemplate(at index: Int) {
    guard index < requiredRowTemplates.count else {
      return
    }
    
    let rowToDelete = requiredRowTemplates[index]
    var rowsToDelete: Set<UIPredicateEditorRowTemplate> = [rowToDelete]
    
    // If the row acts as a parent (has an ID), find all descendants
    if let parentID = rowToDelete.ID {
      var stack: [UUID] = [parentID]
      
      while !stack.isEmpty {
        let currentParentID = stack.removeLast()
        
        // Find immediate children of this parent
        let children = requiredRowTemplates.filter { $0.parentTemplateID == currentParentID }
        
        for child in children {
          rowsToDelete.insert(child)
          // If this child is also a parent, add to stack
          if let childID = child.ID {
            stack.append(childID)
          }
        }
      }
    }
    
    requiredRowTemplates.removeAll { rowsToDelete.contains($0) }
    
    // If we deleted the root row, clear everything?
    if requiredRowTemplates.isEmpty {
        self.predicate = nil
    } else if let rootRow = requiredRowTemplates.first, !rootRow.compoundTypes.isEmpty {
        updatePredicate(for: rootRow.logicalTypeForCurrentState())
    }
  }
  
  /// Helper to update the master predicate based on the current UI state of the root row (Any/All/None).
  public func updatePredicateFromCurrentState() {
    guard let rootRow = requiredRowTemplates.first, !rootRow.compoundTypes.isEmpty else {
      return
    }
    updatePredicate(for: rootRow.logicalTypeForCurrentState())
  }
  
  // MARK: Notify
  @MainActor internal func notifyPredicateWillChange() {
    // @TODO: Refactor to call delegate
    NotificationCenter.default.post(name: .predicateWillChange, object: self)
  }
  
  @MainActor internal func notifyPredicateDidChange() {
    // @TODO: Refactor to call delegate
    NotificationCenter.default.post(name: .predicateDidChange, object: self)
  }
  
  // MARK: Internal
  
  /// Recursively builds a predicate tree from the row templates.
  private func buildRecursivePredicate(from row: UIPredicateEditorRowTemplate) -> NSPredicate? {
    // If it's a leaf node (comparison), return its predicate directly
    if row.compoundTypes.isEmpty {
      return row.predicateForCurrentState()
    }
    
    // It's a compound node.
    guard let rowID = row.ID else { return nil }
    
    let logicalType = row.logicalTypeForCurrentState()
    
    // Find direct children of this row
    let children = requiredRowTemplates.filter { $0.parentTemplateID == rowID }
    
    var subpredicates: [NSPredicate] = []
    
    for child in children {
      if let childPredicate = buildRecursivePredicate(from: child) {
        subpredicates.append(childPredicate)
      }
    }
    
    return NSCompoundPredicate(type: logicalType, subpredicates: subpredicates)
  }
  
  private func rowTemplates(for predicate: NSPredicate, indentationLevel: Int = 0) -> [UIPredicateEditorRowTemplate] {
    if let compoundPredicate = predicate as? NSCompoundPredicate {
      // for compound predicates, break down into sub-predicates
      // with each subpredicate assigned to its own row-template
      // all "contained" by a single parent operator row-template.
      
      var templates: [UIPredicateEditorRowTemplate] = []
      
      // Find the best matching template for the compound predicate itself (usually Any/All/None)
      guard let operatorTemplate: UIPredicateEditorRowTemplate = rowTemplates.reduce(nil, { partialResult, template in
        if template.match(for: predicate) > partialResult?.match(for: predicate) ?? 0 {
          return template
        }
        return partialResult
      }) else {
        return []
      }
      
      let operatorTemplateCopy = operatorTemplate.copy() as! UIPredicateEditorRowTemplate
      operatorTemplateCopy.ID = UUID()
      
      if indentationLevel > 0 {
        operatorTemplateCopy.indentationLevel = indentationLevel - 1
      }
      
      // Important: Update the view state (dropdown selection) to match the logical type
      // This is implicit in setPredicate but ensuring consistency here.
      operatorTemplateCopy.setPredicate(predicate)
      
      templates.append(operatorTemplateCopy)
      
      compoundPredicate.subpredicates.forEach { subpredicate in
        let subTemplates = self.rowTemplates(for: subpredicate as! NSPredicate, indentationLevel: indentationLevel + 1)
        if !subTemplates.isEmpty {
          // assign the parent's ID to all sub-template rows
          subTemplates.forEach {
            $0.parentTemplateID = operatorTemplateCopy.ID
          }
          
          templates.append(contentsOf: subTemplates)
        }
      }
      
      return templates
    }
    
    // Leaf node (Comparison)
    guard let firstMatch: UIPredicateEditorRowTemplate = rowTemplates.reduce(nil, { partialResult, template in
      if template.match(for: predicate) > partialResult?.match(for: predicate) ?? 0 {
        return template
      }
      return partialResult
    }) else {
      return []
    }
    
    // create a copy of the template
    let templateCopy = firstMatch.copy() as! UIPredicateEditorRowTemplate
    
    setFormattingDictionary(on: templateCopy, predicate: predicate)
    
    // update the predicate so it can internally update values on its views
    templateCopy.setPredicate(predicate)
    templateCopy.indentationLevel = indentationLevel
    
    return [templateCopy]
  }
}
#endif
