//
//  UIPredicateEditorCellConfiguration.swift
//  
//
//  Created by Nikhil Nigade on 02/06/22.
//

#if os(iOS)
import UIKit

@available(iOS 14.0, *)
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
  
  var indentationLevel: Int
  
  init(rowTemplate: UIPredicateEditorRowTemplate, traitCollection: UITraitCollection, isEditable: Bool = true, indentationLevel: Int, delegate: (any UIPredicateEditorContentRefreshing)?) {
    self.rowTemplate = rowTemplate
    self.state = UICellConfigurationState(traitCollection: traitCollection)
    self.isEditable = isEditable
    self.indentationLevel = indentationLevel
    self.delegate = delegate
  }
  
  public func makeContentView() -> UIView & UIContentView {
    UIPredicateEditorCellContentView(configuration: self)
  }
  
  public func updated(for state: UIConfigurationState) -> Self {
    guard let state = state as? UICellConfigurationState else {
      return self
    }
    
    let updatedConfig = self
    
    // mutate the configuration here if necessary
    updatedConfig.state = state
    
    return updatedConfig
  }
  
}

public protocol UIPredicateEditorContentRefreshing: NSObject {
  func refreshContentView()
}

@available(iOS 14.0, *)
open class UIPredicateEditorCellContentView: UIView, UIContentView {
  /// horizontal padding between two items and the leading and trailing edges of the content view
  var horizontalPadding: CGFloat { 8.0 }
  
  /// vertical padding between two items
  var interItemVerticalPadding: CGFloat { 4.0 }
  
  /// vertical padding between the content view and the items
  var verticalPadding: CGFloat { 8.0 }
  
  var indentationWidth: CGFloat { 12.0 }
  
