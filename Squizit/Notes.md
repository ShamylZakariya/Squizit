#TODO

	- add tweet + share buttons to the save-to-gallery vc's dialog, perhaps /outside/ the dialog, over the grey blanker
	- on Debug podcast was discussion that Apple made public touch APIs to determine touch intensity - could use this to modulate line width -- see UITouch -majorRadius
	- SquizitThemeLabel line is 2px thick sometimes on non-retina
	
#FIXME

	- Terrible performance on iPad3

	GalleryDetailViewController::updateItemSize
		The viewController's topLayoutGuide.length is zero, so I'm manually setting a fudge factor of 44 to accommodate the navbar height so UICollectionViewFlowLayout doesn't complain about inadequate room to layout cells. 

	SaveToGalleryTransitionManager doesn't actually work - not certain if it's my bug or iOS8. It's disabled, and I'm doing a hacky workaround.

#PROBLEMS

#WRITEUP

	Squizit is a modern take on an old parlour game, "Exquisite Corpse", which was played by surrealists in the 1920's. In it, the first player draws something on the top half or third of a sheet of paper, and then folds it such that the next player can only see the bottom edge. The next player then draws what he or she sees fit based on the the visible bottom portion of the previous player's turn. When complete, the paper is unfolded revealing a strange and often wonderfully absurd drawing.
	
	Squizit is an "Exquisite Corpse" game for the iPad, I hope you like it.
	
	Features:
		- Two or Three-person matches
		- And a gallery for perusing previous matches

	
#SNIPPETS

Rendering a stroke using my bezier interpolator

	var spar = stroke.spars[0]
	for i in 1 ..< stroke.spars.count {

		let nextSpar = stroke.spars[i]
		let interpolator1 = ControlPointCubicBezierInterpolator(a: spar.a, b: nextSpar.a )
		let interpolator2 = ControlPointCubicBezierInterpolator(a: spar.b, b: nextSpar.b )
		let subdivisions = interpolator1.recommendedSubdivisions()

		if subdivisions > 1 {

			var p0 = interpolator1.a.position
			var p1 = interpolator2.a.position

			for s in 1 ... subdivisions {

				let T = CGFloat(s) / CGFloat(subdivisions)
				let p2 = interpolator2.bezierPoint(T)
				let p3 = interpolator1.bezierPoint(T)

				let rect = UIBezierPath()
				rect.moveToPoint(p0)
				rect.addLineToPoint(p1)
				rect.addLineToPoint(p2)
				rect.addLineToPoint(p3)
				rect.closePath()

				shapes.appendPath(rect)
				p1 = p2;
				p0 = p3;
			}
		}

		spar = nextSpar
	}

