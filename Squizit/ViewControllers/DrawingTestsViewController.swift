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

		matchView = NewMatchView(frame: CGRect.zeroRect)
		matchView.turn = (1,3)
		drawingContainerView.drawingView = matchView

		let controller = DrawingInputController()
		controller.drawing = Drawing()
		controller.view = matchView
		controller.viewport = CGRect(x: 0, y: 0, width: 1024, height: 512)
		controller.fill = Fill.Brush
		matchView.controller = controller


		view.addSubview(drawingContainerView)
		view.addSubview(clearButton)
		view.addSubview(undoButton)
		view.addSubview(drawingToolSelector)
		view.addSubview(finishTurnButton)
		view.addSubview(quitGameButton)




		drawingToolSelector.selectedToolIndex = 0
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

			matchView.controller!.fill = fill
		}
	}

	dynamic private func onUndo( sender:AnyObject ) {
		matchView.controller!.undo()
	}

	dynamic private func onClear( sender:AnyObject ) {
		drawingView.drawing!.clear()
		matchView.setNeedsDisplay()
	}

	dynamic private func onToggleDebugRendering( sender:AnyObject ) {
		drawingView.drawing!.debugRender = !drawingView.drawing!.debugRender
		matchView.setNeedsDisplay()
	}

}