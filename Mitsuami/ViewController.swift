//
//  ViewController.swift
//  Mitsuami
//
//  Created by yuyahirayama on 2017/02/05.
//  Copyright © 2017年 Yuya Hirayama. All rights reserved.
//

import Cocoa
import AudioToolbox

class ViewController: NSViewController {

  var recorder = Recorder.init()

  override func viewDidLoad() {
    super.viewDidLoad()
    recorder.start()
    // Do any additional setup after loading the view.
  }

  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }


}

class Recorder {

  var dataFormat = AudioStreamBasicDescription.init(
    mSampleRate: 44100.0,
    mFormatID: kAudioFormatLinearPCM,
    mFormatFlags: AudioFormatFlags.init(kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked),
    mBytesPerPacket: 2,
    mFramesPerPacket: 1,
    mBytesPerFrame: 2,
    mChannelsPerFrame: 1,
    mBitsPerChannel: 16,
    mReserved: 0
  )

  var audioQueue: AudioQueueRef?
  var error = noErr

  func start() {

    error = AudioQueueNewInput(
      &dataFormat,
      { (_, _, _, _, _, _) in

    },
      Unmanaged.passUnretained(self).toOpaque(),
      .none,
      .none,
      0,
      &audioQueue
    )
  }

  private func AudioQueueCInputCallback(inUserData: UnsafeMutableRawPointer, inAQ: AudioQueueRef, inBuffer: AudioQueueBufferRef, inStartTime: UnsafePointer<AudioTimeStamp>, inNumberPacketDescription: UInt32, inPacketDescs: UnsafePointer<AudioStreamPacketDescription>) {
    
  }
}
