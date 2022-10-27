//
//  UIPredicateEditorViewController.swift
//  
//
//  Created by Nikhil Nigade on 26/05/22.
//

#if canImport(UIKit)
import UIKit

public protocol UIPredicateEditorRefreshing: NSObject {
  func reconfigure(_ cell: UIPredicateEditorBaseCell)
}

/// Concrete view controller for managing and editing predicates in a user interface.
///
/// It's `open` by default, encourgaging subclassing, but can be used as is.
///
/// Similar to its `NS` counterpart, it directly queries rows to be displayed based on its `objectValue`, an instance of `NSPredicate`, and matching rows from `rowTemplates`, and array of `UIPredicateEditorRowTemplate`.
open class UIPredicateEditorViewController: UICollectionViewController {
  
  public let predicateController = PredicateController()
  
  /// contains the predicate evaluated by the editor.
  ///
  /// If one or more parts cannot be queried from the row templates, the property evaluates to `nil`.
  /// Should be set on initialization to pre-populate initial rows.
  public var predicate: NSPredicate {
    get { predicateController.predicate }
    set { predicateController.predicate = newValue }
  }
  
  /// Row templates to be used by the receiver.
  ///
  /// These should correspond to the predicate the editor is currently editing.
  /// The number of row templates should match the number of options available to the user.
  /// These are never used directly, and instead copies are maintained.
  public var rowTemplates: [UIPredicateEditorRowTemplate] {
    get { predicateController.rowTemplates }
    set { predicateController.rowTemplates = newValue }
  }
  
  /// A Boolean value that determines whether the rule editor is editable.
  ///
  /// The default is `true`.
  public var isEditable: Bool = true {
    didSet {
      if isEditable != oldValue {
        updateControllerState()
      }
    }
  }
  
  /// The formatting dictionary for the rule editor.
  ///
  /// If you assign a new the formatting dictionary to this property, it sets the current to formatting strings file name to `nil`.
  public var formattingDictionary: [String: String]? {
    get { predicateController.formattingDictionary }
    set { predicateController.formattingDictionary = newValue }
  }
  
  public var formattingStringsFilename: String?
  // @TODO: Implementation pending
  
  /// show context menus from the rows to delete the row if necessary.
  open var showContextMenus: Bool { true }
  
  // MARK: Private
  
  /// Internal copy of row templates, which will be used to populate the collection view.
  ///
  /// Each row will have its own predicate which is used to form the predicate on the `UIPredicateEditor`.
  private var requiredRowTemplates: [UIPredicateEditorRowTemplate] {
    get { predicateController.requiredRowTemplates }
    set { predicateController.requiredRowTemplates = newValue }
  }
  
  /// set to `false` once the view appears and the initial predicate is setup.
  private var isLoading: Bool = true
  
  /// this is created on-demand everytime as the formatting dictionary may change during runtime
  var formattingHelper: FormattingDictionaryHelper {
    FormattingDictionaryHelper(formattingDictionary: formattingDictionary ?? [:])
  }
  
  // MARK: Init
  
  public init(predicate: NSPredicate, rowTemplates: [UIPredicateEditorRowTemplate], layout: UICollectionViewLayout) {
    precondition(!rowTemplates.isEmpty, "Initialize the UIPredicateEditor with atleast one row template")
    
    let compoundTypeRow = rowTemplates.first(where: { !$0.compoundTypes.isEmpty })
    
    precondition(compoundTypeRow != nil, "The row templates should always include one compound type row")
    
    super.init(collectionViewLayout: layout)
    
    self.predicate = predicate
    
    self.rowTemplates = rowTemplates
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init?(coder:) is not implemented for UIPredicateEditor. Initialize using init(predicate:rowTemplates:layout:) only.")
  }
  
