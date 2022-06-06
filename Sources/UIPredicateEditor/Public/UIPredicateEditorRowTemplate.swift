//
//  UIPredicateEditorRowTemplate.swift
//  
//
//  Created by Nikhil Nigade on 26/05/22.
//

import UIKit

#if canImport(CoreData)
import CoreData
#endif

/// A template that describes available predicates and how to display them.
///
/// By default, a noncompound row template has three views: a popup (or static text field) on the left, a popup or static text field for operators, and either a popup or other view on the right.  You can subclass `UIPredicateEditorRowTemplate` to create a row template with different numbers or types of views.
open class UIPredicateEditorRowTemplate: NSObject {
  
  /// An array of ``NSExpression`` objects that represent the left side of a predicate.
  public let leftExpressions: [NSExpression]
  
  /// An array of ``NSExpression`` objects that represent the right side of a predicate.
  public let rightExpressions: [NSExpression]
  
  /// The attribute type for the right side of the predicate determining the custom view to show for the type.
  public let rightExpressionAttributeType: NSAttributeType?
  
  /// A modifier for the predicate (see ``NSComparisonPredicate.Modifier`` for possible values).
  public let modifier: NSComparisonPredicate.Modifier
  
  /// An array of `NSComparisonPredicate.Operator` objects specifying the operator type (see ``NSComparisonPredicate.Operator`` for possible values).
  public let operators: [NSComparisonPredicate.Operator]
  
  /// Options for the predicate (see ``NSComparisonPredicate.Options`` for possible values).
  public let options: NSComparisonPredicate.Options
  
  public let logicalType: NSCompoundPredicate.LogicalType
  
  public let compoundTypes: [NSCompoundPredicate.LogicalType]
  
  /// delegate which is notified when the predicate or any of the view's value change.
  public weak var refreshDelegate: UIPredicateEditorContentRefreshing?
  
  /// The predicate managed by this template.
  ///
  /// Only setup on copies of templates currently managed by the `UIPredicateEditor`.
  internal var predicate: NSPredicate?
  
  /// Matched formatting items from the predicate editor if a value was set.
  ///
  /// This list matches the current `predicate` setup on the template.
  /// This value is only available on the template row copies and never the original template rows. 
  var formattingDictionary: [String: String]?
  
  lazy var formattingHelper: FormattingDictionaryHelper? = {
    guard let formattingDictionary = formattingDictionary else {
      return nil
    }

    return FormattingDictionaryHelper(formattingDictionary: formattingDictionary)
  }()
  
  /// Initializes and returns a “pop-up-pop-up-pop-up”–style row template.
  /// - Parameters:
  ///   - leftExpressions: An array of ``NSExpression`` objects that represent the left side of a predicate.
  ///   - rightExpressions: An array of ``NSExpression`` objects that represent the right side of a predicate.
  ///   - modifier: A modifier for the predicate (see ``NSComparisonPredicate.Modifier`` for possible values).
  ///   - operators: An array of `NSComparisonPredicate.Operator` objects specifying the operator type (see ``NSComparisonPredicate.Operator`` for possible values).
  ///   - options: Options for the predicate (see ``NSComparisonPredicate.Options`` for possible values).
  public init(leftExpressions: [NSExpression], rightExpressions: [NSExpression], modifier: NSComparisonPredicate.Modifier, operators: [NSComparisonPredicate.Operator], options: NSComparisonPredicate.Options) {
    self.leftExpressions = leftExpressions
    self.rightExpressions = rightExpressions
    self.modifier = modifier
    self.operators = operators
    self.options = options
    self.compoundTypes = []
    
    self.logicalType = .and
    self.rightExpressionAttributeType = nil
    super.init()
  }
  
