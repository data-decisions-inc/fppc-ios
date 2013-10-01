//
//  FPPCSourceViewController.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/3/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCSourceViewController.h"
#import "FPPCAmount.h"
#import "FPPCGift.h"
#import "UIColor+FPPC.h"

@interface FPPCSourceViewController ()
@end

@implementation FPPCSourceViewController
@synthesize source = _source;
@synthesize name, totalReceived;
@synthesize sms, email, call;
@synthesize delegate;
@synthesize fetchedResultsController = _fetchedResultsController;

#pragma mark - View lifecycle
#pragma 

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Prepare attributes
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 2.0f;
    paragraphStyle.minimumLineHeight = 14;
    paragraphStyle.maximumLineHeight = 14;
    paragraphStyle.lineHeightMultiple = 1;
    NSDictionary * attributes1 = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [UIColor blueColor],  NSForegroundColorAttributeName,
                                  paragraphStyle,        NSParagraphStyleAttributeName,
                                  nil];
    NSDictionary * attributes2 = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [UIColor blackColor],  NSForegroundColorAttributeName,
                                  paragraphStyle,                   NSParagraphStyleAttributeName,
                                  nil];
    NSDictionary * attributes3 = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [UIColor grayColor],  NSForegroundColorAttributeName,
                                  paragraphStyle,                   NSParagraphStyleAttributeName,
                                  nil];
    
    // Prepare name, lobbying
    NSString *lobbying = [self.source.isLobbying boolValue] ? @" - Lobbyist" : @"";
    NSMutableAttributedString *regString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@",self.source.name,lobbying,nil] attributes:attributes1];
    
    // Prepare business
    [regString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",(self.source.business.length != 0) ? [NSString stringWithFormat:@"\n%@",self.source.business,nil] : @""] attributes:attributes2]];
    
    // Prepare contact info
    NSArray *addressField = @[@"street", @"street2", @"city", @"state", @"zipcode"];
    NSMutableArray *addressArray = [[NSMutableArray alloc] init];
    for (NSString *field in addressField) {
        if (((NSString *)[self.source valueForKey:field]).length != 0)
            [addressArray addObject:[self.source valueForKey:field]];
    }
    NSString *address = [addressArray componentsJoinedByString:@", "];
    [regString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",(address.length != 0) ? [NSString stringWithFormat:@"\n%@",address,nil] : @"",nil] attributes:attributes3]];
    
    // Add this to the above to also show phone number and email
    //,(source.phone.length != 0) ? [NSString stringWithFormat:@"\n%@",source.phone,nil] : @"",(source.email.length != 0) ? [NSString stringWithFormat:@"\n%@",source.email,nil] : @""
    
    // Display name, lobbying, business, contact info
    self.name.attributedText = regString;
    
    // Disable a contact option if that kind of contact information is unavailable
    if (self.source.phone.length == 0) {
        [self.call setEnabled:NO];
        [self.sms setEnabled:NO];
        [self.call setAlpha:0.45f];
        [self.sms setAlpha:0.45f];
    } else {
        [self.call setEnabled:YES];
        [self.sms setEnabled:YES];
        [self.call setAlpha:1.0f];
        [self.sms setAlpha:1.0f];
    }
    if (self.source.email.length == 0) {
        [self.email setEnabled:NO];
        [self.email setAlpha:0.45f];
    } else {
        [self.email setEnabled:YES];
        [self.email setAlpha:1.0f];
    }
    
    // Display total gift
    [self reloadTableView];
}

- (void)reloadSummary {
    double total = 0;
    for (FPPCGift *gift in [self.fetchedResultsController fetchedObjects]) {
        for (FPPCAmount *amount in gift.amount) {
            if ([[amount.source anyObject] isEqual:self.source]) {
                total += [amount.value doubleValue];
            }
        }
    }
    self.totalReceived.text = [self.currencyFormatter stringFromNumber:[NSNumber numberWithDouble:total]];
}

- (void)reloadTableView {
    [super reloadTableView];
    [self reloadSummary];
}

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
    
    // Display name, sources, and amount contributed by this source
    ((FPPCGiftCell *)cell).name.text = gift.name;
    NSMutableSet *sources = [[NSMutableSet alloc] init];
    
    double total = 0;
    for (FPPCAmount *amount in gift.amount) {
        for (FPPCSource *source in amount.source) {
            [sources addObject:source];
            if ([source isEqual:self.source]) total = [amount.value doubleValue];
        }
    }
    ((FPPCGiftCell *)cell).sources.text = (sources.count == 0) ? @"": [NSString stringWithFormat:@"From: %@",[[[sources valueForKey:@"name"] allObjects] componentsJoinedByString:@", "]];
    ((FPPCGiftCell *)cell).totalValue.text = [self.currencyFormatter stringFromNumber:[NSNumber numberWithDouble:total]];
    
    // Display date
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy"];
    ((FPPCGiftCell *)cell).date.text = [formatter stringFromDate:gift.date];
    
    return cell;
}

#pragma mark - Contact the source
#pragma

- (IBAction)sms:(id)sender {
    if ([MFMessageComposeViewController canSendText]) {
        
        // Prepare sms composer
        MFMessageComposeViewController *messageViewController = [[MFMessageComposeViewController alloc] init];
        messageViewController.messageComposeDelegate = self;
        
        // Populate sms
        messageViewController.recipients = [NSArray arrayWithObject:self.source.phone];
        
        // Setup custom navbar
        UIColor *navBarColor = [UIColor FPPCBlueColor];
        messageViewController.navigationBar.tintColor = navBarColor;
        
        // Display sms composer
        [self presentViewController:messageViewController animated:YES completion:nil];
    }
}

- (IBAction)email:(id)sender {
    if ([MFMailComposeViewController canSendMail]) {
        
        // Prepare mail composer
        MFMailComposeViewController *emailViewController = [[MFMailComposeViewController alloc] init];
        emailViewController.mailComposeDelegate = self;
        
        // Populate message
        [emailViewController setToRecipients:[NSArray arrayWithObject:self.source.email]];
        
        // Setup custom navbar
        UIColor *navBarColor = [UIColor FPPCBlueColor];
        emailViewController.navigationBar.tintColor = navBarColor;
        
        // Display mail composer
        [self presentViewController:emailViewController animated:YES completion:nil];
    }
}

- (IBAction)call:(id)sender {
    // Optional TODO: iOS does not let you dial a number with an access code in it. Consider adding a popup with an access code if the user saves one for a number
    
    NSURL *url = [NSURL URLWithString:self.source.phone];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - Message delegates
#pragma

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    // Cancelled: exit and do nothing
    if (result == MFMailComposeResultCancelled) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    // Sent: email was sent successfully!
    if (result == MFMailComposeResultSent) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    // Failure: email was neither saved nor sent
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"" delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
        alert.delegate = self;

        switch (result) {
            case MFMailComposeResultSaved:
                alert.message = @"Message Saved";
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

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    
    // Close the composer view regardless of the result
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
                                   entityForName:@"FPPCGift" inManagedObjectContext:((FPPCAppDelegate *)[[UIApplication sharedApplication] delegate]).managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Only fetch gifts related to this source
    NSPredicate *giftPredicate = [NSPredicate predicateWithFormat:@"SUBQUERY(amount, $b, ANY $b.source == %@).@count > 0", self.source];
    [fetchRequest setPredicate:giftPredicate];
    
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
