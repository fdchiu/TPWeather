//
//  DataViewController.m
//  TPWeather
//
//  Created by David on 5/22/15.
//  Copyright (c) 2015 David Chiu. All rights reserved.
//

#import "DataViewController.h"
#import "DataController.h"


@interface DataViewController () {
}
@end

@implementation DataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refresh];
    NSLog(@"DataViewController: showing weather for: %@ (%@)", [self.dataObject valueForKey:@"city"],[self.dataObject valueForKey:@"zipcode"]);
}

-(void)refresh
{
    self.dataLabel.text = [NSString stringWithFormat:@"%@ (%@)",[(NSDictionary*)self.dataObject objectForKey:@"city"],[(NSDictionary*)self.dataObject objectForKey:@"zipcode"]];
    self.temperatureLabel.text = [NSString stringWithFormat:@"%@ ºF",[[(NSDictionary*)self.dataObject objectForKey:@"temperature"] description]];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM d, h:mm a"];
    NSString *weatherString=[[(NSDictionary*)self.dataObject objectForKey:@"weather"] description];
    
    NSArray *subview=[self.weatherImageView subviews];
    if( subview && [subview count]>0)
        [[[self.weatherImageView subviews] objectAtIndex:0] removeFromSuperview];
    
    UIImageView *imgv=[[UIImageView alloc] initWithImage:[UIImage imageNamed:[DataController getImageForWeather:weatherString]]];
    [self.weatherImageView addSubview:imgv];
    
    self.dateLabel.text = [dateFormatter stringFromDate:[NSDate date]];
    
}
@end
