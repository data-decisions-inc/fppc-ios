//
//  FPPCGiftFormViewController.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/3/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCGiftFormViewController.h"
#import "FPPCSourceFormViewController.h"
#import "FPPCDashboardViewController.h"
#import "FPPCAmount.h"
#import "FPPCActionSheet.h"
#import "FPPCGiftsViewController.h"
#import "FPPCTextField.h"

@interface FPPCGiftFormViewController ()
- (void)updateTotal;
- (void)updateTextFieldAmount:(UITextField *)textField;
#define FPPC_GIFT_SUMMARY_MINIMUM_TAG 1
#define FPPC_GIFT_SUMMARY_MAXIMUM_TAG 4
enum kFPPCNextPrevious {
    NONE = 0,
    NEXT,
    PREVIOUS
};
@property (nonatomic, assign) NSInteger nextPreviousFlag;
- (void)nextField:(UIView *)view;
- (void)previousField:(UIView *)view;
- (void)scrollView:(UIScrollView *)scrollView toFocusTextField:(UITextField *)textField;
- (void)scrollView:(UIScrollView *)scrollView toFocusIndexPath:(NSIndexPath *)indexPath;
@end

@implementation FPPCGiftFormViewController
@synthesize name, month, day, year;
@synthesize keyboardToolbar;
@synthesize gift;
@synthesize months;
@synthesize delegate;
@synthesize source = _source;
@synthesize sourceCell, tableView = _tableView;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize dayPickerView, monthPickerView, yearPickerView;
@synthesize navigationBar;
@synthesize nextPreviousFlag;

#pragma mark - View lifecycle
#pragma

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Create input accessory view for keyboard
    self.keyboardToolbar = [[FPPCToolbar alloc] initWithController:self];
    [self registerForKeyboardNotifications];
    
    // Display summary
    self.name.text = self.gift.name;
    NSDateComponents *date = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit|NSDayCalendarUnit|NSYearCalendarUnit fromDate:self.gift.date ? self.gift.date : [NSDate date]];
    self.day.text = [NSString stringWithFormat:@"%02d", date.day];
    self.month.text = [NSString stringWithFormat:@"%02d", date.month];
    self.year.text = [NSString stringWithFormat:@"%d", date.year];
    
    NSDecimalNumber *total = [NSDecimalNumber zero];
    for (FPPCAmount *amount in gift.amount) {
        total = [total decimalNumberByAdding:amount.value];
    }
    self.total.text = [self.currencyFormatter stringFromNumber:total];
    
    // Initialize pickers
    if (self.months.count == 0) {
        self.months = [[NSMutableArray alloc] init];
        for (int i=1; i<=12; i++) {
            [self.months addObject:[NSString stringWithFormat:@"%02d",i]];
        }
    }
    if (!dayPickerView) {
        dayPickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
        dayPickerView.delegate = self;
        dayPickerView.showsSelectionIndicator = YES;
        self.day.inputView = dayPickerView;
    }
    if (!monthPickerView) {
        monthPickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
        monthPickerView.delegate = self;
        monthPickerView.showsSelectionIndicator = YES;
        self.month.inputView = monthPickerView;
    }
    if (!yearPickerView) {
        yearPickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
        yearPickerView.delegate = self;
        yearPickerView.showsSelectionIndicator = YES;
        self.year.inputView = yearPickerView;
    }
    
    // Setup navigation bar
    self.navigationItem.title = self.gift? @"Edit Gift" : @"New Gift";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(edit)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(add)];
    
    [self.tableView setEditing:YES animated:NO];
    
    if (self.gift) {
        if (self.source)
            [TestFlight passCheckpoint:@"DASHBOARD - SOURCE - VIEW - EDIT GIFT"];
        else
            [TestFlight passCheckpoint:@"DASHBOARD - GIFTS - EDIT GIFT"];
    }
    else
        [TestFlight passCheckpoint:@"DASHBOARD - SOURCE - VIEW - NEW GIFT"];
    
    [self scrollToFirstAmount];
}

- (void)updateTotal {
    NSDecimalNumber *total = [NSDecimalNumber zero];
    for (FPPCAmount *amount in [self.fetchedResultsController fetchedObjects]) {
        total = [total decimalNumberByAdding:amount.value];
    }
    self.total.text = [self.currencyFormatter stringFromNumber:total];
}

