//
//  FPPCTextField.h
//  GiftTracker
//
//  Created by Jaime Ohm on 10/7/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FPPCAmount.h"

@interface FPPCSummaryField : UITextField
@end

@interface FPPCAmountField : UITextField
@property (nonatomic, strong) FPPCAmount *amount;
@end
