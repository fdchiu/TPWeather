//
//  DataViewController.h
//  TPWeather
//
//  Created by David on 5/22/15.
//  Copyright (c) 2015 David Chiu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DataViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *dataLabel;
@property (strong, nonatomic) id dataObject;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;
@property (weak, nonatomic) IBOutlet UIView *weatherImageView;

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

-(void)refresh;

@end

