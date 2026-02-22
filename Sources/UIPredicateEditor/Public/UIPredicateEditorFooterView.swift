//
//  UIPredicateEditorFooterView.swift
//  
//
//  Created by Nikhil Nigade on 05/06/22.
//

#if os(iOS)
import UIKit

/// Footer view used in the last section of the ``UIPredicateEditor``. This section hosts a center aligned ``UIButton`` which displays a menu of all the left expressions present in the predicate editor. The user may select any one and add a new row to the predicate editor.
open class UIPredicateEditorFooterView: UICollectionReusableView {
  static let identifier = "UIPredicateEditor.FooterView"
  
  private(set) weak var button: UIButton!
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    constructView()
  }
  
  required public init?(coder: NSCoder) {
    super.init(coder: coder)
    constructView()
  }
  
  internal func constructView() {
    guard button == nil else { return }
    
    let button = UIButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    
    let title = NSLocalizedString("New", bundle: .module, comment: "New Row Button Title")
    
    var configuration = UIButton.Configuration.tinted()
    configuration.cornerStyle = .capsule
    configuration.buttonSize = .medium
    configuration.title = title
    
    button.configuration = configuration
    button.automaticallyUpdatesConfiguration = true
    button.showsMenuAsPrimaryAction = true
    
    button.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    button.setContentHuggingPriority(.defaultHigh, for: .vertical)
    
    addSubview(button)
    
    NSLayoutConstraint.activate([
      button.centerXAnchor.constraint(equalTo: centerXAnchor),
      button.topAnchor.constraint(equalTo: topAnchor, constant: 8.0),
      button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8.0),
    ])
    
    self.button = button
  }
}

extension UIPredicateEditorFooterView {
  static func register(on collectionView: UICollectionView) {
    collectionView.register(UIPredicateEditorFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: UIPredicateEditorFooterView.identifier)
  }
}
#endif
