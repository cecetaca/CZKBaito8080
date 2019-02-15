//
//  CZKBaito8080OutputView.swift
//  CZKBaito8080
//
//  Created by Cecilio C. Tamarit on 13/02/2018.
//  Copyright © 2018 cecetaca. All rights reserved.
//

import Cocoa

class CZKBaito8080OutputView: NSView {

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		let machine = AppDelegate.machine
		var ram = AppDelegate.machine.array
		let context = NSGraphicsContext.current!.cgContext
		let bitmap = BitmapCanvas(224, 256, "Blue")
		var i = machine.vramLocation;
		var p = 0;
		var col = 0;
		var row = 256;
		while (col < 224) {
			row = 256;
			while (row > 0) {
				p = 0;
				while (p < 8) {
					if (ram[i] & (1<<p) != 0) {
						bitmap[col, row-p] = NSColor.white
					} else {
						bitmap[col, row-p] = NSColor.black
					}
					p+=1;
				}

				i+=1;
				row = row-8;
			}
			col+=1;
		}
		context.draw(bitmap.bitmapImageRep.cgImage!, in: self.bounds)
	}

	override func awakeFromNib() {
		Timer.scheduledTimer(withTimeInterval: 0.42, repeats: true) { (Timer) in
			self.needsDisplay = true
		}
	}

	override var acceptsFirstResponder: Bool { return true }
	override func becomeFirstResponder() -> Bool { return true }
	override func resignFirstResponder() -> Bool { return true }

	override func keyDown(with event: NSEvent) {
		print("Key event")
		interpretKeyEvents([event])
	}

	override func moveLeft(_ sender: Any?) {
		AppDelegate.machine.input1 |= 0x20
		print("Left pressed")
	}

	override func moveRight(_ sender: Any?) {
		AppDelegate.machine.input1 |= 0x40
		print("Right pressed")
	}

	override func insertText(_ insertString: Any) {
		switch insertString as! String {
		case "c":
			AppDelegate.machine.input1 |= 0x1
			print("Coin inserted")
		case " ":
			AppDelegate.machine.input1 |= 0x10
			print("Shoot!")
		case "1":
			print("1 player pressed")
			AppDelegate.machine.input1 |= 0x4
		case "2":
			AppDelegate.machine.input1 |= 0x2
			print("2 players pressed")
		default:
			print("\(insertString) inserted")
		}
	}


    
}
