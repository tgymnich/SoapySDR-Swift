//
//  Device.swift
//  
//
//  Created by Tim Gymnich on 05.12.21.
//

import Foundation
@_implementationOnly import CSoapySDR

public class Device {
  public static var availableDevices: LazyMapSequence<LazySequence<(Range<Int>)>.Elements, Device> {
    var kwargs = SoapySDRKwargs()
    var length = 0
    let pointer = SoapySDRDevice_enumerate(&kwargs, &length)
    let buffer = UnsafeMutableBufferPointer(start: pointer, count: length)
    let devices = (0..<buffer.count).lazy.map { Device(kwargs: &buffer[$0]) }
    return devices
  }
  
  let impl: OpaquePointer
  
  public lazy var rx: Stream? = nil
  public lazy var tx: Stream? = nil
  
  /// A key that uniquely identifies the device driver.
  /// This key identifies the underlying implementation. Several variants of a product may share a driver.
  public var driverKey: String { String(cString: SoapySDRDevice_getDriverKey(impl)!) }
  /// A key that uniquely identifies the hardware.
  /// This key should be meaningful to the user to optimize for the underlying hardware.
  public var hardwareKey: String { String(cString: SoapySDRDevice_getHardwareKey(impl)!) }
  /// Query a dictionary of available device information.
  /// This dictionary can any number of values like vendor name, product name, revisions, serials...
  /// This information can be displayed to the user to help identify the instantiated device.
  public var hardwareInfo: [String: String] { Kwargs(SoapySDRDevice_getHardwareInfo(impl)).toDictionary() }
  
  
  private init(kwargs: UnsafePointer<SoapySDRKwargs>) {
    self.impl = SoapySDRDevice_make(kwargs)
  }
  
  
  /// Set the frontend mapping of available DSP units to RF frontends.
  /// This mapping controls channel mapping and channel availability.
  public func setFrontendMapping(direction: Direction, mapping: String) throws {
    try mapping.utf8CString.withUnsafeBufferPointer { ptr in
      try cTry { SoapySDRDevice_setFrontendMapping(impl, direction.rawValue, ptr.baseAddress!) }
    }
  }

  
  // MARK: Time API
  
  /// Get the list of available time sources
  public var timeSources: [String] {
    var length = 0
    let pointer = SoapySDRDevice_listTimeSources(impl, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return  buffer.compactMap{ $0 }.map { String(cString: $0) }
  }
  
  /// Set the time source on the device
  public func setTimeSource(source: String) throws {
    try cTry { SoapySDRDevice_setTimeSource(impl, source) }
  }
  
  /// Get the time source of the device
  public var timeSource: String { String(cString: SoapySDRDevice_getTimeSource(impl)) }
  
  /// Does this device have a hardware clock?
  public func hasHardwareTime(counter: String? = nil) -> Bool {
    return SoapySDRDevice_hasHardwareTime(impl, counter)
  }
  
  /// Read the time from the hardware clock on the device. The what argument can refer to a specific time counter.
  public func getHardwareTime(counter: String? = nil) -> Int64 {
    return SoapySDRDevice_getHardwareTime(impl, counter)
  }
  
  /// Write the time to the hardware clock on the device.
  /// The what argument can refer to a specific time counter.
  public func setHardwareTime(_ time: Int64, counter: String? = nil) {
    SoapySDRDevice_setHardwareTime(impl, time, counter)
  }
  
  
  // MARK: Clocking API
  
  /// Set the master clock rate of the device.
  public func setMasterClockRate(rate: Measurement<UnitFrequency>) throws {
    try cTry { SoapySDRDevice_setMasterClockRate(impl, rate.converted(to: .hertz).value) }
  }
  
  /// Get the master clock rate of the device.
  public var masterClockRate: Measurement<UnitFrequency> {
    let frequency = SoapySDRDevice_getMasterClockRate(impl)
    return Measurement(value: frequency, unit: .hertz)
  }
  
  /// Get the range of available master clock rates.
  public var masterClockRates: [StrideThrough<Measurement<UnitFrequency>>] {
    var length = 0
    let pointer = SoapySDRDevice_getMasterClockRates(impl, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.map {
      stride(
        from: Measurement(value: $0.minimum, unit: .hertz),
        through: Measurement(value: $0.maximum, unit: .hertz),
        by: $0.step)
    }
  }
  
  /// Set the reference clock rate of the device.
  public func setReferenceClockRate(rate: Measurement<UnitFrequency>) throws {
    try cTry { SoapySDRDevice_setReferenceClockRate(impl, rate.converted(to: .hertz).value) }
  }
  
  /// Get the reference clock rate of the device.
  public var referenceClockRate: Measurement<UnitFrequency> {
    let frequency = SoapySDRDevice_getReferenceClockRate(impl)
    return Measurement(value: frequency, unit: .hertz)
  }
  
  /// Get the range of available reference clock rates.
  public var referenceClockRates: [StrideThrough<Measurement<UnitFrequency>>] {
    var length = 0
    let pointer = SoapySDRDevice_getReferenceClockRates(impl, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.map {
      stride(
        from: Measurement(value: $0.minimum, unit: .hertz),
        through: Measurement(value: $0.maximum, unit: .hertz),
        by: $0.step)
    }
  }
  
  /// Get the list of available clock sources.
  public var clockSources: [String] {
    var length = 0
    let pointer = SoapySDRDevice_listClockSources(impl, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.compactMap{ $0 }.map{ String(cString: $0) }
  }
  
  /// Set the clock source on the device
  public func setClockSource(source: String) throws {
    try cTry { SoapySDRDevice_setClockSource(impl, source) }
  }
  
  /// Get the clock source of the device
  public var clockSource: String? { String(cString: SoapySDRDevice_getClockSource(impl)).nonEmpty }
  
  deinit {
    SoapySDRDevice_unmake(impl)
  }
  
}
