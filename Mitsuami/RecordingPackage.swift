//
//  RecordingPackage.swift
//  Mitsuami
//
//  Created by yuya_hirayama on 2017/02/10.
//  Copyright © 2017年 Yuya Hirayama. All rights reserved.
//

import Foundation

struct RecordingPackage {
  let timestamp: TimeInterval
  let path: String
  let temporaryPath: String

  private let soundFileName = "sound.aiff"

  var soundFileRecordingPath: String {
    return temporaryPath + soundFileName
  }

  var properties: [String: Any] {
    return [
      "timestamp": timestamp
    ]
  }

  func export() {
    let plistPath = path + "info.plist"
    let manager = FileManager.default
    try! manager.copyItem(at: URL.init(fileURLWithPath: temporaryPath + soundFileName), to: URL.init(fileURLWithPath: path + soundFileName))
    let data = NSDictionary.init(dictionary: properties)
    let succeeded = data.write(toFile: plistPath, atomically: true)
    return
  }
}
