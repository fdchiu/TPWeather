//
//  DataController.h
//  TPWeather
//
//  Created by David on 5/23/15.
//  Copyright (c) 2015 David Chiu. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
    TPWeather_Refresh_Sequencial=0,
    TPWeather_Refresh_Concurrent,
};

enum {
    TPWeather_Temp_Units_F=0,
    TPWeather_Temp_Units_C,
    TPWeather_Temp_Units_K,
};

@interface  DataTask:NSObject

@property (strong,nonatomic) NSConnection *connection;
@property (strong,nonatomic) NSData *responseData;

@end

@protocol DataControllerDelegate <NSObject>

@optional

-(void)updateWeatherForZipcode:(NSString*)zipcode;
-(void)refreshComplete;
@end

@interface DataController : NSObject <NSURLConnectionDelegate>
@property (strong,nonatomic) NSMutableArray *weathers;
@property (assign,nonatomic) NSInteger refreshType;
@property(strong,nonatomic) NSDictionary *weatherImage;

@property (weak,nonatomic) id <DataControllerDelegate> delegate;
@property (assign,atomic) BOOL syncing;
@property (assign,nonatomic) NSInteger temperatureUnits;
@property (strong, nonatomic) NSString *baseURL;

+(DataController*)sharedDataController;
+(NSString*)getImageForWeather:(NSString*)weatherString;

-(NSInteger)count;
-(id)objectAtIndex:(NSInteger)index;
- (NSInteger)indexOfObject:(id)object;
-(void)removeObjectAtIndex:(NSInteger)index;
-(NSInteger)dataExist:(NSString*)zipcode;
-(void)addZipcode:(NSString*)zipcode;

-(void)saveSettings;
-(void)loadSettings;

-(void)refresh;

@end
