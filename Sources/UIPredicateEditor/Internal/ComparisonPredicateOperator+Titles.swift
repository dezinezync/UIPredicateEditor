//
//  ComparisonPredicateOperator+Titles.swift
//  
//
//  Created by Nikhil Nigade on 31/05/22.
//

import Foundation

extension NSCompoundPredicate.LogicalType {
  var localizedTitle: String {
    switch self {
    case .and:
      return NSLocalizedString("All", comment: "All")
    case .or:
      return NSLocalizedString("Any", comment: "Any")
    case .not:
      return NSLocalizedString("None", comment: "None")
    @unknown default:
      fatalError("unknown logical type")
    }
  }
}

extension NSComparisonPredicate.Operator {
  var localizedTitle: String {
    switch self {
    case .lessThan:
      return NSLocalizedString("less than", comment: "less than")
    case .lessThanOrEqualTo:
      return NSLocalizedString("less than or equal to", comment: "less than or equal to")
    case .greaterThan:
      return NSLocalizedString("greater than", comment: "greater than")
    case .greaterThanOrEqualTo:
      return NSLocalizedString("greater than or equal to", comment: "greater than or equal to")
    case .equalTo:
      return NSLocalizedString("equal to", comment: "equal to")
    case .notEqualTo:
      return NSLocalizedString("not equal to", comment: "not equal to")
    case .matches:
      return NSLocalizedString("matches", comment: "matches")
    case .like:
      return NSLocalizedString("like", comment: "like")
    case .beginsWith:
      return NSLocalizedString("begins with", comment: "begins with")
    case .endsWith:
      return NSLocalizedString("ends with", comment: "ends with")
    case .in:
      return NSLocalizedString("in", comment: "in")
    case .customSelector:
      fatalError("Unimplemented")
    case .contains:
      return NSLocalizedString("contains", comment: "contains")
    case .between:
      return NSLocalizedString("between", comment: "between")
    @unknown default:
      fatalError("Unknown operator")
    }
  }
  
  static func from(_ title: String) -> NSComparisonPredicate.Operator {
    switch title {
    case NSLocalizedString("less than", comment: "less than"):
      return .lessThan
    case NSLocalizedString("less than or equal to", comment: "less than or equal to"):
      return .lessThanOrEqualTo
    case NSLocalizedString("greater than", comment: "greater than"):
      return .greaterThan
    case NSLocalizedString("greater than or equal to", comment: "greater than or equal to"):
      return .greaterThanOrEqualTo
    case NSLocalizedString("equal to", comment: "equal to"):
      return .equalTo
    case NSLocalizedString("not equal to", comment: "not equal to"):
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
