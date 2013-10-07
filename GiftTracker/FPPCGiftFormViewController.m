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
- (id)view:(UIView *)view superviewWithClass:(Class)class;
#define FPPC_GIFT_SUMMARY_MINIMUM_TAG 1
#define FPPC_GIFT_SUMMARY_MAXIMUM_TAG 4
enum kFPPCNextPrevious {
    NEXT = 0,
    PREVIOUS
};
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
}

- (void)updateTextFieldAmount:(UITextField *)textField {
    
    // Save new amount value
    BOOL isSummaryView = [textField isKindOfClass:[FPPCSummaryField class]];
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
        id superview = [self view:textField superviewWithClass:[FPPCGiftFormCell class]];
        FPPCGiftFormCell *cell = (FPPCGiftFormCell *)superview;
        FPPCAmount *amount = ((FPPCAmount *)[self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForCell:cell]]);
        amount.value = [NSDecimalNumber decimalNumberWithDecimal:[[self.currencyFormatter numberFromString:textField.text] decimalValue]];
        
        // Update summary
        [self updateTotal];
    }
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

    // Fetch the data for this amount
    FPPCAmount *amount = [self.fetchedResultsController objectAtIndexPath:indexPath];
    ((FPPCGiftFormCell *)cell).amount.indexPath = indexPath;
    [amount addObservers];
    
    // Display source name and amount
    ((FPPCGiftFormCell *)cell).name.text = amount.source.name;
    ((FPPCGiftFormCell *)cell).amount.text = [self.currencyFormatter stringFromNumber:amount.value];
    return cell;
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
    NSDictionary* info = [aNotification userInfo];
    keyboardSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height-self.keyboardToolbar.frame.size.height, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    CGRect aRect = self.tableView.frame;
    aRect.size.height -= (keyboardSize.height+self.keyboardToolbar.frame.size.height);
    
    if ([self.keyboardToolbar.textField isKindOfClass:[FPPCAmountField class]]) {
        [self scrollToAmount:(FPPCAmountField *)self.keyboardToolbar.textField];
    }
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
}

#pragma mark - Keyboard delegate
#pragma

- (id)view:(UIView *)view superviewWithClass:(Class)class {
    id superview = view;
    for (int i=0; i<4; i++) {
        superview = [superview superview];
        if ([superview isKindOfClass:[UITableViewCell class]]) {
            return superview;
        }
    }
    return nil;
}

- (NSInteger)maxIndex {
    return FPPC_GIFT_SUMMARY_MAXIMUM_TAG;
}

- (BOOL)hasPrevious:(UIView *)view {
    return [self isField:(UITextField *)view inDirection:PREVIOUS];
}

- (BOOL)hasNext:(UIView *)view {
    return [self isField:(UITextField *)view inDirection:NEXT];
}

- (void)previous:(UIView *)view {
    UITextField *firstResponder = [self field:(UITextField *)view inDirection:PREVIOUS];
    if (firstResponder) {
        [view resignFirstResponder];
        [firstResponder becomeFirstResponder];
    }
}

- (void)next:(UIView *)view {
    UITextField *firstResponder = [self field:(UITextField *)view inDirection:NEXT];
    if (firstResponder) {
        [view resignFirstResponder];
        [firstResponder becomeFirstResponder];
    }
}

