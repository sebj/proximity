proximity
==============

###Description
Proximity monitors the proximity of your mobile phone or other bluetooth device and executes custom Scripts/Apps when the device goes out of range or comes into range of your computer.

###Purpose
The intent of this project is for the source code to be critiqued by other developers in hopes of improving my Cocoa programming abilities, as well as my programming skills in general.

###Credits
This version is based on proximity 1.71 from [Daij-Djan](https://github.com/Daij-Djan/proximity) which in turn is based on proximity 1.5 from [reduxcomputing](https://github.com/revned/proximity/). 
Including fixes from [fivemicro](https://github.com/fivemicro/proximity) 

###Changes
-
#####1.8
* added the option to delay running the script for in/out of range only after a set number of detections have occured

#####1.71
* added the option to require a good signal strength (defined as the Golden Cut in the BT4 Specification)

#####1.7
* Added sandboxing & mac appstore compatible way to open the app at login
* Made the app run sandboxed 
* A command line argument is now passed to the inRange or OutOfRange Action. (Either 'InRange' or 'OutOfRange')
 
#####1.6
* I added the ability to run not only applescripts but also run shell scripts, unix executables or app bundles.
* Fixed some minor crashes
* Migrated all to github. The about link but also the checking for updates
* compiled it as 64bit
