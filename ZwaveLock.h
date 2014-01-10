//
//  ZwaveLock.h
//  Home
//
//  Created by Drew Ingebretsen on 5/20/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZWaveNode.h"

#define UPNP_DEVICE_TYPE_DOOR_LOCK @"urn:schemas-micasaverde-com:device:DoorLock:1"

@interface ZwaveLock : ZwaveNode

@property (nonatomic, assign) BOOL locked;
@property (nonatomic, strong) NSArray *pinCodes;

-(ZwaveLock*)initWithDictionary:(NSDictionary*)dictionary;

-(void)setLocked:(BOOL)locked completion:(void(^)())callback;
-(void)createPin:(NSString*)pin withName:(NSString*)name completion:(void(^)())callback;
-(void)setPinValidity:(NSInteger)pinIndex fromDate:(NSDate*)fromDate toDate:(NSDate*)toDate completion:(void(^)())callback;
-(void)deletePin:(NSInteger)pinIndex completion:(void(^)())callback;

@end

@interface ZwaveLockPinCode : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSInteger pinIndex;
@property (nonatomic, strong) NSDate *endingValidDate;
@property (nonatomic, strong) NSDate *startingValidDate;

@end
