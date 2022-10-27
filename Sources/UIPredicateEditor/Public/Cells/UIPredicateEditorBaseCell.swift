//
//  UIPredicateEditorBaseCell.swift
//  
//
//  Created by Nikhil Nigade on 31/05/22.
//

#if canImport(UIKit)
import UIKit

/// A generic base class for rendering various subpredicates in the `UIPredicateEditor`. 
open class UIPredicateEditorBaseCell: UICollectionViewCell {
  static let identifier = "UIPredicateEditor.BaseCell"
  
  weak var refreshDelegate: UIPredicateEditorRefreshing?
  
  /// Called by the controller when the cell is about to be used for presentation
  open func prepareForUse() {
    // remove existing subviews
    for view in contentView.subviews {
      view.removeFromSuperview()
    }
  }
  
  open override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
    contentView.frame = self.bounds
    contentView.layoutIfNeeded()
    
    var size = super.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
    
    let intrinsicHeight = contentView.intrinsicContentSize.height
    if intrinsicHeight > size.height {
      size.height = intrinsicHeight
    }
    
    return size
  }
}

extension UIPredicateEditorBaseCell: UIPredicateEditorContentRefreshing {
  public func refreshContentView() {
    refreshDelegate?.reconfigure(self)
  }
}

extension UIPredicateEditorBaseCell {
  static func register(on collectionView: UICollectionView) {
    collectionView.register(UIPredicateEditorBaseCell.self, forCellWithReuseIdentifier: UIPredicateEditorBaseCell.identifier)
  }
}
#endif
