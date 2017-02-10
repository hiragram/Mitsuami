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

class ViewController: NSViewController {

  private let bag = DisposeBag.init()

  @IBOutlet private weak var savePathTextField: NSTextField! {
    didSet {
      savePathTextField.rx.text.map { $0 ?? "" }.bindTo(recorder.savePath).addDisposableTo(bag)
    }
  }

  @IBOutlet private weak var startButton: NSButton! {
    didSet {
      startButton.rx.tap.subscribe(onNext: { [unowned self] (_) in
        self.recorder.start()
      }).addDisposableTo(bag)
      recorder.isRecording.map { !$0 }.bindTo(startButton.rx.isEnabled).addDisposableTo(bag)
    }
  }

  @IBOutlet private weak var stopButton: NSButton! {
    didSet {
      stopButton.rx.tap.subscribe(onNext: { [unowned self] (_) in
        self.recorder.stop()
      }).addDisposableTo(bag)
      recorder.isRecording.bindTo(stopButton.rx.isEnabled).addDisposableTo(bag)
    }
  }

  @IBOutlet private weak var exportButton: NSButton! {
    didSet {
      exportButton.rx.tap.subscribe(onNext: { [unowned self] (_) in
        let a = try! RecordingPackage.init(packagePath: URL.init(string: self.pathForSound1.value)!)
        let b = try! RecordingPackage.init(packagePath: URL.init(string: self.pathForSound2.value)!)
        RecordingPackage.mixDown(packages: [a, b], exportTo: self.exportPath.value)
      }).addDisposableTo(bag)
    }
  }

  @IBOutlet private weak var pathForSound1TextField: NSTextField! {
    didSet {
      pathForSound1TextField.rx.text.map { $0 ?? "" }.bindTo(pathForSound1).addDisposableTo(bag)
    }
  }

  @IBOutlet private weak var pathForSound2TextField: NSTextField! {
    didSet {
      pathForSound2TextField.rx.text.map { $0 ?? "" }.bindTo(pathForSound2).addDisposableTo(bag)
    }
  }

  @IBOutlet private weak var exportPathTextField: NSTextField! {
    didSet {
      exportPathTextField.rx.text.map { $0 ?? "" }.bindTo(exportPath).addDisposableTo(bag)
    }
  }

  let pathForSound1 = Variable<String>.init("")
  let pathForSound2 = Variable<String>.init("")
  let exportPath = Variable<String>.init("")

  var recorder = Recorder.init()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }

  override var representedObject: Any? {
    didSet {
      // Update the view, if already loaded.
    }
  }


}

