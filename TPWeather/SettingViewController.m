//
//  SettingViewController.m
//  TPWeather
//
//  Created by David on 5/22/15.
//  Copyright (c) 2015 David Chiu. All rights reserved.
//

#import "SettingViewController.h"
#import "AddZipcodeViewController.h"

@interface SettingViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *queryTypeSC;

@end


@implementation SettingViewController
@synthesize dataController;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //gestures
    UISwipeGestureRecognizer *recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.view addGestureRecognizer:recognizer];
    
    [self.queryTypeSC setSelectedSegmentIndex:[self.dataController refreshType]];
    
    /*recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.view addGestureRecognizer:recognizer];
     */

}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView reloadData];
    
    NSLog(@"Showing settings screen");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didSwipe:(UISwipeGestureRecognizer*)gesture
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)changeQueryMethod:(id)sender {
    [self.dataController setRefreshType:[(UISegmentedControl*)sender selectedSegmentIndex]];
    NSLog(@"Weather query method changed");
}

- (IBAction)done:(id)sender {
    [self.dataController saveSettings];
    [self dismissViewControllerAnimated:YES completion:nil];
    NSLog(@"Exit Setting screen");

}
- (IBAction)addZipcode:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UIViewController *vC=[storyboard instantiateViewControllerWithIdentifier:@"AddZipcodeViewController"];
    [(AddZipcodeViewController*)vC setDataController:self.dataController];
    [self presentViewController:vC animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.dataController count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ZipcodeCell"];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ZipcodeCell"];
    
    NSDictionary *weather=[self.dataController objectAtIndex:indexPath.row];
    cell.imageView.image = [UIImage imageNamed:[DataController getImageForWeather:[weather objectForKey:@"weather"]]];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@",[weather objectForKey:@"city"],[weather objectForKey:@"zipcode"]];
    
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"Temp: %@ Humidity: %@",[weather objectForKey:@"temperature"], [weather objectForKey:@"humidity"]]];

    NSLog(@"Seetings: create new table cell: %@", cell.textLabel.text);
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"Weather zipcode to be deleted:%@",[[self.dataController objectAtIndex:indexPath.row] valueForKey:@"zipcode"]);
        [self.dataController removeObjectAtIndex:indexPath.row];
        [tableView reloadData];

    }
}

@end
