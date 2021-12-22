//
//  Channel.swift
//  
//
//  Created by Tim Gymnich on 05.12.21.
//

import Foundation
@_implementationOnly import CSoapySDR

public struct Channel {
  public let device: Device
  public let direction: Direction
  public let index: Int
  
  init(device: Device, direction: Direction, index: Int) {
    self.device = device
    self.direction = direction
    self.index = index
  }
    
  /// Get the mapping configuration string.
  public var frontendMapping: String? { String(cString: SoapySDRDevice_getFrontendMapping(device.impl, direction.rawValue)).nonEmpty }
  
  /// Get channel info given the streaming direction
  public var info: [String: String] { Kwargs(SoapySDRDevice_getChannelInfo(device.impl, direction.rawValue, index)).toDictionary() }
  
  /// Find out if the specified channel is full or half duplex.
  public var fullDuplex: Bool { SoapySDRDevice_getFullDuplex(device.impl, direction.rawValue, index) }
  
  public var hasAutomaticGainControl: Bool { SoapySDRDevice_hasGainMode(device.impl, direction.rawValue, index) }
  
  public var automaticGainControlEnabled: Bool { SoapySDRDevice_getGainMode(device.impl, direction.rawValue, index) }
  
  public var hasAutomaticDCOffsetCorrection: Bool { SoapySDRDevice_hasDCOffsetMode(device.impl, direction.rawValue, index) }
  
  public var automaticDCOffsetCorrectionEnabled: Bool { SoapySDRDevice_getDCOffsetMode(device.impl, direction.rawValue, index) }
  
  public var hasIQBalanceCorrection: Bool { SoapySDRDevice_hasIQBalance(device.impl, direction.rawValue, index) }
  
  public var iQBalance: (I: Double, Q: Double) {
    var balance = (I: 0.0, Q: 0.0)
    SoapySDRDevice_getIQBalance(device.impl, direction.rawValue, index, &balance.I, &balance.Q)
    return balance
  }
  
  /// Get the frontend frequency correction value.
  public var frequencyCorrection: Measurement<UnitDispersion> {
    let correction = SoapySDRDevice_getFrequencyCorrection(device.impl, direction.rawValue, index)
    return Measurement(value: correction, unit: .partsPerMillion)
  }
    
