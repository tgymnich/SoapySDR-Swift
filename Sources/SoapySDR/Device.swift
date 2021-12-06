//
//  Device.swift
//  
//
//  Created by Tim Gymnich on 05.12.21.
//

import Foundation
@_implementationOnly import CSoapySDR

public class Device {
  public static var availableDevices: [Device] {
    var devices: [Device] = []
    var kwargs = SoapySDRKwargs()
    var length: Int = 0
    let args = SoapySDRDevice_enumerate(&kwargs, &length)
    let buffer = UnsafeBufferPointer(start: args, count: length)
    var iterator = buffer.makeIterator()
    while var next = iterator.next() {
      devices.append(Device(kwargs: &next))
    }
    return devices
  }
  
  let impl: OpaquePointer
  lazy var rx: Stream? = nil
  lazy var tx: Stream? = nil
  
  /// A key that uniquely identifies the device driver.
  /// This key identifies the underlying implementation. Several variants of a product may share a driver.
  public var driverKey: String { String(cString: CSoapySDR.SoapySDRDevice_getDriverKey(impl)) }
  /// A key that uniquely identifies the hardware.
  /// This key should be meaningful to the user to optimize for the underlying hardware.
  public var hardwareKey: String { String(cString: CSoapySDR.SoapySDRDevice_getHardwareKey(impl)) }
  /// Query a dictionary of available device information.
  /// This dictionary can any number of values like vendor name, product name, revisions, serials...
  /// This information can be displayed to the user to help identify the instantiated device.
  private var hardwareInfo: SoapySDRKwargs { CSoapySDR.SoapySDRDevice_getHardwareInfo(impl) }
  
  
  private init(kwargs: UnsafePointer<SoapySDRKwargs>) {
    self.impl = SoapySDRDevice_make(kwargs)
  }
  
  
  /// Set the frontend mapping of available DSP units to RF frontends.
  /// This mapping controls channel mapping and channel availability.
  public func setFrontendMapping(direction: Direction, mapping: String) {
    _ = mapping.utf8CString.withUnsafeBufferPointer {
      SoapySDRDevice_setFrontendMapping(impl, direction.rawValue, $0.baseAddress!)
    }
  }

  
  // MARK: Time API
  
  /// Get the list of available time sources
  var timeSources: [String] {
    var length = 0
    let pointer = SoapySDRDevice_listTimeSources(impl, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return  buffer.compactMap{ $0 }.map { String(cString: $0) }
  }
  
  /// Set the time source on the device
  func setTimeSource(source: String) throws {
    try cTry { SoapySDRDevice_setTimeSource(impl, source) }
  }
  
  /// Get the time source of the device
  var timeSource: String { String(cString: SoapySDRDevice_getTimeSource(impl)) }
  
  /// Does this device have a hardware clock?
  func hasHardwareTime(counter: String? = nil) -> Bool {
    return SoapySDRDevice_hasHardwareTime(impl, counter)
  }
  
  /// Read the time from the hardware clock on the device. The what argument can refer to a specific time counter.
  func getHardwareTime(counter: String? = nil) -> Int64 {
    return SoapySDRDevice_getHardwareTime(impl, counter)
  }
  
  /// Write the time to the hardware clock on the device.
  /// The what argument can refer to a specific time counter.
  func setHardwareTime(_ time: Int64, counter: String? = nil) {
    SoapySDRDevice_setHardwareTime(impl, time, counter)
  }
  
  // MARK: Clocking API
  
  /// Set the master clock rate of the device.
  @available(macOS 10.12, *)
  func setMasterClockRate(rate: Measurement<UnitFrequency>) throws {
    try cTry { SoapySDRDevice_setMasterClockRate(impl, rate.converted(to: .hertz).value) }
  }
  
  /// Get the master clock rate of the device.
  @available(macOS 10.12, *)
  var masterClockRate: Measurement<UnitFrequency> {
    let frequency = SoapySDRDevice_getMasterClockRate(impl)
    return Measurement(value: frequency, unit: .hertz)
  }
  
  /// Get the range of available master clock rates.
  @available(macOS 10.12, *)
  var masterClockRates: [StrideThrough<Measurement<UnitFrequency>>] {
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
  @available(macOS 10.12, *)
  func setReferenceClockRate(rate: Measurement<UnitFrequency>) throws {
    try cTry { SoapySDRDevice_setReferenceClockRate(impl, rate.converted(to: .hertz).value) }
  }
  
  @available(macOS 10.12, *)
  var referenceClockRate: Measurement<UnitFrequency> {
    let frequency = SoapySDRDevice_getReferenceClockRate(impl)
    return Measurement(value: frequency, unit: .hertz)
  }
  
  @available(macOS 10.12, *)
  var referenceClockRates: [StrideThrough<Measurement<UnitFrequency>>] {
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
  
  var clockSources: [String] {
    var length = 0
    let pointer = SoapySDRDevice_listClockSources(impl, &length)
    let buffer = UnsafeBufferPointer(start: pointer, count: length)
    return buffer.compactMap{ $0 }.map{ String(cString: $0) }
  }
  
  func setClockSource(source: String) throws {
    try cTry { SoapySDRDevice_setClockSource(impl, source) }
  }
  
  var clockSourc: String { String(cString: SoapySDRDevice_getClockSource(impl)) }
  
  deinit {
    SoapySDRDevice_unmake(impl)
  }
  
}
