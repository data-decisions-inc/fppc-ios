//
//  FPPCDashboardViewController.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/3/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCDashboardViewController.h"
#import <DHxls/DHWorkBook.h>
#import "FPPCSource.h"
#import "FPPCAmount.h"
#import "FPPCSourceFormViewController.h"
#import "FPPCSourceViewController.h"
#import "FPPCGiftsViewController.h"
#import "UIColor+FPPC.h"
#import "FPPCActionSheet.h"

@interface FPPCDashboardViewController ()
#define NUMBER_OF_TEXT_FIELDS 2
@end

@implementation FPPCDashboardViewController
@synthesize month, year;
@synthesize monthValue, yearValue;
@synthesize monthGifts, yearGifts;
@synthesize keyboardToolbar;
@synthesize monthPickerView, yearPickerView;
@synthesize months;
@synthesize fetchedResultsController = _fetchedResultsController;

#pragma mark - View lifecycle
#pragma

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set this for the search and table methods of the superclass
    self.delegate = self;
    
    // Create input accessory view for keyboard
    self.keyboardToolbar = [[FPPCToolbar alloc] initWithDelegate:self];
    
    // Initialize month and year picker
    self.months = [NSArray arrayWithObjects:@"January",@"February",@"March",@"April",@"May",@"June",@"July",@"August",@"September",@"October",@"November",@"December", nil];
    self.yearPickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
    self.monthPickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];
    self.yearPickerView.delegate = self;
    self.monthPickerView.delegate = self;
    self.yearPickerView.showsSelectionIndicator = YES;
    self.monthPickerView.showsSelectionIndicator = YES;
    self.year.inputView = self.yearPickerView;
    self.month.inputView = self.monthPickerView;

    // Initialize month and year fields with default values
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit|NSYearCalendarUnit fromDate:[NSDate date]];
    self.year.text = [NSString stringWithFormat:@"%d",today.year];
    self.month.text = [self.months objectAtIndex:today.month-1];
}

- (void)viewDidAppear:(BOOL)animated {
    [self reloadTableView];
    [TestFlight passCheckpoint:@"DASHBOARD - OPEN"];
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
                                   entityForName:@"FPPCSource" inManagedObjectContext:((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:@"name" ascending:YES];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:@"Root"];
    
    theFetchedResultsController.delegate = self;
    self.fetchedResultsController = theFetchedResultsController;
    
    NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    TFLog(@"ERROR: Failed to perform fetch - %@, %@", error, [error userInfo]);
	    [self showErrorMessage];
	}
    
    return _fetchedResultsController;
}

#pragma mark - Table view
#pragma

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FPPCActionSheet *sourceActionSheet = [[FPPCActionSheet alloc] initWithTitle:@"What would you like to do?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Edit",@"Add Gift",@"Details", nil];
                                          
    sourceActionSheet.delegate = self;
    [sourceActionSheet setIndexPath:indexPath];
    [sourceActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

#pragma mark - Table view helpers
#pragma

- (void)reloadTableView {
    [self reloadSummary];
    [super reloadTableView];
}

- (void)reloadSummary {
    
    // Update month and year values
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit|NSYearCalendarUnit fromDate:[self date]];
    NSMutableSet *yearGiftsSet = [[NSMutableSet alloc] init];
    NSMutableSet *monthGiftsSet = [[NSMutableSet alloc] init];;
    double yearGiftsSum = 0, monthGiftsSum = 0;
    for (FPPCSource *source in [self.fetchedResultsController fetchedObjects]) {
        for (FPPCAmount *amount in source.amount) {
            for (FPPCGift *gift in amount.gift) {
                NSDateComponents *c = [[NSCalendar currentCalendar] components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:gift.date];
                if (today.year == c.year) {
                    [yearGiftsSet addObject:gift];
                    yearGiftsSum += [amount.value doubleValue];
                    if (today.month == c.month) {
                        [monthGiftsSet addObject:gift];
                        monthGiftsSum += [amount.value doubleValue];
                    }
                }
            }
        }
    }
    self.monthGifts.text = [NSString stringWithFormat:@"%d gift%@",monthGiftsSet.count,(monthGiftsSet.count == 1)?@"":@"s"];
    self.yearGifts.text = [NSString stringWithFormat:@"%d gift%@",yearGiftsSet.count,(monthGiftsSet.count == 1)?@"":@"s"];
    self.monthValue.text = [self.currencyFormatter stringFromNumber:[NSNumber numberWithDouble:monthGiftsSum]];
    self.yearValue.text = [self.currencyFormatter stringFromNumber:[NSNumber numberWithDouble:yearGiftsSum]];
}

