//
//  PredicateController.swift
//  
//
//  Created by Nikhil Nigade on 17/08/22.
//

import Foundation

public extension Notification.Name {
  
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
public final class PredicateController {
  /// contains the predicate evaluated by the editor.
  ///
  /// If one or more parts cannot be queried from the row templates, the property evaluates to `nil`.
  /// Should be set on initialization to pre-populate initial rows.
  @objc dynamic public var predicate: NSPredicate!
  
  /// Row templates to be used by the receiver.
  ///
  /// These should correspond to the predicate the editor is currently editing.
  /// The number of row templates should match the number of options available to the user.
  /// These are never used directly, and instead copies are maintained.
  @objc dynamic public var rowTemplates: [UIPredicateEditorRowTemplate] = []
  
  /// The formatting dictionary for the rule editor.
  ///
  /// If you assign a new the formatting dictionary to this property, it sets the current to formatting strings file name to `nil`.
  @objc dynamic public var formattingDictionary: [String: String]?
  
  /// The name of the rule editor’s strings file.
  ///
  /// The `UIPredicateEditor` class looks for a strings file with the given name in the main bundle. If it finds a strings file resource with the given name, `UIPredicateEditor` loads it and sets it as the formatting dictionary for the receiver. You can obtain the resulting dictionary using the `formattingDictionary` property.
  ///
  /// If you assign a new dictionary to the `formattingDictionary` property, it sets the current to formatting strings file name to `nil`.
  @objc dynamic public var formattingStringsFilename: String?
  // @TODO: Implementation pending
  
  /// Internal copy of row templates, which will be used to populate the  view.
  ///
  /// Each row will have its own predicate which is used to form the predicate on the `UIPredicateEditor`.
  @objc dynamic public var requiredRowTemplates: [UIPredicateEditorRowTemplate] = []
  
  /// this is created on-demand everytime as the formatting dictionary may change during runtime
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
         let rhsKey = rhsComparison.stringValue {
        
        let keyToMatch = "%[\(lhsKey)]@ %[\(comparisonOp.title)]@ %[\(rhsKey)]@"
        
        if let matchedLocalization = formattingDictionary.first(where: { (key: String, value: String) in
          key == keyToMatch
        }) {
          
          /// the partial key only matches the left expression. The formatting
          /// dictionary may have strings for multiple operator and right expression
          /// combinations. This makes a gross assumption that all partial key matches
          /// are valid for this row template.
          let partialKeyToMatch = "%[\(lhsKey)]@"
          
          let allPartialMatches = formattingDictionary.filter { (key, value) in
            return key.contains(partialKeyToMatch)
          }
          
          #if DEBUG
          print("[UIPredicateEditor] localization matches for predicate: \(comparison), firstMatch: \(matchedLocalization), all partial matches: \(allPartialMatches)")
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
    let subpredicates = self.subpredicates
    
    let matchingRowTemplates = subpredicates.map { predicate -> UIPredicateEditorRowTemplate in
      let firstMatch: UIPredicateEditorRowTemplate = rowTemplates.reduce(rowTemplates[0], { partialResult, template in
        if template.match(for: predicate) > partialResult.match(for: predicate) {
          return template
        }
        
        return partialResult
      })
      
      // create a copy of the template
      let templateCopy = firstMatch.copy() as! UIPredicateEditorRowTemplate
      
      setFormattingDictionary(on: templateCopy, predicate: predicate)
      
      // update the predicate so it can internally update values on its views
      templateCopy.setPredicate(predicate)
      
      return templateCopy
    }
    
    self.requiredRowTemplates = matchingRowTemplates
  }
  
  /// Notifies the receiver that the logical type for its predicate has changed.
  ///
  /// The receiver internally updates the derived predicate and notifies subscribers.
  /// - Parameter logicalType: logical type of the predicate.
  public func updatePredicate(for logicalType: NSCompoundPredicate.LogicalType) {
    let predicates = requiredRowTemplates.compactMap { $0.predicate }
    let compoundPredicate = NSCompoundPredicate(
      type: logicalType,
      subpredicates: predicates
    )
    
    self.predicate = compoundPredicate
    
    DispatchQueue.main.async {
      NotificationCenter.default.post(name: .predicateDidChange, object: self)
    }
  }
  
  /// Add a new row template on the receiver for the given LHS expression title.
  ///
  /// The expression title may be a localized variant, corresponding to a label in the formatting dictionary.
  /// - Parameter leftExpressionTitle: the LHS expression title to look up
  /// - Returns: `true` if the row template was found and added, `false` otherwise.
  @discardableResult public func addRowTemplate(for leftExpressionTitle: String) -> Bool {
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
    
    if let predicate = matchedTemplate.predicateForCurrentState() {
      setFormattingDictionary(on: templateCopy, predicate: predicate)
      templateCopy.setPredicate(predicate)
    }
    
    requiredRowTemplates.append(templateCopy)
    
    return true
  }
  
  // MARK: Internal
  internal var subpredicates: [NSPredicate] {
    if let predicate = predicate as? NSCompoundPredicate {
      let subpredicates = predicate.subpredicates.compactMap { $0 as? NSPredicate }
      return subpredicates
    }
    else if predicate.predicateFormat.isEmpty {
      return []
    }
    
    return [predicate]
  }
}
