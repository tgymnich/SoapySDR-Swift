//
//  Logging.swift
//  
//
//  Created by Tim Gymnich on 06.12.21.
//

import Foundation
import Logging
@_implementationOnly import CSoapySDR

public var logger = Logger(label: "SoapySDR",
                    factory: StreamLogHandler.standardError)


func enableLogging(logLevel: SoapySDRLogLevel) {
  SoapySDR_setLogLevel(CSoapySDR.SoapySDRLogLevel(SoapySDRLogLevel.SOAPY_SDR_SSI.rawValue))
  
  SoapySDR_registerLogHandler { logLevel, message in
    guard let msg = message, let logLevel = SoapySDRLogLevel(rawValue: logLevel.rawValue) else { return }
    let message = String(cString: msg)
    
    switch logLevel {
    case .SOAPY_SDR_FATAL:
      logger.critical("\(message)", metadata: .none)
    case .SOAPY_SDR_CRITICAL:
      logger.critical("\(message)", metadata: .none)
    case .SOAPY_SDR_ERROR:
      logger.critical("\(message)", metadata: .none)
    case .SOAPY_SDR_WARNING:
      logger.warning("\(message)", metadata: .none)
    case .SOAPY_SDR_NOTICE:
      logger.notice("\(message)", metadata: .none)
    case .SOAPY_SDR_INFO:
      logger.info("\(message)", metadata: .none)
    case .SOAPY_SDR_DEBUG:
      logger.debug("\(message)", metadata: .none)
    case .SOAPY_SDR_TRACE:
      logger.trace("\(message)", metadata: .none)
    case .SOAPY_SDR_SSI:
      logger.trace("\(message)", metadata: .none)
    }
  }
}

enum SoapySDRLogLevel: UInt32 {
    /// A fatal error. The application will most likely terminate. This is the highest priority.
    case SOAPY_SDR_FATAL    = 1
    /// A critical error. The application might not be able to continue running successfully.
    case SOAPY_SDR_CRITICAL = 2
    /// An error. An operation did not complete successfully, but the application as a whole is not affected.
    case SOAPY_SDR_ERROR    = 3
    /// A warning. An operation completed with an unexpected result.
    case SOAPY_SDR_WARNING  = 4
    /// A notice, which is an information with just a higher priority.
    case SOAPY_SDR_NOTICE   = 5
    /// An informational message, usually denoting the successful completion of an operation.
    case SOAPY_SDR_INFO     = 6
    /// A debugging message.
    case SOAPY_SDR_DEBUG    = 7
    /// A tracing message. This is the lowest priority.
    case SOAPY_SDR_TRACE    = 8
    /// Streaming status indicators such as "U" (underflow) and "O" (overflow).
    case SOAPY_SDR_SSI      = 9
  
  var logLevel: Logger.Level {
    switch self {
    case .SOAPY_SDR_FATAL: return .critical
    case .SOAPY_SDR_CRITICAL: return .critical
    case .SOAPY_SDR_ERROR: return .error
    case .SOAPY_SDR_WARNING: return .warning
    case .SOAPY_SDR_NOTICE: return .notice
    case .SOAPY_SDR_INFO: return .info
    case .SOAPY_SDR_DEBUG: return .debug
    case .SOAPY_SDR_TRACE: return .trace
    case .SOAPY_SDR_SSI: return .trace
    }
  }
}
