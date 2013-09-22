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
#import "VeraRoom.h"

#define VERA_IP_ADDRESS @"192.168.8.30"
#define VERA_SERIAL @""
#define VERA_USERNAME @""
#define VERA_PASSWORD @""
#define EXCLUDED_SWITCH_LIST @[@41,@21]

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
        return [NSString stringWithFormat:@"fwd5.mios.com/%@/%@/%@", VERA_USERNAME, VERA_PASSWORD, VERA_SERIAL];
    }
    else{
        return [NSString stringWithFormat:@"%@:3480", VERA_IP_ADDRESS];
    }
}

-(void)performCommand:(NSString*)command completion:(void(^)(NSURLResponse *response, NSData *data, NSError *devices))callback{
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/data_request?%@",[self controlUrl], command]]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        callback(response, data, error);
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
                dLight.state = [[dictionary objectForKey:@"status"] boolValue];
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
                zSwitch.state = [[dictionary objectForKey:@"status"] boolValue];
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
                ZwaveSensor *zSensor = [[ZwaveSensor alloc] init];
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
            self.sensors = [sensors copy];
            
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
            self.mainThermostat = thermo;
            
            NSDictionary *humidDictionary = [[results objectForKey:@"Humidity Sensor"] objectAtIndex:0];
            ZwaveHumiditySensor *sensor = [[ZwaveHumiditySensor alloc] init];
            sensor.name = [humidDictionary objectForKey:@"name"];
            sensor.identifier = [humidDictionary objectForKey:@"id"];
            sensor.humidity = [[humidDictionary objectForKey:@"humidity"] integerValue];
            sensor.controllerUrl = [self controlUrl];
            self.mainHumiditySensor = sensor;
        }
        
    
        [[NSNotificationCenter defaultCenter] postNotificationName:VERA_DEVICES_DID_REFRESH_NOTIFICATION object:nil];
        
        //NSLog(@"Rooms:%@", self.rooms);
    }];
}


@end
