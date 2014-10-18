//
//  UIColor+Serialization.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/12/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

extension BinaryCoder {
	func getColor() -> UIColor? {
		if self.remaining >= 4 * sizeof(Float) {
			let components = self.getFloat32(4)
			return UIColor(red: CGFloat(components[0]), green: CGFloat(components[1]), blue: CGFloat(components[2]), alpha: CGFloat(components[3]))
		}

		return nil
	}
}

extension MutableBinaryCoder {
	func putColor( color:UIColor ) {
		if color.hasRGBComponents {
			let red = Float(color.redComponent!)
			let green = Float(color.greenComponent!)
			let blue = Float(color.blueComponent!)
			let alpha = Float(color.alphaComponent!)
			self.putFloat32([red,green,blue,alpha])
		}
	}
}

extension UIColor {

	var hasRGBComponents:Bool {
		var m:CGColorSpaceModel = CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor))
		return ( m.value == kCGColorSpaceModelMonochrome.value || m.value == kCGColorSpaceModelRGB.value )
	}

	var isMonochrome:Bool {
		var m:CGColorSpaceModel = CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor))
		return m.value == kCGColorSpaceModelMonochrome.value
	}

	func colorComponentAtIndex( var i:Int ) -> CGFloat {
		i = min( max( i, 0 ), Int(CGColorGetNumberOfComponents(self.CGColor)))
		let components = CGColorGetComponents(self.CGColor)
		return components[i]
	}

	var redComponent:CGFloat? {
		if hasRGBComponents {
			return self.colorComponentAtIndex( 0)
		}

		return nil
	}

	var greenComponent:CGFloat? {
		if hasRGBComponents {
			return self.colorComponentAtIndex( self.isMonochrome ? 0 : 1 )
		}

		return nil
	}

	var blueComponent:CGFloat? {
		if hasRGBComponents {
			return self.colorComponentAtIndex( self.isMonochrome ? 0 : 2 )
		}

		return nil
	}

	var alphaComponent:CGFloat? {
		return self.colorComponentAtIndex( CGColorGetNumberOfComponents(self.CGColor) - 1 )
	}

}