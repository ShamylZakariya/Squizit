//
//  Appearance.m
//  Squizit
//
//  Created by Shamyl Zakariya on 9/3/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

#import "Appearance.h"

void SquizitTheme_ConfigureAppearanceProxies()
{
	//
	//	UITextField inside a UISearchBar
	//

	UITextField *appearanceProxy = [UITextField appearanceWhenContainedIn:[UISearchBar class], nil];
	appearanceProxy.defaultTextAttributes = @{
		NSFontAttributeName:[UIFont fontWithName:@"Baskerville" size:[UIFont labelFontSize]],
		NSForegroundColorAttributeName: [UIColor whiteColor]
	};
}