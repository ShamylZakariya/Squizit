//
//  ViewController.swift
//  FreehandSwift
//
//  Created by Shamyl Zakariya on 7/11/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit

class SimpleDrawingViewController: UIViewController {

	@IBOutlet var drawingView: DrawingView!

	override func viewDidLoad() {
		super.viewDidLoad()

		let paperColor = UIColor( patternImage: UIImage(named: "paper-bg"))
		drawingView.backgroundColor = paperColor

		var tgr = UITapGestureRecognizer(target: self, action: "eraseDrawing:")
		tgr.numberOfTapsRequired = 2
		tgr.numberOfTouchesRequired = 1
		drawingView.addGestureRecognizer(tgr)

		var sgr = UISwipeGestureRecognizer(target: self, action: "swipeLeft:" )
		sgr.direction = .Left
		sgr.numberOfTouchesRequired = 2
		drawingView.addGestureRecognizer(sgr)

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
			return docsURL.path.stringByAppendingPathComponent("drawing.bin")
		}

		return nil
	}

	func save( sender:AnyObject ) {
		if let saveFileName = self.saveFileName {
			println("saving to \(saveFileName)")
			let drawingSaveResult = drawingView.drawing.save( saveFileName )

			if let error = drawingSaveResult.error {
				println(error.message)
				return
			}

		}
	}

	func load( sender:AnyObject ) {
		if let saveFileName = self.saveFileName {
			let drawingLoadResult = Drawing.load( saveFileName )
			if let error = drawingLoadResult.error {
				println(error.message)
				return
			}

			drawingView.drawing = drawingLoadResult.value
		}
	}

	func toggleDebugRendering(sender: AnyObject) {
		drawingView.drawing.debugRender = !drawingView.drawing.debugRender
		drawingView.setNeedsDisplay()
	}

	func undo(sender: AnyObject) {
		drawingView.undo()
	}

	func eraseDrawing( t:UITapGestureRecognizer ) {
		drawingView.drawing.clear()
		drawingView.setNeedsDisplay()
	}

	func usePencil( t:AnyObject ) {
		drawingView.fill = Fill.Pencil
	}

	func useEraser( t:AnyObject ) {
		drawingView.fill = Fill.Eraser
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

		drawingView.undo()
		drawingView.undo()

	}

}

