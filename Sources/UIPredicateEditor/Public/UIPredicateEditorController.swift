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

public protocol UIPredicateEditorRefreshing: NSObject {
  func reconfigure(_ cell: UIPredicateEditorBaseCell)
}

/// Concrete view controller for managing and editing predicates in a user interface.
/// It's `open` by default, encourgaging subclassing, but can be used as is.
///
/// Similar to its `NS` counterpart, it directly queries rows to be displayed based on
/// its `objectValue`, an instance of `NSPredicate`, and matching rows from `rowTemplates`,
/// and array of `UIPredicateEditorRowTemplate`.
open class UIPredicateEditorController: UICollectionViewController {
  
  /// contains the predicate evaluated by the editor.
  ///
  /// If one or more parts cannot be queried from the row templates, the property evaluates to `nil`.
  /// Should be set on initialization to pre-populate initial rows.
  public var predicate: NSPredicate
  
  /// Row templates to be used by the receiver.
  ///
  /// These should correspond to the predicate the editor is currently editing.
  /// The number of row templates should match the number of options available to the user.
  /// These are never used directly, and instead copies are maintained.
  public var rowTemplates: [UIPredicateEditorRowTemplate] = []
  
  /// A Boolean value that determines whether the rule editor is editable.
  ///
  /// The default is `true`.
  public var isEditable: Bool = true
  // @TODO: Implementation pending
  
  /// The formatting dictionary for the rule editor.
  ///
  /// If you assign a new the formatting dictionary to this property, it sets the current to formatting strings file name to `nil`.
  public var formattingDictionary: [String: String]?
  // @TODO: Implementation pending
  
  /// The name of the rule editor’s strings file.
  ///
  /// The `UIPredicateEditor` class looks for a strings file with the given name in the main bundle. If it finds a strings file resource with the given name, `UIPredicateEditor` loads it and sets it as the formatting dictionary for the receiver. You can obtain the resulting dictionary using the `formattingDictionary` property.
  ///
  /// If you assign a new dictionary to the `formattingDictionary` property, it sets the current to formatting strings file name to `nil`.
  public var formattingStringsFilename: String?
  // @TODO: Implementation pending
  
  /// Internal copy of row templates, which will be used to populate the collection view.
  ///
  /// Each row will have its own predicate which is used to form the predicate on the `UIPredicateEditor`.
  private var requiredRowTemplates: [UIPredicateEditorRowTemplate] = []
  
  /// set to `false` once the view appears and the initial predicate is setup.
  private var isLoading: Bool = true
  
  public init(predicate: NSPredicate, rowTemplates: [UIPredicateEditorRowTemplate], layout: UICollectionViewLayout) {
    precondition(!rowTemplates.isEmpty, "Initialize the UIPredicateEditor with atleast one row template")
    
    let compoundTypeRow = rowTemplates.first(where: { !$0.compoundTypes.isEmpty })
    
    precondition(compoundTypeRow != nil, "The row templates should always include one compound type row")
    
    self.predicate = predicate
    
    self.rowTemplates = rowTemplates
    
    super.init(collectionViewLayout: layout)
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init?(coder:) is not implemented for UIPredicateEditor. Initialize using init(predicate:rowTemplates:layout:) only.")
  }
  
  // MARK: Lifecycle
  open override func viewDidLoad() {
    super.viewDidLoad()
    
    // register our cell
    UIPredicateEditorBaseCell.register(on: collectionView)
    
    // reload the predicate and update the view
    reloadPredicate()
  }
  
  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    isLoading = false
  }
  
  // MARK: Predicates
  
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
      let copy = firstMatch.copy() as! UIPredicateEditorRowTemplate
      
      // update the predicate so it can internally update values on its views
      copy.setPredicate(predicate)
      
      return copy
    }
    
    self.requiredRowTemplates = matchingRowTemplates
    
    collectionView.reloadData()
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
  
  public override func numberOfSections(in collectionView: UICollectionView) -> Int {
    if requiredRowTemplates.isEmpty {
      return 0
    }
    
    return 2
  }
  
  public override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    }
    
    return requiredRowTemplates.count
  }
  
  open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UIPredicateEditorBaseCell.identifier, for: indexPath) as! UIPredicateEditorBaseCell
    
    cell.refreshDelegate = self
    
    if indexPath.section == 0 {
      // compound types row
      guard let rowTemplate = rowTemplates.first(where: { !$0.compoundTypes.isEmpty }) else {
        fatalError("Row template for compound type row not found (any/all/not)")
      }
      
      configureCompoundTypesCell(cell, rowTemplate: rowTemplate)
      
      return cell
    }
    
    let rowTemplate = requiredRowTemplates[indexPath.item]
    
    #if DEBUG
    print("UIPredicateEditor: will use template: \(rowTemplate) for index: \(indexPath.item)")
    #endif
    
    if #available(iOS 14.0, *) {
      let configuration = UIPredicateEditorCellConfiguration(rowTemplate: rowTemplate, traitCollection: cell.traitCollection)
      
      var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
      backgroundConfiguration.backgroundColor = .systemBackground
      
      cell.contentConfiguration = configuration
      cell.backgroundConfiguration = backgroundConfiguration
      
      configuration.delegate = cell
    }
    else {
      // Fallback on earlier versions
      fatalError("Implement in your subclass by vendoring a custom cell")
    }
    
    return cell
  }

}

extension UIPredicateEditorController {
  
  /// Configure the compound type cell from the provided row template
  /// - Parameters:
  ///   - cell: cell to configure views on
  ///   - rowTemplate: the row template to fetch views from 
  open func configureCompoundTypesCell(_ cell: UIPredicateEditorBaseCell, rowTemplate: UIPredicateEditorRowTemplate) {
    
    if #available(iOS 14.0, *) {
      var backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
      backgroundConfiguration.backgroundColor = .systemBackground
      
      cell.backgroundConfiguration = backgroundConfiguration
    }
    else {
      // Fallback on earlier versions
      cell.backgroundColor = .systemBackground
    }
    
    // remove existing subviews
    for view in cell.contentView.subviews {
      view.removeFromSuperview()
    }
    
    let views = rowTemplate.templateViews
    
    var previousViewAnchor: NSLayoutAnchor = cell.contentView.leadingAnchor
    
    for view in views {
      cell.contentView.addSubview(view)
      view.frame = .init(x: 0, y: 0, width: 40, height: 24)
      view.sizeToFit()
      
      view.translatesAutoresizingMaskIntoConstraints = false
      
      NSLayoutConstraint.activate([
        view.widthAnchor.constraint(greaterThanOrEqualToConstant: view.frame.width),
        view.heightAnchor.constraint(equalToConstant: view.frame.height),
        view.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
        view.leadingAnchor.constraint(equalTo: previousViewAnchor, constant: 8.0)
      ])
      
      previousViewAnchor = view.trailingAnchor
    }
  }
}

extension UIPredicateEditorController: UIPredicateEditorRefreshing {
  public func reconfigure(_ cell: UIPredicateEditorBaseCell) {
    
    guard !isLoading else {
      return
    }
    
    guard let indexPath = collectionView.indexPath(for: cell) else {
      return
    }
    
    if #available(iOS 15, macCatalyst 12.0, *) {
      collectionView.reconfigureItems(at: [indexPath])
    }
    else {
      collectionView.reloadItems(at: [indexPath])
    }
  }
}
