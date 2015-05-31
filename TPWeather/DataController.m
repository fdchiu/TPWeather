//
//  DataController.m
//  TPWeather
//
//  Created by David on 5/23/15.
//  Copyright (c) 2015 David Chiu. All rights reserved.
//

#import "DataController.h"

#define PREDEFINED_MAX_COUNT 15

@interface DataController() {
    NSInteger syncingMethod;
    NSTimer *startSyncTimer;
    NSInteger loopCounter;
}
@property (assign,atomic) NSInteger nextIndex;
@property (strong,atomic) NSMutableArray *taskQueue;

@end

@implementation DataController

+(DataController*)sharedDataController{
    
    static DataController *sharedInstance=nil;
    static dispatch_once_t  oncePredecate;
    
    if(!sharedInstance)
        dispatch_once(&oncePredecate,^{
            sharedInstance=[[DataController alloc] init];
        
        });
    return sharedInstance;
}


+(NSString*)getImageForWeather:(NSString*)weatherString
{
    return [[DataController sharedDataController] getImageName:weatherString];
}

-(instancetype)init {
    self = [super init];
    if (self) {
        // Create the data model.
        _weathers = [[NSMutableArray alloc] init];
        [self loadSettings];
        if([_weathers count] ==0) { //no data; add default
            _refreshType = TPWeather_Refresh_Sequencial;
            NSMutableDictionary *dic=[NSMutableDictionary dictionaryWithDictionary:@{@"zipcode":@"95014", @"weather":@"Sunny",@"temperature":@"65",@"city":@"Cupertino",@"humidity":@"66"}];
            [_weathers addObject:dic];
        }
     _weatherImage=@{@"Sunny":@"sunny",@"Clear":@"sunny",@"Clouds":@"cloudy",@"Cloudy":@"cloudy",@"Rain":@"rainy",@"Raining":@"rainy",@"Fair":@"fair"};
        _taskQueue = [[NSMutableArray alloc] init];
        _temperatureUnits = TPWeather_Temp_Units_F;
        _baseURL = @"http://api.openweathermap.org/data/2.5/weather?";
    }
    return self;
}

#pragma mark - image method
-(NSString*)getImageName:(NSString*)weatherString
{
 
    NSString *imagename=[self.weatherImage objectForKey:weatherString];
    if(!imagename)
        return [self.weatherImage objectForKey:@"Fair"];
    
    return imagename;
}


#pragma mark - data object managment
-(void)removeObjectAtIndex:(NSInteger)index
{
    if(index>=0 && index<[self.weathers count])
        [self.weathers removeObjectAtIndex:index];
}

-(NSInteger)count
{
    return [self.weathers count];
}
-(id)objectAtIndex:(NSInteger)index
{
    return [self.weathers objectAtIndex:index];
}

- (NSInteger)indexOfObject:(id)object
{
    return [self.weathers indexOfObject:object];
}

-(NSInteger)dataExist:(NSString*)zipcode
{
    for (NSDictionary *dic in self.weathers) {
        NSString *tempString=[NSString stringWithUTF8String:[[dic valueForKey:@"zipcode"] UTF8String]];
        if([tempString isEqualToString:[NSString stringWithUTF8String:[zipcode UTF8String]]])
            return [self.weathers indexOfObject:dic];
    }
    return NSNotFound;
}

-(void)addZipcode:(NSString*)zipcode
{
    if([self dataExist:zipcode] != NSNotFound)
        return;
    
    [self.weathers addObject:[NSMutableDictionary dictionaryWithDictionary:@{@"zipcode":zipcode,@"weather":@"Sunny",@"temperature":@"65",@"city":@"Unknown",@"humidity":@"60"}]];
    
    [self saveSettings];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self getWeatherForZipcode:zipcode];
    });
}

-(NSMutableDictionary*)findWeatherForZipcode:(NSString*)zipcode
{
    NSInteger index=[self dataExist:zipcode];
    if(index == NSNotFound)
        return nil;
    
    return self.weathers[index];
}

-(void)getWeatherForZipcode:(NSString*)zipcode
{
    NSLog(@"Getting weather data for zipcode: %@", zipcode);
    [self syncForZip:zipcode];
    
}

-(void)saveSettings
{
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    
    [defaults setObject:self.weathers forKey:@"zipcode"];
    [defaults setInteger:self.refreshType forKey:@"refresh type"];
    
    [defaults synchronize];

}

-(void)loadSettings
{
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    self.refreshType = [defaults  integerForKey:@"refresh type"];
    
    
    NSArray *loaded = [defaults objectForKey:@"zipcode"];
    for (int i=0; i<[loaded count]; i++) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:loaded[i]];
        self.weathers[i]=dic;
    }

    //[self.weathers addObjectsFromArray:[defaults objectForKey:@"zipcode"]];
    
}

-(void)refresh
{
    [self startSync];
}