#pragma mark - Date and Year Pickers
#pragma

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if ([pickerView isEqual:self.monthPickerView]) {
        return self.months.count;
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

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    if ([pickerView isEqual:self.monthPickerView]) {
        return [self.months objectAtIndex:row];
    } else {
        NSDateComponents *c = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]];
        
        return [NSString stringWithFormat:@"%d",c.year-row];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if ([pickerView isEqual:self.monthPickerView]) {
        self.month.text = [self pickerView:self.monthPickerView titleForRow:row forComponent:component];
        [self reloadTableView];
        [self.month resignFirstResponder];
    } else {
        self.year.text = [self pickerView:self.yearPickerView titleForRow:row forComponent:component];
        [self reloadTableView];
        [self.year resignFirstResponder];
    }
    
    [TestFlight passCheckpoint:@"DASHBOARD - SORT BY DATE"];
}

- (IBAction)emailExcelFile:(id)sender {
    [TestFlight passCheckpoint:@"DASHBOARD - EXPORT"];

    if ([MFMailComposeViewController canSendMail]) {        
        // Prepare mail composer
        MFMailComposeViewController *emailViewController = [[MFMailComposeViewController alloc] init];
        emailViewController.mailComposeDelegate = self;
        
        // Populate message
        [emailViewController setSubject:@"Excel file exported from Gift Tracking App"];
        [emailViewController setMessageBody:@"This is an automated email sent from iOS FPPC Gift Tracking App.\
         Attached is the filled out Schedule D of form 700." isHTML:NO];
        
        // Initialize spreadsheet
        DHCell *cell;
        DHWorkBook *workbook = [DHWorkBook new];
        DHWorkSheet *worksheet = [workbook workSheetWithName:@"ScheduleD"];
        
        // Prepare columns
        NSArray *columnNames = [NSArray arrayWithObjects:@"NAME OF SOURCE", @"ADDRESS OF SOURCE (BUSINESS ADDRESS ACCEPTABLE)", @"ZIP CODE", @"BUSINESS ACTIVITY, IF ANY, OF SOURCE", @"DATE (MM/DD/YYYY)", @"VALUE", @"DESCRIPTION OF GIFT(S)", nil];
        
        enum columns {
            NAME,
            ADDRESS,
            ZIP,
            BUSINESS,
            DATE,
            VALUE,
            DESCRIPTION
        };
        
        static int COLUMN_WIDTH = 3000;
        static int HEADER_ROW = 0;
        
        // Prepare date and number formats
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"MM/dd/yyyy"];
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setNumberStyle: NSNumberFormatterDecimalStyle];
        [numberFormatter setMaximumFractionDigits:2];
        [numberFormatter setMinimumFractionDigits:2];
        
        // Fetch visible sources
        NSArray *sources = [self.searchDisplayController isActive] ? self.searchResults : [self.fetchedResultsController fetchedObjects];
        
        NSArray *amounts;
        FPPCAmount *amount;
        NSString *text;
        
        // Fill columns and rows
        for ( int i=0; i<columnNames.count; i++ ) {
            [worksheet width:COLUMN_WIDTH col:i format:NULL];
            cell = [worksheet label:[columnNames objectAtIndex:i] row:HEADER_ROW col:i];
            [cell horzAlign:HALIGN_RIGHT];
            
            for ( FPPCSource *source in sources ) {
                
                amounts = [source.amount allObjects];
                for ( int j=1; j<=amounts.count; j++ ) {
                    amount = (FPPCAmount *)[amounts objectAtIndex:j-1];

                    switch (i) {
                        case NAME: {
                            text = source.name ? source.name : @"";
                            break;
                        }
                        case ADDRESS: {
                            NSArray *addressField = @[@"street", @"street2", @"city", @"state", @"zipcode"];
                            NSMutableArray *addressArray = [[NSMutableArray alloc] init];
                            for (NSString *field in addressField) {
                                if (((NSString *)[source valueForKey:field]).length != 0)
                                    [addressArray addObject:[source valueForKey:field]];
                            }
                            
                            text = (addressArray.count == 0) ? @"" : [addressArray componentsJoinedByString:@", "];
                            break;
                        }
                        case ZIP: {
                            text = (source.zipcode.length == 0) ? @"" : source.zipcode;
                            break;
                        }
                        case BUSINESS: {
                            text = (source.business.length == 0) ? @"" : source.business;
                            break;
                        }
                        case DATE: {
                            text = [dateFormatter stringFromDate:((FPPCGift *)[amount.gift anyObject]).date];
                            break;
                        }
                        case VALUE: {
                            NSString *number = [numberFormatter stringFromNumber:amount.value];
                            text = (number.length == 0) ? @"" : number;
                            break;
                        }
                        case DESCRIPTION: {
                            NSString *name = ((FPPCGift *)[amount.gift anyObject]).name;
                            text = (name.length == 0) ?  @"" : name;
                            break;
                        }
                        default:
                            break;
                    }
                    cell = [worksheet label:text row:j col:i];
                    [cell horzAlign:HALIGN_RIGHT];
                }
            }
        }
        
        // Export spreadsheet
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *appFile = [documentsDirectory stringByAppendingPathComponent:@"ScheduleD.xls"];
        [workbook writeFile:appFile];
        
        // Was the spreadsheet succesfully created?
        if ([[NSFileManager defaultManager] fileExistsAtPath:appFile]) {
                        
            // Email spreadsheet
            NSData *spreadsheet = [[NSFileManager defaultManager] contentsAtPath:appFile];
            [emailViewController addAttachmentData:spreadsheet mimeType:@"application/excel" fileName:@"ScheduleD.xls"];
            
            [TestFlight passCheckpoint:@"DASHBOARD - EXPORT - SPREADSHEET"];
        }
        else {
            TFLog(@"ERROR: Failed to create spreadsheet.");
        }
                
        // Setup custom navbar
        UIColor *navBarColor = [UIColor FPPCBlueColor];
        emailViewController.navigationBar.tintColor = navBarColor;
        
        // Display mail composer
        [self presentViewController:emailViewController animated:YES completion:nil];
        [TestFlight passCheckpoint:@"DASHBOARD - EXPORT - SPREADSHEET - COMPOSE"];
    }
}

