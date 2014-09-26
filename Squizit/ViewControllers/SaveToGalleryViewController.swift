//
//  SaveToGalleryViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/26/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

protocol SaveToGalleryDelegate : class {

	// invoked when user dismisses the save dialog without saving
	func didDismissSaveToGallery()

	// invoked when user wants to save, passing array of names if user wanted to mark down player names, or nil otherwise
	func didSaveToGalleryWithNames( names:[String]? )

}

class SaveToGalleryViewController : UIViewController, UITextFieldDelegate {



	@IBOutlet weak var dialogView: UIView!
	@IBOutlet weak var questionLabel: UILabel!
	@IBOutlet weak var playerOneNameInputField: SquizitThemeNameInputField!
	@IBOutlet weak var playerTwoNameInputField: SquizitThemeNameInputField!
	@IBOutlet weak var playerThreeNameInputField: SquizitThemeNameInputField!
	@IBOutlet weak var addToGalleryButton: SquizitThemeButton!
	@IBOutlet weak var discardButton: SquizitThemeButton!

	// layout constraints for dynamic sizing

	@IBOutlet weak var topMarginConstraint: NSLayoutConstraint!
	@IBOutlet weak var titleHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var sideMarginConstraint: NSLayoutConstraint!
	@IBOutlet weak var buttonHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var buttonSpacingConstraint: NSLayoutConstraint!
	@IBOutlet weak var bottomMarginConstraint: NSLayoutConstraint!
	@IBOutlet weak var dialogHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var dialogWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var dialogVerticalCenteringConstraint: NSLayoutConstraint!

	weak var delegate:SaveToGalleryDelegate?

	var nameCount:Int = 3 {
		didSet {
			if nameCount < 2 || nameCount > 3 {
				assertionFailure("SaveTogalleryViewController only supports 2 or 3 player names")
			}
		}
	}

	// MARK: UIViewController Overrides

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		dialogView.opaque = false
		dialogView.backgroundColor = SquizitTheme.dialogBackgroundColor()

		discardButton.destructive = true
		questionLabel.font = UIFont(name: "Baskerville-Italic", size: UIFont.labelFontSize())

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
	}

	private var _visible:Bool = false
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		_visible = true

		switch nameCount {
			case 2:
				playerOneNameInputField.nextField = playerTwoNameInputField
				playerTwoNameInputField.nextField = playerOneNameInputField
				playerThreeNameInputField.hidden = true

			case 3:
				playerOneNameInputField.nextField = playerTwoNameInputField
				playerTwoNameInputField.nextField = playerThreeNameInputField
				playerThreeNameInputField.nextField = playerOneNameInputField
				playerThreeNameInputField.hidden = false

			default:
				break;
		}

		switch( traitCollection.userInterfaceIdiom ) {
			case .Phone:
				topMarginConstraint.constant = 16
				titleHeightConstraint.constant = 32
				buttonHeightConstraint.constant = 33
				sideMarginConstraint.constant = 8
				buttonSpacingConstraint.constant = 8
				bottomMarginConstraint.constant = 8

			default:
				buttonHeightConstraint.constant = 65
		}

	}

	private var _didAddMotionEffect:Bool = false

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		if !_didAddMotionEffect {
			_didAddMotionEffect = true
			addParallaxEffect()
		}
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		layout()
	}

	// MARK: IBActions

	@IBAction func addToGallery(sender: AnyObject) {

		// collect names
		var names:[String] = []
		var namesEnteredByUser = 0

		var fields:[UITextField] = []
		switch nameCount {
			case 2:	fields = [playerOneNameInputField,playerTwoNameInputField]
			case 3:	fields = [playerOneNameInputField,playerTwoNameInputField,playerThreeNameInputField]
			default: break;
		}

		for nameField in fields {
			var name = sanitize(nameField.text)
			if countElements(name) == 0 {
				name = NSLocalizedString("Anonymous", comment: "AnonymousPlayerIdentifier")
			} else {
				namesEnteredByUser++
			}

			names.append( name )
		}

		delegate?.didSaveToGalleryWithNames( namesEnteredByUser > 0 ? names : nil )
	}

	@IBAction func discard(sender: AnyObject) {
		delegate?.didDismissSaveToGallery()
	}

	// MARK: Keyboard Handling

	dynamic private func keyboardWillShow( note:NSNotification ) {
		if let info:Dictionary = note.userInfo {
			if let keyboardRect = info[UIKeyboardFrameEndUserInfoKey]?.CGRectValue() {
				keyboardHeight = keyboardRect.height
			}
		}
	}

	dynamic private func keyboardWillHide( note:NSNotification ) {
		keyboardHeight = 0
	}

	private var keyboardHeight:CGFloat = 0 {
		didSet {
			animateLayout()
		}
	}

	// MARK: UITextFieldDelegate

	func textFieldShouldEndEditing(textField: UITextField!) -> Bool {
		textField.text = sanitize(textField.text)
		return true
	}

	func textFieldShouldReturn(textField: UITextField!) -> Bool {

		if let tf = textField as? SquizitThemeNameInputField {
			tf.nextField?.becomeFirstResponder()
		} else {
			textField.resignFirstResponder()
		}

		return true
	}

	// MARK: Private

	private func sanitize( name:String ) -> String {
		return name.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()).capitalizedStringWithLocale(NSLocale.currentLocale())
	}

	private func animateLayout() {
		if _visible {
			UIView.animateWithDuration(0.7,
				delay: 0,
				usingSpringWithDamping: 0.7,
				initialSpringVelocity: 0.0,
				options: UIViewAnimationOptions(0),
				animations: { () -> Void in
					self.layout()
				},
				completion: nil)
		} else {
			layout()
		}
	}

	private func layout() {
		let dialogSize = self.dialogSize
		dialogHeightConstraint.constant = dialogSize.height
		dialogWidthConstraint.constant = dialogSize.width

		if keyboardHeight > 0 {
			let totalHeight = view.bounds.height
			let offset = (totalHeight - keyboardHeight)/2 - dialogSize.height/2
			dialogVerticalCenteringConstraint.constant = offset
		} else {
			dialogVerticalCenteringConstraint.constant = 0
		}
	}

	private var dialogSize:CGSize {

		view.layoutIfNeeded()
		var topHeight:CGFloat = 0
		switch nameCount {
			case 2: topHeight = playerTwoNameInputField.frame.maxY
			case 3: topHeight = playerThreeNameInputField.frame.maxY
			default: return CGSizeZero
		}

		let bottomHeight = dialogView.bounds.height - addToGalleryButton.frame.minY
		let padding:CGFloat = buttonSpacingConstraint.constant

		return CGSize( width: 300, height: topHeight + padding + bottomHeight )
	}

	private func addParallaxEffect() {
		var horizontal = UIInterpolatingMotionEffect(keyPath: "center.x", type: UIInterpolatingMotionEffectType.TiltAlongHorizontalAxis)
		horizontal.minimumRelativeValue = -15
		horizontal.maximumRelativeValue = 15

		var vertical = UIInterpolatingMotionEffect(keyPath: "center.y", type: UIInterpolatingMotionEffectType.TiltAlongVerticalAxis)
		vertical.minimumRelativeValue = -15
		vertical.maximumRelativeValue = 15

		var effect = UIMotionEffectGroup()
		effect.motionEffects = [horizontal, vertical]
		dialogView.addMotionEffect(effect)
	}
}