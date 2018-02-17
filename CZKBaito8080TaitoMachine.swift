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
	var lastInterrupt = 2


	override func handleInterrupts() {
		if (IE == 1 && DispatchTime.now() >= lastRefresh+(1.0/refreshRateHz)) {
			if (lastInterrupt == 2) {
				interruptToHandle = 1
			} else if (lastInterrupt == 1) {
				interruptToHandle = 2
			}
			lastRefresh = DispatchTime.now()
		}
		super.handleInterrupts()
	}


	override func outputTo(port: Int) {
		
	}

}
