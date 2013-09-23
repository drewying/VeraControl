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
#import "ZwaveSecuritySensor.h"
#import "ZwavePhillipsHueBulb.h"
#import "VeraRoom.h"

#define EXCLUDED_SWITCH_LIST @[@41,@21]

#define UPNP_DEVICE_TYPE_DIMMABLE_SWITCH @"urn:schemas-upnp-org:device:DimmableLight:1"
#define UPNP_DEVICE_TYPE_DOOR_LOCK @"urn:schemas-micasaverde-com:device:DoorLock:1"
#define UPNP_DEVICE_TYPE_SWITCH @"urn:schemas-upnp-org:device:BinaryLight:1"
#define UPNP_DEVICE_TYPE_MOTION_SENSOR @"urn:schemas-micasaverde-com:device:MotionSensor:1"
#define UPNP_DEVICE_TYPE_NEST_THERMOSTAT @"urn:schemas-watou-com:device:HVAC_ZoneThermostat:1"
#define UPNP_DEVICE_TYPE_PHILLIPS_HUE_BULB @"urn:schemas-intvelt-com:device:HueLamp:1"

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

-(NSString *)controlUrl{
    if (self.useMiosRemoteService){
        return [NSString stringWithFormat:@"http://fwd5.mios.com/%@/%@/%@", self.miosUsername, self.miosPassword, self.veraSerialNumber];
    }
    else{
        return [NSString stringWithFormat:@"http://%@:3480", self.ipAddress];
    }
}

-(void)performCommand:(NSString*)command completion:(void(^)(NSURLResponse *response, NSData *data, NSError *devices))callback{
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/data_request?%@",[self controlUrl], command]]] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        callback(response, data, error);
    }];
}

