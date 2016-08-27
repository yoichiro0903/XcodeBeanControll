//
//  ViewController.m
//  beanControll
//
//  Created by WatanabeYoichiro on 2014/12/07.
//  Copyright (c) 2014年 YoichiroWatanabe. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _btIns = [[BluetoothConnection alloc] init];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)startScanning:(id)sender {
    NSLog(@"%s", "Button pushed");
    [_btIns startScanning];

}
- (IBAction)litLEDUp:(id)sender {
    [_btIns litUpLED];
}

@end
