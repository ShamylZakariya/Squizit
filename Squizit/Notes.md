#TODO

	- Design an app icon
	- add transitions to my segues

#FIXME

	Use display link to render wiggle animation instead of NSTimer
		- https://github.com/kaishin/gifu

	GalleryDetailViewController::updateItemSize
		The viewController's topLayoutGuide.length is zero, so I'm manually setting a fudge factor of 44 to accommodate the navbar height so UICollectionViewFlowLayout doesn't complain about inadequate room to layout cells. 

#PROBLEMS

	Can't Make SaveToGalleryViewController's view transparent:
		- setting opaque = false on view and view.superview don't seem to help
		- setting view.superview.backgroundColor = UIColor.clearColor() doesn't seem to help
		- when hitting the Next key in name entry fields, I get an ever so brief line-return!
	
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

