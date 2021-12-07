//
//  ArgInfo.swift
//  
//
//  Created by Tim Gymnich on 07.12.21.
//

import Foundation
@_implementationOnly import CSoapySDR


enum ArgInfoType {
  case Bool(value: Bool)
  case Integer(value: Int)
  case Float(value: Double)
  case String(value: String)
}

final class ArgInfo<T> {
  private var impl: SoapySDRArgInfo
  var key: String { String(cString: impl.key) }
  var value: ArgInfoType {
    let type = impl.type.rawValue
    let value = String(cString: impl.value)
    switch type {
    case SOAPY_SDR_ARG_INFO_BOOL.rawValue: return .Bool(value: Bool(value)!)
    case SOAPY_SDR_ARG_INFO_INT.rawValue: return .Integer(value: Int(value)!)
    case SOAPY_SDR_ARG_INFO_FLOAT.rawValue: return .Float(value: Double(value)!)
    case SOAPY_SDR_ARG_INFO_STRING.rawValue: return .String(value: value)
    default: fatalError()
    }
  }
  
  init(_ info: SoapySDRArgInfo) {
    self.impl = info
  }
  
  deinit {
    SoapySDRArgInfo_clear(&impl)
  }
  
}
