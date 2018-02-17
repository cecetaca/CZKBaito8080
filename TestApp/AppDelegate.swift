//
//  AppDelegate.swift
//  CZKBaito8080 Test App
//
//  Created by Cecilio C. Tamarit on 23/11/2017.
//  Copyright © 2017 cecetaca. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	//Inits machine with default path I set for debugging. You should probably change this.
	static var machine = CZKBaito8080TaitoMachine(filePath:"~/invaders/invaders")


	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application

	}


	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}


}

