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
	

	var quitGameButton:QuitGameButton!
	var toolSelector:DrawingToolSelector!
	var stepForwardButton:UIButton!
	var shieldViews:[MatchShieldView] = []
	var endOfMatchGestureRecognizer:UITapGestureRecognizer!

	internal var exportQueue = dispatch_queue_create("com.zakariya.squizit.ExportQueue", nil)

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
				// enable the
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
			message: NSLocalizedString("Are you certain you'd like to bail on this match?", comment:"QuitMatchAlertMessage"),
			preferredStyle: UIAlertControllerStyle.Alert)

		alert.view.tintColor = SquizitTheme.alertTintColor()

		alert.addAction(UIAlertAction(
			title: NSLocalizedString("Continue Match", comment:"QuitMatchAlertButtonCancelTitle"),
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

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		endOfMatchGestureRecognizer.enabled = false
		matchView.match = match
		matchView.player = step
		toolSelector.selectedToolIndex = 0
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
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
		toolSelector.orientation = .Horizontal
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
		quitGameButton = QuitGameButton.quitGameButton()
		quitGameButton.addTarget(self, action: "quitMatch:", forControlEvents: UIControlEvents.TouchUpInside)
		view.addSubview(quitGameButton)

		matchView.match = match
		matchView.player = 0
	}

	override func viewWillLayoutSubviews() {
		self.syncToMatchState()
	}

	// MARK: Private

	internal func syncToMatchState_Animate() {
		let duration:NSTimeInterval = 0.7
		let delay:NSTimeInterval = 0
		let damping:CGFloat = 0.7
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
					self.quitGameButton.hidden = true
				}
			})
	}

	internal func syncToMatchState() {

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
			quitGameButton.alpha = 0

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

	internal func layoutSubviewsForTwoPlayers( currentPlayer:Int ) {

		if let match = self.match {
			let margin = 2 * match.overlap

			// two player game only needs one shield view
			shieldViews[0].hidden = false
			shieldViews[1].hidden = true
			shieldViews[1].frame = CGRectZero

			switch currentPlayer {

				case 0:
					shieldViews[0].frame = matchView.rectForPlayer(1)!.rectByAddingTopMargin(margin)
					positionToolsInShield( shieldViews[0], alignTop:false )

				case 1:
					shieldViews[0].frame = matchView.rectForPlayer(0)!.rectByAddingBottomMargin(margin)
					positionToolsInShield( shieldViews[0], alignTop:true )

				default: break;
			}
		}
	}

	internal func layoutSubviewsForThreePlayers( currentPlayer:Int ) {

		if let match = self.match {
			let margin = 2 * match.overlap
			shieldViews[0].hidden = false
			shieldViews[1].hidden = false
			shieldViews[0].alpha = 1
			shieldViews[1].alpha = 1

			switch currentPlayer {

				case 0:
					// hide shield 1 off top of screen - it will slide down in case 1
					var r = matchView.rectForPlayer(0)!
					r.offset(dx: 0, dy: -r.height )
					shieldViews[0].frame = r

					// shield 2 takes up bottom 2/3
					let r1 = matchView.rectForPlayer(1)!.rectByAddingTopMargin(margin)
					let r2 = matchView.rectForPlayer(2)!
					shieldViews[1].frame = r1.rectByUnion(r2)

					positionToolsInShield( shieldViews[1], alignTop:false )

				case 1:
					shieldViews[0].frame = matchView.rectForPlayer(0)!.rectByAddingBottomMargin(margin)
					shieldViews[1].frame = matchView.rectForPlayer(2)!.rectByAddingTopMargin(margin)
					positionToolsInShield( shieldViews[1], alignTop:false )

				case 2:
					// shield 1 takes up top 2/3
					let r1 = matchView.rectForPlayer(0)!
					let r2 = matchView.rectForPlayer(1)!
					shieldViews[0].frame = r1.rectByUnion(r2).rectByAddingBottomMargin(margin)
					positionToolsInShield( shieldViews[0], alignTop:true )

					// slide shield 2 off bottom of screen
					var r = matchView.rectForPlayer(2)!
					r.offset(dx: 0, dy: r.height )
					shieldViews[1].frame = r

				default: break;
			}
		}
	}

	internal func positionToolsInShield( view:UIView, alignTop:Bool ) {

		let frame = view.frame
		let size = quitGameButton.intrinsicContentSize()
		let margin:CGFloat = 36
		let rowHeight:CGFloat = 176

		var toolSelectorRect = CGRectZero
		var stepForwardButtonCenter = CGPointZero

		toolSelectorRect = CGRect(x: frame.minX, y: frame.minY + frame.height/2 - rowHeight, width: frame.width, height: rowHeight )
		stepForwardButtonCenter = CGPoint( x: frame.midX, y: frame.minY + frame.height/2 + rowHeight/2 )

		if alignTop {
			quitGameButton.frame = CGRect( x: frame.minX + margin, y: frame.minY + margin, width: size.width, height: size.height )
		} else {
			quitGameButton.frame = CGRect( x: frame.minX + margin, y: frame.maxY - margin - size.height, width: size.width, height: size.height )
		}

		toolSelector.frame = toolSelectorRect
		stepForwardButton.center = stepForwardButtonCenter
	}

	internal func showSaveToGalleryQuery() {

		//
		//	Load from storyboard and present
		//

		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		var vc = storyboard.instantiateViewControllerWithIdentifier("SaveToGallery") as SaveToGalleryViewController
		vc.modalPresentationStyle = UIModalPresentationStyle.FormSheet
		vc.nameCount = numPlayers
		vc.delegate = self

		presentViewController(vc, animated: true, completion: nil)
	}


	// MARK: SaveToGalleryDelegate

	internal func didDismissSaveToGallery() {
		dismissViewControllerAnimated(true) {
			if let presenter = self.presentingViewController {
				presenter.dismissViewControllerAnimated(true, completion: nil)
			}
			return
		}
	}

	internal func didSaveToGalleryWithNames(names: [String]? ) {
		if let match = self.match {

			let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
			let galleryStore = appDelegate.galleryStore
			if let moc = galleryStore.managedObjectContext {

				export( match ) {
					[weak self]
					( matchData: NSData?, thumbnailData:NSData? ) -> Void in

					// create the gallery drawing entity
					let drawingEntity = GalleryDrawing.newInstanceInManagedObjectContext(moc)
					drawingEntity.match = matchData!
					drawingEntity.thumbnail = thumbnailData!
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

				let matchDataResult = match.serialize()
				if let error = matchDataResult.error {
					println("unable to save match to data, \(error.message)")
					abort()
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

	internal func export( match:Match, done:((matchData:NSData?, thumbnailData:NSData?) -> Void)) {

			dispatch_async(exportQueue) { [unowned self] in

				let matchDataResult = match.serialize()
				if let error = matchDataResult.error {
					println("unable to save match to data, \(error.message)")
					abort()
				}

				// render match with transparent background
				var rendering = match.render()
				let thumbnailSize = CGSize( width: rendering.size.width/4, height: rendering.size.height/4 )
				rendering = rendering.imageByScalingToSize(thumbnailSize)
				var thumbnailData:NSData? = UIImagePNGRepresentation(rendering)

				dispatch_async(dispatch_get_main_queue()) {
					done( matchData: matchDataResult.value, thumbnailData: thumbnailData )
				}
			}
	}

	internal func DEBUG_saveImage( image:UIImage, path:String ) {
	    let folderURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last as NSURL
		let targetURL = folderURL.URLByAppendingPathComponent(path, isDirectory: false)

		println("saving image to \(targetURL)")
		UIImagePNGRepresentation(image).writeToURL(targetURL, atomically: true)
	}

}