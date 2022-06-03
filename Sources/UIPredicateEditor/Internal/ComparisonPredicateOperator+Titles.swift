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
    return NSLocalizedString(title, comment: title)
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
    return NSLocalizedString(title, comment: title)
  }
  
  static func from(_ localizedTitle: String) -> NSComparisonPredicate.Operator {
    switch localizedTitle {
    case NSLocalizedString("is less than", comment: "less than"):
      return .lessThan
    case NSLocalizedString("is less than or equal to", comment: "less than or equal to"):
      return .lessThanOrEqualTo
    case NSLocalizedString("is greater than", comment: "greater than"):
      return .greaterThan
    case NSLocalizedString("is greater than or equal to", comment: "greater than or equal to"):
      return .greaterThanOrEqualTo
    case NSLocalizedString("is", comment: "is"):
      return .equalTo
    case NSLocalizedString("is not", comment: "is not"):
      return .notEqualTo
    case NSLocalizedString("matches", comment: "matches"):
      return .matches
    case NSLocalizedString("like", comment: "like"):
      return .like
    case NSLocalizedString("begins with", comment: "begins with"):
      return .beginsWith
    case NSLocalizedString("ends with", comment: "ends with"):
      return .endsWith
    case NSLocalizedString("in", comment: "in"):
      return .in
    case NSLocalizedString("contains", comment: "contains"):
      return .contains
    case NSLocalizedString("between", comment: "between"):
      return .between
    default:
      fatalError("Unknown operator")
    }
  }
}
