//
//  NSExpression+Value.swift
//  
//
//  Created by Nikhil Nigade on 03/06/22.
//

import Foundation

private let internalDateFormatter: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateStyle = .short
  return formatter
}()

extension NSExpression {
  var stringValue: String? {
    switch expressionType {
    case .constantValue:
      let value = constantValue
      if let value = value as? String {
        return value
      }
      
      if let value = value as? any BinaryInteger {
        return "\(value)"
      }
      
      if let value = value as? Decimal {
        return "\(value)"
      }
      
      if let value = value as? any BinaryFloatingPoint {
        return "\(value)"
      }
      
      if let value = value as? Bool {
        return value ? NSLocalizedString("True", bundle: .module, comment: "Boolean true value") : NSLocalizedString("False", bundle: .module, comment: "Boolean false value")
      }
      
      if let value = value as? Date {
        return internalDateFormatter.string(from: value)
      }
      
      if value is NSNull {
        return NSLocalizedString("null", bundle: .module, comment: "Null value")
      }
      
      return nil
      /*
       * Use the following format to implement additional cases as nessary
       if let value = value as? <#Type#> {
         return "\(value)"
       }
       */
      
    case .keyPath:
      return keyPath
    case .block:
      fatalError("Not supported in a predicate editor")
    default:
      fatalError("Not implemented")
    }
    
    // fatalError("Unknown or unimplemented expression type")
  }
}