- (void)dealloc {
    _fetchedResultsController.delegate = nil;
}

#pragma mark - UITextField
#pragma

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {

    // Present the custom accessory view for this keyboard
    textField.inputAccessoryView = self.keyboardToolbar;
    [self.keyboardToolbar setTextField:textField];
    
    // Default month, year and day values
    if ([textField isEqual:self.month] && (textField.text.length != 0)) {
        NSDateComponents *date = [self dateComponents];
        [self.monthPickerView selectRow:date.month-1 inComponent:0 animated:YES];
    }
    else if ([textField isEqual:self.year] && textField.text.length !=0){
        [self.yearPickerView selectRow:0 inComponent:0 animated:YES];
    } else if ([textField isEqual:self.day]) {
        NSDateComponents *today = [[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:[NSDate date]];
        [self.dayPickerView selectRow:today.day-1 inComponent:0 animated:YES];
    }

    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self scrollView:self.tableView toFocusTextField:textField];
}

- (void)updateTextFieldAmount:(UITextField *)textField {
    
    // Save new amount value
    BOOL isSummaryView = [textField isKindOfClass:[FPPCSummaryField class]];
    FPPCAmount *amount = nil;
    FPPCAmountField *field = (FPPCAmountField *)textField;
    NSDecimalNumber *oldValue = nil;
    if (!isSummaryView) {
        
        // Keep currency format
        NSNumber *value = [self.currencyFormatter numberFromString:textField.text];
        if (!value) {
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
            value = [numberFormatter numberFromString:textField.text];
        }
        if (!value) value = [NSNumber numberWithInt:0];
        textField.text = [self.currencyFormatter stringFromNumber:value];
        
        // Save if this is an amount field
        NSArray *objects = self.fetchedResultsController.fetchedObjects;
        NSInteger row = [objects indexOfObject:field.amount];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        
        amount = ((FPPCAmount *)[self.fetchedResultsController objectAtIndexPath:indexPath]);
        oldValue = amount.value;
        amount.value = [NSDecimalNumber decimalNumberWithDecimal:[[self.currencyFormatter numberFromString:textField.text] decimalValue]];
        
        // Update summary
        [self updateTotal];
    }
    
    // Navigation happens after the amount is updated in the fetchedresultscontroller
    if ([self nextPreviousFlag] == NEXT) {
        if ([oldValue isEqual:amount.value])
            [self setNextPreviousFlag:NONE];
    } else if ([self nextPreviousFlag] == PREVIOUS) {
        if ([oldValue isEqual:amount.value])
            [self setNextPreviousFlag:NONE];
    } else
        [textField resignFirstResponder];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self updateTextFieldAmount:textField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self updateTextFieldAmount:textField];
    return YES;
}

#pragma mark - UIPickerView
#pragma

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if ([pickerView isEqual:dayPickerView]) {
        return [NSString stringWithFormat:@"%02d",row+1];
    } else if ([pickerView isEqual:monthPickerView]) {
        return [months objectAtIndex:row];
    } else {
        NSDateComponents *c = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]];
        return [NSString stringWithFormat:@"%d",c.year-row];
    }
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if ([pickerView isEqual:dayPickerView]) {
        // number of days in the active month
        return [[NSCalendar currentCalendar] rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:[self date]].length;
    } else if ([pickerView isEqual:monthPickerView]) {
        // number of months in a year
        return months.count;
    } else {
        // Minimum date is January 2010
        NSDateComponents *components = [[NSDateComponents alloc] init];
        [components setDay:1];
        [components setMonth:1];
        [components setYear:2010];
        NSDate *minimumDate = [[NSCalendar currentCalendar] dateFromComponents:components];
        NSDate *today = [NSDate date];
        NSDateComponents *c = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:minimumDate toDate:today options:0];
        return c.year;
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if ([pickerView isEqual:self.monthPickerView]) {
        self.month.text = [self pickerView:self.monthPickerView titleForRow:row forComponent:component];
        [self.month resignFirstResponder];
    } else if ([pickerView isEqual:self.yearPickerView]) {
        self.year.text = [self pickerView:self.yearPickerView titleForRow:row forComponent:component];
        [self.year resignFirstResponder];
    } else {
        self.day.text = [self pickerView:self.dayPickerView titleForRow:row forComponent:component];
        [self.day resignFirstResponder];
    }
}

