//
//  UniversalHowToPlayViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/23/15.
//  Copyright (c) 2015 Shamyl Zakariya. All rights reserved.
//

import UIKit



class UniversalHowToPlayViewController : UIPageViewController, UIPageViewControllerDataSource,UIPageViewControllerDelegate {

	override func awakeFromNib() {
		super.awakeFromNib()
		title = "How to Play"
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle {
		return UIStatusBarStyle.LightContent
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = SquizitTheme.matchBackgroundColor()

		let initialPageVc = vend(0)
		setViewControllers([initialPageVc], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)

		dataSource = self
		delegate = self
	}

	private func vend(index:Int)->ManagedIndexedViewViewController {

		var page = InstructionView.create()
		page.label.attributedText = NSAttributedString(string: "PAGE: \(index)", attributes: [
			NSForegroundColorAttributeName: UIColor.whiteColor()
		])

		page.centeredImageView.backgroundColor = UIColor.redColor()

		return ManagedIndexedViewViewController(view: page, index: index, respectsTopLayoutGuide:true)
	}

	private var count:Int {
		return 6
	}

	private var currentIndex:Int = 0

	// MARK: - UIPageViewControllerDataSource

	func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
		let pageVc = viewController as! ManagedIndexedViewViewController
		if pageVc.index > 0 {
			return vend(pageVc.index-1)
		}

		return nil
	}

	func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
		let pageVc = viewController as! ManagedIndexedViewViewController
		if pageVc.index < count-1 {
			return vend(pageVc.index+1)
		}

		return nil
	}

	func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
		return count
	}

	func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
		return 0
	}

	// MARK: - UIPageViewControllerDelegate

	func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
		let pageVc = pageViewController.viewControllers.first as! ManagedIndexedViewViewController
		currentIndex = pageVc.index
	}

	// MARK: - Actions


	@IBAction func onDoneTapped(sender: AnyObject) {
		presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
	}


}
