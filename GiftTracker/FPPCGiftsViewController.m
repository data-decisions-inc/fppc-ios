//
//  FPPCGiftsViewController.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/14/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCGiftsViewController.h"
#import "FPPCDashboardViewController.h"

@implementation FPPCGiftsViewController
@synthesize fetchedResultsController = _fetchedResultsController;

#pragma mark - Navigation bar
#pragma
- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Delegate
#pragma
- (void)didEditGift {
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
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:@"date" ascending:NO];
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

@end
