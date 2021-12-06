//
//  File.swift
//  
//
//  Created by Tim Gymnich on 05.12.21.
//

import Foundation
@_implementationOnly import CSoapySDR
import OpenGL

public enum Direction: Int32 {
  /// Receive
  case RX = 1
  /// Transmit
  case TX = 0
}

class Stream {
  let impl: OpaquePointer
  let device: Device
  let direction: Direction
  var MTU: Int { SoapySDRDevice_getStreamMTU(device.impl, impl) }
  /// Get a number of channels given the streaming direction.
  private var numberOfChannels: Int { SoapySDRDevice_getNumChannels(impl, direction.rawValue) }
  public var channels: [Channel] { (0..<numberOfChannels).map { Channel(device: device, direction: direction, index: $0) } }
  
  /// Initialize a stream given a list of channels and stream arguments.
  /// The implementation may change switches or power-up components.
  /// All stream API calls should be usable with the new stream object after setupStream() is complete,
  /// regardless of the activity state.
  private init?(device: Device, direction: Direction, format: String, channels: [Int], kwargs: UnsafePointer<SoapySDRKwargs>) {
    guard let handle = SoapySDRDevice_setupStream(device.impl, direction.rawValue, format, channels, channels.count, kwargs) else { return nil }
    self.impl = handle
    self.direction = direction
    self.device = device
  }
  
  convenience init?(device: Device, direction: Direction) {
    var kwargs = SoapySDRKwargs()
    self.init(device: device, direction: direction, format: "", channels: [], kwargs: &kwargs)
  }
  
  subscript(index: Int) -> Channel {
      get { channels[index] }
  }
  
  /// Activate a stream. Call activate to prepare a stream before using read/write().
  /// The implementation control switches or stimulate data flow.
  func activateStream(flags: Flags) throws {
    try cTry { SoapySDRDevice_activateStream(device.impl, impl, flags.rawValue, flags.timeNs ?? 0, flags.numElemnts ?? 0) }
  }
  
  /// Deactivate a stream. Call deactivate when not using using read/write().
  /// The implementation control switches or halt data flow.
  func deactivateStream(flags: Flags) throws {
    try cTry { SoapySDRDevice_deactivateStream(device.impl, impl, flags.rawValue, flags.timeNs ?? 0) }
  }
  
  func readStream(flags: Flags, timeout: Int) throws {
    let size = 10
    var buffer: [Data] = []
    var timeNs: Int64 = 0
    var flags: Int32 = flags.rawValue
    
//    try buffer.withUnsafeMutableBytes { ptr in
//      let errorOrCount = SoapySDRDevice_readStream(device.impl, impl, ptr.baseAddress, size, &flags, &timeNs, timeout)
//      guard let error >= 0 else {
//        throw SDRError(rawValue: error)
//      }
//    }
    // return (data , flags)
  }
  
  func writeStream(data: [Data]) throws {
    guard data.count == channels.count else { throw SDRError.SOAPY_SDR_NOT_SUPPORTED }
//    SoapySDRDevice_writeStream(device.impl, impl, <#T##buffs: UnsafePointer<UnsafeRawPointer?>!##UnsafePointer<UnsafeRawPointer?>!#>, data.first?.count, <#T##flags: UnsafeMutablePointer<Int32>!##UnsafeMutablePointer<Int32>!#>, <#T##timeNs: Int64##Int64#>, <#T##timeoutUs: Int##Int#>)
  }
  
  func readStreamStatus(flags: Flags, channelMask: Int, timeout: Int) throws {
    var flags = flags.rawValue
    var channelMask = channelMask
    var timeNs: Int64 = 0
    try cTry { SoapySDRDevice_readStreamStatus(device.impl, impl, &channelMask, &flags, &timeNs, timeout) }
  }
  
  // MARK: Direct buffer access API
  
  /// How many direct access buffers can the stream provide?
  /// This is the number of times the user can call acquire() on a stream without making subsequent calls to release().
  /// A return value of 0 means that direct access is not supported.
  var getNumDirectAccessBuffers: Int { SoapySDRDevice_getNumDirectAccessBuffers(device.impl, impl) }
  
