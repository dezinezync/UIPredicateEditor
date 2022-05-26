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
    0.0
  }
  
  /// Returns the views that display this template’s predicate.
  ///
  /// The views for an `UIPredicateEditor` to display in a row that represents the predicate from `setPredicate(_:)`.
  public var templateViews: [UIView] {
    []
  }
  
  /// Sets the value of the views according to the given predicate.
  ///
  /// This method is only called if match(for:) returned a positive value for the receiver.
  ///
  /// You can override this to set the values of custom views.
  ///
  /// - Parameter predicate: The predicate value for the receiver.
  open func setPredicate(_ predicate: NSPredicate) {
    
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
}
