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

@protocol VeraControllerDelegate <NSObject>
@end

@interface VeraController : NSObject

+(id)sharedController;

@property (nonatomic, strong) NSArray *switches;
@property (nonatomic, strong) NSArray *locks;
@property (nonatomic, strong) NSArray *dimmerSwitches;
@property (nonatomic, strong) NSArray *sensors;
@property (nonatomic, strong) NSString *ipAddress;
@property (nonatomic, strong) ZwaveThermostat *mainThermostat;
@property (nonatomic, strong) ZwaveHumiditySensor *mainHumiditySensor;

//Lights/Switches
-(void)setZwaveSwitch:(ZwaveSwitch*)zSwitch toState:(BOOL)state completion:(void(^)())callback;
-(void)setZwaveDimmer:(ZwaveDimmerSwitch*)dimmer toBrightnessLevel:(NSInteger)level completion:(void(^)())callback;

//Security
-(void)setZwaveLock:(ZwaveLock*)lock toLocked:(BOOL)locked completion:(void(^)())callback;

//Climate
-(void)setZwaveThermostat:(ZwaveThermostat*)thermostat toHeat:(NSInteger)heat completion:(void(^)())callback;
-(void)setZwaveThermostat:(ZwaveThermostat*)thermostat toCool:(NSInteger)cool completion:(void(^)())callback;
-(void)setZwaveThermostat:(ZwaveThermostat*)thermostat toFanMode:(NSString*)fan completion:(void(^)())callback;
-(void)setZwaveThermostat:(ZwaveThermostat*)thermostat toThermoMode:(NSString*)thermo completion:(void(^)())callback;

//Discovery
-(void)refreshDevices;
-(void)startHeartbeat;
-(void)stopHeartbeat;

@end
