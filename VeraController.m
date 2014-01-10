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

//This is the default forward server
#define FORWARD_SERVER_DEFAULT @"fwd5.mios.com"

@interface VeraController()
@property (nonatomic, strong) NSTimer *heartBeat;

@property (nonatomic, strong) NSArray *rooms;
@property (nonatomic, strong) NSArray *scenes;
@property (nonatomic, strong) NSArray *switches;
@property (nonatomic, strong) NSArray *locks;
@property (nonatomic, strong) NSArray *dimmerSwitches;
@property (nonatomic, strong) NSArray *securitySensors;
@property (nonatomic, strong) NSArray *thermostats;
@property (nonatomic, strong) NSArray *hueBulbs;
@property (nonatomic, strong) NSArray *ipCameras;
@end

@implementation VeraController

static VeraController *sharedInstance;

+(id)sharedController{
    @synchronized(self) {
        if (sharedInstance == nil){
            sharedInstance = [[self alloc] init];
            sharedInstance.switches = @[];
            sharedInstance.dimmerSwitches = @[];
            sharedInstance.locks = @[];
            sharedInstance.thermostats = @[];
            sharedInstance.securitySensors = @[];
            sharedInstance.hueBulbs = @[];
            sharedInstance.ipCameras = @[];
        }
    }
    return sharedInstance;
}

-(void)startHeartbeatWithInterval:(NSInteger)interval{
    if (self.heartBeat == nil || ![self.heartBeat isValid]) {
        self.heartBeat = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(refreshDevices) userInfo:nil repeats:YES];
        [self.heartBeat fire];
    }
}

-(void)stopHeartbeat{
    if (self.heartBeat == nil)
        return;
    
    [self.heartBeat invalidate];
}

