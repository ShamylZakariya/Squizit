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

func dispatch_main( closure:()->()) {
	dispatch_async(dispatch_get_main_queue(), closure )
}