#pragma mark - Segue
#pragma 

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"addExistingSource"]) {
        [[segue destinationViewController] setDelegate:self];
        [[segue destinationViewController] setDate:[self date]];
        [[segue destinationViewController] setDateComponents:[self dateComponents]];
        [[segue destinationViewController] setGift:self.gift];
    }
}

#pragma mark - Source form delegate
#pragma 

- (void)didAddSource:(FPPCSource *)source
{
    // Add source to gift
    FPPCAmount *amount = (FPPCAmount *)[NSEntityDescription insertNewObjectForEntityForName:@"FPPCAmount" inManagedObjectContext:((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext];
    amount.value = [NSDecimalNumber zero];
    amount.source = source;
    [self.gift addAmountObject:amount];
    
    // Update view
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Navigation bar
#pragma

- (IBAction)cancel:(id)sender {

    // Remove object from context
    NSUndoManager *undoManager = [((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext undoManager];
    [undoManager endUndoGrouping];
    [undoManager undoNestedGroup];

    if (self.gift && self.source) {
        [((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext deleteObject:self.gift];
    }

    [self.delegate didUpdateGift:nil];
}

- (IBAction)save:(id)sender {
    
    // Create and configure a new Gift
    BOOL isNewGift = !self.gift;
    if (isNewGift) {
        self.gift = (FPPCGift *)[NSEntityDescription insertNewObjectForEntityForName:@"FPPCGift" inManagedObjectContext:((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext];
    }
    
    // Update gift with new values
    self.gift.date = [self date];
    self.gift.name = self.name.text;
    
    // Commit changes to the persistent store
    NSUndoManager *undoManager = [((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext undoManager];
    [undoManager endUndoGrouping];
    [(FPPCAppDelegate *)[[UIApplication sharedApplication] delegate] saveContext];
    
    // Pass this source back to the dashboard
    [self.delegate didUpdateGift:self.gift];

    [TestFlight passCheckpoint:@"GIFT - SAVE"];
}

#pragma mark - Table view
#pragma 

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.fetchedResultsController fetchedObjects].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // Initialize custom cell
    static NSString *CellIdentifier = @"FPPCGiftFormCell";
    FPPCGiftFormCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"FPPCGiftFormCell" owner:self options:nil];
        cell = self.sourceCell;
        self.sourceCell = nil;
    }
    
    // Update custom cell
    [self tableView:tableView configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (id)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    FPPCGiftFormCell *giftFormCell = (FPPCGiftFormCell *)cell;
    giftFormCell.selectionStyle = UITableViewCellSelectionStyleNone;

    // Fetch the data for this amount
    FPPCAmount *amount = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if ([giftFormCell.amount isKindOfClass:[FPPCAmountField class]])
        ((FPPCAmountField *)giftFormCell.amount).amount = amount;
    [amount addObservers];
    
    // Display source name and amount
    giftFormCell.name.text = amount.source.name;
    giftFormCell.amount.text = [self.currencyFormatter stringFromNumber:amount.value];
    return giftFormCell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Delete the row from the data source
        [self.fetchedResultsController.managedObjectContext deleteObject:[self.fetchedResultsController  objectAtIndexPath:indexPath]];
        [self updateTotal];
    }
}

#pragma mark - Formatted dates & numbers
#pragma 

- (NSDate *)date {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = [self.year.text integerValue];
    dateComponents.month = [[formatter numberFromString:self.month.text] integerValue];
    dateComponents.day = [[formatter numberFromString:self.day.text] integerValue];

    return [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
}

- (NSDateComponents *)dateComponents {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = [self.year.text integerValue];
    dateComponents.month = [[formatter numberFromString:self.month.text] integerValue];
    dateComponents.day = [[formatter numberFromString:self.day.text] integerValue];
    return dateComponents;
}

#pragma mark - FetchedResults
#pragma

- (NSFetchedResultsController *)fetchedResultsController {

    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    // Set up the fetched results controller.
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"FPPCAmount" inManagedObjectContext:((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Only fetch amounts related to this gift
    NSPredicate *giftPredicate = [NSPredicate predicateWithFormat:@"gift == %@", self.gift];
    [fetchRequest setPredicate:giftPredicate];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortByValue = [[NSSortDescriptor alloc]
                              initWithKey:@"value" ascending:YES];
    NSSortDescriptor *sortByName = [[NSSortDescriptor alloc]
                              initWithKey:@"source.name" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:sortByValue,sortByName, nil]];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:nil];
    
    theFetchedResultsController.delegate = self;
    self.fetchedResultsController = theFetchedResultsController;
    
    NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    TFLog(@"ERROR: Failed to perform fetch - %@, %@", error, [error userInfo]);
	    [self showErrorMessage];
	}
    
    return _fetchedResultsController;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self tableView:self.tableView configureCell:[tableView cellForRowAtIndexPath:indexPath]
                atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            
            NSInteger row;
            NSIndexPath *path;
            if ([self nextPreviousFlag] == PREVIOUS) {
                if (newIndexPath.row < indexPath.row)
                    row = indexPath.row;
                else
                    row = indexPath.row - 1;
            } else if ([self nextPreviousFlag] == NEXT) {
                if (newIndexPath.row > indexPath.row)
                    row = indexPath.row;
                else
                    row = indexPath.row + 1;
            }
            
            if ([self nextPreviousFlag]) {
                [self setNextPreviousFlag:NONE];
                path = [NSIndexPath indexPathForRow:row inSection:0];
                [self scrollView:self.tableView toFocusIndexPath:path];
            }
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
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
    
    [self.tableView setEditing:NO animated:YES];
    [self scrollView:self.tableView toFocusTextField:self.keyboardToolbar.textField];
}
- (void)keyboardWillBeHidden:(NSNotification *)aNotification {
//    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.total.frame.size.height, 0.0, 0.0, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    [self.tableView setEditing:YES animated:YES];

}

#pragma mark - Keyboard delegate
#pragma
    
- (void)scrollView:(UIScrollView *)scrollView toFocusIndexPath:(NSIndexPath *)indexPath {
    FPPCGiftFormCell *cell = (FPPCGiftFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.tableView.frame.size.height, 0.0, keyboardSize.height, 0.0);
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
    
    CGRect aRect = self.view.frame;
    aRect.origin.y = self.tableView.frame.origin.y;
    aRect.size.height -= (keyboardSize.height+self.keyboardToolbar.frame.size.height+self.tableView.frame.origin.y);
    CGPoint aPoint = CGPointMake(0,cell.frame.origin.y-cell.amount.frame.size.height+navigationBar.frame.size.height);
    
    if (!CGRectContainsPoint(aRect, aPoint) ) {
        CGPoint scrollPoint = CGPointMake(0.0, cell.frame.origin.y-self.total.frame.size.height);
        [scrollView setContentOffset:scrollPoint animated:YES];
    }
    
    contentInsets = UIEdgeInsetsMake(self.tableView.frame.size.height, 0.0, keyboardSize.height, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    [self.tableView setEditing:YES animated:YES];
}

- (void)scrollView:(UIScrollView *)scrollView toFocusTextField:(UITextField *)textField {
    BOOL isIOS7 = [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0;

    UIEdgeInsets contentInsets;
    if (isIOS7)
        contentInsets = UIEdgeInsetsMake(self.total.frame.size.height, 0.0, keyboardSize.height-self.keyboardToolbar.frame.size.height, 0.0);
    else
        contentInsets = UIEdgeInsetsMake(self.total.frame.size.height, 0.0, keyboardSize.height, 0.0);
    scrollView.contentInset = contentInsets;
    scrollView.scrollIndicatorInsets = contentInsets;
    
    CGRect aRect = self.view.frame;
    aRect.origin.y = self.tableView.frame.origin.y;
    aRect.size.height -= (keyboardSize.height+self.keyboardToolbar.frame.size.height+self.tableView.frame.origin.y);
    CGPoint aPoint = CGPointMake(0,textField.frame.origin.y-textField.frame.size.height+navigationBar.frame.size.height);
    
    if ([textField isKindOfClass:[FPPCAmountField class]]) {
        if (!CGRectContainsPoint(aRect, aPoint) ) {
            
            FPPCAmountField *field = (FPPCAmountField *)textField;
            NSArray *objects = self.fetchedResultsController.fetchedObjects;
            NSInteger row = [objects indexOfObject:field.amount];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            
            FPPCGiftFormCell *cell = (FPPCGiftFormCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            
            CGPoint scrollPoint = CGPointMake(0.0, cell.frame.origin.y-self.total.frame.size.height);
            [scrollView setContentOffset:scrollPoint animated:YES];
        }
    }
}

- (void)scrollToFirstAmount {
    FPPCAmountField *newField = ((FPPCGiftFormCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).amount;
    [self scrollView:self.tableView toFocusTextField:newField];
}

- (BOOL)hasPrevious:(UIView *)view {
    return YES;
    if ([view isKindOfClass:[FPPCSummaryField class]]) {
        if (view.tag == FPPC_GIFT_SUMMARY_MINIMUM_TAG)
            return NO;
    }
    else if (![view isKindOfClass:[FPPCAmountField class]]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"You must add a case to handle %@ in %@", [view class], NSStringFromSelector(_cmd)]
                                     userInfo:nil];
    }
    return YES;
}

- (BOOL)hasNext:(UIView *)view {
    return YES;
    if ([view isKindOfClass:[FPPCSummaryField class]]) {
        if (view.tag == FPPC_GIFT_SUMMARY_MAXIMUM_TAG && self.fetchedResultsController.fetchedObjects.count == 0)
            return NO;
    }
    else if ([view isKindOfClass:[FPPCAmountField class]]) {
        FPPCAmountField *field = (FPPCAmountField *)view;
        NSArray *objects = self.fetchedResultsController.fetchedObjects;
        NSInteger row = [objects indexOfObject:field.amount];
        if (row == objects.count-1)
            return NO;
    }
    else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"You must add a case to handle %@ in %@", [view class], NSStringFromSelector(_cmd)]
                                     userInfo:nil];
    }
    return YES;
}

- (void)previous:(UIView *)view {
    [self setNextPreviousFlag:PREVIOUS];
    [self previousField:view];
    [view resignFirstResponder];
}

- (void)next:(UIView *)view {
    [self setNextPreviousFlag:NEXT];
    [self nextField:view];
    [view resignFirstResponder];
}

- (void)previousField:(UIView *)view {
    if ([view isKindOfClass:[FPPCSummaryField class]]) {
        if (!(view.tag == FPPC_GIFT_SUMMARY_MINIMUM_TAG))
            [[self.view viewWithTag:view.tag - 1] becomeFirstResponder];
        else {
            FPPCAmountField *newField = ((FPPCGiftFormCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.fetchedResultsController.fetchedObjects.count-1 inSection:0]]).amount;
            [newField becomeFirstResponder];
        }
    }
    else if ([view isKindOfClass:[FPPCAmountField class]]) {
        FPPCAmountField *field = (FPPCAmountField *)view;
        NSArray *objects = self.fetchedResultsController.fetchedObjects;
        NSInteger row = [objects indexOfObject:field.amount];
        if (row == 0) {
            [[self.view viewWithTag:FPPC_GIFT_SUMMARY_MAXIMUM_TAG] becomeFirstResponder];
        } else {
            FPPCAmountField *newField = ((FPPCGiftFormCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row-1 inSection:0]]).amount;
            [newField becomeFirstResponder];
        }
    }
    else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"You must add a case to handle %@ in %@", [view class], NSStringFromSelector(_cmd)]
                                     userInfo:nil];
    }
}

- (void)nextField:(UIView *)view {
    if ([view isKindOfClass:[FPPCSummaryField class]]) {
        if (view.tag != FPPC_GIFT_SUMMARY_MAXIMUM_TAG)
            [[self.view viewWithTag:view.tag + 1] becomeFirstResponder];
        else {
            FPPCAmountField *newField = ((FPPCGiftFormCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).amount;
            [newField becomeFirstResponder];
        }
    }
    else if ([view isKindOfClass:[FPPCAmountField class]]) {
        FPPCAmountField *field = (FPPCAmountField *)view;
        NSArray *objects = self.fetchedResultsController.fetchedObjects;
        NSInteger row = [objects indexOfObject:field.amount];
        
        if (row == [objects count]-1)
            [[self.view viewWithTag:FPPC_GIFT_SUMMARY_MINIMUM_TAG] becomeFirstResponder];
        else {
            FPPCAmountField *newField = ((FPPCGiftFormCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row+1 inSection:0]]).amount;
            [newField becomeFirstResponder];
        }
    }
    else {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"You must add a case to handle %@ in %@", [view class], NSStringFromSelector(_cmd)]
                                     userInfo:nil];
    }
}

@end
