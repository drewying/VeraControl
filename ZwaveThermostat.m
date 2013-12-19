//
//  VeraController.m
//  Home
//
//  Created by Drew Ingebretsen on 2/25/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZWaveThermostat.h"

#define UPNP_SERVICE_HEAT @"urn:upnp-org:serviceId:TemperatureSetpoint1_Heat"
#define UPNP_SERVICE_COOL @"urn:upnp-org:serviceId:TemperatureSetpoint1_Cool"
#define UPNP_SERVICE_HVAC_FAN @"urn:upnp-org:serviceId:HVAC_FanOperatingMode1"
#define UPNP_SERVICE_HVAC_THERMO @"urn:upnp-org:serviceId:HVAC_UserOperatingMode1"
#define UPNP_SERVICE_TEMPERATURE_SENSOR @"urn:upnp-org:serviceId:TemperatureSensor1"

@implementation ZwaveThermostat

-(ZwaveThermostat*)initWithDictionary:(NSDictionary*)dictionary{
    self = [super initWithDictionary:dictionary];
    if (self){
        for (NSDictionary *serviceDictionary in dictionary[@"states"]){
            NSString *service = serviceDictionary[@"service"];
            if ([service isEqualToString:UPNP_SERVICE_TEMPERATURE_SENSOR]){
                self.temperature = [serviceDictionary[@"value"] integerValue];
            }
            if ([service isEqualToString:UPNP_SERVICE_HEAT]){
                self.temperatureHeatTarget = [serviceDictionary[@"value"] integerValue];
            }
            if ([service isEqualToString:UPNP_SERVICE_COOL]){
                self.temperatureCoolTarget = [serviceDictionary[@"value"] integerValue];
            }
            if ([service isEqualToString:UPNP_SERVICE_HVAC_FAN]){
                self.fanMode = serviceDictionary[@"value"];
            }
            if ([service isEqualToString:UPNP_SERVICE_HVAC_THERMO]){
                self.thermoMode = serviceDictionary[@"value"];
            }
        }
    }
    return self;
}

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