-(void)findVeraController{
    NSURL *url = [NSURL URLWithString:[self locateUrl]];
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        if (error){
            return;
        }
        
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
            [self refreshDevices];
        }
        else {
            //There was an error locating the device, probably due to bad credentials
            [[NSNotificationCenter defaultCenter] postNotificationName:VERA_LOCATE_CONTROLLER_NOTIFICATION object:[NSError errorWithDomain:@"VeraControl - Could not locate Vera Controller" code:50 userInfo:nil]];
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
            return [NSString stringWithFormat:@"https://%@/%@/%@", self.miosHostname, self.miosUsername, self.miosPassword];
        return [NSString stringWithFormat:@"https://%@/%@/%@/%@", self.miosHostname, self.miosUsername, self.miosPassword, self.veraSerialNumber];
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
            
            if (error != nil) {
                //There was an error processing JSON, this happens if username/password is invalid
                [[NSNotificationCenter defaultCenter] postNotificationName:VERA_DEVICES_DID_REFRESH_NOTIFICATION object:[NSError errorWithDomain:@"VeraControl - Error refreshing devices" code:50 userInfo:error.userInfo]];
                return;
            }
            
            //Gather the rooms
            NSArray *parsedRooms = responseDictionary[@"rooms"];
            
            if (self.roomsDictionary == nil) {
                self.roomsDictionary = [[NSMutableDictionary alloc] initWithCapacity:(parsedRooms.count+1)];
                
                VeraRoom *unassignedRoom = [[VeraRoom alloc] init];
                unassignedRoom.name = @"Unassigned";
                unassignedRoom.identifier = @"0";
                unassignedRoom.section = @"0";
                
                [self.roomsDictionary setObject:unassignedRoom forKey:unassignedRoom.identifier];
            }
            
            //Add the unassigned room
            self.rooms = @[[self.roomsDictionary objectForKey:@"0"]];
            
            for (NSDictionary *parsedRoom in parsedRooms){
                //Check to see if the room exists and update it, if not create one
                NSString *identifier = [[parsedRoom objectForKey:@"id"] stringValue];
                VeraRoom *room = self.roomsDictionary[identifier];
                
                if (room == nil) {
                    VeraRoom *room = [[VeraRoom alloc] init];
                    room.name = [parsedRoom objectForKey:@"name"];
                    room.identifier = [[parsedRoom objectForKey:@"id"] stringValue];
                    room.section = [parsedRoom objectForKey:@"section"];
                    self.rooms = [self.rooms arrayByAddingObject:room];
                    [self.roomsDictionary setObject:room forKey:room.identifier];
                }
                else {
                    room.name = [parsedRoom objectForKey:@"name"];
                    room.identifier = [[parsedRoom objectForKey:@"id"] stringValue];
                    room.section = [parsedRoom objectForKey:@"section"];
                    
                    //Clear the devices since we are going to refill it
                    //TODO: We should create a devices dictionary as well
                    room.devices = @[];
                }
            }
            
            //Gather the devices
            NSArray *devices = responseDictionary[@"devices"];
            
            if (self.deviceDictionary == nil) {
                self.deviceDictionary = [[NSMutableDictionary alloc] initWithCapacity:devices.count];
            }
            
            for (NSDictionary *deviceData in devices){
                NSString *deviceType = deviceData[@"device_type"];
                NSString *deviceIdentifier = deviceData[@"id"];
                
                ZwaveNode *device = self.deviceDictionary[deviceIdentifier];
                
                if (device == nil) {
                    //Create a new ZWaveNode based on deviceType
                    
                    if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_DIMMABLE_SWITCH]){
                        device = [[ZwaveDimmerSwitch alloc] initWithDictionary:deviceData];
                        self.dimmerSwitches = [self.dimmerSwitches arrayByAddingObject:device];
                    }
                    
                    
                    if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_SWITCH]){
                        device = [[ZwaveSwitch alloc] initWithDictionary:deviceData];
                        self.switches = [self.switches arrayByAddingObject:device];
                    }
                    
                    if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_DOOR_LOCK]){
                        device = [[ZwaveLock alloc] initWithDictionary:deviceData];
                        self.locks = [self.locks arrayByAddingObject:device];
                    }
                    
                    if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_NEST_THERMOSTAT]){
                        device = [[ZwaveThermostat alloc] initWithDictionary:deviceData];
                        self.thermostats = [self.thermostats arrayByAddingObject:device];
                    }
                    
                    if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_MOTION_SENSOR]){
                        device = [[ZwaveSecuritySensor alloc] initWithDictionary:deviceData];
                        self.securitySensors = [self.securitySensors arrayByAddingObject:device];
                    }
                    
                    if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_PHILLIPS_HUE_BULB]){
                        device = [[ZwavePhillipsHueBulb alloc] initWithDictionary:deviceData];
                        self.hueBulbs = [self.hueBulbs arrayByAddingObject:device];
                    }
                    
                    if ([deviceType isEqualToString:UPNP_DEVICE_TYPE_IP_CAMERA]){
                        device = [[IPCamera alloc] initWithDictionary:deviceData];
                        self.ipCameras = [self.ipCameras arrayByAddingObject:device];
                    }
                    
                    if (device)
                        [self.deviceDictionary setObject:device forKey:deviceIdentifier];
                }
                
                else {
                    //Update the device
                    [device updateWithDictionary:deviceData];
                }
                
                //Add the device to the room
                if (device){
                    device.controllerUrl = [self controlUrl];
                    VeraRoom *room = [self.roomsDictionary objectForKey:device.room];
                    NSAssert((room != nil), @"Room does not exist - %@", device.room);
                    
                    //Scan the array to see if the device is already added to the room
                    //TODO: This might make sense being a dictionary as well. Also need to deal with device being removed from a room.
                    NSArray *array = [room.devices filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"identifier == %@", device.identifier]];
                    if (array.count == 0){
                        //Device not found, add it
                        room.devices = [room.devices arrayByAddingObject:device];
                    }

                }
            }
            
            
            //Get Scenes
            self.scenes = @[];
            
            //Clear all the room scenes
            //TODO: Make scenes an updateable dictionary like rooms and devices
            for (id roomid in self.roomsDictionary) {
                VeraRoom *room = [self.roomsDictionary objectForKey:roomid];
                room.scenes = @[];
            }
            
            NSArray *scenes = responseDictionary[@"scenes"];
            for (NSDictionary *dictionary in scenes){
                VeraScene *scene = [[VeraScene alloc] initWithDictionary:dictionary];
                scene.controllerUrl = [self controlUrl];
                self.scenes = [self.scenes arrayByAddingObject:scene];
                
                VeraRoom *room = [self.roomsDictionary objectForKey:scene.room];
                NSAssert((room != nil), @"Room does not exist - %@", scene.room);
                NSArray *array = [room.scenes filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"sceneNum == %@", scene.sceneNum]];
                if (array.count == 0){
                    //Scene not found, add it
                    //TODO: deal with device removals
                    room.scenes = [room.scenes arrayByAddingObject:scene];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^(){
                [[NSNotificationCenter defaultCenter] postNotificationName:VERA_DEVICES_DID_REFRESH_NOTIFICATION object:nil];
            });
        }
    }];
}

-(VeraScene*)getEmptyScene{
    VeraScene *scene = [[VeraScene alloc] init];
    scene.controllerUrl = [self controlUrl];
    scene.name = @"Test Scene";
    scene.triggers = @[];
    scene.actions = @[];
    scene.schedules = @[];
    return scene;
}
@end
