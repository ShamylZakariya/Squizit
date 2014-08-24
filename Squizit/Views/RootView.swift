//
//  RootView.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/23/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class RootView : UIView {

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		tintColor = UIColor.whiteColor()
		backgroundColor = UIColor(patternImage: UIImage(named: "cube-background"))
	}
}