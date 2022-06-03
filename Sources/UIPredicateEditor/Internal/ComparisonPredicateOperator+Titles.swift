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
      return NSLocalizedString("is less than", comment: "less than")
    case .lessThanOrEqualTo:
      return NSLocalizedString("is less than or equal to", comment: "less than or equal to")
    case .greaterThan:
      return NSLocalizedString("is greater than", comment: "greater than")
    case .greaterThanOrEqualTo:
      return NSLocalizedString("is greater than or equal to", comment: "greater than or equal to")
    case .equalTo:
      return NSLocalizedString("is", comment: "is")
    case .notEqualTo:
      return NSLocalizedString("is not", comment: "is not")
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
