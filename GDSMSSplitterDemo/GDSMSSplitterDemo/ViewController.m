
//
//  ViewController.m
//  GDSMSSplitterDemo
//
//  Created by Alex G on 13.06.15.
//  Copyright (c) 2015 Alexey Gordiyenko. All rights reserved.
//

#import "ViewController.h"
#import "GDSMSCounterLabel.h"

@interface ViewController () <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet GDSMSCounterLabel *counterLabel;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation ViewController

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self.counterLabel countForText:textView.text];
}

#pragma mark - Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.counterLabel countForText:@""];    
    [self.textView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
