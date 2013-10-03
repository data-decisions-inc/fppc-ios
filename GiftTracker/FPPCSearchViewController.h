//
//  FPPCSearchViewController.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/4/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "FPPCViewController.h"

@interface FPPCSearchViewController : FPPCViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate, NSFetchedResultsControllerDelegate, UIActionSheetDelegate> {
    CGPoint originalCenter;
}
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UINavigationBar *navBar;
@property (strong, nonatomic) NSArray *searchResults;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) FPPCViewController *delegate;
- (void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope;
- (void)deselectTableViewCell;
- (void)reloadTableView;
- (void)reloadSummary;
- (id)tableView:(UITableView *)tableView configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

enum kActionSheet {
    EDIT = 1,
    ADD,
    DETAILS
};
@end
