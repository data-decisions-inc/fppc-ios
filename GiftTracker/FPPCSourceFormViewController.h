//
//  FPPCSourceFormViewController.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/3/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FPPCViewController.h"
#import "FPPCKeyboard.h"
#import "FPPCSource.h"
#import "FPPCGiftFormViewController.h"
#import "DCRoundSwitch.h"

@protocol FPPCSourceFormViewControllerDelegate
- (void)didAddSource:(FPPCSource *)source;
@end

@interface FPPCSourceFormViewController : FPPCViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, FPPCToolbarDelegate>{
    CGSize keyboardSize;
}

@property (strong, nonatomic) FPPCSource *source;
@property (strong, nonatomic) IBOutlet UITextField *name;
@property (strong, nonatomic) IBOutlet UITextField *business;
@property (strong, nonatomic) IBOutlet UITextField *street;
@property (strong, nonatomic) IBOutlet UITextField *street2;
@property (strong, nonatomic) IBOutlet UITextField *city;
@property (strong, nonatomic) IBOutlet UITextField *state;
@property (strong, nonatomic) IBOutlet UITextField *zipcode;
@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UITextField *phone;
@property (strong, nonatomic) IBOutlet UIView *lobbying;
@property (strong, nonatomic) DCRoundSwitch *isLobbying_iOS6;
@property (strong, nonatomic) UISwitch *isLobbying;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) FPPCToolbar *keyboardToolbar;
@property (strong, nonatomic) FPPCViewController<FPPCSourceFormViewControllerDelegate> *delegate;

#pragma mark - Navigation bar
#pragma
@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;
- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;
@end
