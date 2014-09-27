//
//  MatchViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/17/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

extension CGRect {

	func rectByAddingTopMargin( m:CGFloat ) ->CGRect {
		return CGRect(x: origin.x, y: origin.y + m, width: size.width, height: size.height - m )
	}

	func rectByAddingBottomMargin( m:CGFloat ) ->CGRect {
		return CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height - m )
	}

	func rectByAddingMargins( topMargin:CGFloat, bottomMargin:CGFloat ) ->CGRect {
		return CGRect(x: origin.x, y: origin.y + topMargin, width: size.width, height: size.height - topMargin - bottomMargin )
	}
}

class MatchViewController : UIViewController, SaveToGalleryDelegate {

	@IBOutlet var matchView: MatchView!
	

	var quitButton:QuitGameButton!
	var toolSelector:DrawingToolSelector!
	var stepForwardButton:UIButton!
	var shieldViews:[MatchShieldView] = []
	var endOfMatchGestureRecognizer:UITapGestureRecognizer!

	var exportQueue = dispatch_queue_create("com.zakariya.squizit.ExportQueue", nil)

	var match:Match?

	/*
		current game step
		if step < numPlayers the match is active ( see matchActive:Bool )
		if step == numPlayers we're presenting the final drawing to the player
		if step == numPlayers+1 we're showing the save dialog and exiting
	*/
	var step:Int = 0 {
		didSet {
			if matchActive {
				matchView.player = self.step
			} else if step == numPlayers {
				// disable drawing, and listen for a tap to show the save view controller
				matchView.player = nil
				endOfMatchGestureRecognizer.enabled = true
			} else {
				showSaveToGalleryQuery()
			}

			syncToMatchState_Animate()
		}
	}

	var numPlayers:Int {
		if let match = self.match {
			return match.drawings.count
		}

		return 0
	}

	var matchActive:Bool {
		return step < numPlayers
	}

	func undo() {
		if let match = self.match {
			if matchActive {
				matchView.controllers[step].undo()
			}
		}
	}

	func clear() {

		if let match = matchView.match {
			if matchActive {
				match.drawings[step].clear()
			}
		}

		matchView.setNeedsDisplay()
	}

	// MARK: Actions & Gestures

	dynamic func eraseDrawing( t:AnyObject ) {
		clear()
	}

	dynamic func stepForward( t:AnyObject ) {
		step++
	}

	dynamic func quitMatch( t:AnyObject ) {
		var alert = UIAlertController(
			title: NSLocalizedString("Quit?", comment:"QuitMatchAlertTitle"),
			message: NSLocalizedString("Are you certain you'd like to quit this match?", comment:"QuitMatchAlertMessage"),
			preferredStyle: UIAlertControllerStyle.Alert)

		alert.view.tintColor = SquizitTheme.alertTintColor()

		alert.addAction(UIAlertAction(
			title: NSLocalizedString("Continue", comment:"QuitMatchAlertButtonCancelTitle"),
			style: UIAlertActionStyle.Cancel,
			handler: {
				( action:UIAlertAction! ) -> Void in
				alert.dismissViewControllerAnimated(true, completion: nil)
			}))

		alert.addAction(UIAlertAction(
			title: NSLocalizedString("Quit", comment:"QuitMatchAlertButtonQuitTitle"),
			style: UIAlertActionStyle.Destructive,
			handler: {
				[weak self] ( action:UIAlertAction! ) -> Void in

				alert.dismissViewControllerAnimated(true, completion:nil)
				if let sself = self {
					sself.dismissViewControllerAnimated(true, completion: nil)
				}
			}))

		presentViewController(alert, animated: true, completion: nil)
	}

	dynamic func swipeLeft( t:UISwipeGestureRecognizer ) {

		//
		//	NOTE: swipe is recognized by the view and a stroke is drawn
		//	the undo action undoes that stroke immediately.
		//
		//	the hack fix is to call undo() twice
		//	the correct fix is to have the drawing view ignore the touch if it's
		//	part of a swipe gesture.
		//

		undo()
		undo()
	}

