#TODO

	- look into SLComposeViewController to tweet directly, bypassing the share sheet
		http://stackoverflow.com/questions/18982612/twtweetcomposeviewcontroller-alerts-with-no-twitter-accounts-found
		
	- add @squizitapp button to root screen
	- add dedicated tweet this match icon to gallery detail vc's navbar, to left of generic all-purpose share button
	- add tweet + share buttons to the save-to-gallery vc's dialog, perhaps /outside/ the dialog, over the grey blanker
	
	- make SaveToGalleryViewController a more modern VC with a custom segue overlay
		this means I will manually manage the blanker view, and will have to manually manage the content view inside it

#FIXME

	You can still draw on the last drawing of the match when the match is over and the final drawing is presented!

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