  /// the leading padding applied to views based on the indentation level of the configuration.
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
    preservesSuperviewLayoutMargins = true
    apply(configuration: configuration)
  }
  
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: Layout
  open override func layoutSubviews() {
    super.layoutSubviews()
    
    let cellBounds = bounds
    
    if contentView == nil {
      constructView()
    }
    
    // match width and height of self
    contentView.frame = cellBounds
    
    // layout row template views
    var lineWidth: CGFloat = 0.0
    var frame: CGRect = .zero
    var lines: Int = 1
    
    leftExpressionView?.sizeToFit()
    frame = leftExpressionView?.frame ?? .zero
    frame.size = leftExpressionView?.intrinsicContentSize ?? .zero
    frame.origin.y = verticalPadding
    frame.origin.x = leadingPadding
    
    leftExpressionView?.frame = frame
    updateViewInteractionState(for: leftExpressionView)
    
    lineWidth = frame.maxX
    
    operatorView?.sizeToFit()
    
    if (lineWidth + horizontalPadding + (operatorView?.intrinsicContentSize.width ?? 0)) > (cellBounds.width - (leadingPadding + horizontalPadding)) {
      // move it to the next line
      var tempFrame = operatorView?.frame ?? .zero
      tempFrame.origin.y = frame.maxY + interItemVerticalPadding
      
      operatorView?.frame = tempFrame
      lineWidth = 0.0
      
      lines += 1
    }
    
    frame = operatorView?.frame ?? .zero
    frame.size = operatorView?.intrinsicContentSize ?? .zero
    frame.origin.x = lineWidth > 0 ? (lineWidth + horizontalPadding) : leadingPadding
    
    if lineWidth != 0.0 {
      frame.origin.y = verticalPadding
    }
    
    operatorView?.frame = frame
    updateViewInteractionState(for: operatorView)
    
    lineWidth = frame.maxX
    
    if let rightExpressionView = rightExpressionView {
      var rightExpressionViewSize: CGSize = .zero
      
      if rightExpressionView is UITextField {
        // occupy all available space
        var tempFrame = rightExpressionView.frame
        tempFrame.size.width = cellBounds.width - lineWidth - (horizontalPadding * 2.0) - leadingPadding
        
        rightExpressionView.frame = tempFrame
        rightExpressionViewSize = tempFrame.size
      }
      else {
        rightExpressionView.sizeToFit()
        rightExpressionViewSize = rightExpressionView.intrinsicContentSize
      }
      
      // include leading and trailing padding 
      if (lineWidth + (leadingPadding + horizontalPadding) + rightExpressionViewSize.width) > cellBounds.width {
        // move it to the next line
        var tempFrame = rightExpressionView.frame
        tempFrame.origin.y = frame.maxY + interItemVerticalPadding
        
        rightExpressionView.frame = tempFrame
        lineWidth = 0.0
        
        lines += 1
      }
      
      frame = rightExpressionView.frame
      frame.size = rightExpressionViewSize
      frame.origin.x = lineWidth > 0 ? (lineWidth + horizontalPadding) : leadingPadding
      
      if lineWidth != 0.0 {
        frame.origin.y = verticalPadding
      }
      
      rightExpressionView.frame = frame
      updateViewInteractionState(for: rightExpressionView)
      
      lineWidth = frame.maxX
    }
    
    // if all views fit within the line
    // center them vertically in the content view
    if lines == 1, lineWidth <= (cellBounds.width - (leadingPadding + horizontalPadding)) {
      for view: UIView? in [leftExpressionView, operatorView, rightExpressionView].compactMap ({ $0 }) {
        if let view = view {
          var frame = view.frame
          frame.origin.y = (cellBounds.height - frame.height) * 0.5
          
          view.frame = frame
        }
      }
    }
  }
  
  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    var size = super.sizeThatFits(size)
    
    let intrinsicSize = self.intrinsicContentSize
    if intrinsicSize.width > 0 {
      size = intrinsicSize
    }
    
    return size
  }
  
  open override var intrinsicContentSize: CGSize {
    get {
      var size = super.intrinsicContentSize
      
      let maxY: CGFloat = [leftExpressionView, operatorView, rightExpressionView].reduce(0) { partialResult, view in
        let y = ((view?.frame.maxY ?? 0) + verticalPadding)
        if y > partialResult {
          return y
        }
        
        return partialResult
      }
      
      if maxY > size.height {
        size.height = maxY
      }
         
      return size
    }
    set { }
  }
  
  // MARK: - Internal
  internal weak var leftExpressionView: UIView!
  internal weak var operatorView: UIView!
  internal weak var rightExpressionView: UIView?
  
  internal var additionalViews: [UIView] = []
  
  /// private view which hosts all the row template views.
  internal weak var contentView: UIView!
  
  internal var appliedConfiguration: UIPredicateEditorCellConfiguration!
  
  internal func apply(configuration: UIPredicateEditorCellConfiguration) {
    var stateWasDifferent: Bool = false
    
    if let appliedConfiguration = appliedConfiguration,
        appliedConfiguration == configuration {
        if appliedConfiguration.state != configuration.state {
            stateWasDifferent = true
        }
        
        if !stateWasDifferent {
            return
        }
    }
    
    appliedConfiguration = configuration
    appliedConfiguration.rowTemplate?.refreshDelegate = self
    
    // setup the view
    constructView()
  }
  
  internal func constructView() {
    if contentView == nil {
      let contentView = UIView()
      contentView.translatesAutoresizingMaskIntoConstraints = false
      contentView.backgroundColor = .clear
      
      addSubview(contentView)
      self.contentView = contentView
    }
    else {
      contentView.subviews.forEach { $0.removeFromSuperview() }
    }
    
    guard let rowTemplate = appliedConfiguration.rowTemplate else {
      return
    }
    
    let rowViews = rowTemplate.templateViews
    assert(rowViews.count >= 2, "Expected atleast 2 views")
    
    let leftExpressionView = rowViews[0]
    let operatorView = rowViews[1]
    var rightExpressionView: UIView?
    
    if rowViews.count > 2 {
      rightExpressionView = rowViews[2]
      
      if rowViews.count > 3 {
        // @TODO: Implement
        self.additionalViews = Array(rowViews[3..<rowViews.count])
      }
    }
    
    contentView.addSubview(leftExpressionView)
    self.leftExpressionView = leftExpressionView
    
    contentView.addSubview(operatorView)
    self.operatorView = operatorView
    
    if let rightExpressionView = rightExpressionView {
      contentView.addSubview(rightExpressionView)
      
      self.rightExpressionView = rightExpressionView
    }
    
    setNeedsLayout()
  }
  
  /// Update the user interaction flag on the view/control based on the applied configuration.
  /// - Parameter view: the view to update the interaction flag on. If it is an instance of ``UIControl``, its `isEnabled` property will be updated instead. 
  func updateViewInteractionState(for view: UIView?) {
    if let control = view as? UIControl {
      control.isEnabled = appliedConfiguration?.isEditable ?? true
    }
    else{
      view?.isUserInteractionEnabled = appliedConfiguration?.isEditable ?? true
    }
  }
}

@available(iOS 14.0, *)
extension UIPredicateEditorCellContentView: UIPredicateEditorContentRefreshing {
  public func refreshContentView() {
    setNeedsLayout()
    invalidateIntrinsicContentSize()
    
    self.appliedConfiguration.delegate?.refreshContentView()
  }
}
#endif