  // MARK: Lifecycle
  open override func viewDidLoad() {
    super.viewDidLoad()
    
    // register our views
    UIPredicateEditorBaseCell.register(on: collectionView)
    UIPredicateEditorFooterView.register(on: collectionView)
    
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
    predicateController.reloadPredicate()
    
    collectionView.reloadData()
  }
  
  // MARK: Internal
  
  internal func updateControllerState() {
    guard Thread.isMainThread else {
      DispatchQueue.main.async {
        self.updateControllerState()
      }
      return
    }
    
    collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
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
    rowTemplate.formattingDictionary = formattingDictionary
    #if DEBUG
    print("UIPredicateEditorViewController: will use template: \(rowTemplate) for index: \(indexPath.item)")
    #endif
    
    if #available(iOS 14.0, *) {
      let configuration = UIPredicateEditorCellConfiguration(
        rowTemplate: rowTemplate,
        traitCollection: cell.traitCollection,
        isEditable: self.isEditable,
        indentationLevel: rowTemplate.indentationLevel
      )
      
      let backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
      
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
  
  // MARK: Footers
  open override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    
    let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: UIPredicateEditorFooterView.identifier, for: indexPath) as! UIPredicateEditorFooterView
    
    // only the last section should have a footer
    if indexPath.section != (numberOfSections(in: collectionView) - 1) {
      footerView.button?.removeFromSuperview()
    }
    else {
      footerView.constructView() // button may have been removed, add it back. Has no effect if the button already exists.
      configure(footerView: footerView)
    }
    
    return footerView
  }
  
  // MARK: Menus
  
  open override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    guard indexPath.section > 0 else { return nil }
    
    guard showContextMenus else { return nil }
    
    let deleteAction: UIAction? = requiredRowTemplates.count <= 1 ? nil : UIAction(
      title: NSLocalizedString("Delete", bundle: .module, comment: "Delete action under row comments"),
      image: UIImage(systemName: "trash"),
      attributes: .destructive) { [weak self] _ in
        guard let self = self else { return }
        
        let index = indexPath.item
        
        self.predicateController.deleteRowTemplate(at: index)
        self.refreshContentView()
        
        self.refreshContentView()
        self.collectionView.reloadData()
      }
    
    var additionalActions: [UIMenuElement] = []
    
    if requiredRowTemplates[indexPath.item].ID != nil {
      // parent row, allow adding sub-rows
      let addSubMenu = UIMenu(
        title: NSLocalizedString("Add Filter", comment: ""),
        image: UIImage(systemName: "text.append"),
        children: newRowMenuActions(for: requiredRowTemplates[indexPath.item])
      )
      
      additionalActions.append(addSubMenu)
    }
    
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
      UIMenu(
        title: NSLocalizedString("Row Actions", bundle: .module, comment: "Row Actions for predicate editor row template"),
        children: additionalActions + [deleteAction].compactMap { $0 }
      )
    }
  }

}

extension UIPredicateEditorViewController {
  
  /// Configure the compound type cell from the provided row template
  /// - Parameters:
  ///   - cell: cell to configure views on
  ///   - rowTemplate: the row template to fetch views from 
  public func configureCompoundTypesCell(_ cell: UIPredicateEditorBaseCell, rowTemplate: UIPredicateEditorRowTemplate) {
    
    if #available(iOS 14.0, *) {
      let backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
      cell.backgroundConfiguration = backgroundConfiguration
    }
    else {
      // Fallback on earlier versions
      cell.backgroundColor = .systemBackground
    }
    
    cell.prepareForUse()
    
    rowTemplate.refreshDelegate = self
    let views = rowTemplate.templateViews
    
    var previousViewAnchor: NSLayoutAnchor = cell.contentView.leadingAnchor
    
    for view in views {
      cell.contentView.addSubview(view)
      view.frame = .init(x: 0, y: 0, width: 40, height: 24)
      view.sizeToFit()
      
      view.translatesAutoresizingMaskIntoConstraints = false
      
      NSLayoutConstraint.activate([
        view.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor),
        view.leadingAnchor.constraint(equalTo: previousViewAnchor, constant: 8.0)
      ])
      
