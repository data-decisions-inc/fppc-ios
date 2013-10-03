//
//  FPPCSourceSearchViewController.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/4/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCSourceSearchViewController.h"
#import "FPPCAmount.h"
#import "FPPCGift.h"
#import "FPPCAppDelegate.h"
#import "FPPCActionSheet.h"
#import "UIColor+FPPC.h"

@interface FPPCSourceSearchViewController ()

- (id)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation FPPCSourceSearchViewController
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize date;

#pragma mark - TableView
#pragma

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Initialize custom cell
    static NSString *CellIdentifier = @"FPPCSourceCell";
    FPPCSourceCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"FPPCSourceCell" owner:self options:nil];
        cell = self.sourceCell;
        self.sourceCell = nil;
    }
    
    // Update custom cell
    [self tableView:(UITableView *)tableView configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (id)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    // We maintain two sets of data (one for search results and one pre-search)
    // Fetch the appropriate data for the active tableview
    FPPCSource *source;
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        source = [self.searchResults objectAtIndex:indexPath.row];
    }
    else {
        source = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
    
    // Display name, business, and lobbying activity
    ((FPPCSourceCell *)cell).name.text = source.name;
    NSString *lobbying = [source.isLobbying boolValue] ? (source.business.length!=0 ? @" - Lobbying" : @"Lobbying") : @"";
    lobbying = 
    ((FPPCSourceCell *)cell).business.text = [NSString stringWithFormat:@"%@%@",source.business ? source.business : @"",lobbying,nil];
    
    // Display remaining gift limit
    NSDecimalNumber *limit = [self giftLimitWithSource:source forDate:self.date];
    NSString *limitString = [self.currencyFormatter stringFromNumber:limit];
    ((FPPCSourceCell *)cell).remainingLimit.textColor = ([limit compare:[NSDecimalNumber zero]] == NSOrderedAscending) ? [UIColor redColor] : [UIColor FPPCGreenColor];
    ((FPPCSourceCell *)cell).remainingLimit.text = limitString;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // We maintain two sets of data (one for search results and one pre-search)
    // Fetch the appropriate data for the active tableview
    FPPCSource *source;
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        source = [self.searchResults objectAtIndex:indexPath.row];
    }
    else {
        source = [self.fetchedResultsController objectAtIndexPath:indexPath];
    }
    
    // Tell the delegate which source was added
    [self.delegate didAddSource:source];
}

/**
 The targeted user cannot received gifts that amount to more than X dollars (the limit) per calendar year per source (donor). If the donor is a registered lobbyist, the user cannot received more than Y dollars worth of gift per month. (special case)
 
 The gift limit X and lobbyist gift limit Y varies every year, the state legislature vote and decide that.
 
 Right now, these limits are hard-coded and can be updated manually via updates to the application. In the future, it is recommended that these values be pulled from a web page that is updated when new legislation comes through.
 */
- (NSDecimalNumber *)giftLimitWithSource:(FPPCSource *)source forDate:(NSDate *)date {
    NSDecimalNumber *limit;
    
    // Calculate remaining gift limit for lobbying sources
    if ([source.isLobbying boolValue]) {
        limit = [NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithInt:LOBBYING_LIMIT] decimalValue]];
        for (FPPCAmount *amount in source.amount) {
            FPPCGift *gift = amount.gift;
             NSDateComponents *amountDateComponents = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit|NSYearCalendarUnit fromDate:gift.date];
            NSDateComponents *rangeDateComponents = [[NSCalendar currentCalendar] components:NSMonthCalendarUnit|NSYearCalendarUnit fromDate:[self date]];
            if(amountDateComponents.year == rangeDateComponents.year && amountDateComponents.month == rangeDateComponents.month) {
                limit = [limit decimalNumberBySubtracting:[NSDecimalNumber decimalNumberWithDecimal:[amount.value decimalValue]]];
            }
        }
    }
    
    // Calculate remaining gift limit for non-lobbying sources
    else {
        limit = [NSDecimalNumber decimalNumberWithDecimal:[[NSNumber numberWithInt:NON_LOBBYING_LIMIT] decimalValue]];
        for (FPPCAmount *amount in source.amount) {
            FPPCGift *gift = amount.gift;
            NSDateComponents *amountDateComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:gift.date];
            NSDateComponents *rangeDateComponents = [[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[self date]];
            if(amountDateComponents.year == rangeDateComponents.year) {
                limit = [limit decimalNumberBySubtracting:[NSDecimalNumber decimalNumberWithDecimal:[amount.value decimalValue]]];
            }
        }
    }
    
    return limit;
}

#pragma mark - Alert view
#pragma

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    [super actionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
    
    // Respond to user selection
    switch (buttonIndex) {
            
        // Display a form for editing the source
        case EDIT: {
            [self.delegate performSegueWithIdentifier:@"editSource" sender:self];
            break;
        }
        
        // Add a gift to this source
        case ADD: {
            [self.delegate performSegueWithIdentifier:@"addGift" sender:self];
            break;
        }
            
        // Display the detail view for this source
        case DETAILS: {
            [self.delegate performSegueWithIdentifier:@"viewSource" sender:self];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - Search
#pragma

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    // Return names that contain searchText
    if ([scope isEqualToString:@"All"]) {
        NSPredicate *resultPredicate = [NSPredicate
                                        predicateWithFormat:@"(SELF.name contains[cd] %@) OR (SELF.business contains[cd] %@)",
                                        searchText, searchText];
        self.searchResults = [[self.fetchedResultsController fetchedObjects] filteredArrayUsingPredicate:resultPredicate];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