#pragma mark - Formatted dates & numbers
#pragma

- (NSDate *)date {
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = [self.year.text integerValue];
    dateComponents.month = [self.months indexOfObject:self.month.text]+1;
    return [[NSCalendar currentCalendar] dateFromComponents:dateComponents];
}

- (NSDateComponents *)dateComponents {
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = [self.year.text integerValue];
    dateComponents.month = [self.months indexOfObject:self.month.text]+1;
    return dateComponents;
}

#pragma mark - UITextField
#pragma 

- (NSInteger)maxIndex {
    return NUMBER_OF_TEXT_FIELDS;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    // Present the custom accessory view for this keyboard
    textField.inputAccessoryView = self.keyboardToolbar;
    [self.keyboardToolbar setTextField:textField];
    
    // Default month, year and day values
    if ([textField isEqual:self.month] && (textField.text.length != 0)) {
        [self.monthPickerView selectRow:[self.months indexOfObject:self.month.text] inComponent:0 animated:YES];
    }
    else if (textField.text.length !=0){
        NSDateComponents *c = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]];
        NSInteger row = c.year-[self.year.text integerValue];
        [self.yearPickerView selectRow:row inComponent:0 animated:YES];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - MFMailComposeViewControllerDelegate methods
#pragma 

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    // Cancelled: exit and do nothing
    if (result == MFMailComposeResultCancelled) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    //Sent: email was sent successfully!
    if (result == MFMailComposeResultSent) {
        [self dismissViewControllerAnimated:YES completion:nil];        
        return;
    }
    
    //Failure: email was neither saved nor sent
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
        alert.delegate = self;
        
        switch (result) {
            case MFMailComposeResultSaved:
                alert.message = @"Message Saved";
                [TestFlight passCheckpoint:@"DASHBOARD - EXPORT - SPREADSHEET - COMPOSE - SENT"];
                break;
            case MFMailComposeResultFailed:
                alert.message = @"Message Failed";
                break;
            default:
                alert.message = @"Message Not Sent";
                break;
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
        [alert show];
    }
}

