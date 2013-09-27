//
//  FPPCSearchViewController.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/4/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCSearchViewController.h"
#import "FPPCSource.h"
#import "FPPCAmount.h"
#import "FPPCGift.h"
#import "FPPCAppDelegate.h"
#import "FPPCSourceCell.h"
#import "FPPCActionSheet.h"
#import "UIImage+ImageWithColor.h"
#import "UIColor+FPPC.h"
#import "FPPCSourceViewController.h"

@interface FPPCSearchViewController ()
- (id)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation FPPCSearchViewController
@synthesize searchBar = _searchBar;
@synthesize tableView = _tableView;
@synthesize searchResults;
@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize delegate;
@synthesize navBar;

#pragma mark - View lifecycle
#pragma 

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searchResults = [NSMutableArray arrayWithCapacity:[[self fetchedResultsController] fetchedObjects].count];
    [self.tableView reloadData];
    
    // Custom search bar
    [[UISearchBar appearance] setBackgroundColor:[UIColor FPPCBlueColor]];
    
    // Initialize scrolling
    originalCenter = self.view.center;
}

#pragma mark - Factories for singleton instances
#pragma

+ (FPPCSearchViewController *)searchViewController {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

#pragma mark - TableView
#pragma

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (id)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if ([tableView isEqual:self.searchDisplayController.searchResultsTableView]) {
        return self.searchResults.count;
    }
    else {
        return [self.fetchedResultsController fetchedObjects].count;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (void)deselectTableViewCell {
    // Remove row highlight
    if ([self.searchDisplayController isActive]) {
        
        [self.searchDisplayController.searchResultsTableView deselectRowAtIndexPath:[self.searchDisplayController.searchResultsTableView indexPathForSelectedRow] animated:YES];
    }
    else {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}

- (void)reloadTableView {
    
    // Reload the tableView
    if ([self.searchDisplayController isActive]) {
        [self.searchDisplayController.searchResultsTableView reloadData];
    }
    else {
        [self.tableView reloadData];
    }
}

- (void)reloadSummary {
    
}

#pragma mark - Alert view
#pragma

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    // Cancel this action
    if (actionSheet.cancelButtonIndex == buttonIndex) {
        [self deselectTableViewCell];
    }
    
    // Remove the object at this index
    else if (actionSheet.destructiveButtonIndex == buttonIndex) {
        if ([self.searchDisplayController isActive]) {
            NSManagedObject *object = [self.searchResults objectAtIndex:[(FPPCActionSheet *)actionSheet indexPath].row];
            if ([object isMemberOfClass:[FPPCGift class]]) {
                FPPCGift *gift = (FPPCGift *)object;
                for (FPPCAmount *amount in gift.amount) {
                    [self.fetchedResultsController.managedObjectContext deleteObject:amount];
                }
                [self.fetchedResultsController.managedObjectContext deleteObject:gift];
            } else {
                [self.fetchedResultsController.managedObjectContext deleteObject:object];
            }
            
        } else {
            NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:[(FPPCActionSheet *)actionSheet indexPath]];
            
            if ([object isMemberOfClass:[FPPCGift class]]) {
                FPPCGift *gift = (FPPCGift *)object;
                for (FPPCAmount *amount in gift.amount) {
                    [self.fetchedResultsController.managedObjectContext deleteObject:amount];
                }
                [self.fetchedResultsController.managedObjectContext deleteObject:gift];
            } else {
                [self.fetchedResultsController.managedObjectContext deleteObject:object];
            }
        }
                
        // Save if no undo managers are nested in the controller
        if (![self isMemberOfClass:[FPPCSourceViewController class]]) {
            [(FPPCAppDelegate *)[[UIApplication sharedApplication] delegate] saveContext];
        }

        [TestFlight passCheckpoint:@"DELETE"];
    }
}

#pragma mark - FetchedResults
#pragma

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
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
            [self reloadTableView];
            [self reloadSummary];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [self reloadTableView];
            [self reloadSummary];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self tableView:self.tableView configureCell:[tableView cellForRowAtIndexPath:indexPath]
                atIndexPath:indexPath];
            [self reloadTableView];
            [self reloadSummary];
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

#pragma mark - Search
#pragma

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope
{
    // Return names that contain searchText
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

#pragma mark -
#pragma mark UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{    
    [self filterContentForSearchText:searchString scope:@"All"];
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:[self.searchDisplayController.searchBar text] scope:@"All"];
    return YES;
}

//- (void)searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
//    if (self.scrollView)[self.scrollView setContentOffset:CGPointZero animated:YES];
//}
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    
    // Move the search bar up to the correct location
    [UIView animateWithDuration:.4
                     animations:^{
                         self.view.center = CGPointMake(originalCenter.x, originalCenter.y-searchBar.frame.origin.y);
                     }
                     completion:^(BOOL finished){
                         //whatever else you may need to do
                     }];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    
    // Move the search bar down to the correct location eg
    [UIView animateWithDuration:.4
                     animations:^{
                         self.view.center = CGPointMake(originalCenter.x, originalCenter.y);
                     }
                     completion:^(BOOL finished){
                         //whatever else you may need to do
                     }];
}

#pragma mark - FetchedResults
#pragma

- (NSFetchedResultsController *)fetchedResultsController {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end
