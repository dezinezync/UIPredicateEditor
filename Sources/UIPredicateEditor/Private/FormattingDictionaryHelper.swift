//
//  FormattingDictionaryHelper.swift
//  
//
//  Created by Nikhil Nigade on 03/06/22.
//

import Foundation

@available(iOS 14, macOS 11, *)
final class FormattingDictionaryHelper {
  
  private let formattingDictionary: [String: String]
  
  /// Initialize an instance with the localization strings dictionary
  /// - Parameter formattingDictionary: the strings dictionary
  init(formattingDictionary: [String: String]) {
    self.formattingDictionary = formattingDictionary
  }
  
  // MARK: API
  
  /// Find the left expression ($1) match from the template
  /// - Parameter string: the key to match
  /// - Returns: the key's localized value, if one was matched.
  func lhsMatch(for string: String) -> String? {
    let partialKeyToMatch = "%[\(string)]@"
    
    guard let firstMatch = firstKeyMatch(for: partialKeyToMatch) else {
      return nil
    }
    
    // extract the $1 key from the value
    let scanner = Scanner(string: firstMatch.value)
    _ = scanner.scanUpToString("%1$[")
    
    if let _ = scanner.scanString("%1$["),
       let localizedValue = scanner.scanUpToString("]@") {
      return localizedValue
    }
    
    return nil
  }
  
  /// Find the base value of the left expression ($1) from the formatting dictionary keys for the provided localized value.
  /// - Parameter value: the localized value
  /// - Returns: matched base value, if one was found
  func lhsReverseMatch(for value: String) -> String? {
    let partialValueToMatch = "%1$[\(value)]@"
    
    guard let firstMatch = firstValueMatch(for: partialValueToMatch) else {
      return nil
    }
    
    // extract the $1 key from the key
    let scanner = Scanner(string: firstMatch.key)
    _ = scanner.scanUpToString("%[")
    
    if let _ = scanner.scanString("%["),
       let baseValue = scanner.scanUpToString("]@") {
      return baseValue
    }
    
    return nil
  }
  
  /// Find the right expression ($3) match from the template
  /// - Parameter string: the key to match
  /// - Returns: the key's localized value, if one was matched.
  func rhsMatch(for string: String) -> String? {
    let partialKeyToMatch = "%[\(string)]@"
    
    guard let firstMatch = firstKeyMatch(for: partialKeyToMatch) else {
      return nil
    }
    
    // extract the $1 key from the value
    let scanner = Scanner(string: firstMatch.value)
    _ = scanner.scanUpToString("%3$[")
    
    if let _ = scanner.scanString("%3$["),
       let localizedValue = scanner.scanUpToString("]@") {
      return localizedValue
    }
    
    return nil
  }
  
  /// Find the base value of the right expression ($3) from the formatting dictionary keys for the provided localized value.
  /// - Parameter value: the localized value
  /// - Returns: matched base value, if one was found
  func rhsReverseMatch(for value: String) -> String? {
    let partialValueToMatch = "%3$[\(value)]@"
    
    guard let firstMatch = firstValueMatch(for: partialValueToMatch) else {
      return nil
    }
    
    // extract the $3 key from the key
    let scanner = Scanner(string: firstMatch.key)
    
    // skip the $1 and $2 components
    for _ in 0..<2 {
      _ = scanner.scanUpToString("%[")
      _ = scanner.scanString("%[")
      _ = scanner.scanUpToString("]@")
      _ = scanner.scanString("]@")
    }
    
    if let _ = scanner.scanString("%["),
       let baseValue = scanner.scanUpToString("]@") {
      return baseValue
    }
    
    return nil
  }
  
  // MARK: Internal
  
  /// Find the first matching template
  /// - Parameter partialKey: the partial key to match the format with
  /// - Returns: (key,value) tuple if a partial match was found
  internal func firstKeyMatch(for partialKey: String) -> (key: String, value: String)? {
    formattingDictionary.first(where: { (key: String, _: String) in
      key.contains(partialKey)
    })
  }
  
  /// Find the first matching template by value
  /// - Parameter partialKey: the partial value to match the format with
  /// - Returns: (key,value) tuple if a partial match was found
  internal func firstValueMatch(for partialValue: String) -> (key: String, value: String)? {
    formattingDictionary.first(where: { (_: String, value: String) in
      value.contains(partialValue)
    })
  }
  
}
