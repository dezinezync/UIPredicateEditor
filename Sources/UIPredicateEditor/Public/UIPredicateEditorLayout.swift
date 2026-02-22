//
//  UIPredicateEditorLayout.swift
//  
//
//  Created by Nikhil Nigade on 31/05/22.
//

#if os(iOS)
import UIKit

@available(iOS 14, macCatalyst 14, *)
open class UIPredicateEditorLayout: UICollectionViewCompositionalLayout {
  
  /// Creates a prepared layout for using with the `UIPredicateEditor`.
  ///
  /// Uses a list configuration and layout with the `.insetGrouped` style.
  /// - Returns: `UICollectionCompositionalLayout` with list style
  open class func preparedLayout(trailingSwipeActionsConfigurationProvider: UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider? = nil, itemSeparatorHandler: UICollectionLayoutListConfiguration.ItemSeparatorHandler? = nil) -> UICollectionViewCompositionalLayout {
    var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
    configuration.backgroundColor = .systemGroupedBackground
    configuration.showsSeparators = true
    configuration.footerMode = .supplementary
    configuration.trailingSwipeActionsConfigurationProvider = trailingSwipeActionsConfigurationProvider
    
    configuration.itemSeparatorHandler = itemSeparatorHandler
    
    return .list(using: configuration)
  }
}
#endif
