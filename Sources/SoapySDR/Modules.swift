//
//  Modules.swift
//  
//
//  Created by Tim Gymnich on 05.12.21.
//

import Foundation
@_implementationOnly import CSoapySDR


enum Modules {
  
  /// Query the root installation path
  public static var installationPath: String { String(cString: CSoapySDR.SoapySDR_getRootPath()) }

  /// The list of paths automatically searched by loadModules().
  public static var searchPaths: [String] {
    var length = 0
    let pointer = CSoapySDR.SoapySDR_listSearchPaths(&length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.compactMap{ $0 }.map { String(cString: $0) }
  }
  
  static var availableModules: [String] {
    var length = 0
    let pointer = SoapySDR_listModules(&length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.compactMap{ $0 }.map { String(cString: $0) }
  }
  
  static func listModulePaths(path: String) -> [String] {
    var length = 0
    let pointer = CSoapySDR.SoapySDR_listModulesPath(path, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.compactMap{ $0 }.map { String(cString: $0) }
  }
  
  static func loadModule(path: String) throws {
    let errorMessage = String(cString: SoapySDR_loadModule(path))
    guard errorMessage.isEmpty else {
      throw ModuleError(errorDescription: errorMessage)
    }
  }
  
  static func unloadModule(path: String) throws {
    let errorMessage = String(cString: SoapySDR_unloadModule(path))
    guard errorMessage.isEmpty else {
      throw ModuleError(errorDescription: errorMessage)
    }
  }
  
  static func loadModules() {
    SoapySDR_loadModules()
  }
  
  static func unloadModules() {
    SoapySDR_unloadModules()
  }
  
  static func getModuleVersion(path: String) -> String {
    return String(cString: SoapySDR_getModuleVersion(path))
  }
}

struct ModuleError: Error, LocalizedError {
  var errorDescription: String
}
