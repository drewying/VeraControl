//
//  VeraController.h
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

@class ZwaveSwitch;
@class ZwaveDimmerSwitch;
@class ZwaveLock;
@class ZwaveHumiditySensor;
@class ZwaveThermostat;

#import <Foundation/Foundation.h>

#define VERA_DEVICES_DID_REFRESH_NOTIFICATION @"com.peopletech.DevicesDidRefresh"

@protocol VeraControllerDelegate <NSObject>
@end

@interface VeraController : NSObject

+(id)sharedController;

@property (nonatomic, strong) NSArray *rooms;
@property (nonatomic, strong) NSArray *switches;
@property (nonatomic, strong) NSArray *locks;
@property (nonatomic, strong) NSArray *dimmerSwitches;
@property (nonatomic, strong) NSArray *sensors;
@property (nonatomic, strong) NSString *ipAddress;
@property (nonatomic, assign) BOOL useMiosRemoteService;
@property (nonatomic, strong) ZwaveThermostat *mainThermostat;
@property (nonatomic, strong) ZwaveHumiditySensor *mainHumiditySensor;

//Discovery
-(void)refreshDevices;
-(void)startHeartbeat;
-(void)stopHeartbeat;

@end
