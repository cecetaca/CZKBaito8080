//
//  ViewController.swift
//  CZKBaito8080 Test App
//
//  Created by Cecilio C. Tamarit on 23/11/2017.
//  Copyright © 2017 cecetaca. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

	@IBOutlet weak var codeTextView: NSTextView!
	@IBOutlet weak var stateTextView: NSTextView!
	@IBOutlet weak var stepTextField: NSTextField!

	var selectedFilePath: String?

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

	@IBAction func clearButtonClicked(_ sender: Any) {
		AppDelegate.machine = CZKBaito8080(filePath:selectedFilePath!)
		stateTextView.string = ""
		codeTextView.string = ""
		stepTextField.integerValue = 1
	}

	@IBAction func runButtonClicked(_ sender: Any) {
		// Run at specified frequency and the right cycles.

	}

	@IBAction func stepButtonClicked(_ sender: Any) {
		var stepNum = 0
		while (stepNum < stepTextField.integerValue) {
			AppDelegate.machine.step()
			codeTextView.string = AppDelegate.machine.output
			updateRegsView()
			stepNum += 1
		}
	}

	@IBAction func selectFileClicked(_ sender: Any) {
		let openPanel = NSOpenPanel()
		openPanel.begin { (res) in
			if (res == NSApplication.ModalResponse.OK) {
				let url = openPanel.urls[0]
				print("Opening \(url.absoluteString)")
				self.selectedFilePath = url.path
				self.clearButtonClicked(self)
			}
		}

	}


	func updateRegsView() {
		var regsStr = ""
		regsStr += "PC: \(String(AppDelegate.machine.pc,radix:16))   SP: \(String(AppDelegate.machine.SP,radix:16))\n\n"
		regsStr += "Registers:\n"
		regsStr += "A: \(AppDelegate.machine.A)\n"
		regsStr += "B: \(AppDelegate.machine.B)\n"
		regsStr += "C: \(AppDelegate.machine.C)\n"
		regsStr += "D: \(AppDelegate.machine.D)\n"
		regsStr += "E: \(AppDelegate.machine.E)\n"
		regsStr += "H: \(AppDelegate.machine.H)\n"
		regsStr += "L: \(AppDelegate.machine.L)\n\n"
		regsStr += "Flags:\n"
		regsStr += "Z: \(AppDelegate.machine.Z)    S: \(AppDelegate.machine.S)    P: \(AppDelegate.machine.P)   CY: \(AppDelegate.machine.CY)"
		stateTextView.string = regsStr
		codeTextView.scrollToEndOfDocument(self)
	}

}

