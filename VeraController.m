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
#import "VeraScene.h"

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

-(void)findVeraController{
    NSURL *url =[NSURL URLWithString:[NSString stringWithFormat:@"https://sta1.mios.com/locator_json.php?username=%@",self.miosUsername]];
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
            [self refreshDevices];
        }
    }];
}

-(NSString *)controlUrl{
    if (self.useMiosRemoteService){
        return [NSString stringWithFormat:@"http://%@/%@/%@/%@", self.miosHostname, self.miosUsername, self.miosPassword, self.veraSerialNumber];
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
            
            
            NSArray *parsedRooms = responseDictionary[@"rooms"];
            
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
            
            NSArray *devices = responseDictionary[@"devices"];
            
            NSArray *switches = @[];
            NSArray *dimmerSwitches = @[];
            NSArray *locks = @[];
            NSArray *thermostats = @[];
            NSArray *securitySensors = @[];
            NSArray *hueBulbs = @[];
            NSArray *ipCameras = @[];
            
            for (NSDictionary *deviceDictionary in devices){
                NSString *deviceType = deviceDictionary[@"device_type"];
                
                ZwaveNode *device;
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_DIMMABLE_SWITCH]){
                    device = [[ZwaveDimmerSwitch alloc] initWithDictionary:deviceDictionary];
                    dimmerSwitches = [dimmerSwitches arrayByAddingObject:device];
                }
                
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_SWITCH]){
                    device = [[ZwaveSwitch alloc] initWithDictionary:deviceDictionary];
                    switches = [switches arrayByAddingObject:device];
                }
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_DOOR_LOCK]){
                    device = [[ZwaveLock alloc] initWithDictionary:deviceDictionary];
                    locks = [locks arrayByAddingObject:device];
                }
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_NEST_THERMOSTAT]){
                    device = [[ZwaveThermostat alloc] initWithDictionary:deviceDictionary];
                    thermostats = [thermostats arrayByAddingObject:device];
                }
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_MOTION_SENSOR]){
                    device = [[ZwaveSecuritySensor alloc] initWithDictionary:deviceDictionary];
                    securitySensors = [securitySensors arrayByAddingObject:device];
                }
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_PHILLIPS_HUE_BULB]){
                    device = [[ZwavePhillipsHueBulb alloc] initWithDictionary:deviceDictionary];
                    hueBulbs = [hueBulbs arrayByAddingObject:device];
                }
                
                if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_IP_CAMERA]){
                    device = [[IPCamera alloc] initWithDictionary:deviceDictionary];
                    ipCameras = [ipCameras arrayByAddingObject:device];
                }
                
                //Add the device to the room
                if (device){
                    device.controllerUrl = [self controlUrl];
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
            
            //Get Scenes
            self.scenes = @[];
            NSArray *scenes = responseDictionary[@"scenes"];
            for (NSDictionary *dictionary in scenes){
                VeraScene *scene = [[VeraScene alloc] initWithDictionary:dictionary];
                scene.controllerUrl = [self controlUrl];
                self.scenes = [self.scenes arrayByAddingObject:scene];
            }
            
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
                [switches addObject:zSwitch];
        
                
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
