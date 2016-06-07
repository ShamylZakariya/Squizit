//
//  GalleryDetailPageView.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/22/15.
//  Copyright (c) 2015 Shamyl Zakariya. All rights reserved.
//

import UIKit

class GalleryDetailPageView : UIView {
	@IBOutlet weak var centeredImageView: CenteredImageView!
	@IBOutlet weak var playerNamesLabel: UILabel!
	@IBOutlet weak var matchDateLabel: UILabel!


	class func create()->GalleryDetailPageView {
		let items = NSBundle.mainBundle().loadNibNamed("GalleryDetailPageView", owner: nil, options: nil)
		return items[0] as! GalleryDetailPageView
	}

	required override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		commonInit()
	}

	private func commonInit() {
		backgroundColor = UIColor.clearColor()
	}

}
