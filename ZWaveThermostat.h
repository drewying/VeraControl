//
//  ZWaveThermostat.h
//  Home
//
//  Created by Drew Ingebretsen on 5/21/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZWaveNode.h"

#define FAN_MODE_AUTO @"Auto"
#define FAN_MODE_ON @"ContinuousOn"

#define THERMO_MODE_OFF @"Off"
#define THERMO_MODE_AUTO @"AutoChangeOver"
#define THERMO_MODE_COOL @"CoolOn"
#define THERMO_MODE_HEAT @"HeatOn"

@interface ZWaveThermostat : ZWaveNode
@property (nonatomic, strong) NSString *fanMode;
@property (nonatomic, strong) NSString *thermoMode;
@property (nonatomic, assign) NSInteger temperature;
@property (nonatomic, assign) NSInteger heatTermperatureSet;
@property (nonatomic, assign) NSInteger coolTermperatureSet;
@property (nonatomic, strong) NSString *thermoStatus;
@end
