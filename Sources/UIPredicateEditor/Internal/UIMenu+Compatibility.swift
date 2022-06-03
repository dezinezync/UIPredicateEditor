//
//  UIMenu+Compatibility.swift
//  
//
//  Created by Nikhil Nigade on 03/06/22.
//

import UIKit

extension UIMenu {
  
  /// iOS 14 compatibility method for fetching selected menu items
  var uiSelectedElements: [UIMenuElement] {
    if #available(iOS 15, macCatalyst 12.0, *) {
      return selectedElements
    }
    else {
      return children.filter { element in
        if let element = element as? UIMenu {
          return !element.uiSelectedElements.isEmpty
        }
        
        return (element as! UIAction).state == .on
      }.map { element in
        if let element = element as? UIMenu {
          return element.uiSelectedElements
        }
        
        return [element]
      }.reduce([], +)
    }
  }
}
