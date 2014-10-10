//
//  HowToPlayViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 10/7/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit

extension UIView {

	// from http://stackoverflow.com/questions/1968017/changing-my-calayers-anchorpoint-moves-the-view
	func setAnchorPoint( newAnchorPoint:CGPoint ) {
		var newPoint:CGPoint = CGPoint(x: bounds.size.width * newAnchorPoint.x, y: bounds.size.height * newAnchorPoint.y)
		var oldPoint:CGPoint = CGPoint(x: bounds.size.width * layer.anchorPoint.x, y:bounds.size.height * layer.anchorPoint.y)

		newPoint = CGPointApplyAffineTransform(newPoint, transform)
		oldPoint = CGPointApplyAffineTransform(oldPoint, transform)

		var position = layer.position

		position.x -= oldPoint.x
		position.x += newPoint.x

		position.y -= oldPoint.y
		position.y += newPoint.y

		layer.position = position
		layer.anchorPoint = newAnchorPoint
	}

}

class InstructionDrawingView : UIView {

	var image:UIImage? {
		didSet {
			transition()
		}
	}

	private var _currentImageView:UIImageView?
	private var _incomingImageView:UIImageView?

	override func layoutSubviews() {
		super.layoutSubviews()
		if let civ = _currentImageView {
			civ.frame = bounds
		}

		if let iiv = _incomingImageView {
			iiv.frame = bounds
		}
	}

	override var contentMode:UIViewContentMode {
		didSet {
			if let civ = _currentImageView {
				civ.contentMode = contentMode
			}

			if let iiv = _incomingImageView {
				iiv.contentMode = contentMode
			}
		}
	}

	private func transition() {
		if let image = self.image {
			if let civ = _currentImageView {
				// we need to fade in _incomingImageView
				_incomingImageView = UIImageView(image: image)
				_incomingImageView!.contentMode = contentMode
				_incomingImageView!.alpha = 0
				addSubview(_incomingImageView!)
				UIView.animateWithDuration(0.3, animations: { [unowned self] in
					self._incomingImageView!.alpha = 1
					civ.alpha = 0
				}, completion: { [unowned self] completed in
					civ.removeFromSuperview()
					self._currentImageView = self._incomingImageView
					self._incomingImageView = nil
				})
			} else {
				// first-time showing
				_currentImageView = UIImageView(image: image)
				_currentImageView!.contentMode = contentMode
				_currentImageView!.alpha = 0
				addSubview(_currentImageView!)
				UIView.animateWithDuration(0.3, animations: { [unowned self] in
					self._currentImageView!.alpha = 1
				})
			}
		} else {
			if let civ = _currentImageView {
				UIView.animateWithDuration(0.3, animations: { [unowned self] in
					civ.alpha = 0
				}, completion: { [unowned self] completed in
					civ.removeFromSuperview()
					self._currentImageView = nil
				})
			}
		}
	}
}


class HowToPlayViewController: UIViewController {

	@IBOutlet weak var instructionsDrawingsHolder: UIView!
	@IBOutlet weak var instructionsDrawingViewTop: InstructionDrawingView!
	@IBOutlet weak var instructionsDrawingViewBottom: InstructionDrawingView!
	@IBOutlet weak var instructionsText1ImageView: UIImageView!
	@IBOutlet weak var instructionsText2: UILabel!
	@IBOutlet weak var instructionsText3: UILabel!

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = SquizitTheme.howToPlayBackgroundColor()

		instructionsDrawingsHolder.clipsToBounds = false
		instructionsDrawingViewTop.backgroundColor = SquizitTheme.paperBackgroundColor()
		instructionsDrawingViewBottom.backgroundColor = SquizitTheme.paperBackgroundColor()

		for v in [instructionsDrawingsHolder,instructionsText1ImageView,instructionsText2,instructionsText3] {
			v.userInteractionEnabled = false
		}

		// set up appearance of instructions text
		let instructionFont = UIFont(name:"Avenir-Black", size: 16)
		for l in [instructionsText2,instructionsText3] {
			l.font = instructionFont
			l.textColor = UIColor.whiteColor()
		}

		// set up initial transforms & alphas of views
		instructionsDrawingViewTop.layer.transform = CATransform3DIdentity
		instructionsDrawingViewBottom.layer.transform = CATransform3DIdentity
		instructionsDrawingViewTop.image = nil
		instructionsDrawingViewBottom.image = nil

		for v in [instructionsText1ImageView,instructionsText2,instructionsText3] {
			v.alpha = 0
		}

