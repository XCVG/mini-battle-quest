//
//  MainMenuViewController.m
//  minibattlequest
//
//  Created by Erick Fernandez de Arteaga on 2017-01-30.
//  Copyright © 2017 Mini Battle Quest. All rights reserved.
//

#import "MainMenuViewController.h"
#import <Foundation/Foundation.h>

@interface MainMenuViewController () {
    
}



@end

@implementation MainMenuViewController {
    
}

/**
    On load, hide the navigation bar and enable swipe navigation.
 */
-(void)viewDidLoad
{
    [self.navigationController setNavigationBarHidden:YES];
    [self.navigationController.interactivePopGestureRecognizer setDelegate:nil];
}

@end
