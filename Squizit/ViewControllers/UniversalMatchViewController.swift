//
//  UniversalMatchViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/8/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class UniversalMatchViewToolbarBackgroundView : UIView {

	required override init(frame: CGRect) {
		super.init(frame:frame)
		userInteractionEnabled = false
		opaque = false
	}

	required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}

	override func drawRect(rect: CGRect) {
		SquizitTheme.matchBackgroundColor().colorWithAlphaComponent(0.8).set()
		UIRectFill(bounds)
	}
}

class UniversalMatchViewFinishedMatchView : UIView {
	private var image:UIImage?
	private var imageView: UIImageView?
	private var renderQueue = dispatch_queue_create("com.zakariya.squizit.FinishedDrawingRenderQueue", nil)
	private var angle:CGFloat = 0

	override init(frame: CGRect) {
		super.init( frame: frame )
		commonInit()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
		commonInit()
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		if let imageView = imageView, image = image {

			imageView.transform = CGAffineTransformIdentity

			let padding:CGFloat = 40
			let minViewDim = min(bounds.width,bounds.height) - 2*padding
			let maxImageDim = max(image.size.width,image.size.height)
			let scale = minViewDim / maxImageDim
			let imageSize = image.size.scale(scale).integerSize

			imageView.image = image.imageByScalingToSize(imageSize, scale: 0)
			imageView.frame = CGRect(center: bounds.center, size: imageSize)
			imageView.transform = CGAffineTransformMakeRotation(angle)
		}
	}

	var match:Match? {
		didSet {
			render()
		}
	}

	private func commonInit() {
		backgroundColor = UIColor.clearColor()
		opaque = false

		let angleRange = drand48() * 2.0 - 1.0
		angle = CGFloat(3.0 * M_PI/180.0 * angleRange)
	}

	private func render() {
		if let match = match {
			dispatch_async(renderQueue) {

				self.image = match.render(SquizitTheme.paperBackgroundColor(0), scale: 0, watermark: false)
				dispatch_main {
					let imageView = UIImageView(frame: CGRect.zero)
					imageView.layer.shadowColor = UIColor.blackColor().CGColor
					imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
					imageView.layer.shadowOpacity = 1
					imageView.layer.shadowRadius = 5
					imageView.layer.shouldRasterize = true
					imageView.alpha = 0
					self.addSubview(imageView)

					imageView.image = self.image
					UIView.animateWithDuration(0.3) {
						imageView.alpha = 1
					}

					self.imageView = imageView
					self.setNeedsLayout()
				}
			}
		}
	}
}


class UniversalMatchViewController : UIViewController, SaveToGalleryDelegate {

	private var quitGameButton:GameControlButton!
	private var finishTurnButton:GameControlButton!
	private var drawingToolSelector:DrawingToolSelector!
	private var undoButton:SquizitGameTextButton!
	private var clearButton:SquizitGameTextButton!
	private var matchPresenterView:UniversalMatchViewPresenterView!
	private var matchView:UniversalMatchView!
	private var finishedMatchView:UniversalMatchViewFinishedMatchView?
	private var toolBackdropViewTop:UniversalMatchViewToolbarBackgroundView!
	private var toolBackdropViewBottom:UniversalMatchViewToolbarBackgroundView!
	private var finishTurnButtonOverlay:UIView!

