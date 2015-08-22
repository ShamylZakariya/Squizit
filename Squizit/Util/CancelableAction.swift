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

	init( action:Action, done:Done? ) {
		self.done = done
		action(
			done: { [weak self] result in
				if let sself = self {
					synchronized(sself) {
						if !sself._canceled {
							sself._result = result
							sself.done?( result:result )
						}
					}
				}
			},
			canceled: { [weak self] in
				if let sself = self {
					return sself._canceled
				}

				return true
			})
	}

	/*
		Create a CancelableAction without a done block
		When this action is complete, result will be assigned.
		If a done block is assigned later, when the action completes that done block will be invoked.
		If when the done block is assigned the action has already completed, the done block will be immediately invoked.
	*/
	convenience init( action:Action ) {
		self.init( action: action, done: nil )
	}

	/*
		Assign done block
		If the action has already completed ( result != nil ) the assigned done block will be immediately run
	*/
	var done:Done? {
		didSet {
			if let result = self.result {
				if let done = self.done {
					done( result: result )
				}
			}
		}
	}

	/*
		If the action has completed execution the result is available here
	*/
	var result:T? {
		return _result
	}

	/*
		Cancel this action's execution
		This means the done block will never be invoked, and result will never be assigned.
	*/
	func cancel(){
		synchronized(self) {
			self._canceled = true
		}
	}

	var canceled:Bool { return _canceled }

}