		instructionsDrawingsHolder.transform = CGAffineTransformMakeScale(1.1, 1.1)
		instructionsDrawingsHolder.alpha = 0

		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapped:"))
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		showEmptyPaper()
	}

	// MARK: Internal

	enum InstructionStep {
		case EmptyPaper
		case ShowTopHalf
		case ShowTopDrawing
		case ShowBottomHalfWithGuide
		case ShowBottomDrawing
		case ShowFinalDrawing
	}

	var step:InstructionStep = .EmptyPaper {
		didSet {
			switch step {
				case .EmptyPaper: showEmptyPaper()
				case .ShowTopHalf: showTopHalf()
				case .ShowTopDrawing: showTopHalfWithDrawing()
				case .ShowBottomHalfWithGuide: showBottomHalfWithGuide()
				case .ShowBottomDrawing: showBottomHalfWithDrawing()
				case .ShowFinalDrawing: showFinalDrawing()
			}
		}
	}

	func forward() {
		switch step {
			case .EmptyPaper: step = .ShowTopHalf
			case .ShowTopHalf: step = .ShowTopDrawing
			case .ShowTopDrawing: step = .ShowBottomHalfWithGuide
			case .ShowBottomHalfWithGuide: step = .ShowBottomDrawing
			case .ShowBottomDrawing: step = .ShowFinalDrawing
			case .ShowFinalDrawing: finished();
		}
	}

	dynamic func tapped(tgr:UITapGestureRecognizer) {
		forward()
	}

	let zDistance:CGFloat = -500

	func showEmptyPaper() {
		println("showEmptyPaper")

		UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions(0), animations: { () -> Void in
			self.instructionsDrawingsHolder.transform = CGAffineTransformIdentity
			self.instructionsDrawingsHolder.alpha = 1
		}) { [unowned self] completed in
			delay(0.5) {
				self.forward()
			}
		}
	}

	func showTopHalf() {
		println("showTopHalf")

		// fold bottom half behind top half
		instructionsDrawingViewTop.setAnchorPoint(CGPoint( x:0.5, y: 1 ))
		instructionsDrawingViewBottom.setAnchorPoint(CGPoint( x:0.5, y: 0 ))

		UIView.animateWithDuration(0.5, animations: { [unowned self] in
			self.instructionsText1ImageView.alpha = 1

			var trans = CATransform3DIdentity
			trans.m34 = 1 / self.zDistance
			trans = CATransform3DRotate(trans, CGFloat(-M_PI * 0.99), 1, 0, 0)
			self.instructionsDrawingViewBottom.layer.transform = trans
		})
	}

	func showTopHalfWithDrawing() {
		println("showTopHalfWithDrawing")
		instructionsDrawingViewTop.image = UIImage(named:"instructions-drawing-top")

		UIView.animateWithDuration(0.5, animations: { [unowned self] in
			self.instructionsText1ImageView.alpha = 0
			self.instructionsText2.alpha = 1
		})
	}

	func showBottomHalfWithGuide() {
		println("showBottomHalfWithGuide")

		// unfold bottom half, and when complete, fold top half behind bottom half
		self.instructionsDrawingViewBottom.image = UIImage(named:"instructions-drawing-bottom-guide")
		self.instructionsDrawingViewBottom.contentMode = .Top

		UIView.animateWithDuration(0.5, animations: { [unowned self] in
			self.instructionsText2.alpha = 0
			self.instructionsText3.alpha = 1
			self.instructionsDrawingViewBottom.layer.transform = CATransform3DIdentity
		}) { [unowned self] completed in

			self.instructionsDrawingsHolder.sendSubviewToBack(self.instructionsDrawingViewTop)

			UIView.animateWithDuration(0.5, animations: { () -> Void in
				var trans = CATransform3DIdentity
				trans.m34 = 1 / self.zDistance

				trans = CATransform3DRotate(trans, CGFloat(M_PI * 0.99), 1, 0, 0)
				self.instructionsDrawingViewTop.layer.transform = trans

			})
		}
	}

	func showBottomHalfWithDrawing() {
		println("showBottomHalfWithDrawing")

		// unfold bottom half, and when complete, fold top half behind bottom half
		self.instructionsDrawingViewBottom.image = UIImage(named:"instructions-drawing-bottom")
		self.instructionsDrawingViewBottom.contentMode = .Center

		UIView.animateWithDuration(0.5, animations: { [unowned self] in
			self.instructionsText3.alpha = 0
		})
	}

	func showFinalDrawing() {
		println("showFinalDrawing")
		UIView.animateWithDuration(0.5, animations: { [unowned self] in
			self.instructionsDrawingViewTop.layer.transform = CATransform3DIdentity
		})
	}

	func finished() {
		println("finished")
		dismissViewControllerAnimated(true, completion: nil)
	}

}
