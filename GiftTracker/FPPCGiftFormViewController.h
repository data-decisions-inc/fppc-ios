//
//  FPPCGiftFormViewController.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/3/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FPPCViewController.h"
#import "FPPCGift.h"
#import "FPPCKeyboard.h"
#import "FPPCGiftFormCell.h"
#import "FPPCSource.h"
#import "FPPCSourceSearchViewController.h"
#import "FPPCSourceFormViewController.h"

@protocol FPPCGiftFormViewControllerDelegate
- (void)didUpdateGift;
@end

@interface FPPCGiftFormViewController : FPPCViewController <UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, FPPCToolbarDelegate, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UIActionSheetDelegate, FPPCSourceSearchViewControllerDelegate> {
    CGSize keyboardSize;
}

@property (nonatomic, strong) IBOutlet UITextField *name;
@property (nonatomic, strong) IBOutlet UITextField *month;
@property (nonatomic, strong) IBOutlet UITextField *day;
@property (nonatomic, strong) IBOutlet UITextField *year;
@property (nonatomic, strong) IBOutlet UILabel *total;
@property (nonatomic, strong) FPPCToolbar *keyboardToolbar;
@property (nonatomic, strong) FPPCGift *gift;
@property (nonatomic, weak)   id<FPPCGiftFormViewControllerDelegate> delegate;
@property (nonatomic, strong) FPPCSource *source;
- (NSDate *)date;
- (NSDateComponents *)dateComponents;

#pragma mark - Table view
#pragma 
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) IBOutlet FPPCGiftFormCell *sourceCell;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

#pragma mark - UIPickerView
#pragma
@property (nonatomic, strong) UIPickerView *dayPickerView;
@property (nonatomic, strong) UIPickerView *monthPickerView;
@property (nonatomic, strong) UIPickerView *yearPickerView;
@property (nonatomic, strong) NSMutableArray *months;

#pragma mark - Navigation bar
#pragma
@property (nonatomic, strong) IBOutlet UINavigationBar *navigationBar;
- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;
@end
