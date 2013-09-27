//
//  FPPCToolbar.h
//

#import <UIKit/UIKit.h>

@class FPPCSegmentedControl;

@protocol FPPCToolbarDelegate <NSObject>
- (NSInteger)maxIndex;
@end

@interface FPPCToolbar : UIToolbar
@property (nonatomic, strong) UITextField *textField;
- (id)initWithDelegate:(UIViewController<FPPCToolbarDelegate> *)delegate;
- (void)nextPrevious:(FPPCSegmentedControl *)sender;
@end

@interface FPPCSegmentedControl : UISegmentedControl
@end
