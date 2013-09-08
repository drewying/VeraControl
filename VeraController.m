//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "VeraController.h"
#import "ZwaveDimmerSwitch.h"
#import "ZwaveSwitch.h"
#import "ZwaveLock.h"
#import "ZWaveThermostat.h"
#import "ZWaveHumiditySensor.h"
#import "ZwaveSensor.h"

#define VERA_IP_ADDRESS @"192.168.8.30"
#define EXCLUDED_SWITCH_LIST @[@41,@21]

#define SERVICE_SWITCH @"SwitchPower1"
#define SERVICE_DIMMER @"Dimming1"
#define SERVICE_LOCK @"DoorLock1"
#define SERVICE_HEAT @"TemperatureSetpoint1_Heat"
#define SERVICE_COOL @"TemperatureSetpoint1_Cool"
#define SERVICE_HVAC_FAN @"HVAC_FanOperatingMode1"
#define SERVICE_HVAC_THERMO @"HVAC_UserOperatingMode1"

@interface VeraController()
@property (nonatomic, strong) NSTimer *heartBeat;
@end

@implementation VeraController

static VeraController *sharedInstance;

+(id)sharedController{
    @synchronized(self) {
        if (sharedInstance == nil)
            sharedInstance = [[self alloc] init];
    }
    return sharedInstance;
}

-(void)startHeartbeat{
    self.heartBeat = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(refreshDevices) userInfo:nil repeats:YES];
    [self.heartBeat fire];
}

-(void)stopHeartbeat{
    [self.heartBeat invalidate];
}

-(NSString *)ipAddress{
    return VERA_IP_ADDRESS;
}

-(void)performAction:(NSString*)action onDevice:(NSString*)deviceId usingService:(NSString*)service completion:(void(^)(NSURLResponse *response, NSData *data, NSError *devices))callback{
    
    NSString *htmlString = [NSString stringWithFormat:@"http://%@:3480/data_request?id=action&output_format=json&DeviceNum=%@&serviceId=urn:upnp-org:serviceId:%@&action=%@", self.ipAddress, deviceId, service, action];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:htmlString]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        callback(response, data, error);
    }];
}

-(void)performCommand:(NSString*)command completion:(void(^)(NSURLResponse *response, NSData *data, NSError *devices))callback{
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@:3480/data_request?%@",self.ipAddress, command]]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        callback(response, data, error);
    }];
}

-(void)setZwaveSwitch:(ZwaveSwitch*)zSwitch toState:(BOOL)state completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetTarget&newTargetValue=%i",(state == YES)] onDevice:zSwitch.identifier usingService:SERVICE_SWITCH completion:callback];
}

-(void)setZwaveDimmer:(ZwaveDimmerSwitch*)dimmer toBrightnessLevel:(NSInteger)level completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetLoadLevelTarget&newLoadlevelTarget=%i",level] onDevice:dimmer.identifier usingService:SERVICE_DIMMER completion:callback];
}

-(void)setZwaveLock:(ZwaveLock*)lock toLocked:(BOOL)locked completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetTarget&newTargetValue=%i",(locked == YES)] onDevice:lock.identifier usingService:SERVICE_LOCK completion:callback];
}

-(void)setZwaveThermostat:(ZWaveThermostat*)thermostat toHeat:(NSInteger)heat completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetCurrentSetpoint&NewCurrentSetpoint=%i", heat] onDevice:thermostat.identifier usingService:SERVICE_HEAT completion:callback];
}

-(void)setZwaveThermostat:(ZWaveThermostat*)thermostat toCool:(NSInteger)cool completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetCurrentSetpoint&NewCurrentSetpoint=%i", cool] onDevice:thermostat.identifier usingService:SERVICE_COOL completion:callback];
}

-(void)setZwaveThermostat:(ZWaveThermostat*)thermostat toFanMode:(NSString*)fan completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetMode&NewMode=%@", fan] onDevice:thermostat.identifier usingService:SERVICE_HVAC_FAN completion:callback];
}

-(void)setZwaveThermostat:(ZWaveThermostat*)thermostat toThermoMode:(NSString*)thermo completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetModeTarget&NewModeTarget=%@", thermo] onDevice:thermostat.identifier usingService:SERVICE_HVAC_THERMO completion:callback];
}

