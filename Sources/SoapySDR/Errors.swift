//
//  File.swift
//  
//
//  Created by Tim Gymnich on 05.12.21.
//

import Foundation
@_implementationOnly import CSoapySDR

public enum SDRError: RawRepresentable, LocalizedError {
  public typealias RawValue = Int32
  
  /// Returned when read has a timeout.
  case SOAPY_SDR_TIMEOUT
  /// Returned for non-specific stream errors.
  case SOAPY_SDR_STREAM_ERROR
  /// Returned when read has data corruption.
  /// For example, the driver saw a malformed packet.
  case SOAPY_SDR_CORRUPTION
  /// Returned when read has an overflow condition.
  /// For example, and internal buffer has filled.
  case SOAPY_SDR_OVERFLOW
  /// Returned when a requested operation or flag setting
  /// is not supported by the underlying implementation.
  case SOAPY_SDR_NOT_SUPPORTED
  /// Returned when a the device encountered a stream time
  /// which was expired (late) or too early to process.
  case SOAPY_SDR_TIME_ERROR
  /// Returned when write caused an underflow condition.
  /// For example, a continuous stream was interrupted.
  case SOAPY_SDR_UNDERFLOW
  case unkown(code: Int32)
  
  public var rawValue: Int32 {
    switch self {
    case .SOAPY_SDR_TIMEOUT: return -1
    case .SOAPY_SDR_STREAM_ERROR: return -2
    case .SOAPY_SDR_CORRUPTION: return -3
    case .SOAPY_SDR_OVERFLOW: return -4
    case .SOAPY_SDR_NOT_SUPPORTED: return -5
    case .SOAPY_SDR_TIME_ERROR: return -6
    case .SOAPY_SDR_UNDERFLOW: return -7
    case .unkown(code: let code): return code
    }
  }
  
  public init(rawValue: Int32) {
    switch rawValue {
    case -1: self = .SOAPY_SDR_TIMEOUT
    case -2: self = .SOAPY_SDR_STREAM_ERROR
    case -3: self = .SOAPY_SDR_CORRUPTION
    case -4: self = .SOAPY_SDR_OVERFLOW
    case -5: self = .SOAPY_SDR_NOT_SUPPORTED
    case -6: self = .SOAPY_SDR_TIME_ERROR
    case -7: self = .SOAPY_SDR_UNDERFLOW
    default: self = .unkown(code: rawValue)
    }
  }
  
  public var errorDescription: String? {
    return String(cString: CSoapySDR.SoapySDR_errToStr(rawValue)).nonEmpty
  }
}

public struct ModuleError: Error, LocalizedError {
  public var errorDescription: String
}

public struct DeviceError: Error, LocalizedError {
  public var errorDescription: String
}
