//
//  File.swift
//  
//
//  Created by Tim Gymnich on 07.12.21.
//

import Foundation

public protocol StreamSample {
  static var identifier: String { get }
}

func mapToType(identifier: String) -> StreamSample.Type {
  switch identifier {
  case Double.identifier: return Double.self
  case Float.identifier: return Float.self
  case Int32.identifier: return Int32.self
  case UInt32.identifier: return UInt32.self
  case Int16.identifier: return Int16.self
  case UInt16.identifier: return UInt16.self
  case Int8.identifier: return Int8.self
  case UInt8.identifier: return UInt8.self
  case ComplexFloat<Double>.identifier: return ComplexFloat<Double>.self
  case ComplexFloat<Float>.identifier: return ComplexFloat<Float>.self
  case ComplexInt<Int32>.identifier: return ComplexInt<Int32>.self
  case ComplexInt<UInt32>.identifier: return ComplexInt<UInt32>.self
  case ComplexInt<Int16>.identifier: return ComplexInt<Int16>.self
  case ComplexInt<UInt16>.identifier: return ComplexInt<UInt16>.self
  case ComplexInt<Int8>.identifier: return ComplexInt<Int8>.self
  case ComplexInt<UInt8>.identifier: return ComplexInt<UInt8>.self
  case ComplexInt12.identifier: return ComplexInt12.self
  case ComplexUInt12.identifier: return ComplexUInt12.self
  case ComplexInt4.identifier: return ComplexInt4.self
  case ComplexUInt4.identifier: return ComplexUInt4.self
  default: fatalError()
  }
}


extension Double: StreamSample {
  public static var identifier: String { "F64" }
}

extension Float: StreamSample {
  public static var identifier: String { "F32" }
}

extension Int32: StreamSample {
  public static var identifier: String { "S32" }
}

extension UInt32: StreamSample {
  public static var identifier : String { "U32" }
}

extension Int16: StreamSample {
  public static var identifier: String { "S16" }
}

extension UInt16: StreamSample {
  public static var identifier: String { "U16" }
}

extension Int8: StreamSample {
  public static var identifier: String { "S8" }
}

extension UInt8: StreamSample {
  public static var identifier: String { "U8" }
}

public struct ComplexFloat<FloatType: FloatingPoint> {
  public let real: FloatType
  public let imag: FloatType
}

extension ComplexFloat: StreamSample where FloatType: StreamSample {
  public static var identifier: String { "C".appending(FloatType.identifier) }
}

public struct ComplexInt<IntegerType: BinaryInteger> {
  public let real: IntegerType
  public let imag: IntegerType
}

extension ComplexInt: StreamSample where IntegerType: StreamSample {
  public static var identifier: String { "C".appending(IntegerType.identifier) }
}

public struct ComplexInt12: StreamSample {
  public static var identifier: String { "CS12" }
  public let bytes: (UInt8, UInt8, UInt8)
}

public struct ComplexUInt12: StreamSample {
  public static var identifier: String { "CU12" }
  public let bytes: (UInt8, UInt8, UInt8)
}
  
public struct ComplexInt4: StreamSample {
  public static var identifier: String { "CS4" }
  public let byte: UInt8
}

public struct ComplexUInt4: StreamSample {
  public static var identifier: String { "CU4" }
  public let byte: UInt8
}