  #if canImport(CoreData)
  /// Initializes and returns a “pop-up-pop-up-view”–style row template.
  ///
  ///   The type of `attributeType` dictates the type of view created. For example, `NSAttributeType.dateAttributeType` creates an `UIDatePicker` view, `NSAttributeType.integer64AttributeType` creates a short text field, and `NSAttributeType.stringAttributeType` produces a longer text field.
  ///
  ///   Predicates do not automatically coerce types for you. For example, comparing a number to a string will raise an exception. Therefore, the attribute type is also needed to determine how the control's object value must be coerced before putting it into a predicate.
  /// - Parameters:
  ///   - leftExpressions: An array of ``NSExpression`` objects that represent the left side of a predicate.
  ///   - attributeType: An attribute type for the right side of a predicate. This value dictates the type of view created, and how the control’s object value is coerced before putting it into a predicate.
  ///   - modifier: A modifier for the predicate (see ``NSComparisonPredicate.Modifier`` for possible values).
  ///   - operators: An array of `NSComparisonPredicate.Operator` objects specifying the operator type (see ``NSComparisonPredicate.Operator`` for possible values).
  ///   - options: Options for the predicate (see ``NSComparisonPredicate.Options`` for possible values).
  public init(leftExpressions: [NSExpression], rightExpressionAttributeType attributeType: NSAttributeType, modifier: NSComparisonPredicate.Modifier, operators: [NSComparisonPredicate.Operator], options: NSComparisonPredicate.Options) {
    self.leftExpressions = leftExpressions
    self.rightExpressions = []
    self.rightExpressionAttributeType = attributeType
    self.modifier = modifier
    self.operators = operators
    self.options = options
    self.compoundTypes = []
    
    self.logicalType = .and
    super.init()
  }
  #endif
  
  /// Initializes and returns a row template suitable for displaying compound predicates.
  /// - Parameter compoundType: An array of NSNumber objects specifying compound predicate types. See NSCompoundPredicate.LogicalType for possible values.
  public init(compoundTypes: [NSCompoundPredicate.LogicalType]) {
    self.leftExpressions = []
    self.rightExpressions = []
    self.modifier = .direct
    self.operators = [.equalTo]
    self.options = []
    self.logicalType = .and
    self.compoundTypes = compoundTypes
    
    self.rightExpressionAttributeType = nil
    super.init()
  }
  
  internal init(from reference: UIPredicateEditorRowTemplate) {
    self.leftExpressions = reference.leftExpressions
    self.rightExpressions = reference.rightExpressions
    self.rightExpressionAttributeType = reference.rightExpressionAttributeType
    self.modifier = reference.modifier
    self.operators = reference.operators
    self.options = reference.options
    self.logicalType = reference.logicalType
    self.compoundTypes = reference.compoundTypes
    super.init()
  }
  
  // MARK: CoreData Support
  #if canImport(CoreData)
  
  /// Returns an array of predicate templates for the given attribute key paths for a given entity.
  ///
  /// This method determines which key paths in the entity description can use the same views (that is, share the same attribute type). For each of these groups, it instantiates individual templates via `init(leftExpressions:rightExpressions:modifier:operators:options:)`.
  ///
  /// - Parameters:
  ///   - keyPaths: An array of attribute key paths originating at `entityDescription`. The key paths may cross relationships but must terminate in attributes.
  ///   - entityDescription: A Core Data entity description.
  /// - Returns: An array of predicate templates for keyPaths originating at `entityDescription`.
  class func templates(withAttributeKeyPaths keyPaths: [String], in entityDescription: NSEntityDescription) -> [UIPredicateEditorRowTemplate] {
    []
  }
  #endif
  
  // MARK: Primitive Methods
  
