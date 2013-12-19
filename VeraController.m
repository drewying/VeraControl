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
#import "VeraSceneTrigger.h"

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
            [[NSNotificationCenter defaultCenter] postNotificationName:VERA_LOCATE_CONTROLLER_NOTIFICATION object:nil];
        }
    }];
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

-(void)performCommand:(NSString*)command completion:(void(^)(NSURLResponse *response, NSData *data, NSError *devices))callback{
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/data_request?%@",[self controlUrl], command]]] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        callback(response, data, error);
    }];
}

-(void)refreshDevices{
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
                VeraSceneTrigger *scene = [[VeraSceneTrigger alloc] initWithDictionary:dictionary];
                scene.controllerUrl = [self controlUrl];
                self.scenes = [self.scenes arrayByAddingObject:scene];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                [[NSNotificationCenter defaultCenter] postNotificationName:VERA_DEVICES_DID_REFRESH_NOTIFICATION object:nil];
            });
        }
    }];
        
}
@end