-(void)refreshDevicesExtended{
    [self performCommand:@"id=user_data" completion:^(NSURLResponse *response, NSData *data, NSError *error){
        NSHTTPURLResponse *r = (NSHTTPURLResponse*)response;
        if (r.statusCode ==200){
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            
            
            NSArray *parsedRooms = [responseDictionary objectForKey:@"rooms"];
            
            //Gather the rooms
            VeraRoom *unassignedRoom = [[VeraRoom alloc] init];
            unassignedRoom.name = @"Unassigned";
            unassignedRoom.identifier = @"0";
            unassignedRoom.section = @"0";
            unassignedRoom.devices = @[];
            self.rooms = @[unassignedRoom];
            for (NSDictionary *parsedRoom in parsedRooms){
                VeraRoom *room = [[VeraRoom alloc] init];
                room.name = [parsedRoom objectForKey:@"name"];
                room.identifier = [[parsedRoom objectForKey:@"id"] stringValue];
                room.section = [parsedRoom objectForKey:@"section"];
                self.rooms = [self.rooms arrayByAddingObject:room];
            }
            
            //Gather the devices
            
            NSArray *devices = [responseDictionary objectForKey:@"devices"];
            
            self.switches = @[];
            self.dimmerSwitches = @[];
            self.locks = @[];
            self.thermostats = @[];
            self.securitySensors = @[];
            self.hueBulbs = @[];
            
            for (NSDictionary *deviceDictionary in devices){
                NSString *deviceType = [deviceDictionary objectForKey:@"device_type"];
                
                ZwaveNode *device;
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_DIMMABLE_SWITCH]){
                    device = [[ZwaveDimmerSwitch alloc] init];
                    ZwaveDimmerSwitch *dSwitch = (ZwaveDimmerSwitch*)device;
                    for (NSDictionary *serviceDictionary in [deviceDictionary objectForKey:@"services"]){
                        NSString *service = [serviceDictionary objectForKey:@"service"];
                        if ([service isEqualToString:UPNP_SERVICE_DIMMER]){
                            dSwitch.brightness = [[serviceDictionary objectForKey:@"value"] integerValue];
                        }
                        if ([service isEqualToString:UPNP_SERVICE_SWITCH]){
                            dSwitch.on = [[serviceDictionary objectForKey:@"value"] integerValue];
                        }
                    }
                    self.dimmerSwitches = [self.dimmerSwitches arrayByAddingObject:dSwitch];
                }
                
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_SWITCH]){
                    device = [[ZwaveSwitch alloc] init];
                    ZwaveSwitch *zSwitch = (ZwaveSwitch*)device;
                    for (NSDictionary *serviceDictionary in [deviceDictionary objectForKey:@"services"]){
                        NSString *service = [serviceDictionary objectForKey:@"service"];
                        if ([service isEqualToString:UPNP_SERVICE_SWITCH]){
                            zSwitch.on = [[serviceDictionary objectForKey:@"value"] integerValue];
                        }
                    }
                    self.switches = [self.switches arrayByAddingObject:zSwitch];
                }
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_DOOR_LOCK]){
                    device = [[ZwaveLock alloc] init];
                    ZwaveLock *zLock = (ZwaveLock*)device;
                    
                    for (NSDictionary *serviceDictionary in [deviceDictionary objectForKey:@"services"]){
                        NSString *service = [serviceDictionary objectForKey:@"service"];
                        if ([service isEqualToString:UPNP_SERVICE_DOOR_LOCK]){
                            zLock.locked = [[serviceDictionary objectForKey:@"value"] integerValue];
                        }
                    }
                    
                    self.locks = [self.locks arrayByAddingObject:zLock];
                    
                }
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_NEST_THERMOSTAT]){
                    device = [[ZwaveThermostat alloc] init];
                    ZwaveThermostat *zThermo = (ZwaveThermostat*)device;
                    for (NSDictionary *serviceDictionary in [deviceDictionary objectForKey:@"services"]){
                        NSString *service = [serviceDictionary objectForKey:@"service"];
                        if ([service isEqualToString:UPNP_SERVICE_TEMPERATURE_SENSOR]){
                            zThermo.temperature = [[serviceDictionary objectForKey:@"value"] integerValue];
                        }
                        if ([service isEqualToString:UPNP_SERVICE_HEAT]){
                            zThermo.temperatureHeatTarget = [[serviceDictionary objectForKey:@"value"] integerValue];
                        }
                        if ([service isEqualToString:UPNP_SERVICE_COOL]){
                            zThermo.temperatureCoolTarget = [[serviceDictionary objectForKey:@"value"] integerValue];
                        }
                        if ([service isEqualToString:UPNP_SERVICE_HVAC_FAN]){
                            zThermo.fanMode = [serviceDictionary objectForKey:@"value"];
                        }
                        if ([service isEqualToString:UPNP_SERVICE_HVAC_THERMO]){
                            zThermo.thermoMode = [serviceDictionary objectForKey:@"value"];
                        }
                        self.thermostats = [self.thermostats arrayByAddingObject:zThermo];
                    }
                    
                }
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_MOTION_SENSOR]){
                    device = [[ZwaveSecuritySensor alloc] init];
                    ZwaveSecuritySensor *zSensor = (ZwaveSecuritySensor*)device;
                    for (NSDictionary *serviceDictionary in [deviceDictionary objectForKey:@"services"]){
                        NSString *service = [serviceDictionary objectForKey:@"service"];
                        if ([service isEqualToString:UPNP_SERVICE_SENSOR_SECURITY]){
                            NSString *variable = [serviceDictionary objectForKey:@"variable"];
                            if ([variable isEqualToString:@"Armed"]){
                                zSensor.armed = [[serviceDictionary objectForKey:@"value"] integerValue];
                            }
                            if ([variable isEqualToString:@"ArmedTripped"]){
                                //TODO
                                
                            }
                            if ([variable isEqualToString:@"Tripped"]){
                                zSensor.tripped = [[serviceDictionary objectForKey:@"value"] integerValue];
                            }
                        }
                    }
                    self.securitySensors = [self.securitySensors arrayByAddingObject:zSensor];
                }
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_PHILLIPS_HUE_BULB]){
                    device = [[ZwavePhillipsHueBulb alloc] init];
                    ZwavePhillipsHueBulb *zHue = (ZwavePhillipsHueBulb*)device;
                    for (NSDictionary *serviceDictionary in [deviceDictionary objectForKey:@"services"]){
                        NSString *service = [serviceDictionary objectForKey:@"service"];
                        if ([service isEqualToString:UPNP_SERVICE_PHILLIPS_HUE_BULB]){
                            NSString *variable = [serviceDictionary objectForKey:@"variable"];
                            if ([variable isEqualToString:@"Hue"]){
                                zHue.hue = [[serviceDictionary objectForKey:@"value"] integerValue];
                            }
                            if ([variable isEqualToString:@"Saturation"]){
                                zHue.saturation = [[serviceDictionary objectForKey:@"value"] integerValue];
                                
                            }
                            if ([variable isEqualToString:@"Temperature"]){
                                zHue.temperature = [[serviceDictionary objectForKey:@"value"] integerValue];
                            }
                        }
                    }
                    self.hueBulbs = [self.hueBulbs arrayByAddingObject:zHue];
                }
                
                //Add the device to the room
                if (device){
                    device.identifier = [deviceDictionary objectForKey:@"id"];
                    device.name = [deviceDictionary objectForKey:@"name"];
                    NSArray *array = [self.rooms filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", [deviceDictionary objectForKey:@"room"]]];
                    if (array.count == 1){
                        VeraRoom *room = [array objectAtIndex:0];
                        room.devices = [room.devices arrayByAddingObject:device];
                    }
                }
                
               
                
            }
            
            
            [[NSNotificationCenter defaultCenter] postNotificationName:VERA_DEVICES_DID_REFRESH_NOTIFICATION object:nil];
        
        }
    }];
        
}

