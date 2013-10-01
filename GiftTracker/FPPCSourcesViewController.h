//
//  FPPCSourcesViewController.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/14/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCSourceSearchViewController.h"
#import "FPPCGift.h"

@interface FPPCSourcesViewController : FPPCSourceSearchViewController <FPPCSourceSearchViewControllerDelegate>
- (IBAction)cancel:(id)sender;
@property (nonatomic, strong) FPPCGift *gift;
@end