      if let control = view as? UIControl {
        control.isEnabled = self.isEditable
      }
      else {
        view.isUserInteractionEnabled = self.isEditable
      }
      
      previousViewAnchor = view.trailingAnchor
    }
  }
  
  public func configure(footerView: UIPredicateEditorFooterView) {
    guard let button = footerView.button else {
      return
    }
    
    button.menu = UIMenu(
      title: NSLocalizedString("New", bundle: .module, comment: "New button title"),
      children: newRowMenuActions()
    )
    
    button.isEnabled = self.isEditable
  }
  
  private func addRowTemplate(for leftExpressionTitle: String, parentRowTemplate: UIPredicateEditorRowTemplate? = nil) {
    if predicateController.addRowTemplate(for: leftExpressionTitle, for: parentRowTemplate) {
      collectionView.reloadData()
    }
  }
  
  private func newRowMenuActions(for parentRowTemplate: UIPredicateEditorRowTemplate? = nil) -> [UIMenuElement] {
    let formattingHelper = self.formattingHelper
    
    var actions: [UIMenuElement] = self.rowTemplates.map { template in
      template.leftExpressions.compactMap { expression in
        guard let stringValue = expression.stringValue else {
          return nil
        }
        
        if let formattedTitle = formattingHelper.lhsMatch(for: stringValue) {
          return formattedTitle
        }
        
        return stringValue
      }.map { title in
        UIAction(title: title) { [weak self] _ in
          #if DEBUG
          print("UIPredicateEditorViewController: new menu: selected expression with title: \(title)")
          #endif
          
          self?.addRowTemplate(for: title, parentRowTemplate: parentRowTemplate)
        }
      }
    }.reduce([], +)
    
    if parentRowTemplate == nil,
       rowTemplates.first(where: { row in
         guard let predicate = row.predicate else {
           return false
         }
         
         let format = predicate.predicateFormat.lowercased()
         
         return format.contains("and") || format.contains("or")
       }) != nil {
      // allow adding a new combo row
      let comboAction = UIAction(
        title: NSLocalizedString("Combination", comment: "")) { [weak self] _ in
          #if DEBUG
          print("UIPredicateEditorViewController: footer menu: adding a new combination row")
          #endif
          guard let _ = self else { return }
          
          // @TODO: Add a new combo row with a child row
        }
      
      actions.append(comboAction)
    }
    
    return actions
  }
}

// MARK: - UIPredicateEditorRefreshing
extension UIPredicateEditorViewController: UIPredicateEditorRefreshing {
  public func reconfigure(_ cell: UIPredicateEditorBaseCell) {
    guard !isLoading else {
      return
    }
    
    guard let indexPath = collectionView.indexPath(for: cell) else {
      return
    }
    
    if #available(iOS 15, macCatalyst 15.0, *) {
      collectionView.reconfigureItems(at: [indexPath])
    }
    else {
      collectionView.reloadItems(at: [indexPath])
    }
    
    refreshContentView()
  }
}

// MARK: - UIPredicateEditorContentRefreshing
extension UIPredicateEditorViewController: UIPredicateEditorContentRefreshing {
  
  /// refresh the predicate and thereby the controller's view
  public func refreshContentView() {
    // only called for the compund type predicate
    guard let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)),
          !cell.contentView.subviews.isEmpty,
          let button = cell.contentView.subviews[0] as? UIButton,
          let action = button.menu?.uiSelectedElements.first as? UIAction else {
      return
    }
    
    if action.title == NSCompoundPredicate.LogicalType.or.localizedTitle {
      predicateController.updatePredicate(for: .or)
    }
    else if action.title == NSCompoundPredicate.LogicalType.not.localizedTitle {
      predicateController.updatePredicate(for: .not)
    }
    else {
      predicateController.updatePredicate(for: .and)
    }
  }
}
#endif
