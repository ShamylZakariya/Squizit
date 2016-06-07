//
//  InstructionView.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/23/15.
//  Copyright (c) 2015 Shamyl Zakariya. All rights reserved.
//

import UIKit

class InstructionView : UIView {

	@IBOutlet weak var centeredImageView: CenteredImageView!
	@IBOutlet weak var label: UILabel!

	class func create()->InstructionView {
		let items = NSBundle.mainBundle().loadNibNamed("InstructionView", owner: nil, options: nil)
		return items[0] as! InstructionView
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
