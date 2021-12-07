//
//  Modules.swift
//  
//
//  Created by Tim Gymnich on 05.12.21.
//

import Foundation
@_implementationOnly import CSoapySDR


public enum Modules {
  
  /// Query the root installation path
  public static var installationPath: String { String(cString: CSoapySDR.SoapySDR_getRootPath()) }

  /// The list of paths automatically searched by loadModules().
  public static var searchPaths: [String] {
    var length = 0
    let pointer = CSoapySDR.SoapySDR_listSearchPaths(&length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.compactMap{ $0 }.map { String(cString: $0) }
  }
  
  public static var availableModules: [String] {
    var length = 0
    let pointer = SoapySDR_listModules(&length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.compactMap{ $0 }.map { String(cString: $0) }
  }
  
  public static func listModulePaths(path: String) -> [String] {
    var length = 0
    let pointer = CSoapySDR.SoapySDR_listModulesPath(path, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.compactMap{ $0 }.map { String(cString: $0) }
  }
  
  public static func loadModule(path: String) throws {
    let errorMessage = String(cString: SoapySDR_loadModule(path))
    guard errorMessage.isEmpty else {
      throw ModuleError(errorDescription: errorMessage)
    }
  }
  
  public static func unloadModule(path: String) throws {
    let errorMessage = String(cString: SoapySDR_unloadModule(path))
    guard errorMessage.isEmpty else {
      throw ModuleError(errorDescription: errorMessage)
    }
  }
  
  public static func loadModules() {
    SoapySDR_loadModules()
  }
  
  public static func unloadModules() {
    SoapySDR_unloadModules()
  }
  
  public static func getModuleVersion(path: String) -> String {
    return String(cString: SoapySDR_getModuleVersion(path))
  }
}

public struct ModuleError: Error, LocalizedError {
  public var errorDescription: String
}
