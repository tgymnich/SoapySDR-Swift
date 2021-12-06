//
//  Extensions.swift
//  
//
//  Created by Tim Gymnich on 06.12.21.
//

import Foundation

extension Measurement: Strideable {
  public typealias Stride = Double

  public func distance(to other: Measurement<UnitType>) -> Double {
    return (other - self).value
  }
  
  public func advanced(by n: Double) -> Measurement<UnitType> {
    return self + Measurement(value: n, unit: self.unit)
  }
}

extension Array {
  mutating func withUnsafeMutableRawPointerArray<R>(_ body: (Array<UnsafeMutableRawPointer?>) throws -> R) rethrows -> R where Element == Data
    {
        var buffers = Array<UnsafeMutableRawPointer?>()
        var result: R?
        
      func recurse(body: (Array<UnsafeMutableRawPointer?>) throws -> R) rethrows
        {
            let i = buffers.count
            guard i < self.count else {
                result = try body(buffers)
                return
            }
                    
            try self[i].withContiguousStorageIfAvailable { buf in
              buffers.append(UnsafeMutableRawPointer(mutating: buf.baseAddress!))
                try recurse(body: body)
            }
        }
        
      try recurse(body: body)
        
        return result!
    }
}

extension Array {
  mutating func withUnsafeMutableRawPointerArray<R>(_ body: (Array<UnsafeMutableRawPointer?>) -> R) -> R where Element == Data
    {
        var buffers = Array<UnsafeMutableRawPointer?>()
        var result: R?
        
      func recurse(body: (Array<UnsafeMutableRawPointer?>) -> R)
        {
            let i = buffers.count
            guard i < self.count else {
                result = body(buffers)
                return
            }
          
            self[i].withContiguousStorageIfAvailable { buf in
              buffers.append(UnsafeMutableRawPointer(mutating: buf.baseAddress!))
                recurse(body: body)
            }
        }
        
      recurse(body: body)
        
        return result!
    }
}

extension Array {
  func withUnsafeRawPointerArray<R>(_ body: (Array<UnsafeRawPointer?>) throws -> R) rethrows -> R where Element == Data
    {
        var buffers = Array<UnsafeRawPointer?>()
        var result: R?
        
      func recurse(body: (Array<UnsafeRawPointer?>) throws -> R) rethrows
        {
            let i = buffers.count
            guard i < self.count else {
                result = try body(buffers)
                return
            }
          
            try self[i].withContiguousStorageIfAvailable { buf in
              buffers.append(UnsafeRawPointer(buf.baseAddress!))
                try recurse(body: body)
            }
        }
        
      try recurse(body: body)
        
        return result!
    }
}

extension Array {
  func withUnsafeRawPointerArray<R>(_ body: (Array<UnsafeRawPointer?>) -> R) -> R where Element == Data
    {
        var buffers = Array<UnsafeRawPointer?>()
        var result: R?
        
      func recurse(body: (Array<UnsafeRawPointer?>) -> R)
        {
            let i = buffers.count
            guard i < self.count else {
                result = body(buffers)
                return
            }
          
            self[i].withContiguousStorageIfAvailable { buf in
              buffers.append(UnsafeRawPointer(buf.baseAddress!))
                recurse(body: body)
            }
        }
        
      recurse(body: body)
        
        return result!
    }
}
