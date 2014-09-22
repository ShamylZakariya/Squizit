//
//  CancelableAction.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 9/22/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import UIKit


class CancelableAction<T> {

	typealias Done = ( result:T )->()
	typealias Action = ( done:Done )->()

	private var _canceled:Bool = false

	init( action:Action, done:Done ) {
		action({ [weak self] result in
			if let sself = self {
				if !sself._canceled {
					done( result:result )
				}
			}
		})
	}

	func cancel(){
		_canceled = true
	}

}
