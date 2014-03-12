//
//  VeraSceneTrigger.m
//  C2
//
//  Created by Drew Ingebretsen on 9/22/13.
//  Copyright (c) 2013 People Tech. All rights reserved.
//

#import "VeraScene.h"
#import "VeraSceneTrigger.h"
#import "VeraSceneAction.h"

#define UPNP_SERVICE_SCENE @"urn:micasaverde-com:serviceId:HomeAutomationGateway1"

//Sample request - http://ip_address:3480/data_request?id=lu_action&serviceId=urn:micasaverde-com:serviceId:HomeAutomationGateway1&action=RunScene&SceneNum=

@implementation VeraScene


-(VeraScene*)initWithDictionary:(NSDictionary*)dictionary{
    self = [super init];
    if (self){
        self.identifier = [NSString stringWithFormat:@"%i", [dictionary[@"id"] integerValue]];
        self.name = dictionary[@"name"];
        self.sceneNum = dictionary[@"id"];
        self.room = [NSString stringWithFormat:@"%@",dictionary[@"room"]];
        
        self.triggers = @[];
        for (NSDictionary *triggerDictionary in dictionary[@"triggers"]){
            VeraSceneTrigger *trigger = [[VeraSceneTrigger alloc] init];
            self.triggers = [self.triggers arrayByAddingObject:trigger];
        }
    }
    return self;
}

-(void)performAction:(NSString*)action usingService:(NSString*)service onScene:(NSString*)sceneNum completion:(void(^)(NSURLResponse *response, NSData *data, NSError *devices))callback{
    
    NSString *htmlString = [NSString stringWithFormat:@"%@/data_request?id=action&output_format=json&serviceId=%@&action=%@&SceneNum=%@", self.controllerUrl, service, action, sceneNum];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:htmlString]] queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        if (callback){
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(response, data, error);
            });
        }
    }];
}

-(void)runSceneCompletion:(void(^)())callback {
    [self performAction:@"RunScene" usingService:UPNP_SERVICE_SCENE onScene:self.sceneNum completion:^(NSURLResponse *response, NSData *data, NSError *error){
        if (callback){
            dispatch_async(dispatch_get_main_queue(), ^{
                callback();
            });
        }
    }];
    
}

-(void)SceneOffCompletion:(void(^)())callback {
    [self performAction:@"SceneOff" usingService:UPNP_SERVICE_SCENE onScene:self.sceneNum completion:^(NSURLResponse *response, NSData *data, NSError *error){
        if (callback){
            dispatch_async(dispatch_get_main_queue(), ^{
                callback();
            });
        }
    }];
}

-(void)saveSceneToVera:(void(^)())callback {
    
    NSArray *triggers = [self.triggers valueForKeyPath:@"triggerDictionary"];
    NSArray *actions = [self.actions valueForKeyPath:@"actionDictionary"];
    actions = @[@{@"delay":@0, @"actions":actions}];
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:self.name forKey:@"name"];
    [dictionary setObject:triggers forKey:@"triggers"];
    [dictionary setObject:actions forKey:@"groups"];
    [dictionary setObject:@[] forKey:@"timers"];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    NSString *string = [NSString stringWithFormat:@"json=%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
    
    jsonData = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *htmlString = [NSString stringWithFormat:@"%@/data_request?id=scene&action=create",self.controllerUrl];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:htmlString]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
        if (callback){
            NSLog(@"Response:%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            dispatch_async(dispatch_get_main_queue(), ^{
                callback(response, data, error);
            });
        }
    }];
}

@end
