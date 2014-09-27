//
//  ShareToTwitter.m
//  Squizit
//
//  Created by Shamyl Zakariya on 9/27/14.
//  Copyright (c) 2014 Shamyl Zakariya. All rights reserved.
//

#import "ShareToTwitter.h"
@import Social;

SLComposeViewController* SLComposeViewController_Twitter() {
	return [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
}