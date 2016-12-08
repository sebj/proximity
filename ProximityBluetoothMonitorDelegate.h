//
//  ProximityBluetoothMonitorDelegate.h
//  Proximity
//
//  Created by Sebastian Jachec on 08/12/2016.
//
//

@class ProximityBluetoothMonitor;

@protocol ProximityBluetoothMonitorDelegate <NSObject>

@optional;
- (void)proximityBluetoothMonitor:(ProximityBluetoothMonitor*)monitor foundDevice:(IOBluetoothDevice*)device;
- (void)proximityBluetoothMonitor:(ProximityBluetoothMonitor*)monitor lostDevice:(IOBluetoothDevice*)device;
- (void)inRange;
- (void)outOfRange;

@end
