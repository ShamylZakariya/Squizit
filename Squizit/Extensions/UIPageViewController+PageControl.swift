//
//  UIPageViewController+PageControl.swift
//  CNLSecurities
//
//  Created by Zakariya, Shamyl on 6/10/15.
//  Copyright (c) 2015 cnlsecurities. All rights reserved.
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
			if let pageControl = findPageControl(subview as! UIView) {
				return pageControl
			}
		}

		return nil
	}

}