//
//  UIPredicateEditorCellConfiguration.swift
//  
//
//  Created by Nikhil Nigade on 02/06/22.
//

#if os(iOS)
import UIKit

open class UIPredicateEditorCellConfiguration: UIContentConfiguration, Equatable {
  
  public static func == (lhs: UIPredicateEditorCellConfiguration, rhs: UIPredicateEditorCellConfiguration) -> Bool {
    lhs.rowTemplate == rhs.rowTemplate
    && lhs.state == rhs.state
    && lhs.isEditable == rhs.isEditable
    && lhs.indentationLevel == rhs.indentationLevel
  }
  
  internal var state: UICellConfigurationState
  internal var isEditable: Bool
  
  private(set) weak var rowTemplate: UIPredicateEditorRowTemplate?
  
  weak var delegate: UIPredicateEditorContentRefreshing?
  
  let rowMenuActionsProvider: (() -> [UIMenuElement])?
  
  var indentationLevel: Int
  
  init(rowTemplate: UIPredicateEditorRowTemplate, traitCollection: UITraitCollection, isEditable: Bool = true, indentationLevel: Int, delegate: (any UIPredicateEditorContentRefreshing)?, rowMenuActionsProvider: (() -> [UIMenuElement])?) {
    self.rowTemplate = rowTemplate
    self.state = UICellConfigurationState(traitCollection: traitCollection)
    self.isEditable = isEditable
    self.indentationLevel = indentationLevel
    self.delegate = delegate
    self.rowMenuActionsProvider = rowMenuActionsProvider
  }
  
  public func makeContentView() -> UIView & UIContentView {
    UIPredicateEditorCellContentView(configuration: self)
  }
  
  public func updated(for state: UIConfigurationState) -> Self {
    guard let state = state as? UICellConfigurationState else {
      return self
    }
    
    let updatedConfig = self
    
    // Mutate the configuration here if necessary
    updatedConfig.state = state
    
    return updatedConfig
  }
  
}

@MainActor public protocol UIPredicateEditorContentRefreshing: NSObject {
  func refreshContentView()
}

open class UIPredicateEditorCellContentView: UIView, UIContentView {
  /// Horizontal padding between two items
  var horizontalPadding: CGFloat { 8.0 }
  
  /// Vertical padding between the content view and the items
  var verticalPadding: CGFloat { 8.0 }
  
  /// Vertical padding between rows when wrapping occurs
  var interItemVerticalPadding: CGFloat { 4.0 }
  
  var indentationWidth: CGFloat { 12.0 }
  
  /// The leading padding applied based on indentation level
  var leadingPadding: CGFloat {
    CGFloat((appliedConfiguration.indentationLevel + 1)) * indentationWidth
  }
  
  public var configuration: UIContentConfiguration {
    get { appliedConfiguration }
    set {
      guard let newConfig = newValue as? UIPredicateEditorCellConfiguration,
            newConfig != appliedConfiguration else {
        return
      }
      
      apply(configuration: newConfig)
    }
  }
  
  init(configuration: UIPredicateEditorCellConfiguration) {
    super.init(frame: .zero)
    apply(configuration: configuration)
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init?(coder:) has not been implemented")
  }
  
  // MARK: Layout
  
