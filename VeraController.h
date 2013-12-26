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

//These arrays will be automatically populated by running the refreshDevices or refreshDeviceExtended methods

@property (nonatomic, strong) NSArray *rooms;
@property (nonatomic, strong) NSArray *scenes;
@property (nonatomic, strong) NSArray *switches;
@property (nonatomic, strong) NSArray *locks;
@property (nonatomic, strong) NSArray *dimmerSwitches;
@property (nonatomic, strong) NSArray *securitySensors;
@property (nonatomic, strong) NSArray *thermostats;
@property (nonatomic, strong) NSArray *hueBulbs;
@property (nonatomic, strong) NSArray *ipCameras;

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

//The refreshDevice commands polls the device and build a list of all devices.
-(void)refreshDevices;


//Will automatically run refreshDevices at a specified period.
-(void)startHeartbeat;
-(void)stopHeartbeat;

@end
