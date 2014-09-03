//
//  Themes.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/21/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit


class SquizitTheme {

	init() {

		let navAppearance = UINavigationBar.appearance()
		navAppearance.barStyle = UIBarStyle.Black
		navAppearance.translucent = true
		navAppearance.titleTextAttributes = [
			NSFontAttributeName: UIFont(name: "Baskerville-Bold", size: 21),
			NSForegroundColorAttributeName: UIColor.whiteColor()
		]

		let bbiAppearance = UIBarButtonItem.appearance()
		bbiAppearance.setTitleTextAttributes([
			NSFontAttributeName: UIFont(name: "Baskerville", size: 18),
		], forState: UIControlState.Normal)

	}

	class func cubeBackgroundImage() -> UIImage {
		return UIImage(named: "cube-pattern")
	}

	class func leatherBackgroundImage() -> UIImage {
		return UIImage(named: "leather-pattern")
	}

	class func paperBackgroundImage() -> UIImage {
		return UIImage(named: "paper-pattern")
	}

	class func thumbnailPaperBackgroundImage() -> UIImage {
		return UIImage(named: "thumbnail-paper-pattern")
	}

	class func rootScreenBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.cubeBackgroundImage() )
	}

	class func paperBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.paperBackgroundImage() )
	}

	class func matchBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.leatherBackgroundImage() )
	}

	class func matchShieldBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.leatherBackgroundImage() )
	}

	class func galleryBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.leatherBackgroundImage() )
	}

	class func thumbnailBackgroundColor() -> UIColor {
		return UIColor( patternImage: self.thumbnailPaperBackgroundImage() )
	}

	class func tintColor() -> UIColor {
		return UIColor.whiteColor()
	}

	class func dialogBackgroundColor() -> UIColor {
		return UIColor(white: 0.137, alpha: 1)
	}

}

class SquizitThemeButton : UIButton {

	// if a button is destructive, its label text will be a reddish/fuscia-ish color - otherwise it will be the current tintColor
	var destructive:Bool = false {
		didSet {
			self.tintColor = destructive ? UIColor(red: 1, green: 0.27, blue: 0.47, alpha: 1) : nil
		}
	}

	override func setTitle(title: String!, forState state: UIControlState) {
		super.setTitle(title.uppercaseString, forState: state)
	}

	override func didMoveToSuperview() {
		super.didMoveToSuperview()
		update()
	}

	override func didMoveToWindow() {
		super.didMoveToWindow()
		update()
	}

	override var enabled:Bool {
		didSet {
			update()
		}
	}

	override func tintColorDidChange() {
		super.tintColorDidChange()
		update()
	}

	private func update() {
		titleLabel!.font = UIFont(name: "Avenir-Light", size: UIFont.buttonFontSize())
		layer.cornerRadius = 0
		layer.borderWidth = 1
		layer.backgroundColor = UIColor(white: 0.19, alpha: 0.2).CGColor
		layer.borderColor = self.tintColor!.colorWithAlphaComponent(0.2).CGColor
	}

	override func intrinsicContentSize() -> CGSize {
		return CGSize(width: UIViewNoIntrinsicMetric, height: 65)
	}

}

class SquizitThemeNameInputField : UITextField {

	@IBOutlet var nextField:SquizitThemeNameInputField?

	override func drawRect(rect: CGRect) {
		super.drawRect(rect)

		let bounds = self.bounds
		self.tintColor.colorWithAlphaComponent(0.2).set()
		UIBezierPath(rect: CGRect(x: 0, y: bounds.height - 1, width: bounds.width, height: 1)).fill()
	}

	override func awakeFromNib() {
		applyTheme()
	}

	override func tintColorDidChange() {
		super.tintColorDidChange()
		applyTheme()
	}

	override func intrinsicContentSize() -> CGSize {
		return CGSize(width: UIViewNoIntrinsicMetric, height: 29)
	}

	private func applyTheme() {
		self.layer.cornerRadius = 0
		background = nil
		backgroundColor = UIColor.clearColor()
		opaque = false
		borderStyle = UITextBorderStyle.None
		textColor = tintColor
		font = UIFont(name: "Baskerville-Italic", size: UIFont.labelFontSize() )
		textAlignment = NSTextAlignment.Center

		attributedPlaceholder = NSAttributedString(string: placeholder!, attributes: [
			NSForegroundColorAttributeName: tintColor.colorWithAlphaComponent(0.5)
		])
	}


}