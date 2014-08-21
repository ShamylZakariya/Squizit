//
//  DrawingToolSelector.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/20/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

/**
	Emits UIControlEvents.ValueChanged when selectedToolIndex changes
*/
class DrawingToolSelector : UIControl {

	enum Orientation {
		case Vertical
		case Horizontal
	}

	private var _tiles:[UIView] = []

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
	}

	var margin:CGFloat = 10 {
		didSet {
			setNeedsLayout()
		}
	}

	var buttonSize:CGFloat = 44 {
		didSet {
			setNeedsLayout()
		}
	}

	var orientation:Orientation = .Vertical {
		didSet {
			setNeedsLayout()
		}
	}

	var selectedToolIndex:Int? {
		didSet {
			selectedToolIndexDidChange()
		}
	}

	func addTool( name:String, icon:UIImage ) {

		var tile = UIImageView(frame: CGRectZero)
		tile.image = icon.imageWithRenderingMode(.AlwaysTemplate)
		tile.userInteractionEnabled = true
		tile.multipleTouchEnabled = false

		var tgr = UITapGestureRecognizer(target: self, action: "tileTapped:")
		tgr.numberOfTapsRequired = 1
		tile.addGestureRecognizer(tgr)

		addSubview(tile)
		_tiles.append(tile)

		setNeedsLayout()
	}

	// MARK: UIView/Control Overrides

	override func layoutSubviews() {
		if _tiles.isEmpty {
			return
		}

		switch orientation {
			case .Vertical:
				layoutVertical()

			case .Horizontal:
				layoutHorizontal()
		}

		// cause tile's layer to appear circular when a background color is applied
		for tile in _tiles {
			tile.layer.cornerRadius = min( tile.bounds.width, tile.bounds.height ) / 2
		}
	}

	override func tintColorDidChange() {
		updateTileAppearance()
	}

	override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
		for tile in _tiles {
			if tile.frame.contains(point) {
				return true
			}
		}

		return false
	}

	// MARK: Private

	func layoutVertical() {
		let size = buttonSize
		let height = self.bounds.height
		let contentHeight = CGFloat(_tiles.count) * size + (CGFloat(_tiles.count) - 1.0) * margin;
		var x = bounds.width / 2 - size/2
		var y = height/2 - contentHeight/2

		for button in _tiles {
			button.frame = CGRectIntegral(CGRect(x: x, y: y, width: size, height: size))
			y += margin + size
		}
	}

	func layoutHorizontal() {
		let size = buttonSize
		let width = self.bounds.width
		let contentWidth = CGFloat(_tiles.count) * size + (CGFloat(_tiles.count) - 1.0) * margin;
		var x = width/2 - contentWidth/2
		var y = bounds.height/2 - size/2

		for button in _tiles {
			button.frame = CGRectIntegral(CGRect(x: x, y: y, width: size, height: size))
			x += margin + size
		}
	}

	func tileTapped( tgr:UITapGestureRecognizer ) {

		for (i,tile) in enumerate(_tiles) {
			if tile == tgr.view {
				selectedToolIndex = i
				return
			}
		}

		// this shouldn't happen...
		selectedToolIndex = nil
	}

	func selectedToolIndexDidChange() {
		updateTileAppearance()
		sendActionsForControlEvents( UIControlEvents.ValueChanged )
	}

	func updateTileAppearance() {
		if let idx = selectedToolIndex {
			for (i,tile) in enumerate(_tiles) {
				setTileHighlighted(tile, highlighted: i == idx)
			}
		} else {
			for tile in _tiles {
				setTileHighlighted(tile, highlighted: false)
			}
		}
	}

	func setTileHighlighted( tile:UIView, highlighted:Bool ) {
		if highlighted {
			tile.layer.backgroundColor = tintColor.colorWithAlphaComponent(0.25).CGColor
		} else {
			tile.layer.backgroundColor = UIColor.clearColor().CGColor
		}
	}


}