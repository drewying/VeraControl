//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZWaveThermostat.h"

@implementation ZwaveThermostat

-(void)setTemperatureHeatTarget:(NSInteger)temperatureHeatTarget completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetCurrentSetpoint&NewCurrentSetpoint=%i", temperatureHeatTarget] usingService:UPNP_SERVICE_HEAT completion:^(NSURLResponse *response, NSData *data, NSError *error){
        self.temperatureHeatTarget = temperatureHeatTarget;
        if (callback){
            callback();
        }
    }];
}

-(void)setTemperatureCoolTarget:(NSInteger)temperatureCoolTarget completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetCurrentSetpoint&NewCurrentSetpoint=%i", temperatureCoolTarget] usingService:UPNP_SERVICE_COOL completion:^(NSURLResponse *response, NSData *data, NSError *error){
        self.temperatureCoolTarget = temperatureCoolTarget;
        if (callback){
            callback();
        }
    }];
}

-(void)setFanMode:(NSString *)fanMode completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetMode&NewMode=%@", fanMode] usingService:UPNP_SERVICE_HVAC_FAN completion:^(NSURLResponse *response, NSData *data, NSError *error){
        self.fanMode = fanMode;
        if (callback){
            callback();
        }
    }];
}

-(void)setThermoMode:(NSString *)thermoMode completion:(void(^)())callback{
    [self performAction:[NSString stringWithFormat:@"SetModeTarget&NewModeTarget=%@", thermoMode] usingService:UPNP_SERVICE_HVAC_THERMO completion:^(NSURLResponse *response, NSData *data, NSError *error){
        self.thermoMode = thermoMode;
        if (callback){
            callback();
        }
    }];
}

@end