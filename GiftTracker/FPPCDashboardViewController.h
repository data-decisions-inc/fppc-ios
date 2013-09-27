//
//  FPPCDashboardViewController.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/3/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "FPPCViewController.h"
#import "FPPCSourceSearchViewController.h"
#import "FPPCSourceFormViewController.h"
#import "FPPCGiftFormViewController.h"
#import "FPPCKeyboard.h"

@interface FPPCDashboardViewController : FPPCSourceSearchViewController <UIPickerViewDelegate, UIPickerViewDataSource, MFMailComposeViewControllerDelegate, UITextFieldDelegate, FPPCToolbarDelegate, FPPCSourceSearchViewControllerDelegate, FPPCSourceFormViewControllerDelegate, FPPCGiftFormViewControllerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField *month;
@property (strong, nonatomic) IBOutlet UITextField *year;
@property (strong, nonatomic) IBOutlet UILabel *monthValue;
@property (strong, nonatomic) IBOutlet UILabel *yearValue;
@property (strong, nonatomic) IBOutlet UILabel *monthGifts;
@property (strong, nonatomic) IBOutlet UILabel *yearGifts;
@property (strong, nonatomic) FPPCToolbar *keyboardToolbar;
@property (strong, nonatomic) UIPickerView *monthPickerView;
@property (strong, nonatomic) UIPickerView *yearPickerView;
@property (strong, nonatomic) NSArray *months;

- (IBAction)emailExcelFile:(id)sender;

@end
