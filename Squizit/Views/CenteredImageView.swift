//
//  CenteredImageView.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/22/15.
//  Copyright (c) 2015 Shamyl Zakariya. All rights reserved.
//

import UIKit

class CenteredImageView : UIView {

	private (set) var imageView:UIImageView!

	required override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}

	private func commonInit() {
		imageView = UIImageView(frame: CGRect.zeroRect)
		imageView.contentMode = UIViewContentMode.ScaleToFill
		addSubview(imageView)
	}

	var image:UIImage? {
		get {
			return imageView.image
		}
		set {
			imageView.image = newValue
			setNeedsLayout()
		}
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		if let image = image {
			var scale = frame.height / image.size.height
			if image.size.width * scale > frame.width {
				scale *= frame.width / (image.size.width * scale)
			}

			if scale < 1 {
				imageView.frame = CGRect(center: bounds.center, size: CGSize(width: image.size.width * scale, height: image.size.height * scale)).integerRect
			} else {
				// just center image
				imageView.frame = CGRect(center: bounds.center, size: image.size)
			}
		}
	}

}
