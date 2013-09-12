VeraControl
===========

A small library to assist in controlling of a micasaverde Vera unit. More information on Vera can be found here:
http://www.micasaverde.com/controllers/

Still a very early work in progress. 

Usage:

Discovery:
VeraController *veraController = [VeraController sharedInstance];
[veraController refreshDevices];

ZwaveSwitch *bedroomSwitch = [veraController.switches objectAtIndex:0];

Turn on a lightswitch:
[veraController setZwaveSwitch:bedroomSwitch toState:YES completion:^(){}];

TODO:
Seperate VeraController into multiple sub-controller classes
Zwave Sensors control and alerts
UPNP Vera Discovery (have prototype)
Response returned in callback block
