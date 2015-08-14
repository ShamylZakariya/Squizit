//
//  UniversalMatchViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/8/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class UniversalMatchViewController : UIViewController, SaveToGalleryDelegate {

	private var quitGameButton:GameControlButton!
	private var finishTurnButton:GameControlButton!
	private var drawingToolSelector:DrawingToolSelector!
	private var undoButton:SquizitGameTextButton!
	private var clearButton:SquizitGameTextButton!
	private var drawingContainerView:UniversalMatchViewPresenterView!
	private var matchView:UniversalMatchView!

	private var endOfMatchGestureRecognizer:UITapGestureRecognizer!
	private var exportQueue = dispatch_queue_create("com.zakariya.squizit.ExportQueue", nil)

	/**
		The number of players in this match. The value must be 2 or 3
	*/
	var players:Int = 0

	/**
		current game step
		if step ..< players that player is active player, and is drawing
		if step < players the match is active ( see matchActive:Bool )
		if step == numPlayers last player finished & we're presenting the final drawing to the player
		if step == numPlayers+1 we're showing the save dialog and exiting
	*/
	var step:Int = 0 {
		didSet {
			if step < players {
				matchView.turn = step
			} else if step == players {
				endOfMatchGestureRecognizer.enabled = true
			} else {
				querySaveToGallery()
			}
		}
	}

	dynamic func stepForward() {
		step++
	}

	/**
		Get the current player if match is active, else nil
	*/
	var player:Int? {
		return matchActive ? step : nil
	}

	/**
		Return true if a player is currently drawing
	*/
	var matchActive:Bool {
		return step < players
	}

	var match:Match? {
		return matchView.match
	}

	override func viewDidLoad() {
		title = "Drawing Tests..."
		view.backgroundColor = SquizitTheme.matchBackgroundColor()

		quitGameButton = GameControlButton.quitGameButton()
		finishTurnButton = GameControlButton.finishTurnButton()

		drawingToolSelector = DrawingToolSelector(frame: CGRect.zeroRect)
		drawingToolSelector.addTool("Pencil", icon: UIImage(named: "tool-pencil")!)
		drawingToolSelector.addTool("Brush", icon: UIImage(named: "tool-brush")!)
		drawingToolSelector.addTool("Eraser", icon: UIImage(named: "tool-eraser")!)
		drawingToolSelector.addTarget(self, action: "onDrawingToolSelected:", forControlEvents: .ValueChanged)

		undoButton = SquizitGameTextButton.create("Undo")
		undoButton.addTarget(self, action: "onUndo:", forControlEvents: .TouchUpInside)

		clearButton = SquizitGameTextButton.create("Clear")
		clearButton.addTarget(self, action: "onClear:", forControlEvents: .TouchUpInside)

		drawingContainerView = UniversalMatchViewPresenterView(frame: CGRect.zeroRect)


		assert(players == 2 || players == 3, "Number of players MUST be 2, or 3")
		let match = Match(players: players, stageSize: CGSize(width: 1024, height: 1024), overlap: 32)

		matchView = UniversalMatchView(frame: CGRect.zeroRect)
		matchView.match = match
		matchView.turn = 0
		drawingContainerView.drawingView = matchView


		view.addSubview(drawingContainerView)
		view.addSubview(clearButton)
		view.addSubview(undoButton)
		view.addSubview(drawingToolSelector)
		view.addSubview(finishTurnButton)
		view.addSubview(quitGameButton)


		finishTurnButton.addTarget(self, action: "onFinishTurnTapped:", forControlEvents: .TouchUpInside)
		quitGameButton.addTarget(self, action: "onQuitTapped:", forControlEvents: .TouchUpInside)

		drawingToolSelector.selectedToolIndex = 0

		// subscribe to notifications
		let ns = NSNotificationCenter.defaultCenter()
		ns.addObserver(self, selector: "onDrawingDidChange", name: UniversalMatchView.Notifications.DrawingDidChange, object: matchView)
		ns.addObserver(self, selector: "onTurnDidChange", name: UniversalMatchView.Notifications.TurnDidChange, object: matchView)

		// this will be enabled only when the match is complete
		endOfMatchGestureRecognizer = UITapGestureRecognizer(target: self, action: "stepForward")
		endOfMatchGestureRecognizer.numberOfTapsRequired = 1
		endOfMatchGestureRecognizer.enabled = false
		view.addGestureRecognizer(endOfMatchGestureRecognizer)

		// go default
		onDrawingDidChange()

		delay(1) {
			NSLog("UniversalMatchViewController::viewDidLoad - showing save to gallery for testing!!!")
			self.querySaveToGallery()
		}
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		setNeedsStatusBarAppearanceUpdate()
	}

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

	override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
	}

	override func viewWillLayoutSubviews() {

		// generally, the drawingContainerView will fill the available space, rendering the drawing inside, scaled or translated.
		// quit is on top left, finish-turn on top right, undo and clear in top-middle
		// and the tool picker in center bottom.
		// but in tight scenarios, like a phone in landscape, the drawingContainer will
		// leave room at top for all controls, which will be positioned across the top

		let layoutRect = CGRect(x: 0, y: topLayoutGuide.length, width: view.bounds.width, height: view.bounds.height - (topLayoutGuide.length+bottomLayoutGuide.length))
		let naturalDrawingSize = drawingContainerView.drawingSize
		let (scaledDrawingSize,scaledDrawingScale) = drawingContainerView.fittedDrawingSize(layoutRect.size)
		let drawingToolSize = drawingToolSelector.intrinsicContentSize()
		let buttonSize = quitGameButton.intrinsicContentSize().height
		let margin = CGFloat(traitCollection.horizontalSizeClass == .Compact ? 8 : 36)
		let textButtonWidth = max(undoButton.intrinsicContentSize().width,clearButton.intrinsicContentSize().width)

		if (scaledDrawingSize.height + 2*drawingToolSize.height) < layoutRect.height {
			// we can perform normal layout
			drawingContainerView.frame = view.bounds
			quitGameButton.frame = CGRect(x: margin, y: layoutRect.minY + margin, width: buttonSize, height: buttonSize)
			finishTurnButton.frame = CGRect(x: layoutRect.maxX - margin - buttonSize, y: layoutRect.minY + margin, width: buttonSize, height: buttonSize)

			var textButtonTotalWidth = 2*textButtonWidth + margin
			undoButton.frame = CGRect(x: layoutRect.midX - textButtonWidth - margin/2, y: layoutRect.minY + margin, width: textButtonWidth, height: buttonSize)
			clearButton.frame = CGRect(x: layoutRect.midX + margin/2, y: layoutRect.minY + margin, width: textButtonWidth, height: buttonSize)

			drawingToolSelector.frame = CGRect(x: round(layoutRect.midX - drawingToolSize.width/2), y: round(layoutRect.maxY - drawingToolSize.height - margin), width: drawingToolSize.width, height: drawingToolSize.height)
		} else {
			// compact layout needed
			let toolsHeight = max(drawingToolSize.height,buttonSize)
			let toolBarRect = CGRect(x: margin, y: layoutRect.minY + margin, width: layoutRect.width-(2*margin), height: toolsHeight)

			drawingContainerView.frame = CGRect(x: layoutRect.minX, y: toolBarRect.maxY + margin, width: layoutRect.width, height: (layoutRect.maxY - toolBarRect.maxY) - 2*margin)
			quitGameButton.frame = CGRect(x: margin, y: layoutRect.minY + margin, width: buttonSize, height: buttonSize)
			finishTurnButton.frame = CGRect(x: layoutRect.maxX - margin - buttonSize, y: layoutRect.minY + margin, width: buttonSize, height: buttonSize)
			drawingToolSelector.frame = CGRect(x: round(layoutRect.midX - drawingToolSize.width/2), y: margin, width: drawingToolSize.width, height: drawingToolSize.height)

			// undo button goes between quit button right edge and the drawingToolSelector left edge
			undoButton.frame = CGRect(x: round((quitGameButton.frame.maxX + drawingToolSelector.frame.minX)/2 - textButtonWidth/2),
				y: margin, width: textButtonWidth, height: buttonSize)

			clearButton.frame = CGRect(x: round((drawingToolSelector.frame.maxX + finishTurnButton.frame.minX)/2 - textButtonWidth/2),
				y: margin, width: textButtonWidth, height: buttonSize)
		}
	}

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

		if let identifier = segue.identifier {
			switch identifier {
			case "showSaveToGallery":
				let saveToGalleryVC = segue.destinationViewController as! SaveToGalleryViewController
				saveToGalleryVC.nameCount = players
				saveToGalleryVC.delegate = self

			default: break;
			}
		}
	}


	// MARK: - Private

	/*
		returns true iff the current player is allowed to end his turn.
		Player 0 must have a drawing that overlaps the bottom of drawing area
		Last player must have a drawing that overlaps the top of drawing area
		Middle player must have drawing that overlaps top and bottom
	*/
	var playerCanEndTurn:Bool {
		if let match = matchView.match, drawing = matchView.drawing, viewport = matchView.controller?.viewport {

			let numPlayers = match.players
			let drawingBounds = drawing.boundingRect

			if drawing.strokes.isEmpty || drawingBounds.isNull {
				return false
			}

			let extendsToBottom = drawingBounds.maxY >= viewport.height - match.overlap/2
			let extendsToTop = drawingBounds.minY <= match.overlap/2

			switch matchView.turn {
				case 0:	return extendsToBottom
				case numPlayers-1: return extendsToTop
				default: return extendsToBottom && extendsToTop
			}
		}

		// no match!
		return false
	}

	var playerCanUndo:Bool {
		if let drawing = matchView.drawing {
			return !drawing.strokes.isEmpty
		}

		// no player or no match, so player can't undo
		return false
	}

	private func updateUi() {
		finishTurnButton.enabled = self.playerCanEndTurn

		let canUndo = playerCanUndo
		undoButton.enabled = canUndo
		clearButton.enabled = canUndo
	}

	// MARK: - Notifications

	dynamic private func onDrawingDidChange() {
		updateUi()
	}

	dynamic private func onTurnDidChange() {
		updateUi()
	}

	// MARK: - Actions

	dynamic private func onDrawingToolSelected( sender:DrawingToolSelector ) {
		if let idx = sender.selectedToolIndex {
			var fill = Fill.Pencil
			switch idx {
			case 0: fill = Fill.Pencil
			case 1: fill = Fill.Brush
			case 2: fill = Fill.Eraser
			default: break;
			}

			for c in matchView.controllers {
				c.fill = fill
			}
		}
	}

	dynamic private func onUndo( sender:AnyObject ) {
		matchView.controller!.undo()
		onDrawingDidChange()
	}

	dynamic private func onClear( sender:AnyObject ) {
		matchView.drawing!.clear()
		onDrawingDidChange()
		matchView.setNeedsDisplay()
	}

	dynamic private func onToggleDebugRendering( sender:AnyObject ) {
		matchView.showDirtyRectUpdates = !matchView.showDirtyRectUpdates
		for drawing in matchView.match!.drawings {
			drawing.debugRender = matchView.showDirtyRectUpdates
		}
	}

	private dynamic func onFinishTurnTapped(sender:AnyObject) {
		stepForward()
	}

	private dynamic func onQuitTapped(sender:AnyObject) {
		queryQuitMatch()
	}

	// MARK: - Dialogs

	private dynamic func querySaveToGallery() {
		performSegueWithIdentifier("showSaveToGallery", sender: self)
	}

	private dynamic func queryQuitMatch() {
		var alert = UIAlertController(
			title: NSLocalizedString("Quit?", comment:"QuitMatchAlertTitle"),
			message: NSLocalizedString("Are you certain you'd like to quit this match?", comment:"QuitMatchAlertMessage"),
			preferredStyle: UIAlertControllerStyle.Alert)

		alert.view.tintColor = SquizitTheme.alertTintColor()

		alert.addAction(UIAlertAction(
			title: NSLocalizedString("Continue", comment:"QuitMatchAlertButtonCancelTitle"),
			style: UIAlertActionStyle.Cancel,
			handler: nil))

		alert.addAction(UIAlertAction(
			title: NSLocalizedString("Quit", comment:"QuitMatchAlertButtonQuitTitle"),
			style: UIAlertActionStyle.Destructive,
			handler: { [weak self] action in
				self?.dismissViewControllerAnimated(true, completion: nil)
			}))

		presentViewController(alert, animated: true, completion: nil)
	}

	// MARK: SaveToGalleryDelegate

	func didDismissSaveToGallery() {
		dismissViewControllerAnimated(true) {
			if let presenter = self.presentingViewController {
				presenter.dismissViewControllerAnimated(true, completion: nil)
			}
			return
		}
	}

	func didSaveToGalleryWithNames(names: [String]? ) {
		if let match = self.match {

			let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
			let galleryStore = appDelegate.galleryStore
			if let moc = galleryStore.managedObjectContext {

				export( match ) { (matchData, thumbnailSize, thumbnailData) in

					// create the gallery drawing entity
					let drawingEntity = GalleryDrawing.newInstanceInManagedObjectContext(moc)
					drawingEntity.match = matchData!
					drawingEntity.thumbnail = thumbnailData!
					drawingEntity.thumbnailWidth = Int32(thumbnailSize.width)
					drawingEntity.thumbnailHeight = Int32(thumbnailSize.height)
					drawingEntity.numPlayers = Int16(match.drawings.count)
					drawingEntity.date = NSDate().timeIntervalSinceReferenceDate

					// lookup the artists referenced ( if any ) creating them if they're new
					var artists:[GalleryArtist] = []
					if let names = names {
						for name in names {
							if let artist = galleryStore.loadArtist(name, create: true) {
								artists.append( artist )
							}
						}
					}

					// link up artists and the drawing
					for artistEntity in artists {
						artistEntity.addDrawingsObject(drawingEntity)
						drawingEntity.addArtistsObject(artistEntity)
					}

					// finish up
					galleryStore.save()
				}
			}
		}

		//
		// we can dismiss this VC immediately since it's no longer needed
		//

		dismissViewControllerAnimated(true) {
			if let presenter = self.presentingViewController {
				presenter.dismissViewControllerAnimated(true, completion: nil)
			}
			return
		}
	}

	/**
		serializes match to NSData and saves a thumbnail PNG rep to NSData as well, in a background queue,
		calling done() on main queue when complete
	*/

	private func export( match:Match, done:((matchData:NSData?, thumbnailSize:CGSize, thumbnailData:NSData?) -> Void)) {

		dispatch_async(exportQueue) {

			let matchDataResult = match.serialize()
			if let error = matchDataResult.error {
				NSLog("UniversalMatchViewController::export - unable to save match to data, error: \(error.message)")
				abort()
			}

			// render match with transparent background
			var rendering = match.render( backgroundColor: nil, scale: UIScreen.mainScreen().scale )

			#if DEBUG
				self.DEBUG_saveImage(rendering, name: "drawing.png")
			#endif

			let thumbnailSize = CGSize( width: rendering.size.width/2, height: rendering.size.height/2 )
			rendering = rendering.imageByScalingToSize(thumbnailSize)

			#if DEBUG
				self.DEBUG_saveImage(rendering, name: "drawing-thumbnail.png")
			#endif

			var thumbnailData:NSData? = UIImagePNGRepresentation(rendering)

			dispatch_main {
				done( matchData: matchDataResult.value, thumbnailSize:thumbnailSize, thumbnailData: thumbnailData )
			}
		}
	}

	private func DEBUG_saveImage( image:UIImage, name:String ) {
		let folderURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last as! NSURL
		let targetURL = folderURL.URLByAppendingPathComponent(name, isDirectory: false)

		NSLog("UniversalMatchViewController::DEBUG_saveImage - saving: \(targetURL)")
		UIImagePNGRepresentation(image).writeToURL(targetURL, atomically: true)
	}

}