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

	static var machine = CZKBaito8080(filePath:"~/invaders/invaders")


	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application

	}


	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}


}

