//
//  ViewController.m
//  OpenGLES_索引
//
//  Created by Sangxiedong on 2019/6/13.
//  Copyright © 2019 ZB. All rights reserved.
//

#import "ViewController.h"
#import "ZBView.h"

@interface ViewController ()

@property (nonatomic, strong) ZBView *zbView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.zbView = [[ZBView alloc]initWithFrame:self.view.bounds];
    [self.view addSubview:self.zbView];
    
}


@end
