//
//  RootViewController.swift
//  Squizit
//
//  Created by Shamyl Zakariya on 8/18/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

import Foundation
import UIKit

class RootViewController : UIViewController {


	@IBOutlet weak var twoPlayersButton: UIButton!
	@IBOutlet weak var threePlayersButton: UIButton!
	@IBOutlet weak var galleryButton: UIButton!

	override func viewWillAppear(animated: Bool) {
		UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Fade)
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {

		if sender === galleryButton {

			// no gallery, yet

		} else {

			var players = 0
			if sender === twoPlayersButton {
				players = 2
			} else if sender === threePlayersButton {
				players = 3
			}

			println("starting \(players) player match")
			let matchVC = segue.destinationViewController as MatchViewController
			matchVC.match = Match(players: players, stageSize: CGSize(width: 768, height: 1024), overlap: 40)
			matchVC.player = 0
			matchVC.fill = Fill.Pencil

		}
	}
}