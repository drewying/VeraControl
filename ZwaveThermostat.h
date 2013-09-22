//
//  ZWaveThermostat.h
//  Home
//
//  Created by Drew Ingebretsen on 5/21/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZwaveNode.h"

#define FAN_MODE_AUTO @"Auto"
#define FAN_MODE_ON @"ContinuousOn"

#define THERMO_MODE_OFF @"Off"
#define THERMO_MODE_AUTO @"AutoChangeOver"
#define THERMO_MODE_COOL_ONLY @"CoolOn"
#define THERMO_MODE_HEAT_ONLY @"HeatOn"

@interface ZwaveThermostat : ZwaveNode
@property (nonatomic, strong) NSString *fanMode;
@property (nonatomic, strong) NSString *thermoMode;
@property (nonatomic, strong) NSString *thermoStatus;

@property (nonatomic, assign) NSInteger temperature;
@property (nonatomic, assign) NSInteger temperatureHeatTarget;
@property (nonatomic, assign) NSInteger temperatureCoolTarget;


@end
