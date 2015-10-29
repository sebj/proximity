#Proximity
==============

###Description
Proximity runs custom scripts or applications when a Bluetooth device you choose (phone/watch/etc.) enters or exits range of your Mac.

This fork is a work-in-progress: feel free to [create an issue](https://github.com/sebj/Proximity/issues/new) for any problems/suggestions or a pull request with code or icons (*currently in need of: an app icon, menubar icons for in and out of range states*).

###Fork Ancestry
* Bugfixes from [niobos](https://github.com/niobos/proximity) and [Niels Laukens](https://github.com/nielslaukens)

* proximity 1.81 from [Jesse Smick](https://github.com/janka102/proximity)
* [Stuart Eichart](https://github.com/fivemicro/proximity)
* proximity 1.7 from [Dominik Pich](https://github.com/Daij-Djan/proximity)
* proximity 1.6 from [revned](https://github.com/revned/proximity/)

###Changes
===

**1.9 (work in progress – no menubar icons)**
* General code tidy (some outlets replaced with bindings; syntax changes etc.)
* Removed update checking due to nature of forking on GitHub
* UI updates; added sheet to choose device
* Minimum OS X version is now 10.9

**1.81**
* Added a Signal Bar to display the current signal of the device
* Widened the Required Signal slider so it can be viewed in relation to the Signal Bar
* Replaced Popup Statuses with a new Status Area next the Check Connection button
* Added steppers to the number inputs
    * Detection inputs now in range of 1-15
    * Timer interval input is now in range of 2-99999

**1.8**
* Added option to delay running the script for in/out of range only after a set number of detections have occured

**1.71**
* Added option to require a good signal strength (defined as the Golden Cut in the BT4 Specification)

**1.7**
* Added sandboxing & App Store compatible way to open the app at login
* Made the app run sandboxed 
* A command line argument is now passed to the inRange or OutOfRange Action. (Either `InRange` or `OutOfRange`)
 
**1.6**
* Added ability to run not only applescripts but also run shell scripts, unix executables or app bundles.
* Fixed minor crashes
* Migrated all to GitHub – about link but also update checking
* Compiled as 64bit