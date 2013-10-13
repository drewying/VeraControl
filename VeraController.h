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

#define VERA_LOCATE_CONTROLLER_NOTIFICATION @"com.peopletech.LocatedController"
#define VERA_DEVICES_DID_REFRESH_NOTIFICATION @"com.peopletech.DevicesDidRefresh"

@protocol VeraControllerDelegate <NSObject>
@end

@interface VeraController : NSObject

+(id)sharedController;

@property (nonatomic, strong) NSArray *rooms;
@property (nonatomic, strong) NSArray *switches;
@property (nonatomic, strong) NSArray *locks;
@property (nonatomic, strong) NSArray *dimmerSwitches;
@property (nonatomic, strong) NSArray *securitySensors;
@property (nonatomic, strong) NSArray *thermostats;
@property (nonatomic, strong) NSArray *hueBulbs;

@property (nonatomic, strong) NSString *ipAddress;
@property (nonatomic, strong) NSString *veraSerialNumber;
@property (nonatomic, strong) NSString *miosUsername;
@property (nonatomic, strong) NSString *miosPassword;
@property (nonatomic, strong) NSString *forwardServer;

@property (nonatomic, assign) BOOL useMiosRemoteService;

//Discovery
-(void)locateController;
-(void)refreshDevices;
-(void)refreshDevicesExtended;
-(void)startHeartbeat;
-(void)stopHeartbeat;

@end
