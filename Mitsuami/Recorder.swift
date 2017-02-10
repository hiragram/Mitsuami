//
//  Recorder.swift
//  Mitsuami
//
//  Created by yuya_hirayama on 2017/02/10.
//  Copyright © 2017年 Yuya Hirayama. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import AudioToolbox

class Recorder {

  // private variables
  private let _savePath = Variable<String>.init("")

  // interfaces
  var savePath: AnyObserver<String>! = nil
  var isRecording: Observable<Bool> {
    return state.isRunning.asObservable()
  }

  private class State {
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
    let isRunning = Variable<Bool>.init(false)
    var fileType = kAudioFileAIFFType
    var bufferByteSize: UInt32 = 0
    let numberOfBuffers = 3
    var buffers: [AudioQueueBufferRef?]

    init() {
      buffers = (1...numberOfBuffers).map { _ in return nil }
    }
  }

  private var state = State.init()

  init() {
    savePath = AnyObserver<String>.init { [unowned self] (event) in
      switch event {
      case .next(let path):
        self._savePath.value = path
      default:
        break
      }
    }
  }

  func start() {
    let audioFileURL = URL.init(fileURLWithPath: _savePath.value)

    var audioFile: AudioFileID?
    var creationError = noErr
    creationError = AudioFileCreateWithURL(
      audioFileURL as CFURL,
      state.fileType,
      &state.dataFormat,
      AudioFileFlags.eraseFile,
      &audioFile
    )
    if creationError == noErr {
      state.audioFile = audioFile
    } else {
      print(creationError)
      return
    }

    var audioQueue: AudioQueueRef?
    state.error = AudioQueueNewInput(
      &state.dataFormat,
      { (rawPointer, inputAudioQueue, inputBuffer, inputTimeStamp, inputPacketNumber, inputPacketDescription) in
        let pointer = UnsafeMutablePointer<Recorder.State>.init(OpaquePointer.init(rawPointer))
        guard let state = pointer?.pointee else {
          return
        }

        var _inputPacketNumber: UInt32 = inputPacketNumber
        if inputPacketNumber == 0 && state.dataFormat.mBytesPerPacket != 0 {
          _inputPacketNumber = inputBuffer.pointee.mAudioDataByteSize / state.dataFormat.mBytesPerPacket
        }

        if AudioFileWritePackets(
          state.audioFile,
          false,
          inputBuffer.pointee.mAudioDataByteSize,
          inputPacketDescription,
          state.currentPacketCount,
          &_inputPacketNumber,
          inputBuffer.pointee.mAudioData
          ) == noErr {
          state.currentPacketCount += Int64(_inputPacketNumber)
        }

        if state.isRunning.value == false {
          return
        }

        var result = noErr
        result = AudioQueueEnqueueBuffer(state.audioQueue, inputBuffer, 0, nil)
        if result != noErr {
          print(result)
        }

    },
      &state,
      .none,
      .none,
      0,
      &audioQueue
    )

    if state.error == noErr {
      state.audioQueue = audioQueue
    } else {
      print(state.error)
    }

    deriveBufferSize(
      audioQueue: state.audioQueue,
      description: state.dataFormat,
      seconds: 0.5,
      outBufferSize: &state.bufferByteSize
    )

    for i in 0 ..< state.numberOfBuffers {
      AudioQueueAllocateBuffer(state.audioQueue, state.bufferByteSize, &state.buffers[i])
      AudioQueueEnqueueBuffer(state.audioQueue, state.buffers[i]!, 0, nil)
    }

    var startError = noErr
    state.isRunning.value = true
    startError = AudioQueueStart(state.audioQueue, nil)
    if startError != noErr {
      print(startError)
      return
    }
  }

  func stop() {
    AudioQueueStop(state.audioQueue, true)
    state.isRunning.value = false

    AudioQueueDispose(state.audioQueue, true)
    AudioFileClose(state.audioFile)
    print("録音を終了しました")
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
