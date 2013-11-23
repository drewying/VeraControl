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
#import "IPCamera.h"
#import "VeraRoom.h"

#define EXCLUDED_SWITCH_LIST @[]

#define UPNP_DEVICE_TYPE_DIMMABLE_SWITCH @"urn:schemas-upnp-org:device:DimmableLight:1"
#define UPNP_DEVICE_TYPE_DOOR_LOCK @"urn:schemas-micasaverde-com:device:DoorLock:1"
#define UPNP_DEVICE_TYPE_SWITCH @"urn:schemas-upnp-org:device:BinaryLight:1"
#define UPNP_DEVICE_TYPE_MOTION_SENSOR @"urn:schemas-micasaverde-com:device:MotionSensor:1"
#define UPNP_DEVICE_TYPE_NEST_THERMOSTAT @"urn:schemas-watou-com:device:HVAC_ZoneThermostat:1"
#define UPNP_DEVICE_TYPE_PHILLIPS_HUE_BULB @"urn:schemas-intvelt-com:device:HueLamp:1"
#define UPNP_DEVICE_TYPE_IP_CAMERA @"urn:schemas-upnp-org:device:DigitalSecurityCamera:2"

//This is the default forward server
#define FORWARD_SERVER_DEFAULT @"fwd5.mios.com"

@interface VeraController()
@property (nonatomic, strong) NSTimer *heartBeat;

@end

@implementation VeraController

static VeraController *sharedInstance;

+(id)sharedController{
    @synchronized(self) {
        if (sharedInstance == nil){
            sharedInstance = [[self alloc] init];
            sharedInstance.extendedMode = YES;
        }
        
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


-(NSString *)locateUrl{
    if (self.miosUsername.length == 0)
        return [NSString stringWithFormat:@"https://sta1.mios.com/locator_json.php?username=user"];
    
    return [NSString stringWithFormat:@"https://sta1.mios.com/locator_json.php?username=%@", self.miosUsername];
}

-(NSString *)controlUrl{
    if (self.miosHostname.length == 0)
        self.miosHostname = FORWARD_SERVER_DEFAULT;
    
    if (self.useMiosRemoteService || self.ipAddress.length == 0){
        if ([self.veraSerialNumber length] == 0)
            return [NSString stringWithFormat:@"http://%@/%@/%@", self.miosHostname, self.miosUsername, self.miosPassword];
        return [NSString stringWithFormat:@"http://%@/%@/%@/%@", self.miosHostname, self.miosUsername, self.miosPassword, self.veraSerialNumber];
    }
    else{
        return [NSString stringWithFormat:@"http://%@:3480", self.ipAddress];
    }
}


-(void)findVeraController{
    NSURL *url = [NSURL URLWithString:[self locateUrl]];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSDictionary *miosLocatorResponse = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
        NSArray *units = [miosLocatorResponse objectForKey:@"units"];
        if (units.count > 0){
            NSDictionary *mainUnit = [units objectAtIndex:0];
            self.veraSerialNumber = [mainUnit objectForKey:@"serialNumber"];
            NSString *ipAddress = [mainUnit objectForKey:@"ipAddress"];
            self.ipAddress = ipAddress;
            self.miosHostname = [mainUnit objectForKey:@"active_server"];
            self.useMiosRemoteService = (self.ipAddress.length < 7);
            
            //[self refreshDevices];
            [[NSNotificationCenter defaultCenter] postNotificationName:VERA_LOCATE_CONTROLLER_NOTIFICATION object:nil];
        }
    }];
}

/*-(void)locateController {
    NSURL *url = [NSURL URLWithString:[self locateUrl]];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
        NSDictionary *responseDataInner = [[responseDictionary objectForKey:@"units"] objectAtIndex:0];
        
        self.ipAddress = [responseDataInner objectForKey:@"ipAddress"];
        self.veraSerialNumber = [responseDataInner objectForKey:@"serialNumber"];
        self.forwardServer = [[[responseDataInner objectForKey:@"forwardServers"] objectAtIndex:0] objectForKey:@"hostName"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:VERA_LOCATE_CONTROLLER_NOTIFICATION object:nil];
    }];
}*/

