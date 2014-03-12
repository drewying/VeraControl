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
[VeraController findVeraControllers:miosUsername password:miosPassword completion:^(NSArray *units, NSError *error){
   VeraController *veraController = [units firstObject];
  [veraController refreshDevices]; //This  populates all the device arrays, rooms, and scenes, sending out a NSNotification when complete.
}
```

Turn on a lightswitch:
```
ZwaveSwitch *bedroomSwitch = [veraController.switches firstObject];
[bedroomSwitch setOn:YES completion:^(){
  NSLog(@"Bedroom Light turned on");
}];
```
TODO:

Unidentified device support.

UI6 authentication support

Better scene creation support