  /// Describe the allowed keys and values used for channel settings.
  private var channelSettingInfo: [SoapySDRArgInfo] {
    var length = 0
    let pointer = SoapySDRDevice_getChannelSettingInfo(device.impl, direction.rawValue, index, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return Array(buffer)
  }
  
  /// Query a list of the available stream formats.
  public var streamFormats: [String] {
    var length = 0
    let pointer = SoapySDRDevice_getStreamFormats(device.impl, direction.rawValue, index, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.compactMap{ $0 }.map { String(cString: $0) }
  }
  
  /// Get the hardware's native stream format for this channel.
  /// This is the format used by the underlying transport layer, and the direct buffer access API calls (when available).
  public var nativeStreamFormat: (format: String, fullScale: Double) {
    var fullScale = 0.0
    let format = String(cString: SoapySDRDevice_getNativeStreamFormat(device.impl, direction.rawValue, index, &fullScale))
    return (format,fullScale)
  }
  
  /// Query the argument info description for stream args.
  private var streamArgsInfo: [SoapySDRArgInfo] {
    var length = 0
    let ptr = SoapySDRDevice_getStreamArgsInfo(device.impl, direction.rawValue, index, &length)
    let buffer = UnsafeBufferPointer(start: ptr, count: length)
    return Array(buffer)
  }
    
  
  // MARK: Channel Settings API
  
  /// Write an arbitrary channel setting on the device. The interpretation is up the implementation.
  public func writeChannelSetting(key: String, value: String) throws {
    try checkReturnCode { SoapySDRDevice_writeChannelSetting(device.impl, direction.rawValue, index, key, value) }
  }
  
  /// Write an arbitrary channel setting on the device. The interpretation is up the implementation.
  public func readChannelSetting(key: String) -> String? {
    return String(cString: SoapySDRDevice_readChannelSetting(device.impl, direction.rawValue, index, key)).nonEmpty
  }
  
  
  // MARK: Gain API

  /// List available amplification elements. Elements should be in order RF to baseband.
  public var gains: [String] {
    var length: Int = 0
    let pointer = SoapySDRDevice_listGains(device.impl, direction.rawValue, index, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.compactMap{ $0 }.map { String(cString: $0) }
  }
    
  /// Get the value of an individual amplification element in a chain.
  public func getGainElement(name: String) -> Double {
    return SoapySDRDevice_getGainElement(device.impl, direction.rawValue, index, name)
  }
  
  /// Get the overall range of possible gain values.
  public var gainRange: StrideThrough<Double> {
    let range = SoapySDRDevice_getGainRange(device.impl, direction.rawValue, index)
    return stride(from: range.minimum, through: range.maximum, by: range.step)
  }
  
  /// Get the range of possible gain values for a specific element.
  public func getGainElementRange(name: String) -> StrideThrough<Double> {
    let range = SoapySDRDevice_getGainElementRange(device.impl, direction.rawValue, index, name)
    return stride(from: range.minimum, through: range.maximum, by: range.step)
  }
  
  
  // MARK: Frequency API
  
  /// Set the center frequency of the chain. - For RX, this specifies the down-conversion frequency. - For TX, this specifies the up-conversion frequency.
  public func setFrequency(frequency: Measurement<UnitFrequency>) throws {
    var args = SoapySDRKwargs()
    try checkReturnCode { SoapySDRDevice_setFrequency(device.impl, direction.rawValue, index, frequency.converted(to: .hertz).value, &args) }
  }
    
  /// Get the range of overall frequency values.
  public var frequencyRange: [StrideThrough<Double>] {
    var length = 0
    let pointer = SoapySDRDevice_getFrequencyRange(device.impl, direction.rawValue, index, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.map { stride(from: $0.minimum, through: $0.maximum, by: $0.step) }
  }
  
  /// Get the range of tunable values for the specified element.
  public func getFrequencyRangeComponent(name: String) -> [StrideThrough<Double>] {
    var length = 0
    let pointer = SoapySDRDevice_getFrequencyRangeComponent(device.impl, direction.rawValue, index, name, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.map { stride(from: $0.minimum, through: $0.maximum, by: $0.step) }
  }
  
  /// Get the range of tunable values for the specified element.
  public func getFrequencyRangeComponent(name: String) -> [StrideThrough<Measurement<UnitFrequency>>] {
    var length = 0
    let pointer = SoapySDRDevice_getFrequencyRangeComponent(device.impl, direction.rawValue, index, name, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.map {
      stride(
        from: Measurement(value: $0.minimum, unit: .hertz),
        through: Measurement(value: $0.maximum, unit: .hertz),
        by: $0.step)
    }
  }
  
  /// Get the range of possible baseband sample rates.
  public var sampleRateRange: [StrideThrough<Double>] {
    var length = 0
    let pointer = SoapySDRDevice_getSampleRateRange(device.impl, direction.rawValue, index, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.map { stride( from: $0.minimum, through: $0.maximum, by: $0.step) }
  }
  
  /// Get the range of possible baseband sample rates.
  public var sampleRates: [Measurement<UnitFrequency>] {
    var length = 0
    let pointer = SoapySDRDevice_listSampleRates(device.impl, direction.rawValue, index, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.map { Measurement(value: $0, unit: .hertz) }
  }
  
  /// List available tunable elements in the chain. Elements should be in order RF to baseband.
  public var frequencies: [String] {
    var length = 0
    let pointer = SoapySDRDevice_listFrequencies(device.impl, direction.rawValue, index, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return  buffer.compactMap{ $0 }.map { String(cString: $0) }
  }
  
  /// Get the overall center frequency of the chain. - For RX, this specifies the down-conversion frequency. - For TX, this specifies the up-conversion frequency.
  public var frequency: Measurement<UnitFrequency> {
    let frequency = SoapySDRDevice_getFrequency(device.impl, direction.rawValue, index)
    return Measurement(value: frequency, unit: .hertz)
  }
  
  /// Get the baseband filter width of the chain
  public var bandwidth: Measurement<UnitFrequency> {
    let bandwidth = SoapySDRDevice_getBandwidth(device.impl, direction.rawValue, index)
    return Measurement(value: bandwidth, unit: .hertz)
  }
  
  /// Get the frequency of a tunable element in the chain.
  public func getFrequencyComponent(name: String) -> Measurement<UnitFrequency> {
    let frequency = SoapySDRDevice_getFrequencyComponent(device.impl, direction.rawValue, index, name)
    return Measurement(value: frequency, unit: .hertz)
  }
  
  public func setFrequencyComponent(name: String, frequency: Measurement<UnitFrequency>) throws {
    var args = SoapySDRKwargs()
    let frequency = frequency.converted(to: .hertz).value
    try checkReturnCode { SoapySDRDevice_setFrequencyComponent(device.impl, direction.rawValue, index, name, frequency, &args) }
  }
  
  
  // MARK: Sensor API
  
  /// List the available channel readback sensors. A sensor can represent a reference lock, RSSI, temperature.
  public var sensors: [String] {
    var length = 0
    let pointer = SoapySDRDevice_listChannelSensors(device.impl, direction.rawValue, index, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.compactMap{ $0 }.map{ String(cString: $0) }
  }
  
  private func getSensorInfo(key: String) -> SoapySDRArgInfo {
    return SoapySDRDevice_getChannelSensorInfo(device.impl, direction.rawValue, index, key)
  }
  
  /// Readback a channel sensor given the name.
  /// The value returned is a string which can represent a boolean ("true"/"false"), an integer, or float.
  private func readSensor(key: String) -> String {
    return String(cString: SoapySDRDevice_readChannelSensor(device.impl, direction.rawValue, index, key))
  }
  
  /// Readback a channel sensor given the name.
  /// The value returned is a string which can represent a boolean ("true"/"false"), an integer, or float.
  public func readSensor(key: String) -> Bool? {
    return Bool(readSensor(key: key))
  }
  
  /// Readback a channel sensor given the name.
  /// The value returned is a string which can represent a boolean ("true"/"false"), an integer, or float.
  public func readSensor(key: String) -> Int? {
    return Int(readSensor(key: key))
  }
  
  /// Readback a channel sensor given the name.
  /// The value returned is a string which can represent a boolean ("true"/"false"), an integer, or float.
  public func readSensor(key: String) -> Double? {
    return Double(readSensor(key: key))
  }
  
  
  // MARK: Antenna API
  
  /// Get a list of available antennas to select on a given chain.
  public var antennas: [String] {
    var length: Int = 0
    let pointer = SoapySDRDevice_listAntennas(device.impl, direction.rawValue, index, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return  buffer.compactMap{ $0 }.map { String(cString: $0) }
  }
  
  /// Get the selected antenna on a chain.
  public var antennaName: String { String(cString: SoapySDRDevice_getAntenna(device.impl, direction.rawValue, index)) }
  
  /// Set the selected antenna on a chain.
  public func setAntennaName(name: String) throws {
    try checkReturnCode { SoapySDRDevice_setAntenna(device.impl, direction.rawValue, index, name) }
  }
  
    
}


