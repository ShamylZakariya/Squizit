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

	var animate:Bool = true

	var image:UIImage? {
		didSet {
			if image !== oldValue || image == nil {
				imageView.image = image
				update()
			}
		}
	}

	var placeholderImage:UIImage? {
		didSet {
			placeholderImageView.image = placeholderImage
			update()
		}
	}

	override var contentMode:UIViewContentMode {
		didSet {
			placeholderImageView.contentMode = contentMode
			imageView.contentMode = contentMode
		}
	}

	private (set) var placeholderImageView:UIImageView = UIImageView(frame: CGRect.zeroRect)
	private (set) var imageView:UIImageView = UIImageView(frame: CGRect.zeroRect)

	override func layoutSubviews() {
		placeholderImageView.frame = self.bounds
		imageView.frame = self.bounds
	}

	private func commonInit() {
		addSubview(placeholderImageView)
		addSubview(imageView)
		imageView.alpha = 0
		placeholderImageView.alpha = 0
	}

	private func update() {

		let placeholderImageView = self.placeholderImageView
		let imageView = self.imageView

		if animate {
			let duration:NSTimeInterval = 0.15

			if let image = self.image {

				UIView.animateWithDuration(duration) {
					placeholderImageView.alpha = 0
					imageView.alpha = 1
				}

			} else {

				// don't animate transition to placeholder since this is being used in collection views and we nil the image during recycling
				placeholderImageView.alpha = placeholderImage != nil ? 1 : 0
				imageView.alpha = 0

			}
		} else {
			if let image = self.image {
				placeholderImageView.alpha = 0
				imageView.alpha = 1
			} else {
				placeholderImageView.alpha = placeholderImage != nil ? 1 : 0
				imageView.alpha = 0
			}
		}

	}

}
