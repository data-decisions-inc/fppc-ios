//
//  FPPCViewController.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/4/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCViewController.h"

@implementation FPPCViewController

#pragma mark - Formatted dates & numbers
#pragma

- (NSNumberFormatter *)currencyFormatter
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setNumberStyle: NSNumberFormatterCurrencyStyle];
    [numberFormatter setCurrencySymbol:@"$"];
    [numberFormatter setMaximumFractionDigits:2];
    [numberFormatter setMinimumFractionDigits:2];
    [numberFormatter setNegativePrefix:[NSString stringWithFormat:@"-%@", [numberFormatter currencySymbol]]];
    [numberFormatter setNegativeSuffix:@""];
    return numberFormatter;
}

/**
 * When an unrecoverable error occurs, tell the user to restart the application.
 */
- (void)showErrorMessage {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Uh Oh!" message:@"The database is misbehaving. Please restart this application." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    [alert show];
}

@end
