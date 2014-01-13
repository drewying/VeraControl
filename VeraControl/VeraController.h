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
@class VeraScene;

#import <Foundation/Foundation.h>


//This notification is when the controller is located
#define VERA_LOCATE_CONTROLLER_NOTIFICATION @"com.peopletech.LocatedController"
//This notification goes out after devices are fully refreshed
#define VERA_DEVICES_DID_REFRESH_NOTIFICATION @"com.peopletech.DevicesDidRefresh"

@protocol VeraControllerDelegate <NSObject>
@end

@interface VeraController : NSObject

//Singleton instance of the controller
+(id)sharedController;

//Must be defined for remote access or auto Vera discovery
@property (nonatomic, strong) NSString *miosUsername;
@property (nonatomic, strong) NSString *miosPassword;

//These arrays will be automatically populated by running the refreshDevices methods
@property (nonatomic, readonly) NSArray *rooms;
@property (nonatomic, readonly) NSArray *scenes;
@property (nonatomic, readonly) NSArray *switches;
@property (nonatomic, readonly) NSArray *locks;
@property (nonatomic, readonly) NSArray *dimmerSwitches;
@property (nonatomic, readonly) NSArray *securitySensors;
@property (nonatomic, readonly) NSArray *thermostats;
@property (nonatomic, readonly) NSArray *hueBulbs;
@property (nonatomic, readonly) NSArray *ipCameras;

//These dictionaries store the rooms and devices by id so that they can later be referenced.
@property (nonatomic, strong) NSMutableDictionary *roomsDictionary;
@property (nonatomic, strong) NSMutableDictionary *deviceDictionary;

//These values will be automatically found by running the findVeraController method. I'm keeping them public for manual override if needed
@property (nonatomic, strong) NSString *ipAddress;
@property (nonatomic, strong) NSString *veraSerialNumber;
@property (nonatomic, assign) BOOL useMiosRemoteService;
@property (nonatomic, strong) NSString *miosHostname;

//Discovery
-(void)findVeraController;

//The refreshDevice commands polls the device and builds a list of all devices.
-(void)refreshDevices;

//Will automatically run refreshDevices at a specified period.
-(void)startHeartbeatWithInterval:(NSInteger)interval;
-(void)stopHeartbeat;

//This returns an empty scene for scene creation
-(VeraScene*)getEmptyScene;

@end
