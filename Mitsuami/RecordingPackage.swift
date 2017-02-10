//
//  RecordingPackage.swift
//  Mitsuami
//
//  Created by yuya_hirayama on 2017/02/10.
//  Copyright © 2017年 Yuya Hirayama. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa

struct RecordingPackage {

  fileprivate static let bag = DisposeBag.init()

  let timestamp: TimeInterval
  let path: String
  let temporaryPath: String

  private let soundFileName = "sound.aif"
  private let plistFileName = "info.plist"

  enum Error: Swift.Error {
    case packageNotFound
    case plistNotFound
  }

  init(timestamp: TimeInterval, path: String, temporaryPath: String) {
    self.timestamp = timestamp
    self.path = path
    self.temporaryPath = temporaryPath
  }

  init(packagePath: URL) throws {
    guard let plist = NSDictionary.init(contentsOfFile: packagePath.appendingPathComponent(plistFileName).absoluteString) as? [String: Any] else {
      throw Error.plistNotFound
    }

    self.timestamp = try plist.value(forKey: "timestamp")
    self.temporaryPath = "" // TODO
    self.path = packagePath.absoluteString
  }

  var soundFileRecordingPath: String {
    return temporaryPath + soundFileName
  }

  var properties: [String: Any] {
    return [
      "timestamp": timestamp
    ]
  }

  var exportedSoundFilePath: String {
    return path + soundFileName
  }

  func export() {
    let plistPath = path + plistFileName
    let manager = FileManager.default
    try! manager.copyItem(at: URL.init(fileURLWithPath: temporaryPath + soundFileName), to: URL.init(fileURLWithPath: path + soundFileName))
    let data = NSDictionary.init(dictionary: properties)
    let succeeded = data.write(toFile: plistPath, atomically: true)
    return
  }
}

extension RecordingPackage {
  static func mixDown(packages: [RecordingPackage]) {
    let composition = AVMutableComposition.init()

    let timeOrderedPackages = packages.sorted { (a, b) -> Bool in
      a.timestamp < b.timestamp
    }
    guard let baseTimestamp = timeOrderedPackages.first?.timestamp else {
      fatalError()
    }

    let timeRate: Double = 1000

    Observable<AVKeyValueStatus>.create { (observer) -> Disposable in
      timeOrderedPackages.forEach { (package) in
        let audioTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)

        let asset = AVURLAsset.init(url: URL.init(fileURLWithPath: package.exportedSoundFilePath))

        let time = package.timestamp - baseTimestamp
        let startTime = CMTime.init(
          value: CMTimeValue.init(time * timeRate),
          timescale: CMTimeScale(timeRate)
        )

        asset.loadValuesAsynchronously(forKeys: ["tracks"], completionHandler: {

          DispatchQueue.main.async {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "tracks", error: &error)
            if status == AVKeyValueStatus.loaded {

              print("composing...")
              try! audioTrack.insertTimeRange(
                CMTimeRange.init(
                  start: kCMTimeZero,
                  end: asset.duration
                ),
                of: asset.tracks(withMediaType: AVMediaTypeAudio).first!,
                at: startTime
              )
              observer.onNext(status)
            } else {
              print(error)
            }
          }
        })
      }

      return Disposables.create()
    }.buffer(timeSpan: 100, count: packages.count, scheduler: MainScheduler.instance)
    .subscribe(onNext: { (_) in
      print("exporting...")
      let exportSession = AVAssetExportSession.init(asset: composition, presetName: AVAssetExportPresetAppleM4A)!
      exportSession.outputURL = URL.init(fileURLWithPath: "/Users/yuya_hirayama/Desktop/result.m4a")
      exportSession.outputFileType = AVFileTypeAppleM4A

      exportSession.exportAsynchronously(completionHandler: {
        print(exportSession.status.hashValue)
      })
    }).addDisposableTo(bag)
  }
}
