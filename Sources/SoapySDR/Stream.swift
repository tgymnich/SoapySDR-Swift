//
//  File.swift
//  
//
//  Created by Tim Gymnich on 05.12.21.
//

import Foundation
@_implementationOnly import CSoapySDR

public enum Direction: Int32 {
  /// Receive
  case RX = 1
  /// Transmit
  case TX = 0
}

public class Stream {
  let impl: OpaquePointer
  let device: Device
  public let direction: Direction
  public var MTU: Int { SoapySDRDevice_getStreamMTU(device.impl, impl) }
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
  
  public subscript(index: Int) -> Channel {
      get { channels[index] }
  }
  
  
  // MARK: Stream API
  
  /// Activate a stream. Call activate to prepare a stream before using read/write().
  /// The implementation control switches or stimulate data flow.
  public func activateStream() throws {
    let flags: Int32 = 0
    let timeNs: Int64 = 0
    let numElements = 0
    try cTry { SoapySDRDevice_activateStream(device.impl, impl, flags, timeNs, numElements) }
  }
  
  /// Deactivate a stream. Call deactivate when not using using read/write().
  /// The implementation control switches or halt data flow.
  public func deactivateStream() throws {
    let flags: Int32 = 0
    let timeNs: Int64 = 0
    try cTry { SoapySDRDevice_deactivateStream(device.impl, impl, flags, timeNs) }
  }
  
  /// Read elements from a stream for reception. This is a multi-channel call, and buffs should be an array of void *, where each pointer will be filled with data from a different channel.
  public func readStream(buffers: inout [Data], timeout: Measurement<UnitDuration>) throws -> Int {
    assert(buffers.count == channels.count)
    var timeNs: Int64 = 0
    var flags: Int32 = 0
    let numberOfSamples = buffers.map{ $0.count }.min() ?? 0
    let timeout = Int(timeout.converted(to: .microseconds).value)

    return try buffers.withUnsafeMutableRawPointerArray { ptr -> Int in
      let errorOrCount = SoapySDRDevice_readStream(device.impl, impl, ptr, numberOfSamples, &flags, &timeNs, timeout)
      guard errorOrCount >= 0 else {
        throw SDRError(rawValue: errorOrCount)
      }
      return Int(errorOrCount)
    }
  }
  
  /// Write elements to a stream for transmission. This is a multi-channel call, and buffs should be an array of void *, where each pointer will be filled with data for a different channel.
  public func writeStream(buffers: [Data], timeout: Measurement<UnitDuration>) throws -> Int {
    assert(buffers.count == channels.count)
    let timeNs: Int64 = 0
    var flags: Int32 = 0
    let numberOfSamples = buffers.map{ $0.count }.min() ?? 0
    let timeout = Int(timeout.converted(to: .microseconds).value)
    
    guard buffers.count == channels.count else { throw SDRError.SOAPY_SDR_NOT_SUPPORTED }
    return try buffers.withUnsafeRawPointerArray { ptr in
      let errorOrCount = SoapySDRDevice_writeStream(device.impl, impl, ptr, numberOfSamples, &flags, timeNs, timeout)
      guard errorOrCount >= 0 else {
        throw SDRError(rawValue: errorOrCount)
      }
      return Int(errorOrCount)
    }
  }
  
  /// Readback status information about a stream. This call is typically used on a transmit stream to report time errors, underflows, and burst completion.
  public func readStreamStatus(channelMask: Int, timeout: Int) throws {
    var flags: Int32 = 0
    var channelMask = channelMask
    var timeNs: Int64 = 0
    try cTry { SoapySDRDevice_readStreamStatus(device.impl, impl, &channelMask, &flags, &timeNs, timeout) }
  }
  
  
  // MARK: Direct buffer access API
  
  /// How many direct access buffers can the stream provide?
  /// This is the number of times the user can call acquire() on a stream without making subsequent calls to release().
  /// A return value of 0 means that direct access is not supported.
  private var getNumDirectAccessBuffers: Int { SoapySDRDevice_getNumDirectAccessBuffers(device.impl, impl) }
  
  private func getDirectAccessBufferAddress(handle: Int) throws {
    // try cTry { SoapySDRDevice_getDirectAccessBufferAddrs(device.impl, impl, handle, buffs) }
  }
  
  private func acquireReadBuffer(handle: inout Int, timeout: Int) {
//    var flags: Int32 = 0
//    var timeNs: Int64 = 0
    // SoapySDRDevice_acquireReadBuffer(device.impl, impl, &handle, buffs, &flags, &timeNs, timeout)
  }
  
  /// Release an acquired buffer back to the receive stream.
  /// This call is part of the direct buffer access API.
  private func releaseReadBuffer(handle: Int) {
    SoapySDRDevice_releaseReadBuffer(device.impl, impl, handle)
  }
  
