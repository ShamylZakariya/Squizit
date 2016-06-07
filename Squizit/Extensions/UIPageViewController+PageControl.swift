//
//  UIPageViewController+PageControl.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 6/27/15.
//  Copyright (c) 2015 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

extension UIPageViewController {

	var pageControl:UIPageControl? {
		return findPageControl(view)
	}

	private func findPageControl(view:UIView) -> UIPageControl? {

		if let pageControl = view as? UIPageControl {
			return pageControl
		}

		for subview in view.subviews {
			if let pageControl = findPageControl(subview ) {
				return pageControl
			}
		}

		return nil
	}

}