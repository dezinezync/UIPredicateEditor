//
//  NSPredicate+Formatted.swift
//  Pockity
//
//  Created by Nikhil Nigade on 12/06/22.
//

import Foundation

extension NSPredicate {
  
  /// Pre-formatted string created from the receiver's  format for displaying in the UI
  public var localizedFormat: String {
    let format = predicateFormat
    guard !format.isEmpty else {
      return ""
    }
    
    if let compound = self as? NSCompoundPredicate {
      // get formatted strings for subpredicates
      let subpredicates = compound.subpredicates
        .compactMap { $0 as? NSPredicate }
        .map { $0.localizedFormat }
      
      let type = compound.compoundPredicateType.localizedFormattingTitle.localizedUppercase
      
      // using a list formatter here does not make sense
      // as we are concatenating multiple logical predicates
      return subpredicates.joined(separator: " \(type) ")
    }
    
    if let comparison = self as? NSComparisonPredicate {
      let lhsValue = comparison.leftExpression.stringValue ?? ""
      let rhsValue = comparison.rightExpression.stringValue ?? ""
      let operatorValue = comparison.predicateOperatorType.localizedTitle
      
      // @TODO: Handle RTL languages
      return "\(lhsValue) \(operatorValue) \(rhsValue)"
    }
    
    return format
  }
}