  private func acquireWriteBuffer(timeout: Int64) {
//    SoapySDRDevice_acquireWriteBuffer(device.impl, impl,  ,  , timeout)
  }
  
  /// Release an acquired buffer back to the transmit stream.
  /// This call is part of the direct buffer access API.
  private func releaseWriteBuffer(handle: Int, count: Int) {
    var flags: Int32 = 0
    let timeNs: Int64 = 0
    SoapySDRDevice_releaseWriteBuffer(device.impl, impl, handle, count, &flags, timeNs)
  }
  
  
  // MARK: Sensor API
  
  /// List the available global readback sensors. A sensor can represent a reference lock, RSSI, temperature.
  public var sensors: [String] {
    var length = 0
    let pointer = SoapySDRDevice_listSensors(device.impl, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.compactMap{ $0 }.map{ String(cString: $0) }
  }
  
  private func getSensorInfo(id: String) -> SoapySDRArgInfo {
    return SoapySDRDevice_getSensorInfo(device.impl, id)
  }
  
  /// Readback a global sensor given the name.
  /// The value returned is a string which can represent a boolean ("true"/"false"), an integer, or float.
  private func readSensor(key: String) -> String {
    return String(cString: SoapySDRDevice_readSensor(device.impl, key))
  }
  
  /// Readback a global sensor given the name.
  /// The value returned is a string which can represent a boolean ("true"/"false"), an integer, or float.
  public func readSensor(key: String) -> Bool? {
    return Bool(readSensor(key: key))
  }
  
  /// Readback a global sensor given the name.
  /// The value returned is a string which can represent a boolean ("true"/"false"), an integer, or float.
  public func readSensor(key: String) -> Int? {
    return Int(readSensor(key: key))
  }
  
  /// Readback a global sensor given the name.
  /// The value returned is a string which can represent a boolean ("true"/"false"), an integer, or float.
  public func readSensor(key: String) -> Double? {
    return Double(readSensor(key: key))
  }
  
  
  // MARK: Settings API
  
  private var settingInfo: [SoapySDRArgInfo] {
    var length = 0
    let pointer = SoapySDRDevice_getSettingInfo(device.impl, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return Array(buffer)
  }
  
  /// Write an arbitrary setting on the device. The interpretation is up the implementation.
  public func writeSetting(key: String, value: String) throws {
    try cTry { SoapySDRDevice_writeSetting(device.impl, key, value) }
  }
  
  /// Read an arbitrary setting on the device.
  public func readSetting(key: String) -> String {
    return String(cString: SoapySDRDevice_readSetting(device.impl, key))
  }
  
  
  // MARK: Native Access API
  
  private var nativeDeviceHandle: UnsafeMutableRawPointer? {
    return SoapySDRDevice_getNativeDeviceHandle(device.impl)
  }
  
  deinit {
    SoapySDRDevice_closeStream(device.impl, impl)
  }
  
}


struct Flags: OptionSet {
  /// Indicate end of burst for transmit or receive.
  /// For write, end of burst if set by the caller.
  /// For read, end of burst is set by the driver."""
  static let SOAPY_SDR_END_BURST = Flags(rawValue: 1 << 1)

  /// Indicates that the time stamp is valid.
  /// For write, the caller must set has time when timeNs is provided.
  /// For read, the driver sets has time when timeNs is provided."""
  static let SOAPY_SDR_HAS_TIME = Flags(rawValue: 1 << 2)

  /// Indicates that stream terminated prematurely.
  /// This is the flag version of an overflow error
  /// that indicates an overflow with the end samples."""
  static let SOAPY_SDR_END_ABRUPT = Flags(rawValue: 1 << 3)

  /// Indicates transmit or receive only a single packet.
  /// Applicable when the driver fragments samples into packets.
  /// For write, the user sets this flag to only send a single packet.
  /// For read, the user sets this flag to only receive a single packet."""
  static let SOAPY_SDR_ONE_PACKET = Flags(rawValue: 1 << 4)

  /// Indicate that this read call and the next results in a fragment.
  /// Used when the implementation has an underlying packet interface.
  /// The caller can use this indicator and the SOAPY_SDR_ONE_PACKET flag
  /// on subsequent read stream calls to re-align with packet boundaries."""
  static let SOAPY_SDR_MORE_FRAGMENTS = Flags(rawValue: 1 << 5)

  /// Indicate that the stream should wait for an external trigger event.
  /// This flag might be used with the flags argument in any of the
  /// stream API calls. The trigger implementation is hardware-specific."""
  static let SOAPY_SDR_WAIT_TRIGGER = Flags(rawValue: 1 << 6)

  let rawValue: Int32
}
