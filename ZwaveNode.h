//
//  ZWaveNode.h
//  Home
//
//  Created by Drew Ingebretsen on 5/21/13.
//  Copyright (c) 2013 PeopleTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZwaveNode : NSObject
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *room;
@property (nonatomic, strong) NSString *controllerUrl;
@property (nonatomic, strong) NSString *veraDeviceFileName;

-(id)initWithDictionary:(NSDictionary*)dictionary;
-(void)updateWithDictionary:(NSDictionary*)dictionary; //This method should be extended by subclasses to update specific parameters of the device.

-(void)performAction:(NSString*)action usingService:(NSString*)service completion:(void(^)(NSURLResponse *response, NSData *data, NSError *devices))callback;

-(void)getSceneActionFactories:(void(^)(NSArray *actions))callback;
-(void)getSceneTriggerFactories:(void(^)(NSArray *triggers))callback;

@end
