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
	typealias Canceled = ()->Bool
	typealias Action = ( done:Done, canceled:Canceled )->()

	private var _canceled:Bool = false
	private var _result:T?

	init( action:Action, done:Done ) {
		action({ [weak self] result in
			if let sself = self {
				if !sself._canceled {
					sself._result = result
					done( result:result )
				}
			}
		}, { [weak self] in
			if let sself = self {
				return sself._canceled
			}

			return true
		})
	}

	var result:T? {
		return _result
	}

	func cancel(){
		_canceled = true
	}

}
