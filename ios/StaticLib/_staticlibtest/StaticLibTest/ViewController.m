//
//  ViewController.m
//  StaticLibTest
//
//  Created by Chacka Shacka on 29.03.15.
//  Copyright (c) 2015 mkonrad.net. All rights reserved.
//

#import "ViewController.h"

#include "staticexamplelib/staticexamplelib.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    staticexamplelib_module1func();
    staticexamplelib_module2func();
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
