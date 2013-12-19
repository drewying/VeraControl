VeraControl
===========

A small library to assist in controlling of a micasaverde Vera unit. 

Vera is a home automation controller designed to work with Z-Wave enabled home automated devices as well as "virtual devices" via an IP interface.

More information on Vera can be found here:
http://www.micasaverde.com/controllers/

Usage:

The main class is the VeraController. You can look at the VeraController.h for a good overview of what's available. But here is a quick example for you.

Discovery:
```
VeraController *veraController = [VeraController sharedInstance];
veraController.username = @"MyMiosUsername";
veraController.password = @"MyMiosPassword";
[veraController findVeraController]; //This automaticallly determines whether the controller is local or remote.
[veraController refreshDevices] //This populates all the device arrays, rooms, and scenes, sending out a NSNotification when complete.
```

Turn on a lightswitch:
```
ZwaveSwitch *bedroomSwitch = [veraController.switches objectAtIndex:0];
[bedroomSwitch setOn:YES completion:^(){
  NSLog(@"Bedroom Light turned on");
}];
```
TODO:

Seperate VeraController into multiple sub-controller classes

Scenes.

Response returned in callback block

Unidentified device support.
