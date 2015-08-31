# APPSTORE SUBMISSION TODO

Screenshots for phones
The buttons at the top of the phone layout are not receiving input events because of edge tracking. Need to move then down.
Match.render is rendering NOT at retina scale,making renderings look like shit
The universal match view controller layout algo is screwing up compact layout because of smaller button sizes

#CURRENT

- When toggle zoom/pan mode in UniversalMatchViewPresenterView, there's still a jump

- Immediate vector drawing pipeline has following issues:
	- doesn't clip drawing to viewport
	- player N where N > 0 can't see drawing (maybe a matter of context transforms)
	- zoomed mode still pixellated. Probably something to do with layer rasterization scale...

#FIXME

- Terrible performance on iPad3
- SaveToGalleryTransitionManager doesn't actually work - not certain if it's my bug or iOS8. It's disabled, and I'm doing a hacky workaround.

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

