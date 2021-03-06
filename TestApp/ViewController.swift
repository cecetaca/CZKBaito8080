//
//  ViewController.swift
//  CZKBaito8080 Test App
//
//  Created by Cecilio C. Tamarit on 23/11/2017.
//  Copyright © 2017 cecetaca. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

	@IBOutlet weak var codeTextView: NSTextView!
	@IBOutlet weak var stateTextView: NSTextView!
	@IBOutlet weak var stepTextField: NSTextField!
	@IBOutlet weak var stepButton: NSButton!
	@IBOutlet weak var memoryTableView: NSTableView!

	var selectedFilePath: String?

	var cpi = 0.0

	override func viewDidLoad() {
		super.viewDidLoad()
		codeTextView.string += "\n"
		memoryTableView.delegate = self
		memoryTableView.dataSource = self
		updateRegsView()
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

	@IBAction func clearButtonClicked(_ sender: Any) {
		if (selectedFilePath == nil) {
			selectFileClicked(self)
		} else {
			AppDelegate.machine = CZKBaito8080TaitoMachine(filePath:selectedFilePath!)
		}
		stateTextView.string = ""
		codeTextView.string = ""
		stepTextField.integerValue = 1
	}

	@IBAction func runButtonClicked(_ sender: Any) {
		// Run at specified frequency and the right cycles.
		Timer.scheduledTimer(withTimeInterval: 0.001, repeats: true) { (tm) in
			DispatchQueue.global(qos: .background).async {
				AppDelegate.machine.run(specifiedCycles:Int(AppDelegate.machine.freqMHz)*1000)
				DispatchQueue.main.sync {
					self.cpi = Double(AppDelegate.machine.cycles) / Double(AppDelegate.machine.instCount)
					self.codeTextView.string = AppDelegate.machine.output
					self.updateRegsView()
				}
			}
		} 
		let outputWindow = self.storyboard?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "OutputWindow")) as! NSWindowController
		outputWindow.showWindow(self)
	}

	@IBAction func stepButtonClicked(_ sender: Any) {
		var stepNum = 0
		let stepMax = self.stepTextField.integerValue
		DispatchQueue.global(qos: .background).async {
			while (stepNum < stepMax) {
				AppDelegate.machine.step()
				stepNum += 1
			}
			DispatchQueue.main.sync {
				self.cpi = Double(AppDelegate.machine.cycles) / Double(AppDelegate.machine.instCount)
				self.codeTextView.string = AppDelegate.machine.output
				self.updateRegsView()
			}
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
		regsStr += "Z: \(AppDelegate.machine.Z)    S: \(AppDelegate.machine.S)    P: \(AppDelegate.machine.P)   CY: \(AppDelegate.machine.CY)\n\n"
		regsStr += "Instr: \(AppDelegate.machine.instCount)  Cycles: \(AppDelegate.machine.cycles)\nCPI: \(cpi)"
		stateTextView.string = regsStr
		codeTextView.scrollToEndOfDocument(self)
		memoryTableView.reloadData()
	}

	func numberOfRows(in tableView: NSTableView) -> Int {
		return AppDelegate.machine.array.count
	}

	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		let item = AppDelegate.machine.array[row]
		var cellIdentifier = ""
		var cellText = ""

		if (tableColumn == tableView.tableColumns[0]) {
			cellIdentifier = "AddressCell"
			cellText = "0x"+String(row,radix:16)
		} else {
			cellIdentifier = "ContentCell"
			cellText = String(item,radix:16)
		}

		if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: self) as? NSTableCellView {
			cell.textField?.stringValue = cellText
			return cell
		}
		return nil
	}

}

