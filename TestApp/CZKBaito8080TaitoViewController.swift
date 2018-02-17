//
//  CZKBaito8080TaitoViewController.swift
//  CZKBaito8080
//
//  Created by Cecilio C. Tamarit on 12/02/2018.
//  Copyright © 2018 cecetaca. All rights reserved.
//

import Cocoa

class CZKBaito8080TaitoViewController: NSViewController {

	@IBOutlet weak var gameView: CZKBaito8080OutputView!

	override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
	@IBAction func refreshScreen(_ sender: Any) {
		gameView.refresh()
	}
}