- (BOOL)isField:(UITextField *)field inDirection:(enum kFPPCNextPrevious)direction {
    if ((direction == PREVIOUS) && field.tag == 0 && [field isKindOfClass:[FPPCSummaryField class]]) {
        return NO;
    }
    else if ((direction == NEXT) && [field isKindOfClass:[FPPCAmountField class]] && (((FPPCAmountField *)field).indexPath.row+1) == [[[self fetchedResultsController] fetchedObjects] count]) {
        return NO;
    }
    else return YES;
}
- (BOOL)isAmountField:(UITextField *)field inDirection:(enum kFPPCNextPrevious)direction {
    if (direction == NEXT)
        return (!((field.tag < FPPC_GIFT_SUMMARY_MAXIMUM_TAG) && (field.tag >= FPPC_GIFT_SUMMARY_MINIMUM_TAG)));
    else
        return [field respondsToSelector:@selector(indexPath)] && ([(FPPCAmountField *)field indexPath].row > 0);
}
- (UITextField *)field:(UITextField *)field inDirection:(enum kFPPCNextPrevious)direction {
    if ([self isAmountField:field inDirection:direction]) {
        if (direction == NEXT) {
            if (field.tag == FPPC_GIFT_SUMMARY_MAXIMUM_TAG)
                [self scrollToFirstAmount];
            else
                [self scrollToAmount:(FPPCAmountField *)field inDirection:direction];
        } else {
            [self scrollToAmount:(FPPCAmountField *)field inDirection:direction];
        }
        return nil;
    } else {
        if (direction == NEXT)
            return [self summaryField:(FPPCSummaryField *)field inDirection:direction];
        else {
            if (field.tag > FPPC_GIFT_SUMMARY_MINIMUM_TAG)
                return [self summaryField:(FPPCSummaryField *)field inDirection:direction];
            else
                return [self lastSummaryField];
        }
    }
}
- (FPPCSummaryField *)summaryField:(FPPCSummaryField *)textField inDirection:(enum kFPPCNextPrevious)direction {
    NSInteger offset = (direction == NEXT) ? 1 : -1;
    return (FPPCSummaryField *)[self.view viewWithTag:textField.tag + offset];
}
- (FPPCSummaryField *)lastSummaryField {
    return (FPPCSummaryField *)[self.view viewWithTag:FPPC_GIFT_SUMMARY_MAXIMUM_TAG];
}
- (void)scrollToFirstAmount {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    self.keyboardToolbar.nextIndexPath = indexPath;
    [self scrollToAmountAtIndexPath:indexPath
                   atScrollPosition:UITableViewScrollPositionTop];
}
- (void)scrollToAmount:(FPPCAmountField *)textField {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.indexPath.row inSection:0];
    self.keyboardToolbar.nextIndexPath = indexPath;
    [self scrollToAmountAtIndexPath:indexPath
                   atScrollPosition:UITableViewScrollPositionTop];
}
- (void)scrollToAmount:(FPPCAmountField *)textField inDirection:(enum kFPPCNextPrevious)direction {
    NSInteger offset = (direction == NEXT) ? 1 : -1;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.indexPath.row+offset inSection:0];
    self.keyboardToolbar.nextIndexPath = indexPath;
    [self scrollToAmountAtIndexPath:indexPath
                   atScrollPosition:UITableViewScrollPositionTop];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self didScrollToAmount];
}

- (void)didScrollToAmount {
    if (self.keyboardToolbar.nextIndexPath) {
        FPPCGiftFormCell *cell = (FPPCGiftFormCell *)[self.tableView cellForRowAtIndexPath:self.keyboardToolbar.nextIndexPath];
        [self.keyboardToolbar setTextField:cell.amount];
        [cell.amount becomeFirstResponder];
    }
}

- (void)scrollToAmountAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UITableViewScrollPosition)position {
    
    CGFloat originalOffset = self.tableView.contentOffset.y;
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:position animated:NO];
    CGFloat offset = self.tableView.contentOffset.y;
    
    if (originalOffset == offset)
    {
        // scroll animation not required because it's already scrolled exactly there
        [self didScrollToAmount];
    }
    else
    {
        // We know it will scroll to a new position
        // Return to originalOffset. animated:NO is important
        [self.tableView setContentOffset:CGPointMake(0, originalOffset) animated:NO];
        // Do the scroll with animation so `scrollViewDidEndScrollingAnimation:` will execute
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:position animated:YES];
    }
}

@end