-(void)refreshDevices{
    [self performCommand:@"id=sdata" completion:^(NSURLResponse *response, NSData *data, NSError *error){
        NSHTTPURLResponse *r = (NSHTTPURLResponse*)response;
        if (r.statusCode ==200){
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            NSArray *devices = [responseDictionary objectForKey:@"devices"];
            NSArray *categories = [responseDictionary objectForKey:@"categories"];
            
            
            
            NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
            for (NSDictionary *category in categories){
                NSNumber *categoryID = [category objectForKey:@"id"];
                NSArray *filteredArray = [devices filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category==%@",categoryID]];
                [results setObject:[filteredArray copy] forKey:[category objectForKey:@"name"]];
            }
            
            //NSLog(@"Results:%@",results);
            
            NSMutableArray *dimmableLights = [NSMutableArray array];
            for (NSDictionary *dictionary in [results objectForKey:@"Dimmable Light"]){
                ZwaveDimmerSwitch *dLight = [[ZwaveDimmerSwitch alloc] init];
                dLight.name = [dictionary objectForKey:@"name"];
                dLight.identifier = [dictionary objectForKey:@"id"];
                dLight.brightness = [[dictionary objectForKey:@"level"] integerValue];
                dLight.state = [[dictionary objectForKey:@"status"] boolValue];
                [dimmableLights addObject:dLight];
            }
            self.dimmerSwitches = [dimmableLights copy];
            
            NSMutableArray *switches = [NSMutableArray array];
            for (NSDictionary *dictionary in [results objectForKey:@"Switch"]){
                ZwaveSwitch *zSwitch = [[ZwaveSwitch alloc] init];
                zSwitch.name = [dictionary objectForKey:@"name"];
                zSwitch.identifier = [dictionary objectForKey:@"id"];
                zSwitch.state = [[dictionary objectForKey:@"status"] boolValue];
                if ([EXCLUDED_SWITCH_LIST filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"integerValue == %i", [zSwitch.identifier integerValue]]].count==0){
                    [switches addObject:zSwitch];
                }
            }
            
            self.switches = [switches copy];
            
            NSMutableArray *locks = [NSMutableArray array];
            //Locks
            for (NSDictionary *dictionary in [results objectForKey:@"Door lock"]){
                ZwaveLock *zLock = [[ZwaveLock alloc] init];
                zLock.name = [dictionary objectForKey:@"name"];
                zLock.identifier = [dictionary objectForKey:@"id"];
                zLock.locked = [[dictionary objectForKey:@"locked"] boolValue];
                [locks addObject:zLock];
            }
            self.locks = [locks copy];
           
            
            
            NSMutableArray *sensors = [NSMutableArray array];
            //Sensors
            for (NSDictionary *dictionary in [results objectForKey:@"Sensor"]){
                ZwaveSensor *zSensor = [[ZwaveSensor alloc] init];
                zSensor.name = [dictionary objectForKey:@"name"];
                zSensor.identifier = [dictionary objectForKey:@"id"];
                zSensor.tripped = [[dictionary objectForKey:@"tripped"] boolValue];
                zSensor.armed = [[dictionary objectForKey:@"armed"] boolValue];
                zSensor.lastTrip = [NSDate dateWithTimeIntervalSince1970:[[dictionary objectForKey:@"lasttrip"] integerValue]];
                
                [sensors addObject:zSensor];
            }
            self.sensors = [sensors copy];
            
            NSDictionary *thermoDictionary = [[results objectForKey:@"Thermostat"] objectAtIndex:0];
            ZWaveThermostat *thermo = [[ZWaveThermostat alloc] init];
            thermo.name = [thermoDictionary objectForKey:@"name"];
            thermo.identifier = [thermoDictionary objectForKey:@"id"];
            thermo.heatTermperatureSet = [[thermoDictionary objectForKey:@"heatsp"] integerValue];
            thermo.coolTermperatureSet = [[thermoDictionary objectForKey:@"coolsp"] integerValue];
            thermo.temperature = [[thermoDictionary objectForKey:@"temperature"] integerValue];
            thermo.thermoMode = [thermoDictionary objectForKey:@"mode"];
            thermo.fanMode = [thermoDictionary objectForKey:@"fanmode"];
            thermo.thermoStatus = [thermoDictionary objectForKey:@"hvacstate"];
            self.mainThermostat = thermo;
            
            NSDictionary *humidDictionary = [[results objectForKey:@"Humidity Sensor"] objectAtIndex:0];
            ZWaveHumiditySensor *sensor = [[ZWaveHumiditySensor alloc] init];
            sensor.name = [humidDictionary objectForKey:@"name"];
            sensor.identifier = [humidDictionary objectForKey:@"id"];
            sensor.humidity = [[humidDictionary objectForKey:@"humidity"] integerValue];
            self.mainHumiditySensor = sensor;
        }
        
    
        [[NSNotificationCenter defaultCenter] postNotificationName:@"com.peopletech.veraObjects" object:nil];
        
        
    }];
}


@end
