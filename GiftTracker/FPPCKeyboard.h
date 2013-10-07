//
//  FPPCToolbar.h
//

#import <UIKit/UIKit.h>

@class FPPCSegmentedControl;

@protocol FPPCToolbarDelegate <NSObject>
- (BOOL)hasNext:(UIView *)view;
- (BOOL)hasPrevious:(UIView *)view;
- (void)next:(UIView *)view;
- (void)previous:(UIView *)view;
@end

@interface FPPCToolbar : UIToolbar
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIViewController<FPPCToolbarDelegate> *controller;
@property (nonatomic, strong) NSIndexPath *nextIndexPath;
- (id)initWithController:(UIViewController<FPPCToolbarDelegate> *)delegate;
- (void)nextPrevious:(FPPCSegmentedControl *)sender;
@end

@interface FPPCSegmentedControl : UISegmentedControl
@end
