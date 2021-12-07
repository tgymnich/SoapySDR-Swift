//
//  ErrorHandling.swift
//  
//
//  Created by Tim Gymnich on 06.12.21.
//

@_implementationOnly import CSoapySDR

func checkReturnCode(closure: () -> Int32) throws {
  let errorCode = closure()
  guard errorCode == 0 else {
    throw SDRError(rawValue: errorCode)
  }
}

func checkReturnCode(closure: () throws -> Int32) throws {
  let errorCode = try closure()
  guard errorCode == 0 else {
    throw SDRError(rawValue: errorCode)
  }
}

func checkError<T>(closure: () -> T) throws -> T {
  let result = closure()
  let status = CSoapySDR.SoapySDRDevice_lastStatus()
  guard status == 0 else {
    let message = String(cString: SoapySDRDevice_lastError())
    throw DeviceError(errorDescription: message)
  }
  return result
}