  /// Returns a positive number if the receiver can represent a given predicate, and 0 if it cannot.
  ///
  /// By default, returns values in the range 0 to 1.
  ///
  /// The highest match among all the templates determines which template is responsible for displaying the predicate. You can override this to determine which predicates your custom template handles.
  open func match(for predicate: NSPredicate) -> Double {
    var score: Double = 0.0
    
    if let comparison = predicate as? NSComparisonPredicate {
      if operators.contains(comparison.predicateOperatorType) {
        score += 0.33
      }
      
      if leftExpressions.contains(comparison.leftExpression) {
        score += 0.33
      }
      
      if rightExpressions.contains(comparison.rightExpression) {
        score += 0.33
      }
      
      if comparison.comparisonPredicateModifier == modifier {
        score += 0.33
      }
      
      score = min(1.0, score)
    }
    else if let compound = predicate as? NSCompoundPredicate {
      // evaluate all subpredicates
      let subpredicates = compound.subpredicates.compactMap { $0 as? NSPredicate }
      let incrementCounter = 1.0 / Double(subpredicates.count)
      
      for subpredicate in subpredicates {
        score += match(for: subpredicate) >= 0.5 ? incrementCounter : 0.0
      }
    }
    
    return score
  }
  
  /// Returns the views that display this template’s predicate.
  ///
  /// The views for an `UIPredicateEditor` to display in a row that represents the predicate from `setPredicate(_:)`.
  open var templateViews: [UIView] {
    var views: [UIView] = []
    
    // check for any/all templates first
    if !compoundTypes.isEmpty {
      views.append(compoundTypesButton)
      
      let label = operatorStaticLabel
      label.text = NSLocalizedString("of the following are true", comment: "of the following are true")
      
      views.append(label)
    }
    else {
      if !leftExpressions.isEmpty {
        views.append(leftExpressionPopupButton)
      }
      
      if !operators.isEmpty {
        views.append(operatorsPopupButton)
      }
      
      if !rightExpressions.isEmpty {
        views.append(rightExpressionPopupButton)
      }
      else {
        if predicate is NSComparisonPredicate {
          if rightExpressionAttributeType != nil {
            if rightExpressionAttributeType == .dateAttributeType {
              views.append(dateInputView)
            }
            else {
              views.append(textInputView)
            }
          }
          else {
            fatalError("a comparison predicate without a right expression attribute type should have at least one right expression")
          }
        }
      }
    }
    
    return views
  }
  
  /// Sets the value of the views according to the given predicate.
  ///
  /// This method is only called if match(for:) returned a positive value for the receiver.
  ///
  /// You can override this to set the values of custom views.
  ///
  /// - Parameter predicate: The predicate value for the receiver.
  open func setPredicate(_ predicate: NSPredicate) {
    self.predicate = predicate
  }
  
  /// Returns the subpredicates that should be made sub-rows of a given predicate.
  ///
  /// You can override this method to create custom templates that handle complicated compound predicates.
  ///
  /// - Parameter predicate: a predicate object
  /// - Returns: The subpredicates that should be made sub-rows of predicate. For compound predicates (instances of `NSCompoundPredicate`), the array of subpredicates; for other types of predicate, returns `nil`. If a template represents a predicate in its entirety, or if the predicate has no subpredicates, returns `nil`.
  open func displayableSubpredicates(of predicate: NSPredicate) -> [NSPredicate]? {
    []
  }
  
  /// Returns the predicate represented by the receiver’s views' values and the given sub-predicates.
  ///
  /// This method is only called if match(for:) returned a positive value for the receiver.
  ///
  /// You can override this method to return the predicate represented by a custom view.
  ///
  /// - Parameter subpredicates: An array of predicates.
  /// - Returns: The predicate represented by the values of the template's views and the given subpredicates. You can override this method to return the predicate represented by your custom views.
  open func predicate(withSubpredicates subpredicates: [NSPredicate]?) -> NSPredicate {
    NSPredicate()
  }

  
  // MARK: - Internal
  public func updatePredicate() {
    defer {
      // refresh views
      refreshDelegate?.refreshContentView()
    }
    
    guard let comparisonPredicate = predicateForCurrentState() else {
      return
    }
    
    self.predicate = comparisonPredicate
  }
  
