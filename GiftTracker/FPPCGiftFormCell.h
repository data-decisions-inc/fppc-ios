//
//  FPPCGiftFormCell.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/11/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FPPCTextField.h"

@interface FPPCGiftFormCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *name;
@property (strong, nonatomic) IBOutlet FPPCAmountField *amount;
@end
