//
//  FPPCSourceFormViewController.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/3/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCSourceFormViewController.h"
#import "FPPCSource.h"
#import "FPPCGift.h"
#import "FPPCDashboardViewController.h"
#import "UIColor+FPPC.h"

@interface FPPCSourceFormViewController ()
#define FPPC_SOURCE_MINIMUM_TAG 1
#define FPPC_SOURCE_MAXIMUM_TAG 9
- (void)scrollView:(UIScrollView *)scrollView toFocusTextField:(UITextField *)textField;
@end

@implementation FPPCSourceFormViewController
@synthesize source;
@synthesize name, business, email, phone, lobbying, isLobbying, isLobbying_iOS6;
@synthesize street, street2, city, state, zipcode;
@synthesize scrollView = _scrollView;
@synthesize keyboardToolbar;
@synthesize delegate;
@synthesize navigationBar;

#pragma mark - View Lifecycle
#pragma

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Setup navigation bar
    self.navigationBar.topItem.title = source ? @"Edit Source" : @"New Source";
    
    // Create input accessory view for keyboard
    self.keyboardToolbar = [[FPPCToolbar alloc] initWithController:self];
    [self registerForKeyboardNotifications];
    
    // Custom switch
    BOOL isIOS7 = [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0;
    if (isIOS7) {
        self.isLobbying = [[UISwitch alloc] init];
        [self.isLobbying setAccessibilityLabel:@"Lobbying"];
        [self.lobbying addSubview:self.isLobbying];
    } else {
        self.isLobbying_iOS6 = [[DCRoundSwitch alloc] init];
        self.isLobbying_iOS6.onText = @"YES";
        self.isLobbying_iOS6.offText = @"NO";
        self.isLobbying_iOS6.onTintColor = [UIColor FPPCBlueColor];
        [self.isLobbying_iOS6 setAccessibilityLabel:@"Lobbying"];
        [self.lobbying addSubview:self.isLobbying_iOS6];
    }
    
    // Initialize form
    if (source) {
        name.text = source.name;
        business.text = source.business;
        street.text = source.street;
        street2.text = source.street2;
        city.text = source.city;
        state.text = source.state;
        zipcode.text = source.zipcode;
        email.text = source.email;
        phone.text = source.phone;
        
        if (isIOS7)
            [isLobbying setOn:[source.isLobbying boolValue] ];
        else
            [isLobbying_iOS6 setOn:[source.isLobbying boolValue] ];
    }
    
    // Set scrollview content size
    self.scrollView.contentSize = self.view.frame.size;
}

#pragma mark - Navigation Bar
#pragma

- (void)cancel:(id)sender {
    [self.delegate didAddSource:nil];
}

- (void)save:(id)sender {
    
    // Create and configure a new Source
    if (!source) {
        source = (FPPCSource *)[NSEntityDescription insertNewObjectForEntityForName:@"FPPCSource" inManagedObjectContext:((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext];
    }
    
    source.name = name.text;
    source.business = business.text;
    source.street = street.text;
    source.street2 = street2.text;
    source.city = city.text;
    source.state = state.text;
    source.zipcode = zipcode.text;
    source.email = email.text;
    source.phone = phone.text;
    
    BOOL isIOS7 = [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0;
    if (isIOS7)
        source.isLobbying = [NSNumber numberWithBool:isLobbying.isOn];
    else
        source.isLobbying = [NSNumber numberWithBool:isLobbying_iOS6.isOn];
    
    // Commit changes to the persistent store
    [(FPPCAppDelegate *)[[UIApplication sharedApplication] delegate] saveContext];
    
    // Pass this source back to the new-gift form
    [self.delegate didAddSource:source];
}

#pragma mark - UITextField
#pragma mark

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    textField.inputAccessoryView = self.keyboardToolbar;
    [self.keyboardToolbar setTextField:textField];
    return YES;
}

- (void)scrollView:(UIScrollView *)scrollView toFocusTextField:(UITextField *)textField {
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
    
    CGRect aRect = self.view.frame;
    aRect.origin.y = navigationBar.frame.size.height;
    aRect.size.height -= (keyboardSize.height+self.keyboardToolbar.frame.size.height+navigationBar.frame.size.height*2);
    [scrollView scrollRectToVisible:self.keyboardToolbar.textField.frame animated:YES];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self scrollView:self.scrollView toFocusTextField:textField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UIPickerView
#pragma

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 50;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSArray *states = [NSArray arrayWithObjects:@"AL", @"AK", @"AZ", @"AR", @"CA", @"CO", @"CT", @"DE", @"FL", @"GA", @"HI", @"ID", @"IL", @"IN", @"IA", @"KS", @"KY", @"LA", @"ME", @"MD", @"MA", @"MI", @"MN", @"MS", @"MO", @"MT", @"NE", @"NV", @"NH", @"NJ", @"NM", @"NY", @"NC", @"ND", @"OH", @"OK", @"OR", @"PA", @"RI", @"SC", @"SD", @"TN", @"TX", @"UT", @"VT", @"VA", @"WA", @"WV", @"WI", @"WY", @"AS", @"DC", @"FM", @"GU", @"MH", @"MP", @"PR", @"PW", @"VI", nil];
    return [states objectAtIndex:row];
}

#pragma mark - Keyboard notifications
#pragma 

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    // Ensure the active textfield is visible
    NSDictionary* info = [aNotification userInfo];
    keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    [self scrollView:self.scrollView toFocusTextField:self.keyboardToolbar.textField];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
}

#pragma mark - Keyboard delegate
#pragma

- (BOOL)hasPrevious:(UIView *)view {
    if (view.tag == FPPC_SOURCE_MINIMUM_TAG) return NO;
    return YES;
}

- (BOOL)hasNext:(UIView *)view {
    if (view.tag == FPPC_SOURCE_MAXIMUM_TAG) return NO;
    return YES;
}

- (void)previous:(UIView *)view {
    [view resignFirstResponder];
    [[self.view viewWithTag:view.tag - 1] becomeFirstResponder];
}

- (void)next:(UIView *)view {
    [view resignFirstResponder];
    [[self.view viewWithTag:view.tag + 1] becomeFirstResponder];
}

@end
