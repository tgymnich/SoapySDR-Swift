//
//  Extensions.swift
//  
//
//  Created by Tim Gymnich on 06.12.21.
//

import Foundation

@available(macOS 10.12, *)
extension Measurement: Strideable {
  public typealias Stride = Double

  public func distance(to other: Measurement<UnitType>) -> Double {
    return (other - self).value
  }
  
  public func advanced(by n: Double) -> Measurement<UnitType> {
    return self + Measurement(value: n, unit: self.unit)
  }
}
