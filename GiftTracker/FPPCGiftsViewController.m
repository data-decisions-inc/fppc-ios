//
//  FPPCGiftsViewController.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/14/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCGiftsViewController.h"
#import "FPPCDashboardViewController.h"
#import "FPPCAmount.h"

@implementation FPPCGiftsViewController
@synthesize fetchedResultsController = _fetchedResultsController;

#pragma mark - Table view
#pragma
- (id)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    // We maintain two sets of data (one for search results and one pre-search)
    // Fetch the appropriate data for the active tableview
    FPPCGift *gift;
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        gift = [self.searchResults objectAtIndex:indexPath.row];
    }
    else {
        gift = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
    
    // Display name, sources, and total amount
    ((FPPCGiftCell *)cell).name.text = gift.name;
    NSMutableSet *sources = [[NSMutableSet alloc] init];
    NSDecimalNumber *total = [NSDecimalNumber zero];
    for (FPPCAmount *amount in gift.amount) {
        total = [total decimalNumberByAdding:amount.value];
        [sources addObject:amount.source];
    }
    ((FPPCGiftCell *)cell).sources.text = (sources.count == 0) ? @"": [NSString stringWithFormat:@"From: %@",[[[sources valueForKey:@"name"] allObjects] componentsJoinedByString:@", "]];
    ((FPPCGiftCell *)cell).totalValue.text = [self.currencyFormatter stringFromNumber:total];
    
    // Display date
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    ((FPPCGiftCell *)cell).date.text = [formatter stringFromDate:gift.date];
    
    return cell;
}

#pragma mark - Navigation bar
#pragma
- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Delegate
#pragma
- (void)didUpdateGift:(FPPCGift *)gift {
    [self reloadTableView];
    [self dismissViewControllerAnimated:YES completion:nil];
};

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
                                   entityForName:@"FPPCGift" inManagedObjectContext:((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Only fetch gifts for the selected year
    NSDate *yearStart, *yearEnd;
    NSDateComponents *year = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[FPPCSource date]];
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    [components setDay:1];
    [components setMonth:1];
    [components setYear:year.year];
    yearStart = [[NSCalendar currentCalendar] dateFromComponents:components];
    [components setDay:31];
    [components setMonth:12];
    yearEnd = [[NSCalendar currentCalendar] dateFromComponents:components];
    
    NSPredicate *datePredicate = [NSPredicate predicateWithFormat:@"(date >= %@) AND (date <= %@)", yearStart, yearEnd];
    [fetchRequest setPredicate:datePredicate];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:@"date" ascending:NO];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sort]];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:@"FPPCGiftsView"];
    
    theFetchedResultsController.delegate = self;
    self.fetchedResultsController = theFetchedResultsController;
    
    NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    TFLog(@"ERROR: Failed to perform fetch - %@, %@", error, [error userInfo]);
	    [self showErrorMessage];
	}
    
    return _fetchedResultsController;
}

@end
