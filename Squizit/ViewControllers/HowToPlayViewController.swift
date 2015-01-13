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
	@IBOutlet weak var nextButton: SquizitThemeButton!
	@IBOutlet weak var doneButton: SquizitThemeButton!

	var instructionsText1: SquizitThemeLabel!
	var instructionsText2: SquizitThemeLabel!
	var instructionsText3: SquizitThemeLabel!
	var instructionsText4: UILabel!
	var overlapHighlightView: UIView!

	var duration:NSTimeInterval = 0.5
	var instructionsDrawingHolderDefaultFrame:CGRect = CGRect.zeroRect

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = SquizitTheme.howToPlayBackgroundColor()

		instructionsDrawingsHolder.clipsToBounds = false
		instructionsDrawingViewTop.backgroundColor = SquizitTheme.paperBackgroundColor()
		instructionsDrawingViewBottom.backgroundColor = SquizitTheme.paperBackgroundColor()

		overlapHighlightView = UIView(frame: CGRect.zeroRect)
		overlapHighlightView.backgroundColor = UIColor.redColor().colorWithAlphaComponent(0.5)
		overlapHighlightView.opaque = false
		overlapHighlightView.alpha = 0
		overlapHighlightView.hidden = true
		view.addSubview(overlapHighlightView);

		instructionsText1 = SquizitThemeLabel(frame: CGRect.zeroRect)
		instructionsText2 = SquizitThemeLabel(frame: CGRect.zeroRect)
		instructionsText3 = SquizitThemeLabel(frame: CGRect.zeroRect)

		// set up appearance of instructions text
		let instructionFont = UIFont(name:"Avenir-Black", size: 18)
		for l in [instructionsText1,instructionsText2,instructionsText3] {
			view.insertSubview(l, atIndex: 0)

			l.label.font = instructionFont
			l.label.textColor = UIColor.whiteColor()
			l.label.textAlignment = .Center
			l.alpha = 0
		}

		instructionsText4 = UILabel(frame: CGRect.zeroRect)
		instructionsText4.font = UIFont(name:"Baskerville-Italic", size: 16)
		instructionsText4.textColor = UIColor.whiteColor()
		instructionsText4.textAlignment = .Center
		instructionsText4.numberOfLines = 0
		instructionsText4.lineBreakMode = .ByWordWrapping
		instructionsText4.alpha = 0
		view.insertSubview(instructionsText4, atIndex: 0)



		instructionsText1.label.text = NSLocalizedString("A piece of paper is folded over itself into halves or thirds", comment: "Instructions Text 1")
		instructionsText2.label.text = NSLocalizedString("The first player draws all the way to the bottom fold - leaving marks to guide the next player", comment: "Instructions Text 2")
		instructionsText3.label.text = NSLocalizedString("The next player completes the drawing,\nguided by the marks left at the top", comment: "Instructions Text 3")
		instructionsText4.text = NSLocalizedString("And we have an Exquisite Corpse", comment: "Instructions Text 4")


		// set up initial transforms & alphas of views
		instructionsDrawingViewTop.layer.transform = CATransform3DIdentity
		instructionsDrawingViewBottom.layer.transform = CATransform3DIdentity
		instructionsDrawingViewTop.image = nil
		instructionsDrawingViewBottom.image = nil

		instructionsDrawingsHolder.layer.shadowColor = UIColor.blackColor().CGColor
		instructionsDrawingsHolder.layer.shadowOffset = CGSize(width: 0, height:4)
		instructionsDrawingsHolder.layer.shadowRadius = 8
		instructionsDrawingsHolder.layer.shadowOpacity = 0

		// cache the default frame before we set a transform
		instructionsDrawingHolderDefaultFrame = instructionsDrawingsHolder.frame
		instructionsDrawingsHolder.transform = CGAffineTransformMakeScale(1.1, 1.1)
		instructionsDrawingsHolder.alpha = 0

		nextButton.alpha = 0
		doneButton.alpha = 0
		doneButton.hidden = true

		for v in [instructionsDrawingsHolder,instructionsText1,instructionsText2,instructionsText3] {
			v.userInteractionEnabled = false
		}

		view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapped:"))
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		let bounds = view.bounds
		let defaultHeight:CGFloat = 60
		let inset:CGFloat = 20
		let offset:CGFloat = 40

		let bottomFrame = CGRect(x: instructionsDrawingHolderDefaultFrame.minX, y: instructionsDrawingHolderDefaultFrame.midY, width: instructionsDrawingHolderDefaultFrame.width, height: defaultHeight).rectByInsetting(dx: inset, dy: 0).rectByOffsetting(dx: 0, dy: offset)

		let topFrame = CGRect(x: instructionsDrawingHolderDefaultFrame.minX, y: instructionsDrawingHolderDefaultFrame.midY, width: instructionsDrawingHolderDefaultFrame.width, height: defaultHeight).rectByOffsetting(dx: 0, dy: -defaultHeight).rectByInsetting(dx: inset, dy: 0).rectByOffsetting(dx: 0, dy: -offset)

		instructionsText1.frame = bottomFrame
		instructionsText2.frame = bottomFrame
		instructionsText3.frame = topFrame

		// now we can use intrinsic content size to adjust height
		for v in [instructionsText1,instructionsText2,instructionsText3] {
			let center = v.center
			var frame = v.frame
			frame.size.height = round(v.intrinsicContentSize().height)

			v.frame = frame
			v.center = center

			v.frame = v.frame.integerRect
		}

		instructionsText4.frame = CGRect(x: instructionsDrawingHolderDefaultFrame.minX, y: doneButton.frame.minY - instructionsText4.intrinsicContentSize().height - 24, width: instructionsDrawingHolderDefaultFrame.width, height: 40)
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		showEmptyPaper()
	}

	// MARK: IBActions

	@IBAction func onNextButtonTap(sender: AnyObject) {
		forward()
	}

	@IBAction func onDoneButtonTap(sender: AnyObject) {
		finished()
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
				case .ShowBottomHalfWithGuide: showBottomHalfWithOverlap()
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
		//println("showEmptyPaper")

		UIView.animateWithDuration(duration, delay: 0.0, options: UIViewAnimationOptions(0), animations: { () -> Void in
			self.instructionsDrawingsHolder.transform = CGAffineTransformIdentity
			self.instructionsDrawingsHolder.alpha = 1
		}) { [unowned self] completed in
			delay(0.5) {
				self.forward()
			}
		}
	}

	func showTopHalf() {
		//println("showTopHalf")

		// fold bottom half behind top half
		instructionsDrawingViewTop.setAnchorPoint(CGPoint( x:0.5, y: 1 ))
		instructionsDrawingViewBottom.setAnchorPoint(CGPoint( x:0.5, y: 0 ))

		UIView.animateWithDuration(duration, animations: { [unowned self] in
			self.instructionsText1.alpha = 1

			var trans = CATransform3DIdentity
			trans.m34 = 1 / self.zDistance
			trans = CATransform3DRotate(trans, CGFloat(-M_PI * 0.99), 1, 0, 0)
			self.instructionsDrawingViewBottom.layer.transform = trans

			self.nextButton.alpha = 1
		})
	}

	func showTopHalfWithDrawing() {
		//println("showTopHalfWithDrawing")
		instructionsDrawingViewTop.image = UIImage(named:"instructions-drawing-top")

		UIView.animateWithDuration(duration, animations: { [unowned self] in
			self.instructionsText1.alpha = 0
			self.instructionsText2.alpha = 1
		})
	}

	func showBottomHalfWithOverlap() {
		//println("showBottomHalfWithOverlap")

		// unfold bottom half, and when complete, fold top half behind bottom half
		self.instructionsDrawingViewBottom.image = UIImage(named:"instructions-drawing-bottom-guide")
		self.instructionsDrawingViewBottom.contentMode = .Top

		UIView.animateWithDuration(duration, animations: { [unowned self] in
			self.instructionsText2.alpha = 0
			self.instructionsText3.alpha = 1
			self.instructionsDrawingViewBottom.layer.transform = CATransform3DIdentity
			self.nextButton.alpha = 0


		}) { [unowned self] completed in
			self.highlightBottomHalfOverlap()
		}
	}

	func highlightBottomHalfOverlap() {

		var highlightView = self.overlapHighlightView;
		let highlightHeight = CGFloat(8);
		let bottomFrame = instructionsDrawingHolderDefaultFrame
			.rectByOffsetting(dx: 0, dy: instructionsDrawingHolderDefaultFrame.height/2)
			.rectByInsetting(dx: 20, dy: 0)

		highlightView.frame = CGRect(x: bottomFrame.minX, y: bottomFrame.minY, width: bottomFrame.width, height: highlightHeight);
		highlightView.hidden = false

		self.instructionsDrawingsHolder.sendSubviewToBack(self.instructionsDrawingViewTop)

		UIView.animateWithDuration(self.duration, animations: { () -> Void in
			var trans = CATransform3DIdentity
			trans.m34 = 1 / self.zDistance

			trans = CATransform3DRotate(trans, CGFloat(M_PI * 0.99), 1, 0, 0)
			self.instructionsDrawingViewTop.layer.transform = trans
		}, completion: nil)

		// now, blink the highlight rect
		UIView.animateKeyframesWithDuration(1, delay: self.duration, options: UIViewKeyframeAnimationOptions(0),
			animations: { [unowned self] in
				let stops = [0.25,0.5,0.75,1.0]
				let duration = 0.25
				for (i,stop) in enumerate(stops) {
					UIView.addKeyframeWithRelativeStartTime(stop, relativeDuration: duration, animations: {
						//	because of an LLVM bug as of Xcode 6.1.1, I can't use an unowned self to refer to
						//	self.overlapHighlightView here... it causes an compiler failure
						highlightView.alpha = i % 2 == 0 ? 1 : 0
					})
				}
			}, completion: nil)

		delay(2){
			self.forward()
		}
	}

	func showBottomHalfWithDrawing() {
		//println("showBottomHalfWithDrawing")

		// unfold bottom half, and when complete, fold top half behind bottom half
		self.instructionsDrawingViewBottom.image = UIImage(named:"instructions-drawing-bottom")
		self.instructionsDrawingViewBottom.contentMode = .Center

		UIView.animateWithDuration(duration, animations: { [unowned self] in
			self.nextButton.alpha = 1
		})
	}

	func showFinalDrawing() {
		//println("showFinalDrawing")

		nextButton.setTitle(NSLocalizedString("DONE", comment:"InstructionsDoneButtonTitle"), forState: .Normal)

		self.instructionsDrawingsHolder.layer.shouldRasterize = true
		self.doneButton.hidden = false

		UIView.animateWithDuration(duration/2, delay: 0, options: UIViewAnimationOptions(0), animations: { [unowned self] in

			//	hide the instructionsText3 FIRST, because a triggered call to layoutSubviews will happen when
			//	self.instructionsDrawingsHolder.transform is set, and this will jarringly bump up the label, since it's
			//	y position is dependant on the drawings holder

			self.nextButton.alpha = 0
			self.instructionsText3.alpha = 0
		}) { [unowned self] completed in

			UIView.animateWithDuration(self.duration, animations: { [unowned self] in
				self.doneButton.alpha = 1
				self.instructionsText4.alpha = 1
				self.instructionsDrawingViewTop.layer.transform = CATransform3DIdentity
				self.instructionsDrawingsHolder.layer.shadowOpacity = 1

				var transform = CGAffineTransformIdentity
				transform = CGAffineTransformTranslate(transform, 0, -70)
				transform = CGAffineTransformScale(transform,0.85, 0.85)
				transform = CGAffineTransformRotate(transform, CGFloat(1.5 * M_PI / 180.0))
				self.instructionsDrawingsHolder.transform = transform
			})
		}
	}

	func finished() {
		//println("finished")
		dismissViewControllerAnimated(true, completion: nil)
	}

}