-(void)refreshDevices{
    [self performCommand:@"id=sdata" completion:^(NSURLResponse *response, NSData *data, NSError *error){
        NSHTTPURLResponse *r = (NSHTTPURLResponse*)response;
        if (r.statusCode ==200){
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            NSArray *parsedRooms = [responseDictionary objectForKey:@"rooms"];
            NSArray *devices = [responseDictionary objectForKey:@"devices"];
            NSArray *categories = [responseDictionary objectForKey:@"categories"];
            
            //Gather the rooms
            VeraRoom *unassignedRoom = [[VeraRoom alloc] init];
            unassignedRoom.name = @"Unassigned";
            unassignedRoom.identifier = @"0";
            unassignedRoom.section = @"0";
            unassignedRoom.devices = @[];
            self.rooms = @[unassignedRoom];
            for (NSDictionary *parsedRoom in parsedRooms){
                VeraRoom *room = [[VeraRoom alloc] init];
                room.name = [parsedRoom objectForKey:@"name"];
                room.identifier = [[parsedRoom objectForKey:@"id"] stringValue];
                room.section = [parsedRoom objectForKey:@"section"];
                self.rooms = [self.rooms arrayByAddingObject:room];
            }
            
            
            //Organize the devices by category
            NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
            for (NSDictionary *category in categories){
                NSNumber *categoryID = [category objectForKey:@"id"];
                NSArray *filteredArray = [devices filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"category==%@",categoryID]];
                [results setObject:[filteredArray copy] forKey:[category objectForKey:@"name"]];
            }
            
           
            //Add the devices
            NSMutableArray *dimmableLights = [NSMutableArray array];
            for (NSDictionary *dictionary in [results objectForKey:@"Dimmable Light"]){
                ZwaveDimmerSwitch *dLight = [[ZwaveDimmerSwitch alloc] init];
                dLight.name = [dictionary objectForKey:@"name"];
                dLight.identifier = [dictionary objectForKey:@"id"];
                dLight.brightness = [[dictionary objectForKey:@"level"] integerValue];
                dLight.on = [[dictionary objectForKey:@"status"] boolValue];
                dLight.controllerUrl = [self controlUrl];
                [dimmableLights addObject:dLight];
                
                NSArray *array = [self.rooms filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", [[dictionary objectForKey:@"room"] stringValue]]];
                if (array.count == 1){
                    VeraRoom *room = [array objectAtIndex:0];
                    room.devices = [room.devices arrayByAddingObject:dLight];
                }
                
            }
            self.dimmerSwitches = [dimmableLights copy];
            
            NSMutableArray *switches = [NSMutableArray array];
            for (NSDictionary *dictionary in [results objectForKey:@"Switch"]){
                ZwaveSwitch *zSwitch = [[ZwaveSwitch alloc] init];
                zSwitch.name = [dictionary objectForKey:@"name"];
                zSwitch.identifier = [[dictionary objectForKey:@"id"] stringValue];
                zSwitch.on = [[dictionary objectForKey:@"status"] boolValue];
                zSwitch.controllerUrl = [self controlUrl];
                if ([EXCLUDED_SWITCH_LIST filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"integerValue == %i", [zSwitch.identifier integerValue]]].count==0){
                    [switches addObject:zSwitch];
                }
                
                NSArray *array = [self.rooms filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", [[dictionary objectForKey:@"room"] stringValue]]];
                if (array.count == 1){
                    VeraRoom *room = [array objectAtIndex:0];
                    room.devices = [room.devices arrayByAddingObject:zSwitch];
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
                zLock.controllerUrl = [self controlUrl];
                [locks addObject:zLock];
                
                NSArray *array = [self.rooms filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", [[dictionary objectForKey:@"room"] stringValue]]];
                if (array.count == 1){
                    VeraRoom *room = [array objectAtIndex:0];
                    room.devices = [room.devices arrayByAddingObject:zLock];
                }
            }
            self.locks = [locks copy];
           
            
            
            NSMutableArray *sensors = [NSMutableArray array];
            
            //Sensors
            for (NSDictionary *dictionary in [results objectForKey:@"Sensor"]){
                ZwaveSecuritySensor *zSensor = [[ZwaveSecuritySensor alloc] init];
                zSensor.name = [dictionary objectForKey:@"name"];
                zSensor.identifier = [dictionary objectForKey:@"id"];
                zSensor.tripped = [[dictionary objectForKey:@"tripped"] boolValue];
                zSensor.armed = [[dictionary objectForKey:@"armed"] boolValue];
                zSensor.lastTrip = [NSDate dateWithTimeIntervalSince1970:[[dictionary objectForKey:@"lasttrip"] integerValue]];
                zSensor.controllerUrl = [self controlUrl];
                [sensors addObject:zSensor];
                
                NSArray *array = [self.rooms filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", [[dictionary objectForKey:@"room"] stringValue]]];
                if (array.count == 1){
                    VeraRoom *room = [array objectAtIndex:0];
                    room.devices = [room.devices arrayByAddingObject:zSensor];
                }
            }
            self.securitySensors = [sensors copy];
            
            NSDictionary *thermoDictionary = [[results objectForKey:@"Thermostat"] objectAtIndex:0];
            ZwaveThermostat *thermo = [[ZwaveThermostat alloc] init];
            thermo.name = [thermoDictionary objectForKey:@"name"];
            thermo.identifier = [thermoDictionary objectForKey:@"id"];
            thermo.temperatureHeatTarget = [[thermoDictionary objectForKey:@"heatsp"] integerValue];
            thermo.temperatureCoolTarget = [[thermoDictionary objectForKey:@"coolsp"] integerValue];
            thermo.temperature = [[thermoDictionary objectForKey:@"temperature"] integerValue];
            thermo.thermoMode = [thermoDictionary objectForKey:@"mode"];
            thermo.fanMode = [thermoDictionary objectForKey:@"fanmode"];
            thermo.thermoStatus = [thermoDictionary objectForKey:@"hvacstate"];
            thermo.controllerUrl = [self controlUrl];
            //self.mainThermostat = thermo;
            
            NSDictionary *humidDictionary = [[results objectForKey:@"Humidity Sensor"] objectAtIndex:0];
            ZwaveHumiditySensor *sensor = [[ZwaveHumiditySensor alloc] init];
            sensor.name = [humidDictionary objectForKey:@"name"];
            sensor.identifier = [humidDictionary objectForKey:@"id"];
            sensor.humidity = [[humidDictionary objectForKey:@"humidity"] integerValue];
            sensor.controllerUrl = [self controlUrl];
            //self.mainHumiditySensor = sensor;
        }
        
    
        [[NSNotificationCenter defaultCenter] postNotificationName:VERA_DEVICES_DID_REFRESH_NOTIFICATION object:nil];
    }];
}


@end
