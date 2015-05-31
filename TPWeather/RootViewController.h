//
//  RootViewController.h
//  TPWeather
//
//  Created by David on 5/22/15.
//  Copyright (c) 2015 David Chiu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataController.h"

@interface RootViewController : UIViewController <UIPageViewControllerDelegate,DataControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageViewController;

@end

