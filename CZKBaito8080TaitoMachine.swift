//
//  CZKBaito8080TaitoMachine.swift
//  CZKBaito8080
//
//  Created by Cecilio C. Tamarit on 12/02/2018.
//  Copyright © 2018 cecetaca. All rights reserved.
//

import Cocoa

class CZKBaito8080TaitoMachine: CZKBaito8080 {

	let romLocation = 0x0000
	let ramLocation = 0x2000
	let vramLocation = 0x2400
	let ramMirrorLocation = 0x4000

	let freqMHz = 2.0
	let refreshRateHz = 60.0

	var lastRefresh = DispatchTime.now()

	var shiftRegister: UInt16 = 0
	var shiftOffset: UInt8 = 0


	override func handleInterrupts() {
		if (IE == 1 && DispatchTime.now() >= lastRefresh+(1.0/refreshRateHz)) {
			if (interruptToHandle == 2) {
				interruptToHandle = 1
			} else if (interruptToHandle == 1) {
				interruptToHandle = 2
			} else {
				interruptToHandle = 2
			}
			lastRefresh = DispatchTime.now()
		}
		super.handleInterrupts()
	}


	override func outputTo(port: Int) {
		var hShift = UInt8((shiftRegister & 0xFF00) >> 8)
		var lShift = UInt8(shiftRegister & 0x00FF)
		if (port ==  2) {
			shiftOffset = 0x7 & A
		} else if (port == 4) {
			lShift = hShift
			hShift = A
			shiftRegister = UInt16("\(String(hShift, radix:16))\(String(lShift, radix:16))", radix: 16)!
		}
	}

	override func inputIn(port: Int) {
		if (port == 3) {
			let actualShift = UInt8(8) - shiftOffset
			A = UInt8(shiftRegister >> actualShift) & 0xFF
		} else if (port == 0) {
			A = 1
		} else if (port == 1) {
			A = 0
		}
	}

}
