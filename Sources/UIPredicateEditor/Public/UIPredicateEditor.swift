//
//  UIPredicateEditor.swift
//  
//
//  Created by Nikhil Nigade on 26/05/22.
//

import UIKit

public extension Notification.Name {
  
  /// Notified when the predicate of the `UIPredicateEditor` changes.
  ///
  /// The `object` on the `Notification` will be the editor.
  static let predicateDidChange = Notification.Name(rawValue: "UIPredicateEditor.predicateDidChange")
}

/// Concrete view controller for managing and editing predicates in a user interface.
/// It's `open` by default, encourgaging subclassing, but can be used as is.
///
/// Similar to its `NS` counterpart, it directly queries rows to be displayed based on
/// its `objectValue`, an instance of `NSPredicate`, and matching rows from `rowTemplates`,
/// and array of `UIPredicateEditorRowTemplate`.
open class UIPredicateEditor: UICollectionViewController {
  
  /// contains the predicate evaluated by the editor.
  ///
  /// If one or more parts cannot be queried from the row templates, the property evaluates to `nil`.
  /// Should be set on initialization to pre-populate initial rows.
  public var predicate: NSPredicate
  
  public var rowTemplates: [UIPredicateEditorRowTemplate] = []
  
  /// A Boolean value that determines whether the rule editor is editable.
  ///
  /// The default is `true`.
  public var isEditable: Bool = true
  
  /// The formatting dictionary for the rule editor.
  ///
  /// If you assign a new the formatting dictionary to this property, it sets the current to formatting strings file name to `nil`.
  public var formattingDictionary: [String: String]?
  
  /// The name of the rule editor’s strings file.
  ///
  /// The `UIPredicateEditor` class looks for a strings file with the given name in the main bundle. If it finds a strings file resource with the given name, `UIPredicateEditor` loads it and sets it as the formatting dictionary for the receiver. You can obtain the resulting dictionary using the `formattingDictionary` property.
  ///
  /// If you assign a new dictionary to the `formattingDictionary` property, it sets the current to formatting strings file name to `nil`.
  var formattingStringsFilename: String?
  
  init(predicate: NSPredicate?, rowTemplates: [UIPredicateEditorRowTemplate]) {
    precondition(!rowTemplates.isEmpty, "Initialize the UIPredicateEditor with atleast one row template")
    
    if predicate == nil {
      self.predicate = NSPredicate()
    }
    else {
      self.predicate = predicate!
    }
    
    self.rowTemplates = rowTemplates
    
    // @TODO: Use a compositional layout
    super.init(collectionViewLayout: UICollectionViewFlowLayout())
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init?(coder:) is not implemented for UIPredicateEditor. Initialize using init(predicate:rowTemplates:) only.")
  }
  
  // MARK: Predicates
  
  /// Instructs the receiver to regenerate its predicate by invoking the corresponding internal methods.
  ///
  /// You typically invoke this method because something has changed (for example, a view's value).
  ///
  /// When predicates of row templates change, this is invoked automatically.
  public func reloadPredicate() {
    
  }
  
}
