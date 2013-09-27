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
#define NUMBER_OF_TEXT_FIELDS 9
@end

@implementation FPPCSourceFormViewController
@synthesize source;
@synthesize name, business, email, phone, lobbying, isLobbying, isLobbying_iOS6;
@synthesize street, street2, city, state, zipcode;
@synthesize scrollView;
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
    self.keyboardToolbar = [[FPPCToolbar alloc] initWithDelegate:self];
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
}

#pragma mark - Navigation Bar
#pragma

- (void)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    if ([delegate isMemberOfClass:[FPPCGiftFormViewController class]]) {
        [(FPPCGiftFormViewController *)self.delegate didAddSource:source];

    } else if ([delegate isMemberOfClass:[FPPCDashboardViewController class]]) {
        [(FPPCDashboardViewController *)self.delegate didAddSource:source];
        [TestFlight passCheckpoint:@"SOURCE - SAVE"];
    }
}

#pragma mark - Field validation
#pragma

- (BOOL)isValidEmail:(NSString *)emailString
{
    BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:emailString];
}

- (BOOL)isValidZipcode:(NSString *)zipcodeString
{
    NSString *zipcodeExpression = @"^[0-9]{5}(-/d{4})?$"; //U.S Zip ONLY
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:zipcodeExpression options:0 error:NULL];
    NSTextCheckingResult *match = [regex firstMatchInString:zipcodeString options:0 range:NSMakeRange(0, [zipcodeString length])];
    if (match) return true;
    return false;
}

- (BOOL)isValidPhone:(NSString *)phoneString
{
    NSString * const regularExpression = @"^([+-]{1})([0-9]{3})$";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regularExpression
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    if (error) {
        TFLog(@"ERROR: Failed to read phone number - %@", error);
    }
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:phoneString
                                                        options:0
                                                          range:NSMakeRange(0, [phoneString length])];
    return numberOfMatches > 0;
}

#pragma mark - UITextField
#pragma mark

- (NSInteger)maxIndex {
    return NUMBER_OF_TEXT_FIELDS;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    textField.inputAccessoryView = self.keyboardToolbar;
    [self.keyboardToolbar setTextField:textField];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= (keyboardSize.height+self.keyboardToolbar.frame.size.height+navigationBar.frame.size.height);
    aRect.origin.y = navigationBar.frame.size.height;
    CGPoint aPoint = CGPointMake(0,self.keyboardToolbar.textField.frame.origin.y-self.keyboardToolbar.textField.frame.size.height+navigationBar.frame.size.height);
    
    if (!CGRectContainsPoint(aRect, aPoint) ) {
        CGPoint scrollPoint = CGPointMake(0.0, self.keyboardToolbar.textField.frame.origin.y+aRect.size.height-keyboardSize.height+self.navigationBar.frame.size.height-self.keyboardToolbar.textField.frame.size.height);
        [scrollView setContentOffset:scrollPoint animated:YES];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    // Optional TODO: Validation warnings
//    if ([textField isEqual:phone]) {
//        if (![self isValidPhone:phone.text]) {
//            // TODO validation warning
//        }
//    }
//    else if ([textField isEqual:zipcode]) {
//        if (![self isValidZipcode:zipcode.text]) {
//            // TODO validation warning 
//        }
//    }
//    else if ([textField isEqual:email]) {
//        if (![self isValidEmail:email.text]) {
//            // TODO validation warning
//        }
//    }
    
    [textField resignFirstResponder];
    if (self.scrollView)[self.scrollView setContentOffset:CGPointZero animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (self.scrollView)[self.scrollView setContentOffset:CGPointZero animated:YES];
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

// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your application might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= (keyboardSize.height+self.keyboardToolbar.frame.size.height+navigationBar.frame.size.height);
    aRect.origin.y = navigationBar.frame.size.height;
    CGPoint aPoint = CGPointMake(0,self.keyboardToolbar.textField.frame.origin.y-self.keyboardToolbar.textField.frame.size.height+navigationBar.frame.size.height);
    
    if (!CGRectContainsPoint(aRect, aPoint) ) {
        CGPoint scrollPoint = CGPointMake(0.0, self.keyboardToolbar.textField.frame.origin.y+aRect.size.height-keyboardSize.height+self.navigationBar.frame.size.height-self.keyboardToolbar.textField.frame.size.height);
        [scrollView setContentOffset:scrollPoint animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
}

@end
