//
//  TurnBasedMatchHelper.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 1/14/15.
//  Copyright (c) 2015 Shamyl Zakariya. All rights reserved.
//

import Foundation
//import GameKit

/*
class TurnBasedMatchHelper {

	class var sharedInstance: TurnBasedMatchHelper {
		struct Static {
			static let instance:TurnBasedMatchHelper = TurnBasedMatchHelper()
		}

		return Static.instance;
	}

	init() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "authenticationChanged", name: GKPlayerAuthenticationDidChangeNotificationName, object: nil);
	}

	var rootViewController:UIViewController? = nil

	var userAuthenticated:Bool = false {
		didSet {
			NSLog("userAuthenticated: \(userAuthenticated)")
		}
	}

	func authenticateLocalPlayer() {
		var player = GKLocalPlayer.localPlayer()
		if let rvc = rootViewController {
			player.authenticateHandler = { [unowned self] viewController, error in
				if viewController != nil {
					rvc.presentViewController(viewController, animated: true, completion: nil)
				} else {
					self.userAuthenticated = player.authenticated
				}
			}
		}
	}

	dynamic private func authenticationChanged( note:NSNotification ) {
		userAuthenticated = GKLocalPlayer.localPlayer().authenticated;
	}
}
*/