	dynamic func toolSelected( sender:DrawingToolSelector ) {
		if let idx = sender.selectedToolIndex {
			var fill = Fill.Pencil
			switch idx {
				case 0: fill = Fill.Pencil
				case 1: fill = Fill.Brush
				case 2: fill = Fill.Eraser
				default: break;
			}

			for controller in matchView.controllers {
				controller.fill = fill
			}
		}
	}

	// MARK: UIKit Overrides

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		edgesForExtendedLayout = UIRectEdge.None
		extendedLayoutIncludesOpaqueBars = true
	}

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.clipsToBounds = true
		view.backgroundColor = SquizitTheme.matchBackgroundColor()

		matchView.backgroundColor = SquizitTheme.paperBackgroundColor()
		matchView.layer.shadowOffset = CGSize(width: 0, height: 3)
		matchView.layer.shadowColor = UIColor.blackColor().CGColor
		matchView.layer.shadowOpacity = 0
		matchView.layer.shadowRadius = 10

		var tgr = UITapGestureRecognizer(target: self, action: "eraseDrawing:")
		tgr.numberOfTapsRequired = 2
		tgr.numberOfTouchesRequired = 1
		matchView.addGestureRecognizer(tgr)

		// this will be enabled only when the match is complete
		endOfMatchGestureRecognizer = UITapGestureRecognizer(target: self, action: "stepForward:")
		endOfMatchGestureRecognizer.numberOfTapsRequired = 1
		endOfMatchGestureRecognizer.enabled = false
		matchView.addGestureRecognizer(endOfMatchGestureRecognizer)

		var sgr = UISwipeGestureRecognizer(target: self, action: "swipeLeft:" )
		sgr.direction = .Left
		sgr.numberOfTouchesRequired = 2
		matchView.addGestureRecognizer(sgr)

		// create the shield views

		var sv = MatchShieldView(frame: CGRectZero)
		view.addSubview(sv)
		shieldViews.append(sv)

		sv = MatchShieldView(frame: CGRectZero)
		view.addSubview(sv)
		shieldViews.append(sv)

		// create the tool selector

		toolSelector = DrawingToolSelector(frame: CGRectZero)
		toolSelector.addTool("Pencil", icon: UIImage(named: "tool-pencil"))
		toolSelector.addTool("Brush", icon: UIImage(named: "tool-brush"))
		toolSelector.addTool("Eraser", icon: UIImage(named: "tool-eraser"))
		toolSelector.addTarget(self, action: "toolSelected:", forControlEvents: UIControlEvents.ValueChanged)
		view.addSubview(toolSelector)

		// create the turn-finished button

		stepForwardButton = SquizitThemeButton.buttonWithType(UIButtonType.Custom) as UIButton
		stepForwardButton.setTitle(NSLocalizedString("Next", comment: "UserFinishedRound" ).uppercaseString, forState: UIControlState.Normal)
		stepForwardButton.addTarget(self, action: "stepForward:", forControlEvents: UIControlEvents.TouchUpInside)
		stepForwardButton.frame = CGRect(x: 0, y: 0, width: 200, height: 44)
		view.addSubview(stepForwardButton)

		// create the quit game button
		quitButton = QuitGameButton.quitGameButton()
		quitButton.addTarget(self, action: "quitMatch:", forControlEvents: UIControlEvents.TouchUpInside)
		view.addSubview(quitButton)

		matchView.match = match
		matchView.player = 0
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		endOfMatchGestureRecognizer.enabled = false
		matchView.match = match
		matchView.player = step
		toolSelector.selectedToolIndex = 0
	}

	override func viewWillLayoutSubviews() {
		self.syncToMatchState()
	}


	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {

		switch segue.identifier {
			case "showSaveToGallery":
				let saveToGalleryVC = segue.destinationViewController as SaveToGalleryViewController
				saveToGalleryVC.nameCount = numPlayers
				saveToGalleryVC.delegate = self

			default: break;
		}
	}

	// MARK: Private

	func syncToMatchState_Animate() {
		let duration:NSTimeInterval = 0.7
		let delay:NSTimeInterval = 0
		let damping:CGFloat = 0.9
		let initialSpringVelocity:CGFloat = 0
		let options:UIViewAnimationOptions = UIViewAnimationOptions.AllowUserInteraction

		UIView.animateWithDuration(duration,
			delay: delay,
			usingSpringWithDamping: damping,
			initialSpringVelocity: initialSpringVelocity,
			options: options,
			animations: { [unowned self] () -> Void in
				self.syncToMatchState()
			},
			completion: { [unowned self] (complet:Bool) -> Void in
				if self.step >= self.numPlayers {
					self.shieldViews[0].hidden = true
					self.shieldViews[1].hidden = true
					self.toolSelector.hidden = true
					self.stepForwardButton.hidden = true
					self.quitButton.hidden = true
				}
			})
	}

	func syncToMatchState() {

		if matchActive {

			toolSelector.alpha = 1
			stepForwardButton.alpha = 1
			matchView.layer.shadowOpacity = 0
			matchView.layer.shouldRasterize = false

			switch numPlayers {
				case 2: layoutSubviewsForTwoPlayers(step)
				case 3: layoutSubviewsForThreePlayers(step)
				default: break;
			}

		} else if step == numPlayers {

			shieldViews[0].alpha = 0
			shieldViews[1].alpha = 0
			toolSelector.alpha = 0
			stepForwardButton.alpha = 0
			quitButton.alpha = 0

			let angleRange = drand48() * 2.0 - 1.0
			let angle = M_PI * 0.00625 * angleRange
			let scale = CATransform3DMakeScale(0.9, 0.9, 1.0)
			let rotation = CATransform3DMakeRotation(CGFloat(angle), 0, 0, 1)
			matchView.layer.transform = CATransform3DConcat(scale, rotation)
			matchView.layer.shouldRasterize = true
			matchView.layer.shadowOpacity = 1

		} else {

		}
	}

	func layoutSubviewsForTwoPlayers( currentPlayer:Int ) {

		if let match = self.match {
			let margin = 2 * match.overlap

			// two player game only needs one shield view
			shieldViews[0].hidden = false
			shieldViews[1].hidden = true
			shieldViews[1].frame = CGRectZero

			switch currentPlayer {

				case 0:
					shieldViews[0].frame = matchView.screenRectForDrawing(1)!.rectByAddingTopMargin(margin)
					positionToolsInShield( shieldViews[0], alignTop:false )

				case 1:
					shieldViews[0].frame = matchView.screenRectForDrawing(0)!.rectByAddingBottomMargin(margin)
					positionToolsInShield( shieldViews[0], alignTop:true )

				default: break;
			}
		}
	}

	func layoutSubviewsForThreePlayers( currentPlayer:Int ) {

		if let match = self.match {
			let margin = 2 * match.overlap
			shieldViews[0].hidden = false
			shieldViews[1].hidden = false
			shieldViews[0].alpha = 1
			shieldViews[1].alpha = 1

			switch currentPlayer {

				case 0:
					// hide shield 1 off top of screen - it will slide down in case 1
					var r = matchView.screenRectForDrawing(0)!
					r.offset(dx: 0, dy: -r.height )
					shieldViews[0].frame = r

					// shield 2 takes up bottom 2/3
					let r1 = matchView.screenRectForDrawing(1)!.rectByAddingTopMargin(margin)
					let r2 = matchView.screenRectForDrawing(2)!
					shieldViews[1].frame = r1.rectByUnion(r2)

					positionToolsInShield( shieldViews[1], alignTop:false )

				case 1:
					shieldViews[0].frame = matchView.screenRectForDrawing(0)!.rectByAddingBottomMargin(margin)
					shieldViews[1].frame = matchView.screenRectForDrawing(2)!.rectByAddingTopMargin(margin)
					positionToolsInShield( shieldViews[1], alignTop:false )

				case 2:
					// shield 1 takes up top 2/3
					let r1 = matchView.screenRectForDrawing(0)!
					let r2 = matchView.screenRectForDrawing(1)!
					shieldViews[0].frame = r1.rectByUnion(r2).rectByAddingBottomMargin(margin)
					positionToolsInShield( shieldViews[0], alignTop:true )

					// slide shield 2 off bottom of screen
					var r = matchView.screenRectForDrawing(2)!
					r.offset(dx: 0, dy: r.height )
					shieldViews[1].frame = r

				default: break;
			}
		}
	}

	func positionToolsInShield( view:UIView, alignTop:Bool ) {

		let frame = view.frame
		let margin:CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 32 : 16
		let insetFrame = frame.rectByInsetting(dx: margin, dy: margin)
		let toolsHeight:CGFloat = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? 88 : 66

		var toolSelectorFrame = CGRect.zeroRect
		var stepForwardButtonFrame = CGRect.zeroRect
		var quitButtonFrame = CGRect.zeroRect

		// position tool selector in center of shield
		toolSelectorFrame = CGRect(x: insetFrame.minX, y: insetFrame.midY - toolsHeight/2, width: insetFrame.width, height: toolsHeight )

		// position step forward button in center bottom of shield
		let stepForwardButtonSize = stepForwardButton.frame.size
		stepForwardButtonFrame = CGRect(
			x: insetFrame.midX - stepForwardButtonSize.width/2,
			y: insetFrame.maxY - stepForwardButtonSize.height,
			width: stepForwardButtonSize.width,
			height: stepForwardButtonSize.height )


		let quitButtonSize = quitButton.intrinsicContentSize()
		if alignTop {
			quitButtonFrame = CGRect( x: insetFrame.minX, y: insetFrame.minY, width: quitButtonSize.width, height: quitButtonSize.height )
		} else {
			quitButtonFrame = CGRect( x: insetFrame.minX, y: insetFrame.maxY - quitButtonSize.height, width: quitButtonSize.width, height: quitButtonSize.height )

			// right-align step forward button if we're crowded
			if quitButtonFrame.maxX + margin > stepForwardButtonFrame.minX {
				stepForwardButtonFrame.offset(dx: insetFrame.maxX - stepForwardButtonFrame.maxX, dy: 0)
			}
		}

		if toolSelectorFrame.maxY + margin > stepForwardButtonFrame.minY {
			toolSelectorFrame.origin.y = stepForwardButtonFrame.minY - margin - toolSelectorFrame.height
		}

		toolSelector.frame = toolSelectorFrame
		stepForwardButton.frame = stepForwardButtonFrame
		quitButton.frame = quitButtonFrame
	}

	func showSaveToGalleryQuery() {
		performSegueWithIdentifier("showSaveToGallery", sender: self)
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

			let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
			let galleryStore = appDelegate.galleryStore
			if let moc = galleryStore.managedObjectContext {

				export( match ) { matchData, thumbnailSize, thumbnailData in

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

	/*
		serializes match to NSData and saves a thumbnail PNG rep to NSData as well, in a background queue,
		calling done() on main queue when complete
	*/

	func export( match:Match, done:((matchData:NSData?, thumbnailSize:CGSize, thumbnailData:NSData?) -> Void)) {

			dispatch_async(exportQueue) {

				let matchDataResult = match.serialize()
				if let error = matchDataResult.error {
					println("unable to save match to data, \(error.message)")
					abort()
				}

				// render match with transparent background
				var rendering = match.render( backgroundColor: nil, scale: UIScreen.mainScreen().scale )

				let thumbnailSize = CGSize( width: rendering.size.width/2, height: rendering.size.height/2 )
				rendering = rendering.imageByScalingToSize(thumbnailSize)

				var thumbnailData:NSData? = UIImagePNGRepresentation(rendering)

				dispatch_async(dispatch_get_main_queue()) {
					done( matchData: matchDataResult.value, thumbnailSize:thumbnailSize, thumbnailData: thumbnailData )
				}
			}
	}

	func DEBUG_saveImage( image:UIImage, path:String ) {
	    let folderURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last as NSURL
		let targetURL = folderURL.URLByAppendingPathComponent(path, isDirectory: false)

		println("saving image to \(targetURL)")
		UIImagePNGRepresentation(image).writeToURL(targetURL, atomically: true)
	}
	
}