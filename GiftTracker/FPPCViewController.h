//
//  FPPCViewController.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/4/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FPPCAppDelegate.h"
#import "TestFlight.h"

@interface FPPCViewController : UIViewController
- (NSNumberFormatter *)currencyFormatter;
- (void)showErrorMessage;
@end
