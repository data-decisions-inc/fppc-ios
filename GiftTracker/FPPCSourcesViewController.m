//
//  FPPCSourcesViewController.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/14/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCSourcesViewController.h"
#import "FPPCAmount.h"

@implementation FPPCSourcesViewController
@synthesize fetchedResultsController = _fetchedResultsController;

#pragma mark - Navigation bar
#pragma 
- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
    
    // No duplicate sources
    NSMutableArray *sources = [[NSMutableArray alloc] init];
    for (FPPCAmount *amount in self.gift.amount) {
        for (FPPCSource *source in amount.source) {
            [sources addObject:source];
        }
    }
    NSPredicate *dupePredicate = [NSPredicate predicateWithFormat:@"NOT (SELF IN %@)", sources];
    [fetchRequest setPredicate:dupePredicate];
    
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

@end
