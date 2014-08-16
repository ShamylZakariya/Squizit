//
//  Match.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/15/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

/**
	Represents a game match
*/
class Match {

	private var _drawings:[Drawing] = []
	private var _transforms:[CGAffineTransform] = []

	init( players:Int, stageSize:CGSize ){

		let rowHeight:CGFloat = CGFloat(round(stageSize.height / CGFloat(players)))
		let drawingSize = CGSize(width: stageSize.width, height: rowHeight )
		let t:CGAffineTransform = CGAffineTransformMakeTranslation(0, 0)

		for i in 0 ..< players {
			_drawings.append(Drawing(width: Int(drawingSize.width), height: Int(drawingSize.height)))
			_transforms.append(CGAffineTransformMakeTranslation( 0, rowHeight * CGFloat(i) ))

			_drawings.last?.backgroundColor = UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1)
		}
	}

	var drawings:[Drawing] { return _drawings }
	var transforms:[CGAffineTransform] { return _transforms }

}