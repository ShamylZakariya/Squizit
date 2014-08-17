//
//  ViewController.swift
//  FreehandSwift
//
//  Created by Shamyl Zakariya on 7/11/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit

class SimpleDrawingViewController: UIViewController {

	@IBOutlet var matchView: MatchView!

	override func viewDidLoad() {
		super.viewDidLoad()

		let paperColor = UIColor( patternImage: UIImage(named: "paper-bg"))
		matchView.backgroundColor = paperColor

		matchView.match = Match(players: 2, stageSize: CGSize(width: 768, height: 1024))

		var tgr = UITapGestureRecognizer(target: self, action: "eraseDrawing:")
		tgr.numberOfTapsRequired = 2
		tgr.numberOfTouchesRequired = 1
		matchView.addGestureRecognizer(tgr)

		var sgr = UISwipeGestureRecognizer(target: self, action: "swipeLeft:" )
		sgr.direction = .Left
		sgr.numberOfTouchesRequired = 2
		matchView.addGestureRecognizer(sgr)

		self.navigationItem.leftBarButtonItems = [
			UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Undo, target: self, action: "undo:"),
			UIBarButtonItem(title: "Toggle Debug", style: UIBarButtonItemStyle.Plain, target: self, action: "toggleDebugRendering:"),
			UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Plain, target: self, action: "save:"),
			UIBarButtonItem(title: "Load", style: UIBarButtonItemStyle.Plain, target: self, action: "load:"),
		]

		self.navigationItem.rightBarButtonItems = [
			UIBarButtonItem(title: "Pencil", style: UIBarButtonItemStyle.Plain, target: self, action: "usePencil:"),
			UIBarButtonItem(title: "Eraser", style: UIBarButtonItemStyle.Plain, target: self, action: "useEraser:")
		]

	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: Actions

	var saveFileName:String? {

		var fm = NSFileManager.defaultManager()
		var maybeDocsURL:NSURL? = fm.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).first as? NSURL

		if let docsURL = maybeDocsURL {
			return docsURL.path.stringByAppendingPathComponent("match.bin")
		}

		return nil
	}

	func save( sender:AnyObject ) {
		if let saveFileName = self.saveFileName {
			println("saving to \(saveFileName)")
			let result = matchView.match!.save( saveFileName )

			if let error = result.error {
				println(error.message)
				return
			}

		}
	}

	func load( sender:AnyObject ) {
		if let saveFileName = self.saveFileName {
			let result = Match.load( saveFileName )
			if let error = result.error {
				println(error.message)
				return
			}

			matchView.match = result.value
		}
	}

	func toggleDebugRendering(sender: AnyObject) {
		if let match = matchView.match {
			for drawing in match.drawings {
				drawing.debugRender = !drawing.debugRender
			}
		}

		matchView.setNeedsDisplay()
	}

	func undo(sender: AnyObject) {
		matchView.undo()
	}

	func eraseDrawing( t:UITapGestureRecognizer ) {

		if let match = matchView.match {
			if let player = matchView.player {
				match.drawings[player].clear()
			}
		}

		matchView.setNeedsDisplay()
	}

	func usePencil( t:AnyObject ) {

		if let match = matchView.match {
			for adapter in matchView.adapters {
				adapter.fill = Fill.Pencil
			}
		}
	}

	func useEraser( t:AnyObject ) {
		if let match = matchView.match {
			for adapter in matchView.adapters {
				adapter.fill = Fill.Eraser
			}
		}
	}

	func swipeLeft( t:UISwipeGestureRecognizer ) {

		//
		//	NOTE: swipe is recognized by the view and a stroke is drawn
		//	the undo action undoes that stroke immediately.
		//
		//	the hack fix is to call undo() twice
		//	the correct fix is to have the drawing view ignore the touch if it's
		//	part of a swipe gesture.
		//

		matchView.undo()
		matchView.undo()

	}

}

