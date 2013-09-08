//
//  ZwaveDimmerSwitch.h
//  Home
//
//  Created by Drew Ingebretsen on 3/8/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZwaveSwitch.h"

@interface ZwaveDimmerSwitch : ZwaveSwitch
@property (nonatomic, assign) NSInteger brightness;
@end
