//
//  FPPCGiftSearchViewController.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/4/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCGiftSearchViewController.h"
#import "FPPCGiftFormViewController.h"
#import "FPPCGift.h"
#import "FPPCAmount.h"
#import "FPPCSource.h"
#import "FPPCActionSheet.h"

@interface FPPCGiftSearchViewController ()
@end

@implementation FPPCGiftSearchViewController
@synthesize giftCell;
@synthesize navBar;

- (void)viewDidLoad {
    [super viewDidLoad];
    [TestFlight passCheckpoint:@"DASHBOARD - GIFTS"];
}

#pragma mark - TableView
#pragma

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // Initialize custom cell
    static NSString *CellIdentifier = @"FPPCGiftCell";
    FPPCGiftCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        [[NSBundle mainBundle] loadNibNamed:@"FPPCGiftCell" owner:self options:nil];
        cell = self.giftCell;
        self.giftCell = nil;
    }
    
    // Update custom cell
    [self tableView:(UITableView *)tableView configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {    
    FPPCActionSheet *sourceActionSheet = [[FPPCActionSheet alloc] initWithTitle:@"What would you like to do?" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Edit", nil];
    
    sourceActionSheet.delegate = self;
    [sourceActionSheet setIndexPath:indexPath];
    [sourceActionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

#pragma mark - Alert view
#pragma

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    [super actionSheet:actionSheet clickedButtonAtIndex:buttonIndex];
    
    // Respond to user selection
    switch (buttonIndex) {
            
        // Display a form for editing the gift
        case EDIT: {
            NSUndoManager *undoManager = [((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext undoManager];
            [undoManager beginUndoGrouping];
            
            [self performSegueWithIdentifier:@"editGift" sender:self];
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
                                        predicateWithFormat:@"SELF.name contains[cd] %@",
                                        searchText, searchText];
        self.searchResults = [[self.fetchedResultsController fetchedObjects] filteredArrayUsingPredicate:resultPredicate];
    }
}

#pragma mark - Navigation bar
#pragma

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Segue
#pragma

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"editGift"]) {
        FPPCGift *gift;
        NSIndexPath *indexPath;
        if ([self.searchDisplayController isActive]) {
            indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
            gift = [self.searchResults objectAtIndex:indexPath.row];
        }
        else {
            indexPath = [self.tableView indexPathForSelectedRow];
            gift = [[self.fetchedResultsController fetchedObjects] objectAtIndex:indexPath.row];
        }
        [[segue destinationViewController] setGift:gift];
        [[segue destinationViewController] setDelegate:self];
    }
    
    // Remove row highlight
    [self deselectTableViewCell];
}

@end
