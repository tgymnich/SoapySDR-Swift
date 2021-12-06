//
//  Misc.swift
//  
//
//  Created by Tim Gymnich on 06.12.21.
//

func cTry(closure: () -> Int32) throws {
  let errorCode = closure()
  guard errorCode == 0 else {
    throw SDRError(rawValue: errorCode)
  }
}
