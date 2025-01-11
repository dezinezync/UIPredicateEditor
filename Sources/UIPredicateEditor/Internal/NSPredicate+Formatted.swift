//
//  NSPredicate+Formatted.swift
//  Zypher
//
//  Created by Nikhil Nigade on 12/06/22.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

extension NSPredicate {
  
  public func localizedString(using formattingHelper: FormattingDictionaryHelper?) -> String {
    guard let formattingHelper else {
      return self.localizedFormat
    }
    
    let format = predicateFormat
    guard !format.isEmpty else {
      return ""
    }
    
    if let compound = self as? NSCompoundPredicate {
      // get formatted strings for subpredicates
      let subpredicates = compound.subpredicates
        .compactMap { $0 as? NSPredicate }
        .map { $0.localizedString(using: formattingHelper) }
      
      let type = compound.compoundPredicateType.localizedFormattingTitle.localizedUppercase
      
      // Using a list formatter here does not make sense
      // as we are concatenating multiple logical predicates
      return subpredicates.joined(separator: " \(type) ")
    }
    
    if let comparison = self as? NSComparisonPredicate {
      let lhsValue = formattingHelper.lhsMatch(for: comparison.leftExpression.stringValue ?? "") ?? ""
      let rhsValue = formattingHelper.rhsMatch(for: comparison.rightExpression.stringValue ?? "") ??  comparison.rightExpression.stringValue ?? ""
      let operatorValue = comparison.predicateOperatorType.localizedTitle
      
      return "\(lhsValue) \(operatorValue) \(rhsValue)"
    }
    
    return format
  }
  #if canImport(UIKit)
  public func localizedAttributedString(
    using formattingHelper: FormattingDictionaryHelper?,
    baseFont: UIFont = .preferredFont(forTextStyle: .body),
    textColor: UIColor = .label,
    indent: Int = 0
  ) -> NSAttributedString {
    guard let formattingHelper else {
      return NSAttributedString(string: self.localizedFormat)
    }
    
    let format = predicateFormat
    guard !format.isEmpty else {
      return NSAttributedString(string: "")
    }
    
    if let compound = self as? NSCompoundPredicate {
      // get formatted strings for subpredicates
      let subpredicates = compound.subpredicates
        .compactMap { $0 as? NSPredicate }
        .map {
          $0.localizedAttributedString(
            using: formattingHelper,
            baseFont: baseFont,
            textColor: textColor,
            indent: indent + 1
          )
        }
      
      let type = compound.compoundPredicateType.localizedFormattingTitle.localizedUppercase
      
      // Using a list formatter here does not make sense
      // as we are concatenating multiple logical predicates
      let copyToReturn = NSMutableAttributedString(string: "")
      let lastIndex = subpredicates.count - 1
      subpredicates.enumerated().forEach { (index, attr) in
        copyToReturn.append(attr)
        if index < lastIndex {
          copyToReturn.append(NSAttributedString(string: "\n\(String(repeating: "\t", count: indent))\(type) ", attributes: [
            .font: UIFont.systemFont(ofSize: baseFont.pointSize - 1.0, weight: .medium),
            .foregroundColor: textColor.withAlphaComponent(0.5)
          ]))
        }
      }
      
      return copyToReturn
    }
    
    if let comparison = self as? NSComparisonPredicate {
      let lhsValue = formattingHelper.lhsMatch(for: comparison.leftExpression.stringValue ?? "") ?? ""
      let rhsValue = formattingHelper.rhsMatch(for: comparison.rightExpression.stringValue ?? "") ??  comparison.rightExpression.stringValue ?? ""
      let operatorValue = comparison.predicateOperatorType.localizedTitle
      
      let format = "\(lhsValue) \(operatorValue) \(rhsValue)"
      let attr = NSMutableAttributedString(string: format, attributes: [
        .font: baseFont,
        .foregroundColor: textColor
      ])
      
      if let operatorRange = format.range(of: operatorValue) {
        let range = NSRange(operatorRange, in: format)
        if range.length > 0 {
          attr.setAttributes([
            .foregroundColor: textColor.withAlphaComponent(0.5),
            .font: UIFont.italicSystemFont(ofSize: baseFont.pointSize - 1),
          ], range: range)
        }
      }
      
      return attr
    }
    
    return NSAttributedString(string: format, attributes: [
      .font: baseFont,
      .foregroundColor: textColor
    ])
  }
  #endif
  
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
