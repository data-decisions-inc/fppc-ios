//
//  FPPCToolbar.m
//

#import "FPPCKeyboard.h"
#import "UIColor+FPPC.h"

@interface FPPCToolbar ()
@property (nonatomic, strong) UIViewController<FPPCToolbarDelegate> *controller;
@property (nonatomic, strong) FPPCSegmentedControl *segmentedControl;
@property (nonatomic, strong) UIBarButtonItem *doneButton;

enum FPPCSegmentedControlIndex {
    NEXT_INDEX = 0,
    PREVIOUS_INDEX
};
- (void)previous;
- (void)next;
@end

@implementation FPPCToolbar
@synthesize controller;
@synthesize segmentedControl;
@synthesize textField = _textField;
@synthesize doneButton;

- (id)initWithDelegate:(UIViewController<FPPCToolbarDelegate> *)delegate {
    if ((self = [super initWithFrame:CGRectMake(10.0, 0.0, 310.0, 40.0)])) {
        BOOL isIOS7 = [[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0;
        
        // Setup delegate
        self.controller = delegate;
        
        // Setup next/previous buttons
        self.segmentedControl = [[FPPCSegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
                                                                             NSLocalizedString(@"Previous",@"Previous form field"),
                                                                             NSLocalizedString(@"Next",@"Next form field"),
                                                                             nil]];        
        self.segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        if (isIOS7)
            self.segmentedControl.tintColor = [UIColor FPPCBlueColor];
        else
            self.segmentedControl.tintColor = [UIColor darkGrayColor];
        self.segmentedControl.momentary = YES;
        [self.segmentedControl addTarget:self action:@selector(nextPrevious:) forControlEvents:UIControlEventValueChanged];
        
        UIBarButtonItem *controlItem = [[UIBarButtonItem alloc] initWithCustomView:self.segmentedControl];
        
        // Setup done button
        doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:nil action:@selector(resignFirstResponder)];
        if (isIOS7)
            doneButton.tintColor = [UIColor FPPCBlueColor];
        else
            doneButton.tintColor = [UIColor darkGrayColor];
        
        // Display next/previous/done buttons
        UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        if (!isIOS7) self.barStyle = UIBarStyleBlackTranslucent;
        self.items = [[NSArray alloc] initWithObjects:controlItem, flex, doneButton, nil];

    }
    return self;
}

- (void)setTextField:(UITextField *)textField {
    self.doneButton.target = textField;
    
    // Disable 'Previous'
    if (textField.tag == 1) {
        [self.segmentedControl setEnabled:NO forSegmentAtIndex:0];
    } else {
        [self.segmentedControl setEnabled:YES forSegmentAtIndex:0];
    }
    
    // Disable 'next'
    if (((textField.tag == self.controller.maxIndex) && ![self.controller.view viewWithTag:(-1)]) || (!([self.controller.view viewWithTag:textField.tag-1]) && (textField.tag < 0))) {
        [self.segmentedControl setEnabled:NO forSegmentAtIndex:1];
    } else {
        [self.segmentedControl setEnabled:YES forSegmentAtIndex:1];
    }
    
    _textField = textField;
}

- (void)nextPrevious:(FPPCSegmentedControl *)sender {
    if (sender.selectedSegmentIndex == PREVIOUS_INDEX)
        [self next];
    else if (sender.selectedSegmentIndex == NEXT_INDEX)
        [self previous];
}

- (void)previous {
    
    // Allow for a second list of negative tags
    NSInteger previousIndex;
    if (self.textField.tag == -1) {
        previousIndex = self.controller.maxIndex;
    }
    else if (self.textField.tag < 0) {
        previousIndex = self.textField.tag + 1;
    }
    else {
        previousIndex = self.textField.tag - 1;
    }
    
    // Change text fields
    [self.textField resignFirstResponder];
    [(UITextField *)[self.controller.view viewWithTag:previousIndex] becomeFirstResponder];
}

- (void)next {
    
    // Allow for a second list of negative tags
    NSInteger nextIndex;
    if (self.textField.tag == self.controller.maxIndex) {
        nextIndex = -1;
    }
    else if (self.textField.tag < 0) {
        nextIndex = self.textField.tag - 1;
    }
    else {
        nextIndex = self.textField.tag + 1;
    }
    
    // Change text fields
    [self.textField resignFirstResponder];
    [(UITextField *)[self.controller.view viewWithTag:nextIndex] becomeFirstResponder];
}

@end

@implementation FPPCSegmentedControl
@end