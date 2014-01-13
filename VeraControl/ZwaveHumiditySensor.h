//
//  ZWaveHumiditySensor.h
//  Home
//
//  Created by Drew Ingebretsen on 5/21/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import "ZWaveNode.h"

@interface ZwaveHumiditySensor : ZwaveNode
@property (nonatomic, assign) NSInteger humidity;
@end
