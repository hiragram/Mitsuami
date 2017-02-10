//
//  ViewController.swift
//  Mitsuami
//
//  Created by yuyahirayama on 2017/02/05.
//  Copyright © 2017年 Yuya Hirayama. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa
import AudioToolbox

class ViewController: NSViewController {

  var recorder = Recorder.init()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }

  override func viewDidAppear() {
    super.viewDidAppear()
    recorder.start()
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

  var audioQueue: AudioQueueRef!
  var error = noErr
  var audioFile: AudioFileID! = nil
  var currentPacketCount: Int64 = 0
  var isRunning: Bool = false
  var fileType = kAudioFileAIFFType
  var bufferByteSize: UInt32 = 0
  let numberOfBuffers = 3
  var buffers: [AudioQueueBufferRef?]

  private let level = Observable<Int>.interval(1, scheduler: MainScheduler.instance)

  init() {
     buffers = (1...numberOfBuffers).map { _ in return nil }
  }

  var aaa: String?

  func start() {

    aaa = "わいわい"


    let audioFileURL = URL.init(fileURLWithPath: "/Users/yuya_hirayama/Desktop/sound.aiff")

    var audioFile: AudioFileID?
    var creationError = noErr
    creationError = AudioFileCreateWithURL(
      audioFileURL as CFURL,
      fileType,
      &dataFormat,
      AudioFileFlags.eraseFile,
      &audioFile
    )
    if creationError == noErr {
      self.audioFile = audioFile
    } else {
      print(creationError)
      return
    }

    var audioQueue: AudioQueueRef?
    error = AudioQueueNewInput(
      &dataFormat,
      { (rawPointer, inputAudioQueue, inputBuffer, inputTimeStamp, inputPacketNumber, inputPacketDescription) in
//        let recorderPointer = OpaquePointer.init(aqData)
//        let pointer = UnsafeMutablePointer<Recorder>.init(recorderPointer)

        let pointer = UnsafeMutablePointer<Recorder>.init(OpaquePointer.init(rawPointer))
        guard let recorder = pointer?.pointee else {
          print("あああああ")
          return
        }

        print(rawPointer)
        print(pointer)
        print(recorder)
        pointer?.pointee.aaa

//        var _inputPacketNumber: UInt32 = inputPacketNumber
//        if inputPacketNumber == 0 && recorder.dataFormat.mBytesPerPacket != 0 {
//          _inputPacketNumber = inputBuffer.pointee.mAudioDataByteSize / recorder.dataFormat.mBytesPerPacket
//        }
//
//        print(recorder.aaa)
//
//        if AudioFileWritePackets(
//          recorder.audioFile,
//          false,
//          inputBuffer.pointee.mAudioDataByteSize,
//          inputPacketDescription,
//          recorder.currentPacketCount,
//          &_inputPacketNumber,
//          inputBuffer.pointee.mAudioData
//          ) == noErr {
//          recorder.currentPacketCount += Int64(_inputPacketNumber)
//        }
//
//        if recorder.isRunning == false {
//          return
//        }
//
//        AudioQueueEnqueueBuffer(recorder.audioQueue, inputBuffer, 0, nil)

    },
      Unmanaged.passUnretained(self).toOpaque(),
      .none,
      .none,
      0,
      &audioQueue
    )

    if error == noErr {
      self.audioQueue = audioQueue
    } else {
      print(error)
    }

    deriveBufferSize(
      audioQueue: self.audioQueue,
      description: dataFormat,
      seconds: 0.5,
      outBufferSize: &bufferByteSize
    )

    for i in 0 ..< numberOfBuffers {
      AudioQueueAllocateBuffer(self.audioQueue, bufferByteSize, &buffers[i])
      AudioQueueEnqueueBuffer(self.audioQueue, buffers[i]!, 0, nil)
    }

    var startError = noErr
    startError = AudioQueueStart(self.audioQueue, nil)
    if startError != noErr {
      print(startError)
      return
    }

  }


  func deriveBufferSize(audioQueue: AudioQueueRef, description: AudioStreamBasicDescription, seconds: Float64, outBufferSize: UnsafeMutablePointer<UInt32>) {
    let maxBufferSize = 0x50000

    var maxPacketSize = description.mBytesPerPacket
    if maxPacketSize == 0 {
      var maxVBRPacketSize = UInt32(MemoryLayout<UInt32>.size)
      AudioQueueGetProperty(
        audioQueue,
        kAudioQueueProperty_MaximumOutputPacketSize,
        &maxPacketSize,
        &maxVBRPacketSize
      )
    }

    let numBytesForTime = Double(description.mSampleRate) * Double(maxPacketSize) * Double(seconds)
    outBufferSize.pointee = UInt32(numBytesForTime < Double(maxBufferSize) ? UInt32(numBytesForTime) : UInt32(maxBufferSize))
  }
}