-(void)performCommand:(NSString*)command completion:(void(^)(NSURLResponse *response, NSData *data, NSError *devices))callback{
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/data_request?%@",[self controlUrl], command]]] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        callback(response, data, error);
    }];
}

-(void)refreshDevices{
    if (self.extendedMode){
        [self getDevicesExtended];
    }
    else{
        [self getDevices];
    }
}


-(void)getDevicesExtended{
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
            
            NSArray *switches = @[];
            NSArray *dimmerSwitches = @[];
            NSArray *locks = @[];
            NSArray *thermostats = @[];
            NSArray *securitySensors = @[];
            NSArray *hueBulbs = @[];
            NSArray *ipCameras = @[];
            
            for (NSDictionary *deviceDictionary in devices){
                NSString *deviceType = [deviceDictionary objectForKey:@"device_type"];
                
                ZwaveNode *device;
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_DIMMABLE_SWITCH]){
                    device = [[ZwaveDimmerSwitch alloc] init];
                    ZwaveDimmerSwitch *dSwitch = (ZwaveDimmerSwitch*)device;
                    for (NSDictionary *serviceDictionary in [deviceDictionary objectForKey:@"states"]){
                        NSString *service = [serviceDictionary objectForKey:@"service"];
                        if ([service isEqualToString:UPNP_SERVICE_DIMMER]){
                            dSwitch.brightness = [[serviceDictionary objectForKey:@"value"] integerValue];
                        }
                        if ([service isEqualToString:UPNP_SERVICE_SWITCH]){
                            dSwitch.on = [[serviceDictionary objectForKey:@"value"] integerValue];
                        }
                    }
                    dimmerSwitches = [dimmerSwitches arrayByAddingObject:dSwitch];
                }
                
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_SWITCH]){
                    device = [[ZwaveSwitch alloc] init];
                    ZwaveSwitch *zSwitch = (ZwaveSwitch*)device;
                    for (NSDictionary *serviceDictionary in [deviceDictionary objectForKey:@"states"]){
                        NSString *service = [serviceDictionary objectForKey:@"service"];
                        if ([service isEqualToString:UPNP_SERVICE_SWITCH]){
                            zSwitch.on = [[serviceDictionary objectForKey:@"value"] integerValue];
                        }
                    }
                    switches = [switches arrayByAddingObject:zSwitch];
                }
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_DOOR_LOCK]){
                    device = [[ZwaveLock alloc] init];
                    ZwaveLock *zLock = (ZwaveLock*)device;
                    
                    for (NSDictionary *serviceDictionary in [deviceDictionary objectForKey:@"states"]){
                        NSString *service = [serviceDictionary objectForKey:@"service"];
                        if ([service isEqualToString:UPNP_SERVICE_DOOR_LOCK]){
                            zLock.locked = [[serviceDictionary objectForKey:@"value"] integerValue];
                        }
                    }
                    
                    locks = [locks arrayByAddingObject:zLock];
                    
                }
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_NEST_THERMOSTAT]){
                    device = [[ZwaveThermostat alloc] init];
                    ZwaveThermostat *zThermo = (ZwaveThermostat*)device;
                    for (NSDictionary *serviceDictionary in [deviceDictionary objectForKey:@"states"]){
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
                        thermostats = [thermostats arrayByAddingObject:zThermo];
                    }
                    
                }
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_MOTION_SENSOR]){
                    device = [[ZwaveSecuritySensor alloc] init];
                    ZwaveSecuritySensor *zSensor = (ZwaveSecuritySensor*)device;
                    for (NSDictionary *serviceDictionary in [deviceDictionary objectForKey:@"states"]){
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
                    securitySensors = [securitySensors arrayByAddingObject:zSensor];
                }
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_PHILLIPS_HUE_BULB]){
                    device = [[ZwavePhillipsHueBulb alloc] init];
                    ZwavePhillipsHueBulb *zHue = (ZwavePhillipsHueBulb*)device;
                    for (NSDictionary *serviceDictionary in [deviceDictionary objectForKey:@"states"]){
                        NSString *service = [serviceDictionary objectForKey:@"service"];
                        if ([service isEqualToString:UPNP_SERVICE_PHILLIPS_HUE_BULB]){
                            NSString *variable = [serviceDictionary objectForKey:@"variable"];
                            if ([variable isEqualToString:@"Hue"]){
                                zHue.hue = [[serviceDictionary objectForKey:@"value"] integerValue];
                            }
                            if ([variable isEqualToString:@"Saturation"]){
                                zHue.saturation = [[serviceDictionary objectForKey:@"value"] integerValue];
                                
                            }
                            if ([variable isEqualToString:@"ColorTemperature"]){
                                zHue.temperature = [[serviceDictionary objectForKey:@"value"] integerValue];
                            }
                        }
                    }
                    hueBulbs = [hueBulbs arrayByAddingObject:zHue];
                }
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_IP_CAMERA]){
                    device = [[IPCamera alloc] init];
                    IPCamera *ipCam = (IPCamera*)device;
                    ipCam.username = [deviceDictionary objectForKey:@"username"];
                    ipCam.password = [deviceDictionary objectForKey:@"password"];
                    ipCam.ipAddress = [deviceDictionary objectForKey:@"ipaddress"];
                    
                    for (NSDictionary *serviceDictionary in [deviceDictionary objectForKey:@"states"]){
                        NSString *service = [serviceDictionary objectForKey:@"service"];
                        if ([service isEqualToString:UPNP_SERVICE_CAMERA]){
                            NSString *variable = [serviceDictionary objectForKey:@"variable"];
                            if ([variable isEqualToString:@"URL"]){
                                ipCam.snapshotUrl = [serviceDictionary objectForKey:@"value"];
                            }
                            if ([variable isEqualToString:@"DirectStreamingURL"]){
                                ipCam.videoUrl = [serviceDictionary objectForKey:@"value"];
                            }
                            if ([variable isEqualToString:@"Commands"]){
                                NSString *commandString = [serviceDictionary objectForKey:@"value"];
                                if ([commandString hasPrefix:@"camera_up"]){
                                    ipCam.canPan = YES;
                                }
                            }
                        }
                    }
                    ipCameras = [ipCameras arrayByAddingObject:ipCam];
                }
                
                //Add the device to the room
                if (device){
                    device.identifier = [deviceDictionary objectForKey:@"id"];
                    device.name = [deviceDictionary objectForKey:@"name"];
                    device.controllerUrl = [self controlUrl];
                    device.veraDeviceFileName = [[deviceDictionary objectForKey:@"device_file"] stringByReplacingOccurrencesOfString:@"xml" withString:@"json"];
                    NSArray *array = [self.rooms filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", [deviceDictionary objectForKey:@"room"]]];
                    if (array.count == 1){
                        VeraRoom *room = [array objectAtIndex:0];
                        room.devices = [room.devices arrayByAddingObject:device];
                    }
                }
            }
            
            self.switches = switches;
            self.dimmerSwitches = dimmerSwitches;
            self.hueBulbs = hueBulbs;
            self.securitySensors = securitySensors;
            self.locks = locks;
            self.thermostats = thermostats;
            self.ipCameras = ipCameras;
            dispatch_async(dispatch_get_main_queue(), ^(){
                [[NSNotificationCenter defaultCenter] postNotificationName:VERA_DEVICES_DID_REFRESH_NOTIFICATION object:nil];
            });
        }
    }];
        
}


-(void)getDevices{
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
            
            NSLog(@"%@", [results objectForKey:@"Camera"]);
           
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
            
            for (NSDictionary *dictiony in [results objectForKey:@"Camera"]){
                
            }
            
            
            NSMutableArray *cameras = [NSMutableArray array];
            for (NSDictionary *cameraDictionary in [results objectForKey:@"Camera"]){
                IPCamera *camera = [[IPCamera alloc] init];
                camera.identifier = [cameraDictionary objectForKey:@"id"];
                camera.name = [cameraDictionary objectForKey:@"name"];
                camera.ipAddress = [cameraDictionary objectForKey:@"ip"];
                camera.videoUrl = [cameraDictionary objectForKey:@"streaming"];
                camera.snapshotUrl = [cameraDictionary objectForKey:@"url"];
                [cameras addObject:camera];
            }
            
            
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
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            [[NSNotificationCenter defaultCenter] postNotificationName:VERA_DEVICES_DID_REFRESH_NOTIFICATION object:nil];
        });
    }];
}


@end
