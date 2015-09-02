//
//  UIImage_Alpha.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 6/27/15.
//  Copyright (c) 2015 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {

	func imageWithAlpha(alpha:CGFloat) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(size, false, scale)

		let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
		CGContextClearRect(UIGraphicsGetCurrentContext(), rect)
		self.drawInRect(rect, blendMode: kCGBlendModeNormal, alpha: alpha)

		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return newImage;
	}

}
