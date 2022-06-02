//
//  UIPredicateEditorLayout.swift
//  
//
//  Created by Nikhil Nigade on 31/05/22.
//

import UIKit

@available(iOS 14, macCatalyst 11, *)
open class UIPredicateEditorLayout: UICollectionViewCompositionalLayout {
  
  /// Creates a prepared layout for using with the `UIPredicateEditor`.
  ///
  /// Uses a list configuration and layout with the `.insetGrouped` style.
  /// - Returns: `UICollectionCompositionalLayout` with list style
  open class func preparedLayout() -> UICollectionViewCompositionalLayout {
    
    var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    configuration.backgroundColor = .systemGroupedBackground
    configuration.showsSeparators = true
    
    return .list(using: configuration)
  }
}
