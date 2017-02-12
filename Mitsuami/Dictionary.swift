//
//  Dictionary.swift
//  Mitsuami
//
//  Created by yuya_hirayama on 2017/02/11.
//  Copyright © 2017年 Yuya Hirayama. All rights reserved.
//

import Foundation

extension Dictionary {
  func value<T>(forKey key: Key) throws -> T {
    guard let value = self[key] as? T else {
      throw DictionaryError.castFailed
    }

    return value
  }
}

enum DictionaryError: Swift.Error {
  case castFailed
}
