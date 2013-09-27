//
//  FPPCGiftCell.h
//  GiftTracker
//
//  Created by Jaime Ohm on 9/6/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FPPCGiftCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *name;
@property (nonatomic, weak) IBOutlet UILabel *sources;
@property (nonatomic, weak) IBOutlet UILabel *totalValue;
@property (nonatomic, weak) IBOutlet UILabel *date;
@end