  /// Returns the predicate evaluated from the current state of its views
  /// - Returns: `NSComparisonPredicate` if one could be formed
  public func predicateForCurrentState() -> NSComparisonPredicate? {
    if !self.compoundTypes.isEmpty {
      if #available(iOS 14, macCatalyst 11.0, *) {
        if let selected = self.compoundTypesButton.menu?.uiSelectedElements.first as? UIAction {
          if selected.title == NSCompoundPredicate.LogicalType.and.localizedTitle {
            self.predicate = NSCompoundPredicate(type: .and, subpredicates: [])
          }
          else if selected.title == NSCompoundPredicate.LogicalType.or.localizedTitle {
            self.predicate = NSCompoundPredicate(type: .or, subpredicates: [])
          }
          else if selected.title == NSCompoundPredicate.LogicalType.and.localizedTitle {
            self.predicate = NSCompoundPredicate(type: .not, subpredicates: [])
          }
        }
      }
      
      return nil
    }
    
    // update the predicate
    var leftExpression: NSExpression?
    var predicateOperator: NSComparisonPredicate.Operator = .equalTo
    var rightExpression: NSExpression?
    
    let views = templateViews
    let leftExpressionView = views[0]
    
    if #available(iOS 14, macCatalyst 11.0, *) {
      if let button = leftExpressionView as? UIButton,
         let item = button.menu?.uiSelectedElements.first as? UIAction {
        
        var title = item.title
        
        // we may have localized this title
        if let formattingHelper = formattingHelper,
           let baseKey = formattingHelper.lhsReverseMatch(for: title) {
          title = baseKey
        }
        
        let matchingExpression = leftExpressions.first { expression in
          title == expression.stringValue
        }
        
        leftExpression = matchingExpression
      }
      
      let operatorView = views[1]
      
      if let operatorButton = operatorView as? UIButton,
         let item = operatorButton.menu?.uiSelectedElements.first as? UIAction {
        predicateOperator = NSComparisonPredicate.Operator.from(item.title)
      }
      