	private var endOfMatchGestureRecognizer:UITapGestureRecognizer!
	private var exportQueue = dispatch_queue_create("com.zakariya.squizit.UniversalMatchViewController.ExportQueue", nil)

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
				showCompletedDrawing()
			} else {
				showSaveToGalleryDialog()
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
		title = NSLocalizedString("Match",comment:"MatchTitle")
		view.backgroundColor = SquizitTheme.matchBackgroundColor()

		quitGameButton = GameControlButton.quitGameButton()
		finishTurnButton = GameControlButton.finishTurnButton()

		finishTurnButtonOverlay = UIView(frame: CGRect.zero)
		finishTurnButtonOverlay.userInteractionEnabled = false
		finishTurnButtonOverlay.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "onFinishTurnOverlayTapped:"))

		drawingToolSelector = DrawingToolSelector(frame: CGRect.zero)
		drawingToolSelector.addTool("Pencil", icon: UIImage(named: "tool-pencil")!)
		drawingToolSelector.addTool("Brush", icon: UIImage(named: "tool-brush")!)
		drawingToolSelector.addTool("Eraser", icon: UIImage(named: "tool-eraser")!)
		drawingToolSelector.addTarget(self, action: "onDrawingToolSelected:", forControlEvents: .ValueChanged)
		drawingToolSelector.toolSeparation = isSmallScreen ? 8 : 20

		undoButton = SquizitGameTextButton.create(NSLocalizedString("Undo", comment:"UndoButtonTitle"), compact: isSmallScreen)
		undoButton.addTarget(self, action: "onUndo:", forControlEvents: .TouchUpInside)

		clearButton = SquizitGameTextButton.create(NSLocalizedString("Clear", comment:"ClearButtonTitle"), compact: isSmallScreen)
		clearButton.addTarget(self, action: "onClear:", forControlEvents: .TouchUpInside)

		matchPresenterView = UniversalMatchViewPresenterView(frame: CGRect.zero)


		assert(players == 2 || players == 3, "Number of players MUST be 2, or 3")
		let match = Match(players: players, stageSize: CGSize(width: 1024, height: 1024), overlap: 32)

		matchView = UniversalMatchView(frame: CGRect.zero)
		matchView.match = match
		matchView.turn = 0
		matchPresenterView.matchView = matchView
		matchPresenterView.onPanningChanged = self.onMatchPresenterViewPanningStateChanged
		view.addSubview(matchPresenterView)

		// build and install tool backdrop views - they're only visible when matchPresenterView is in panning mode
		toolBackdropViewTop = UniversalMatchViewToolbarBackgroundView(frame:CGRect.zero)
		toolBackdropViewBottom = UniversalMatchViewToolbarBackgroundView(frame:CGRect.zero)
		view.addSubview(toolBackdropViewTop!)
		view.addSubview(toolBackdropViewBottom!)

		toolBackdropViewTop!.alpha = 0
		toolBackdropViewTop!.hidden = true
		toolBackdropViewBottom!.alpha = 0
		toolBackdropViewBottom!.hidden = true

		view.addSubview(clearButton)
		view.addSubview(undoButton)
		view.addSubview(drawingToolSelector)
		view.addSubview(finishTurnButton)
		view.addSubview(finishTurnButtonOverlay)
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

		// for testing, enable dirty rect tracking
		matchView.showDirtyRectUpdates = false
		matchView.useExperimentalResolutionIndependantRenderPipeline = false
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		setNeedsStatusBarAppearanceUpdate()
	}

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

	override func viewWillLayoutSubviews() {

		let layoutRect = CGRect(x: 0, y: topLayoutGuide.length, width: view.bounds.width, height: view.bounds.height - (topLayoutGuide.length+bottomLayoutGuide.length))
		let toolScale:CGFloat = isSmallScreen ? 0.8 : 1.0
		let drawingToolSize = drawingToolSelector.intrinsicContentSize().scale(toolScale)
		let buttonSize = quitGameButton.intrinsicContentSize().height * toolScale
		let margin = CGFloat(traitCollection.horizontalSizeClass == .Compact ? 16 : 20)
		let textButtonWidth = max(undoButton.intrinsicContentSize().width,clearButton.intrinsicContentSize().width)

		// match presenter always gets full bounds, but has edge insets set below
		matchPresenterView.frame = view.bounds

		if layoutRect.width < layoutRect.height {

			//
			// portrait layout, put tools on bottom
			//

			quitGameButton.frame = CGRect(x: margin, y: layoutRect.minY + margin, width: buttonSize, height: buttonSize)
			finishTurnButton.frame = CGRect(x: layoutRect.maxX - margin - buttonSize, y: layoutRect.minY + margin, width: buttonSize, height: buttonSize)

			undoButton.frame = CGRect(x: layoutRect.midX - textButtonWidth - margin/2, y: layoutRect.minY + margin, width: textButtonWidth, height: buttonSize)
			clearButton.frame = CGRect(x: layoutRect.midX + margin/2, y: layoutRect.minY + margin, width: textButtonWidth, height: buttonSize)

			drawingToolSelector.frame = CGRect(x: round(layoutRect.midX - drawingToolSize.width/2), y: round(layoutRect.maxY - drawingToolSize.height - margin), width: drawingToolSize.width, height: drawingToolSize.height)

			matchPresenterView.insets = UIEdgeInsets(top: buttonSize + 2*margin, left: margin, bottom: drawingToolSize.height + 2*margin, right: margin)


			let toolBackdropViewTopHeight = max(quitGameButton.frame.maxY,finishTurnButton.frame.maxY,undoButton.frame.maxY,clearButton.frame.maxY) + margin
			toolBackdropViewTop.frame = CGRect(x: 0, y: layoutRect.minY, width: layoutRect.width, height: toolBackdropViewTopHeight)

			let toolBackdropViewBottomHeight = layoutRect.maxY - drawingToolSelector.frame.minY + margin
			toolBackdropViewBottom.frame = CGRect(x: 0, y: layoutRect.maxY - toolBackdropViewBottomHeight, width: layoutRect.width, height: toolBackdropViewBottomHeight + margin)

		} else {

			//
			// landscape layout, put all tools across top
			//

			quitGameButton.frame = CGRect(x: margin, y: layoutRect.minY + margin, width: buttonSize, height: buttonSize)
			finishTurnButton.frame = CGRect(x: layoutRect.maxX - margin - buttonSize, y: layoutRect.minY + margin, width: buttonSize, height: buttonSize)
			drawingToolSelector.frame = CGRect(x: round(layoutRect.midX - drawingToolSize.width/2), y: margin, width: drawingToolSize.width, height: drawingToolSize.height)

			// undo button goes between quit button right edge and the drawingToolSelector left edge
			undoButton.frame = CGRect(x: round((quitGameButton.frame.maxX + drawingToolSelector.frame.minX)/2 - textButtonWidth/2),
				y: margin, width: textButtonWidth, height: buttonSize)

			clearButton.frame = CGRect(x: round((drawingToolSelector.frame.maxX + finishTurnButton.frame.minX)/2 - textButtonWidth/2),
				y: margin, width: textButtonWidth, height: buttonSize)

			matchPresenterView.insets = UIEdgeInsets(top: drawingToolSize.height + 2*margin, left: margin, bottom: margin, right: margin)

			toolBackdropViewTop.frame = CGRect(x: 0, y: 0, width: layoutRect.width, height: drawingToolSize.height + 2*margin)
			toolBackdropViewBottom.frame = CGRect(x:0, y:layoutRect.maxY, width:layoutRect.width, height:0) // hide off bottom of screen
		}

		if let finishedDrawingView = finishedMatchView {
			finishedDrawingView.frame = layoutRect
		}

		// the finish turn overlay tracks the position of the finish turn button - but it's only enabled when finish turn button is disabled
		finishTurnButtonOverlay.frame = finishTurnButton.frame
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

	lazy var isSmallScreen:Bool = {
		return min(self.view.frame.width,self.view.frame.height) <= 320
	}()

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
		finishTurnButtonOverlay.userInteractionEnabled = !finishTurnButton.enabled

		let canUndo = playerCanUndo
		undoButton.enabled = canUndo
		clearButton.enabled = canUndo
	}

	private func updateToolBackdropViews(panning:Bool) {
		if panning {
			toolBackdropViewTop.hidden = false
			toolBackdropViewBottom.hidden = false
			UIView.animateWithDuration(0.3) {
				self.toolBackdropViewTop.alpha = 1
				self.toolBackdropViewBottom.alpha = 1
			}

		} else {

			UIView.animateWithDuration(0.3, animations: {
				self.toolBackdropViewTop.alpha = 0
				self.toolBackdropViewBottom.alpha = 0
			}, completion: { complete in
				self.toolBackdropViewTop.hidden = true
				self.toolBackdropViewBottom.hidden = true
			})
		}
	}

	private func showCompletedDrawing() {
		UIView.animateWithDuration(0.3,
			animations: {
				self.toolBackdropViewTop.alpha = 0
				self.toolBackdropViewBottom.alpha = 0
				self.matchPresenterView.alpha = 0
				self.quitGameButton.alpha = 0
				self.clearButton.alpha = 0
				self.undoButton.alpha = 0
				self.finishTurnButton.alpha = 0
				self.drawingToolSelector.alpha = 0
			},
			completion: { completed in
				self.toolBackdropViewTop.hidden = true
				self.toolBackdropViewBottom.hidden = true
				self.matchPresenterView.hidden = true
				self.quitGameButton.hidden = true
				self.clearButton.hidden = true
				self.undoButton.hidden = true
				self.finishTurnButton.hidden = true
				self.drawingToolSelector.hidden = true
			})

		finishedMatchView = UniversalMatchViewFinishedMatchView(frame: CGRect.zero)
		finishedMatchView!.match = match
		view.addSubview(finishedMatchView!)
	}

	// MARK: - Notifications

	dynamic private func onDrawingDidChange() {
		updateUi()
	}

	dynamic private func onTurnDidChange() {
		matchPresenterView.setPanning(false, animated: false)
		updateUi()
	}

	// MARK: - Actions

	dynamic private func onMatchPresenterViewPanningStateChanged(panning:Bool) {
		updateToolBackdropViews(panning)
	}

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

	private dynamic func onFinishTurnOverlayTapped(tgr:UITapGestureRecognizer) {
		let acStyle = traitCollection.horizontalSizeClass == .Regular && traitCollection.verticalSizeClass == .Regular
			? UIAlertControllerStyle.ActionSheet
			: UIAlertControllerStyle.Alert

		let ac = UIAlertController(
			title: NSLocalizedString("Finish Turn?", comment:"FinishMatchTurnAlertTitle"),
			message: NSLocalizedString("Your drawing doesn't overlap the fold", comment:"FinishMatchTurnAlertMessage"),
			preferredStyle: acStyle)

		ac.view.tintColor = SquizitTheme.alertTintColor()

		ac.popoverPresentationController?.sourceView = finishTurnButtonOverlay
		ac.popoverPresentationController?.sourceRect = finishTurnButtonOverlay.bounds

		ac.addAction(UIAlertAction(title: "Nevermind", style: UIAlertActionStyle.Cancel, handler: nil))
		ac.addAction(UIAlertAction(title: "Finish", style: UIAlertActionStyle.Default, handler: { action in
			self.stepForward()
		}))

		presentViewController(ac, animated: true, completion: nil)
	}

	private dynamic func onQuitTapped(sender:AnyObject) {
		showQuitMatchDialog()
	}

	// MARK: - Dialogs

	private dynamic func showSaveToGalleryDialog() {
		performSegueWithIdentifier("showSaveToGallery", sender: self)
	}

	private dynamic func showQuitMatchDialog() {
		let ac = UIAlertController(
			title: NSLocalizedString("Quit?", comment:"QuitMatchAlertTitle"),
			message: NSLocalizedString("Are you certain you'd like to quit this match?", comment:"QuitMatchAlertMessage"),
			preferredStyle: UIAlertControllerStyle.Alert)

		ac.view.tintColor = SquizitTheme.alertTintColor()

		ac.addAction(UIAlertAction(
			title: NSLocalizedString("Continue", comment:"QuitMatchAlertButtonCancelTitle"),
			style: UIAlertActionStyle.Cancel,
			handler: nil))

		ac.addAction(UIAlertAction(
			title: NSLocalizedString("Quit", comment:"QuitMatchAlertButtonQuitTitle"),
			style: UIAlertActionStyle.Destructive,
			handler: { [weak self] action in
				self?.dismissViewControllerAnimated(true, completion: nil)
			}))

		presentViewController(ac, animated: true, completion: nil)
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
			var rendering = match.render( nil, scale: UIScreen.mainScreen().scale )

			#if DEBUG
				self.DEBUG_saveImage(rendering, name: "drawing.png")
			#endif

			let thumbnailSize = CGSize( width: rendering.size.width/2, height: rendering.size.height/2 )
			rendering = rendering.imageByScalingToSize(thumbnailSize)

			#if DEBUG
				self.DEBUG_saveImage(rendering, name: "drawing-thumbnail.png")
			#endif

			let thumbnailData:NSData? = UIImagePNGRepresentation(rendering)

			dispatch_main {
				done( matchData: matchDataResult.value, thumbnailSize:thumbnailSize, thumbnailData: thumbnailData )
			}
		}
	}

	private func DEBUG_saveImage( image:UIImage, name:String ) {
		guard let folderURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last else {
			fatalError("UniversalMatchViewController::DEBUG_saveImage - unable to get documents folder URL");
		}

		let targetURL = folderURL.URLByAppendingPathComponent(name, isDirectory: false)
		NSLog("UniversalMatchViewController::DEBUG_saveImage - saving: \(targetURL)")

		guard let pngRep = UIImagePNGRepresentation(image) else {
			fatalError("UniversalMatchViewController::DEBUG_saveImage - unable to encode image as PNG");
		}

		pngRep.writeToURL(targetURL, atomically: true)
	}

}