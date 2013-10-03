//
//  FPPCGiftsViewController.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/14/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCGiftSearchViewController.h"
#import "FPPCGiftFormViewController.h"

@interface FPPCGiftsViewController : FPPCGiftSearchViewController <FPPCGiftFormViewControllerDelegate>
- (IBAction)cancel:(id)sender;
@property (nonatomic, strong) NSDate *date;
@end
