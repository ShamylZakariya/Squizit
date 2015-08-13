//
//  DrawingTestsViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/8/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class DrawingTestsViewController : UIViewController {

	var quitGameButton:GameControlButton!
	var finishTurnButton:GameControlButton!
	var drawingToolSelector:DrawingToolSelector!
	var undoButton:SquizitGameTextButton!
	var clearButton:SquizitGameTextButton!
	var drawingContainerView:ScalingMatchViewContainerView!
	var matchView:NewMatchView!

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

		drawingContainerView = ScalingMatchViewContainerView(frame: CGRect.zeroRect)


		let match = Match(players: 3, stageSize: CGSize(width: 1024, height: 1024), overlap: 32)

		matchView = NewMatchView(frame: CGRect.zeroRect)
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
		ns.addObserver(self, selector: "onDrawingDidChange", name: NewMatchView.Notifications.DrawingDidChange, object: matchView)
		ns.addObserver(self, selector: "onTurnDidChange", name: NewMatchView.Notifications.TurnDidChange, object: matchView)

		// go default
		onDrawingDidChange()
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
		matchView.turn++
	}

	private dynamic func onQuitTapped(sender:AnyObject) {
		presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
	}

}