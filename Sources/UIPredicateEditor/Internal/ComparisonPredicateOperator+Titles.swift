//
//  ComparisonPredicateOperator+Titles.swift
//  
//
//  Created by Nikhil Nigade on 31/05/22.
//

import Foundation

extension NSCompoundPredicate.LogicalType {
  var title: String {
    switch self {
    case .and:
      return "All"
    case .or:
      return "Any"
    case .not:
      return "None"
    @unknown default:
      fatalError("unknown logical type")
    }
  }
  
  var localizedTitle: String {
    let title = self.title
    return NSLocalizedString(title, bundle: .module, comment: title)
  }
  
  var formattingTitle: String {
    switch self {
    case .and:
      return "and"
    case .or:
      return "or"
    case .not:
      return "not"
    @unknown default:
      fatalError("unknown logical type")
    }
  }
  
  var localizedFormattingTitle: String {
    let title = self.formattingTitle
    return NSLocalizedString(title, bundle: .module, comment: title)
  }
}

extension NSComparisonPredicate.Operator {
  var title: String {
    switch self {
    case .lessThan:
      return "is less than"
    case .lessThanOrEqualTo:
      return "is less than or equal to"
    case .greaterThan:
      return "is greater than"
    case .greaterThanOrEqualTo:
      return "is greater than or equal to"
    case .equalTo:
      return "is"
    case .notEqualTo:
      return "is not"
    case .matches:
      return "matches"
    case .like:
      return "like"
    case .beginsWith:
      return "begins with"
    case .endsWith:
      return "ends with"
    case .in:
      return "in"
    case .customSelector:
      fatalError("Unimplemented")
    case .contains:
      return "contains"
    case .between:
      return "between"
    @unknown default:
      fatalError("Unknown operator")
    }
  }
  
  var localizedTitle: String {
    let title = self.title
    return NSLocalizedString(title, bundle: .module, comment: title)
  }
  
  static let allCases: [NSComparisonPredicate.Operator] = [
    .lessThan, .lessThanOrEqualTo, .greaterThan, .greaterThanOrEqualTo,
    .equalTo, .notEqualTo, .matches, .like, .beginsWith, .endsWith,
    .in, .contains, .between
  ]
  
  static func from(_ localizedTitle: String) -> NSComparisonPredicate.Operator {
    if let match = allCases.first(where: { $0.localizedTitle == localizedTitle }) {
      return match
    }
    
    fatalError("Unknown operator: \(localizedTitle)")
  }
}
