//
//  NSExpression+Value.swift
//  
//
//  Created by Nikhil Nigade on 03/06/22.
//

import Foundation

extension NSExpression {
  var stringValue: String? {
    switch expressionType {
    case .constantValue:
      let value = constantValue
      if let value = value as? String {
        return value
      }
      
      if let value = value as? Int {
        return "\(value)"
      }
      
      if let value = value as? Int16 {
        return "\(value)"
      }
      
      if let value = value as? Int32 {
        return "\(value)"
      }
      
      if let value = value as? Int64 {
        return "\(value)"
      }
      
      if let value = value as? Decimal {
        return "\(value)"
      }
      
      if let value = value as? Float {
        return "\(value)"
      }
      
      if let value = value as? Double {
        return "\(value)"
      }
      
      if let value = value as? Bool {
        return value ? NSLocalizedString("True", comment: "") : NSLocalizedString("False", comment: "")
      }
      
      if let value = value as? Date {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: value)
      }
      
      if value is NSNull {
        return "null"
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
