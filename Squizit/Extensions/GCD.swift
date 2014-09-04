//
//  GCD.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/31/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

func debounce( delay:NSTimeInterval, #queue:dispatch_queue_t, action: (()->()) ) -> ()->() {
	
	var lastFireTime:dispatch_time_t = 0
	let dispatchDelay = Int64(delay * Double(NSEC_PER_SEC))
	
	return {
		lastFireTime = dispatch_time(DISPATCH_TIME_NOW,0)
		dispatch_after(
			dispatch_time(
				DISPATCH_TIME_NOW,
				dispatchDelay
			),
			queue) {
				let now = dispatch_time(DISPATCH_TIME_NOW,0)
				let when = dispatch_time(lastFireTime, dispatchDelay)
				if now >= when {
					action()
				}
			}
	}
}

func debounce( delay:NSTimeInterval, action: (()->()) ) -> ()->() {
	return debounce( delay, queue: dispatch_get_main_queue(), action )
}

func dispatch_main( closure:()->()) {
	dispatch_async(dispatch_get_main_queue(), closure )
}