      if views.count > 2 {
        let rightExpressionView = views[2]
        
        if let rightExpressionView = rightExpressionView as? UIButton,
           let item = rightExpressionView.menu?.uiSelectedElements.first as? UIAction {
          
          var title = item.title
          
          // we may have localized this title
          if let formattingHelper = formattingHelper,
             let baseKey = formattingHelper.rhsReverseMatch(for: title) {
            title = baseKey
          }
          
          rightExpression = NSExpression(forConstantValue: title)
        }
        else if let textField = rightExpressionView as? UITextField {
          
          if textField.keyboardType == .URL,
          let url = URL(string: textField.text ?? "") {
            rightExpression = NSExpression(forConstantValue: url)
          }
          else if textField.keyboardType == .numbersAndPunctuation {
            let text = (textField.text ?? "") as NSString
            
            if rightExpressionAttributeType == .doubleAttributeType {
              rightExpression = NSExpression(forConstantValue: text.doubleValue)
            }
            else if rightExpressionAttributeType == .floatAttributeType {
              rightExpression = NSExpression(forConstantValue: text.floatValue)
            }
            else if rightExpressionAttributeType == .integer16AttributeType || rightExpressionAttributeType == .integer32AttributeType {
              rightExpression = NSExpression(forConstantValue: text.intValue)
            }
            else if rightExpressionAttributeType == .integer64AttributeType {
              rightExpression = NSExpression(forConstantValue: text.integerValue)
            }
            /*
             * Use the following template to handle additional cases
             else if rightExpressionAttributeType == <#type#> {
               rightExpression = NSExpression(forConstantValue: text.<#valueType#>)
             }
             */
          }
        }
        else if let dateView = rightExpressionView as? UIDatePicker {
          rightExpression = NSExpression(forConstantValue: dateView.date)
        }
      }
    }
    
    if rightExpression == nil,
       let rightExpressionAttributeType = rightExpressionAttributeType {
      if rightExpressionAttributeType == .URIAttributeType {
        rightExpression = NSExpression(forConstantValue: URL(string: ""))
      }
      else if rightExpressionAttributeType == .doubleAttributeType {
        rightExpression = NSExpression(forConstantValue: 0.0)
      }
      else if rightExpressionAttributeType == .floatAttributeType {
        rightExpression = NSExpression(forConstantValue: 0.0)
      }
      else if rightExpressionAttributeType == .integer16AttributeType || rightExpressionAttributeType == .integer32AttributeType {
        rightExpression = NSExpression(forConstantValue: 0)
      }
      else if rightExpressionAttributeType == .integer64AttributeType {
        rightExpression = NSExpression(forConstantValue: 0)
      }
      /*
       * Use the following template to handle additional cases
       else if rightExpressionAttributeType == <#type#> {
         rightExpression = NSExpression(forConstantValue: text.<#valueType#>)
       }
       */
    }
    
    guard let leftExpression = leftExpression,
          let rightExpression = rightExpression else {
      return nil
    }
    
    let comparisonPredicate = NSComparisonPredicate(
      leftExpression: leftExpression,
      rightExpression: rightExpression,
      modifier: modifier,
      type: predicateOperator,
      options: options
    )
    
    return comparisonPredicate
  }
  
  // MARK: Views
  func buttonWithMenu(_ actions: [UIMenuElement]) -> UIButton {
    let button = UIButton(frame: .zero)
    
    if #available(iOS 14.0, *) {
      button.menu = UIMenu(children: actions)
      button.showsMenuAsPrimaryAction = true
      
      if actions.count == 1 {
        // single value, disable interaction
        button.isUserInteractionEnabled = false
      }
    }
    else {
      // fallback for older versions
    }
    
    if #available(iOS 15, macCatalyst 12.0, *) {
      button.changesSelectionAsPrimaryAction = true
      
      if actions.count > 1 {
        var config = UIButton.Configuration.gray()
        config.buttonSize = .small
        config.cornerStyle = .dynamic
        
        button.configuration = config
      }
      else {
        // single action, disable tappable appearance
        var config = UIButton.Configuration.plain()
        config.buttonSize = .small
        
        button.configuration = config
      }
    }
    else {
      button.backgroundColor = .secondarySystemFill
    }
    
    return button
  }
  
  lazy var leftExpressionPopupButton: UIButton = {
    // check if we have any matching localization templates
    var expressions = leftExpressions
    
    if let formattingHelper = formattingHelper {
      
      expressions = expressions.map { expression in
        guard let stringValue = expression.stringValue,
              let localizedValue = formattingHelper.lhsMatch(for: stringValue) else {
          return expression
        }
        
        return NSExpression(forConstantValue: localizedValue)
      }
    }
    
    let menuActions: [UIAction] = expressions.compactMap { expression in
      guard let stringValue = expression.stringValue else {
        return nil
      }
      
      return UIAction(title: stringValue) { [weak self] _ in
        #if DEBUG
        print("[UIPredicateEditor] left expression action: \(stringValue)")
        #endif
        self?.updatePredicate()
      }
    }
    
    return buttonWithMenu(menuActions)
  }()
  
  lazy var operatorsPopupButton: UIButton = {
    let menuActions = operators.map { operation in
      UIAction(title: operation.localizedTitle) { [weak self] _ in
        #if DEBUG
        print("[UIPredicateEditor] operation action: \(operation.localizedTitle)")
        #endif
        
        self?.updatePredicate()
      }
    }
    
    return buttonWithMenu(menuActions)
  }()
  
  lazy var operatorStaticLabel: UILabel = {
    let label = UILabel()
    label.text = operators.first!.localizedTitle
    label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
    label.textColor = .secondaryLabel
    label.numberOfLines = 1
    label.sizeToFit()
    
    return label
  }()
  
  lazy var rightExpressionPopupButton: UIButton = {
    // check if we have any matching localization templates
    var expressions = rightExpressions
    
    if let formattingHelper = formattingHelper {
      
      expressions = expressions.map { expression in
        guard let stringValue = expression.stringValue,
              let localizedValue = formattingHelper.rhsMatch(for: stringValue) else {
          return expression
        }
        
        return NSExpression(forConstantValue: localizedValue)
      }
    }
    
    let menuActions = expressions.compactMap { expression -> UIAction? in
      guard let title = expression.stringValue else {
        return nil
      }
      
      return UIAction(title: title) { [weak self] _ in
        #if DEBUG
        print("[UIPredicateEditor] right expression action: \(title)")
        #endif
        
        self?.updatePredicate()
      }
    }
    
    return buttonWithMenu(menuActions)
  }()
  
  lazy var boolMenuButton: UIButton = {
    let menuActions = [NSLocalizedString("Yes", comment: "Yes"), NSLocalizedString("No", comment: "No")].compactMap { bool in
      UIAction(title: bool) { [weak self] _ in
        #if DEBUG
        print("[UIPredicateEditor] boolean menu action: \(bool)")
        #endif
        
        self?.updatePredicate()
      }
    }
    
    return buttonWithMenu(menuActions)
  }()
  
  lazy var compoundTypesButton: UIButton = {
    let menuActions = compoundTypes.compactMap { type in
      UIAction(title: type.localizedTitle) { [weak self] _ in
        #if DEBUG
        print("[UIPredicateEditor] compound type menu action: \(type.localizedTitle)")
        #endif
        
        self?.updatePredicate()
      }
    }
    
    return buttonWithMenu(menuActions)
  }()
  
  lazy var textInputView: UITextField = {
    let textField = UITextField()
    textField.spellCheckingType = .no
    textField.textColor = .label
    textField.font = .systemFont(ofSize: 14, weight: .regular)
    
    // styling
    textField.backgroundColor = .tertiarySystemBackground
    textField.layer.cornerRadius = 4
    textField.layer.masksToBounds = true
    
    switch rightExpressionAttributeType! {
    case .URIAttributeType:
      textField.keyboardType = .URL
      textField.textContentType = .URL
      textField.placeholder = "URL"
      
    case .decimalAttributeType, .floatAttributeType, .integer16AttributeType, .integer32AttributeType, .integer64AttributeType:
      textField.keyboardType = .numbersAndPunctuation
      textField.placeholder = "Number"
    default:
      textField.keyboardType = UIKeyboardType.default
      textField.placeholder = "Value"
    }
    
    textField.delegate = self
    
    textField.sizeToFit()
    
    return textField
  }()
  
  lazy var dateInputView: UIDatePicker = {
    let datePicker = UIDatePicker()
    datePicker.datePickerMode = .dateAndTime
    
    if #available(iOS 14.0, *) {
      datePicker.preferredDatePickerStyle = .inline
    }
    
    datePicker.addTarget(self, action: #selector(didChangeDate(_:)), for: .valueChanged)
    
    datePicker.sizeToFit()
    
    return datePicker
  }()
  
  @objc func didChangeDate(_ sender: Any?) {
    updatePredicate()
  }
}

// MARK: - Copying

extension UIPredicateEditorRowTemplate: NSCopying {
  open func copy(with zone: NSZone? = nil) -> Any {
    UIPredicateEditorRowTemplate(from: self)
  }
}

// MARK: - UITextFieldDelegate
extension UIPredicateEditorRowTemplate: UITextFieldDelegate {
  public func textFieldDidEndEditing(_ textField: UITextField) {
    updatePredicate()
  }
  
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }
}

// MARK: - Debug

extension UIPredicateEditorRowTemplate {
  open override var description: String {
    let inherit = super.description
    let meta = ", predicate: \(self.predicate?.predicateFormat ?? "no predicate"), view count: \(templateViews.count)"
    
    return inherit + meta
  }
}
