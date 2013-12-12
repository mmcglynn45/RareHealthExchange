//
//  ApplicationTabController.m
//  RareHealthExchange
//
//  Created by Matt McGlynn on 12/11/13.
//  Copyright (c) 2013 Matt McGlynn. All rights reserved.
//

#import "ApplicationTabController.h"

@interface ApplicationTabController ()

@end

@implementation ApplicationTabController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tabBarItem.title = @"test";
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
