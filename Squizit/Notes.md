#TODO

	Drawing lines at 90% opacity looks great... but there's a hairline crack between stroke segments
		Since we're drawing at partial opacity we can't stroke, because the stroke would darken the line. 
		- Should strokes be slightly outset at edges? 
		- Or should I use a stroke + transparency layer when drawing? NO: transparency layers apparently don't work this way.
		
		The problem is that my drawing lines are made of numerous strokes. I had trouble with joining strokes before, and I'm guessing it's the source of my trouble here.

#FIXME

	GalleryDetailViewController::updateItemSize
		The viewController's topLayoutGuide.length is zero, so I'm manually setting a fudge factor of 44 to accommodate the navbar height so UICollectionViewFlowLayout doesn't complain about inadequate room to layout cells. 

#PROBLEMS

	Can't Make SaveToGalleryViewController's view transparent:
		- setting opaque = false on view and view.superview don't seem to help
		- setting view.superview.backgroundColor = UIColor.clearColor() doesn't seem to help
		- when hitting the Next key in name entry fields, I get an ever so brief line-return!
	
#DONE

	Don't save paper texture in screenshots, save just clear with alpha channel then composite a scaled-down paper texture as background of imageView showing the image'
	Wiggle mode on GalleryViewController doesn't work well



