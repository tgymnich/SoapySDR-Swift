//
//  Kwargs.swift
//  
//
//  Created by Tim Gymnich on 07.12.21.
//

import Foundation
@_implementationOnly import CSoapySDR


final class Kwargs {
  private var impl: SoapySDRKwargs
  
  init(_ kwargs: SoapySDRKwargs) {
    self.impl = kwargs
  }
  
  func toDictionary() -> [String: String] {
    let csv = String(cString: SoapySDRKwargs_toString(&impl))
    return csv
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .split(separator: "=")
      .reduce(into: [:]) { $0[String($1[0])] = String($1[1]) }
  }
  
  subscript(key: String) -> String? {
    get {
      return String(cString: SoapySDRKwargs_get(&impl, key)).nonEmpty
    } set {
      SoapySDRKwargs_set(&impl, key, newValue)
    }
  }
  
  deinit {
    SoapySDRKwargs_clear(&impl)
  }
}

typealias KwargsList = [Kwargs]
