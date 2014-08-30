#TODO

Don't save paper texture in screenshots, save just clear with alpha channel
then composite a scaled-down paper texture as background of imageView showing the image'

Drawing lines at 90% opacity looks great... but there's a hairline crack between stroke segments. And since we're drawing at partial opacity we can't stroke, because the stroke would darken the line. Should strokes be slightly outset at edges?

Make SaveToGalleryViewController's view transparent.
	- setting opaque = false on view and view.superview don't seem to help
	- setting view.superview.backgroundColor = UIColor.clearColor() doesn't seem to help
	- when hitting the Next key in name entry fields, I get an ever so brief line-return!
	