#pragma mark - Segue
#pragma

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"presentGifts"]) {
        [(FPPCGiftsViewController *)[segue destinationViewController] setDate:[self date]];
    }
    else if ([[segue identifier] isEqualToString:@"editSource"] || [[segue identifier] isEqualToString:@"addGift"] || [[segue identifier] isEqualToString:@"viewSource"]) {
        FPPCSource *source;
        NSIndexPath *indexPath;
        if ([self.searchDisplayController isActive]) {
            indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
            source = [self.searchResults objectAtIndex:indexPath.row];
        }
        else {
            indexPath = [self.tableView indexPathForSelectedRow];
            source = [[self.fetchedResultsController fetchedObjects] objectAtIndex:indexPath.row];
        }
        if ([[segue identifier] isEqualToString:@"addGift"]) {
            [TestFlight passCheckpoint:@"DASHBOARD - GIFT - ADD"];

            // Create and configure a new Gift
            NSUndoManager *undoManager = [((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext undoManager];
            [undoManager beginUndoGrouping];

            FPPCGift *gift = (FPPCGift *)[NSEntityDescription insertNewObjectForEntityForName:@"FPPCGift" inManagedObjectContext:((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext];
            gift.date = [NSDate date];
            FPPCAmount *amount = (FPPCAmount *)[NSEntityDescription insertNewObjectForEntityForName:@"FPPCAmount" inManagedObjectContext:((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext];
            amount.value = [NSNumber numberWithInt:0];
            [amount addSourceObject:source];
            [gift addAmountObject:amount];
                        
            [(FPPCGiftFormViewController *)[segue destinationViewController] setGift:gift];
            [[segue destinationViewController] setSource:source];
            
        }
        else if ([[segue identifier] isEqualToString:@"editSource"]) {
            [TestFlight passCheckpoint:@"DASHBOARD - SOURCE - EDIT"];
            [(FPPCSourceFormViewController *)[segue destinationViewController] setSource:source];
        }
        else if ([[segue identifier] isEqualToString:@"viewSource"]) {
            [TestFlight passCheckpoint:@"DASHBOARD - SOURCE - VIEW"];
            [(FPPCSourceViewController *)[segue destinationViewController] setSource:source];
        }
        [[segue destinationViewController] setDelegate:self];
    }
    
    else if ([[segue identifier] isEqualToString:@"addSource"]) {
        [TestFlight passCheckpoint:@"DASHBOARD - SOURCE - ADD"];
        [[segue destinationViewController] setDelegate:self];
    }
    
    // Remove row highlight
    [self deselectTableViewCell];
}

#pragma mark - Form delegate
#pragma 
- (void)didAddSource:(FPPCSource *)source
{
    [self reloadTableView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didAddGift
{
    [self reloadTableView];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Search
#pragma
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
}

@end
