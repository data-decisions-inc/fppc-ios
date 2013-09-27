//
//  FPPCGiftSearchViewController.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/4/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCSearchViewController.h"
#import "FPPCGiftCell.h"

@interface FPPCGiftSearchViewController : FPPCSearchViewController
@property (nonatomic, assign) IBOutlet FPPCGiftCell *giftCell;
@property (nonatomic, strong) IBOutlet UINavigationBar *navBar;
- (IBAction)cancel:(id)sender;
@end
