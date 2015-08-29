//
//  ManagedIndexedViewViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/23/15.
//  Copyright (c) 2015 Shamyl Zakariya. All rights reserved.
//

import UIKit

/**
	A view controller that shows a view, and has an index associated with it.
	It is meant to represent a "page" for a UIPageViewController.
*/

class ManagedIndexedViewViewController : UIViewController {

	private (set) var index:Int = 0
	private (set) var managedView:UIView!

	var respectsTopLayoutGuide:Bool = true {
		didSet {
			view.setNeedsLayout()
		}
	}

	init(view:UIView, index:Int, respectsTopLayoutGuide:Bool) {
		super.init(nibName: nil, bundle: nil)
		self.index = index
		self.managedView = view
		self.view.addSubview(self.managedView)
		self.respectsTopLayoutGuide = respectsTopLayoutGuide
	}

	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()

		if respectsTopLayoutGuide {
			// I would use topLayoutGuide.length, but it reports erroneous values during scrolling
			let app = UIApplication.sharedApplication()
			let statusBarHeight = app.statusBarHidden ? CGFloat(0) : app.statusBarFrame.size.height
			let navbarHeight = navigationController?.navigationBar.frame.height ?? 0
			let topLayoutGuideLength = statusBarHeight + navbarHeight

			var frame = view.bounds
			frame.origin.y += topLayoutGuideLength
			frame.size.height -= topLayoutGuideLength

			managedView.frame = frame
		} else {
			managedView.frame = view.bounds
		}
	}
}