-(void)syncForZip:(NSString*)zipcode
{
    NSLog(@"Sync weather data for zipcode: %@", zipcode);
    
    // Create the request.
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@zip=%@,us",self.baseURL, zipcode]]];
    
    // Create url connection and fire request
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    NSMutableDictionary *dic=[NSMutableDictionary dictionaryWithDictionary:@{@"connection":conn,@"data":[NSNull null],@"zipcode":zipcode}];
    [self.taskQueue addObject:dic];
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    
    NSMutableDictionary *dic=[self findTaskForConnection:connection];
    if(dic) {
        [dic setObject:[[NSMutableData alloc] init] forKey:@"data"];
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    
    NSDictionary *task = [self findTaskForConnection:connection];
    if(task) 
        [[task valueForKey:@"data"] appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
   
    NSDictionary *task=[self findTaskForConnection:connection];
    
    if(task) {
        [self parseResponseForTask:task];
        [self handleNext:task];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    NSLog(@"Error: %@",error);
    NSDictionary *task=[self findTaskForConnection:connection];
    if(task)
        [self handleNext:task];
}

-(void)parseResponseForTask:(NSDictionary*)task
{
    //NSURLConnection *connection=[task valueForKey:@"connection"];
    NSLog(@"Parsing received data:");
    NSData *response=[task valueForKey:@"data"];
    NSString *zipcode=[task valueForKey:@"zipcode"];
    NSMutableDictionary *weather= [self findWeatherForZipcode:zipcode];//[NSMutableDictionary dictionaryWithDictionary:[self findWeatherForZipcode:zipcode]];
    
    NSString *responseString= [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
    NSLog(@"Received: %@",responseString);
    NSError *localError = nil;
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:response options:0 error:&localError];
    if(localError) {
        NSLog(@"Response corrupt. Error: %@",localError);
        return;
    }
    if([parsedObject valueForKey:@"message"]) {
        [weather setObject:@"Invalid Zipcode" forKey:@"city"];
        return;
    }
    NSArray *weatherArr=[parsedObject valueForKey:@"weather"];
    NSDictionary *weather0=weatherArr[0];
    NSDictionary *temp=[parsedObject valueForKey:@"main"];
    NSLog(@"Zip: %@\nWeather: %@\nTemp: %@", zipcode, [weather0 valueForKey:@"main"],[temp valueForKey:@"temp"]);
    if(weather) {
        [weather setObject:[weather0 valueForKey:@"main"] forKey:@"weather"];
        [weather setObject:[NSString stringWithFormat:@"%.0f",[self convertTemperature:[temp valueForKey:@"temp"]] ] forKey:@"temperature"];
        [weather setObject:[temp valueForKey:@"humidity"] forKey:@"humidity"];
        [weather setObject:[parsedObject valueForKey:@"name"] forKey:@"city"];
    }
}

#pragma mark - syncing
-(void)startSync
{
    if(self.syncing) {
        NSLog(@"Previous syncing not completed yet. Waite");
        startSyncTimer = [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(syncChecking) userInfo:nil repeats:NO];
        return;
    }
    self.syncing = TRUE;
    if(self.refreshType == TPWeather_Refresh_Sequencial) {
        NSLog(@"Sync weather data sequencially. Syncing: %ld", self.nextIndex);
        [self syncForZip:[self.weathers[self.nextIndex] valueForKey:@"zipcode"]];
    }
    else {
        NSLog(@"Sync weather data concurrently");
        for(NSDictionary *dic in self.weathers)
            dispatch_async(dispatch_get_main_queue(),
                           ^{
                            [self syncForZip:[dic valueForKey:@"zipcode"]];
                           });
    }
}
-(void)syncChecking
{
    if(!self.syncing)
        loopCounter=0;
    else {
        loopCounter++;
        if(loopCounter>PREDEFINED_MAX_COUNT) {
            [self.taskQueue removeAllObjects];
            self.syncing = FALSE;
            loopCounter =0;
            NSLog(@"Time out. Clear all task");
        }
    }
    [self startSync];
}


#pragma mark - task queue
-(NSMutableDictionary*)findTaskForConnection:(id)connection
    {
        for(NSMutableDictionary *dic in self.taskQueue)
            if([dic objectForKey:@"connection"] == connection)
                return dic;
        return nil;
    }

-(void)handleNext:(NSDictionary*)task
{
    if(self.delegate)
        if([self.delegate respondsToSelector:@selector(updateWeatherForZipcode:)])
            [self.delegate performSelector:@selector(updateWeatherForZipcode:) withObject:[task valueForKey:@"zipcode"]];

    [self.taskQueue removeObject:task];
    if(self.refreshType==TPWeather_Refresh_Sequencial) {
        self.nextIndex++;
        if(self.nextIndex >= [self.weathers count]) {
            self.nextIndex=0;
            self.syncing = FALSE;
            if(self.delegate)
                if([self.delegate respondsToSelector:@selector(refreshComplete)])
                    [self.delegate performSelector:@selector(refreshComplete)];
            NSLog(@"Sequencial weather data syncing completed");
        }
        else {
            NSLog(@"Sequencial weather data sync next:%ld", (long)self.nextIndex);
            [self syncForZip:[self.weathers[self.nextIndex] valueForKey:@"zipcode"]];
        }
        return;
    }
    if([self.taskQueue count]==0) {
        self.syncing = FALSE;
        if(self.delegate)
            if([self.delegate respondsToSelector:@selector(refreshComplete)])
                [self.delegate performSelector:@selector(refreshComplete)];
        NSLog(@"Concurrent weather data syncing completed");

    }
}

-(float)convertTemperature:(NSString*)temperatureK
{
    if(self.temperatureUnits==TPWeather_Temp_Units_F)
        return [temperatureK floatValue]*9.0/5.0 - 459.67;
    if(self.temperatureUnits==TPWeather_Temp_Units_C)
        return [temperatureK floatValue] - 273.15;
    return [temperatureK floatValue];
}
@end