  open override func layoutSubviews() {
    super.layoutSubviews()
    performLayout(for: bounds.width, apply: true)
  }
  
  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    performLayout(for: size.width, apply: false)
  }
  
  open override var intrinsicContentSize: CGSize {
    performLayout(for: bounds.width > 0 ? bounds.width : 375, apply: false)
  }
  
  @discardableResult
  private func performLayout(for width: CGFloat, apply: Bool) -> CGSize {
    guard appliedConfiguration != nil else { return .zero }
    
    let contentWidth = width > 0 ? width : 375
    
    struct Line {
      var views: [(UIView, CGSize)] = []
      var height: CGFloat = 0
      var width: CGFloat = 0
    }
    
    var lines: [Line] = [Line()]
    let allViews: [UIView] = [leftExpressionView, operatorView, rightExpressionView].compactMap { $0 }
    
    for view in allViews {
      var size = view.intrinsicContentSize
      
      let currentLineIdx = lines.count - 1
      if view is UITextField {
        // Text field logic: Try to fit on current line if there's enough space, otherwise wrap.
        let remainingWidth = contentWidth - lines[currentLineIdx].width - leadingPadding - horizontalPadding
        if remainingWidth < 100 && lines[currentLineIdx].width > 0 {
          lines.append(Line())
        }
        
        let idx = lines.count - 1
        size.width = max(100, contentWidth - lines[idx].width - leadingPadding - horizontalPadding)
      }
      else {
        // Standard view logic: Wrap if it exceeds the width
        if lines[currentLineIdx].width + size.width + horizontalPadding > (contentWidth - leadingPadding) && lines[currentLineIdx].width > 0 {
          lines.append(Line())
        }
      }
      
      let idx = lines.count - 1
      lines[idx].views.append((view, size))
      lines[idx].width += size.width + horizontalPadding
      lines[idx].height = max(lines[idx].height, size.height)
    }
    
    // Calculate total height needed
    let contentHeight = lines.reduce(0) { $0 + $1.height } + CGFloat(lines.count - 1) * interItemVerticalPadding
    let totalHeight = contentHeight + (verticalPadding * 2)
    if apply {
      let viewHeight = bounds.height > 0 ? bounds.height : totalHeight
      var currentY = verticalPadding + max(0, (viewHeight - totalHeight) * 0.5)
      
      for line in lines {
        var currentX = leadingPadding
        for (view, size) in line.views {
          // Center each view vertically within the line's height
          let yOffset = (line.height - size.height) * 0.5
          view.frame = CGRect(x: currentX, y: currentY + yOffset, width: size.width, height: size.height).integral
          updateViewInteractionState(for: view)
          currentX += size.width + horizontalPadding
        }
        currentY += line.height + interItemVerticalPadding
      }
      
      // Trailing button (The "+" button for compound rows)
      if let trailingButton {
        let size = trailingButton.intrinsicContentSize
        let firstLine = lines.first
        let firstLineHeight = firstLine?.height ?? 0
        
        // Position relative to the first line's vertical center
        let basePadding = verticalPadding + max(0, (viewHeight - totalHeight) * 0.5)
        let yPos = basePadding + (firstLineHeight - size.height) * 0.5
        
        trailingButton.frame = CGRect(
          x: contentWidth - size.width - horizontalPadding,
          y: yPos,
          width: size.width,
          height: size.height
        ).integral
        updateViewInteractionState(for: trailingButton)
      }
    }
    
    return CGSize(width: contentWidth, height: totalHeight)
  }
  
  
  // MARK: - Internal
  internal weak var leftExpressionView: UIView?
  internal weak var operatorView: UIView?
  internal weak var rightExpressionView: UIView?
  internal weak var trailingButton: UIButton?
  
  internal var appliedConfiguration: UIPredicateEditorCellConfiguration!
  
  internal func apply(configuration: UIPredicateEditorCellConfiguration) {
    self.appliedConfiguration = configuration
    appliedConfiguration.rowTemplate?.refreshDelegate = self
    
    constructView()
  }
  
  internal func constructView() {
    // Clear existing views
    subviews.forEach { $0.removeFromSuperview() }
    leftExpressionView = nil
    operatorView = nil
    rightExpressionView = nil
    trailingButton = nil
    
    guard let rowTemplate = appliedConfiguration.rowTemplate else { return }
    
    let rowViews = rowTemplate.templateViews
    guard rowViews.count >= 2 else { return }
    
    leftExpressionView = rowViews[0]
    operatorView = rowViews[1]
    
    if let left = leftExpressionView { addSubview(left) }
    if let op = operatorView { addSubview(op) }
    
    if rowViews.count > 2 {
      rightExpressionView = rowViews[2]
      if let right = rightExpressionView { addSubview(right) }
    } else if !rowTemplate.compoundTypes.isEmpty,
              let rowMenuActionsProvider = appliedConfiguration.rowMenuActionsProvider {
      // Compound (Combination) row, add a trailing button to this view to show a popup menu (+)
      let button = UIButton(type: .system)
      var config = UIButton.Configuration.plain()
      config.buttonSize = .small
      config.image = UIImage(systemName: "plus.circle")
      button.configuration = config
      button.showsMenuAsPrimaryAction = true
      button.menu = UIMenu(children: rowMenuActionsProvider())
      
      addSubview(button)
      self.trailingButton = button
    }
    
    setNeedsLayout()
    invalidateIntrinsicContentSize()
  }
  
  func updateViewInteractionState(for view: UIView?) {
    let isEditable = appliedConfiguration?.isEditable ?? true
    if let control = view as? UIControl {
      control.isEnabled = isEditable
    } else {
      view?.isUserInteractionEnabled = isEditable
    }
  }
}

extension UIPredicateEditorCellContentView: UIPredicateEditorContentRefreshing {
  public func refreshContentView() {
    setNeedsLayout()
    invalidateIntrinsicContentSize()
    
    self.appliedConfiguration.delegate?.refreshContentView()
  }
}
#endif