  func getDirectAccessBufferAddress(handle: Int) throws {
//    try cTry { SoapySDRDevice_getDirectAccessBufferAddrs(device.impl, impl, handle, <#T##buffs: UnsafeMutablePointer<UnsafeMutableRawPointer?>!##UnsafeMutablePointer<UnsafeMutableRawPointer?>!#>) }
  }
  
  func acquireReadBuffer(handle: Int, flags: Flags, timeout: Int) {
    var handle = handle
    var flags = flags.rawValue
    var timeNs: Int64 = 0
//    SoapySDRDevice_acquireReadBuffer(device.impl, impl, &handle, <#T##buffs: UnsafeMutablePointer<UnsafeRawPointer?>!##UnsafeMutablePointer<UnsafeRawPointer?>!#>, &flags, &timeNs, timeout)
  }
  
  /// Release an acquired buffer back to the receive stream.
  /// This call is part of the direct buffer access API.
  func releaseReadBuffer(handle: Int) {
    SoapySDRDevice_releaseReadBuffer(device.impl, impl, handle)
  }
  
  func acquireWriteBuffer(timeout: Int64) {
//    SoapySDRDevice_acquireWriteBuffer(device.impl, impl, <#T##handle: UnsafeMutablePointer<Int>!##UnsafeMutablePointer<Int>!#>, <#T##buffs: UnsafeMutablePointer<UnsafeMutableRawPointer?>!##UnsafeMutablePointer<UnsafeMutableRawPointer?>!#>, timeout)
  }
  
  /// Release an acquired buffer back to the transmit stream.
  /// This call is part of the direct buffer access API.
  func releaseWriteBuffer(handle: Int, count: Int, flags: Flags) {
    var flags = flags.rawValue
    var timeNs: Int64 = 0
    SoapySDRDevice_releaseWriteBuffer(device.impl, impl, handle, count, &flags, timeNs)
  }
  
  // MARK: Sensor API
  
  var sensors: [String] {
    var length = 0
    let pointer = SoapySDRDevice_listSensors(device.impl, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.compactMap{ $0 }.map{ String(cString: $0) }
  }
  
  private func getSensorInfo(id: String) -> SoapySDRArgInfo {
    return SoapySDRDevice_getSensorInfo(device.impl, id)
  }
  
  func readSensor(id: String) -> String {
    return String(cString: SoapySDRDevice_readSensor(device.impl, id))
  }
  
  func listChannelSensors(channel: Int) -> [String] {
    var length = 0
    let pointer = SoapySDRDevice_listChannelSensors(device.impl, direction.rawValue, channel, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.compactMap{ $0 }.map{ String(cString: $0) }
  }
  
  private func getChannelSensorInfo(channel: Int, key: String) -> SoapySDRArgInfo {
    return SoapySDRDevice_getChannelSensorInfo(device.impl, direction.rawValue, channel, key)
  }
  
  func readChannelSensor(channel: Int, key: String) -> String {
    return String(cString: SoapySDRDevice_readChannelSensor(device.impl, direction.rawValue, channel, key))
  }
  
  // MARK: Settings API
  
  private var settingInfo: [SoapySDRArgInfo] {
    var length = 0
    let pointer = SoapySDRDevice_getSettingInfo(device.impl, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return Array(buffer)
  }
  
  func writeSetting(key: String, value: String) throws {
    try cTry { SoapySDRDevice_writeSetting(device.impl, key, value) }
  }
  
  func readSetting(key: String) -> String {
    return String(cString: SoapySDRDevice_readSetting(device.impl, key))
  }
  
  // MARK: Native Access API
  
  var nativeDeviceHandle: UnsafeMutableRawPointer? {
    return SoapySDRDevice_getNativeDeviceHandle(device.impl)
  }
  
  deinit {
    SoapySDRDevice_closeStream(device.impl, impl)
  }
  
}

public enum Flags: RawRepresentable {
  public typealias RawValue = Int32

  case unkown(code: Int32)
  
  public var timeNs: Int64? { nil }
  public var numElemnts: Int? { nil }
  public var rawValue: Int32 {
    switch self {
    case .unkown(code: let code):
      return code
    }
  }
  
  public init(rawValue: Int32) {
    self = .unkown(code: rawValue)
  }
}
