//
//  AppDelegate.h
//  TPWeather
//
//  Created by David on 5/22/15.
//  Copyright (c) 2015 David Chiu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TPWeatherSetup: NSObject
@property (strong,nonatomic) NSMutableArray *zipcode;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;


@end

