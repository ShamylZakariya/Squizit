//
//  UIImage_sizing.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/28/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {

	func imageByScalingToSize( size:CGSize, scale:CGFloat = 0.0 ) -> UIImage {

		if CGSizeEqualToSize(size, self.size) {
			return self
		}

		UIGraphicsBeginImageContextWithOptions(size, false, scale)

		self.drawInRect(CGRect(x: 0, y: 0, width: size.width, height: size.height), blendMode: kCGBlendModeNormal, alpha: 1)

		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return newImage;
	}

	func imageByScalingToSize( newSize:CGSize, contentMode:UIViewContentMode, scale:CGFloat = 0.0 ) -> UIImage {
		if CGSizeEqualToSize(newSize, self.size) {
			return self
		}

		UIGraphicsBeginImageContextWithOptions(newSize, false, scale)

		let imageWidth = self.size.width
		let imageHeight = self.size.height

		switch contentMode {

			case UIViewContentMode.ScaleToFill:
				self.drawInRect(CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height), blendMode: kCGBlendModeNormal, alpha: 1)

			case UIViewContentMode.ScaleAspectFit:
				var scale = newSize.width / imageWidth
				if ( imageHeight * scale > newSize.height )
				{
					scale *= newSize.height / (imageHeight*scale)
				}

				let center = CGPoint( x:newSize.width/2, y: newSize.height/2)
				self.drawInRect(centeredRect( center, width: imageWidth*scale, height: imageHeight*scale), blendMode: kCGBlendModeNormal, alpha: 1)

			case UIViewContentMode.ScaleAspectFill:
				var scale = newSize.width / imageWidth
				if ( imageHeight * scale < newSize.height )
				{
					scale *= newSize.height / (imageHeight*scale)
				}
				let center = CGPoint( x:newSize.width/2, y: newSize.height/2)
				self.drawInRect(centeredRect( center, width: imageWidth*scale, height: imageHeight*scale), blendMode: kCGBlendModeNormal, alpha: 1)

			case UIViewContentMode.Center:
				let center = CGPoint( x:newSize.width/2, y: newSize.height/2)
				self.drawInRect(centeredRect( center, width: newSize.width, height: newSize.height), blendMode: kCGBlendModeNormal, alpha: 1)

			default:
				assertionFailure("Unsupported contentMode, sorry")
				break;
		}

		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return newImage;
	}

	private func centeredRect( center:CGPoint, width:CGFloat, height:CGFloat ) -> CGRect {
		return CGRect(x: center.x - width/2, y: center.y - height/2, width: width, height: height)
	}

}