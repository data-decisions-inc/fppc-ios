//
//  FPPCSourceViewController.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/3/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "FPPCViewController.h"
#import "FPPCSource.h"
#import "FPPCGiftSearchViewController.h"

@interface FPPCSourceViewController : FPPCGiftSearchViewController <MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, UISearchBarDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) FPPCSource *source;
@property (strong, nonatomic) IBOutlet UILabel *name;
@property (strong, nonatomic) IBOutlet UILabel *totalReceived;
@property (strong, nonatomic) FPPCViewController *delegate;

#pragma mark - Contact the source
#pragma
@property (strong, nonatomic) IBOutlet UIButton *sms;
@property (strong, nonatomic) IBOutlet UIButton *email;
@property (strong, nonatomic) IBOutlet UIButton *call;
- (IBAction)sms:(id)sender;
- (IBAction)email:(id)sender;
- (IBAction)call:(id)sender;
@end
