//
//  ImagePresenterView.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/12/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit

class ImagePresenterView : UIView {


	override init(frame: CGRect) {
		super.init( frame: frame )
		commonInit()
	}

	required init(coder aDecoder: NSCoder) {
		super.init( coder: aDecoder )
		commonInit()
	}

	var image:UIImage? {
		didSet {
			_imageView.image = image
			update()
		}
	}

	var placeholderImage:UIImage? {
		didSet {
			_placeholderImageView.image = placeholderImage
			update()
		}
	}

	private var _placeholderImageView:UIImageView = UIImageView(frame: CGRect.zeroRect)
	var placeholderView:UIImageView { return _placeholderImageView }

	private var _imageView:UIImageView = UIImageView(frame: CGRect.zeroRect)
	var imageView:UIImageView { return _imageView }

	override func layoutSubviews() {
		_placeholderImageView.frame = self.bounds
		_imageView.frame = self.bounds
	}

	private func commonInit() {
		addSubview(_placeholderImageView)
		addSubview(_imageView)
		_imageView.alpha = 0
		_placeholderImageView.alpha = 0
	}

	private func update() {

		let duration:NSTimeInterval = 0.2
		let placeholderImageView = _placeholderImageView
		let imageView = _imageView

		if let image = self.image {

			UIView.animateWithDuration(duration, animations: { () -> Void in
				placeholderImageView.alpha = 0
				imageView.alpha = 1
			})

		} else {

			// don't animate transition to placeholder since this is being used in collection views and we nil the image during recycling
			placeholderImageView.alpha = placeholderImage != nil ? 1 : 0
			imageView.alpha = 0

		}

	}

}
