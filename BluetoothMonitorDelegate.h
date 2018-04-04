//
//  BluetoothMonitorDelegate.h
//  Proximity
//
//  Created by Sebastian Jachec on 08/12/2016.
//
//

@class BluetoothMonitor;

@protocol BluetoothMonitorDelegate <NSObject>

@optional;
- (void)proximityBluetoothMonitor:(BluetoothMonitor*)monitor foundDevice:(IOBluetoothDevice*)device;
- (void)proximityBluetoothMonitor:(BluetoothMonitor*)monitor lostDevice:(IOBluetoothDevice*)device;
- (void)inRange;
- (void)outOfRange;

@end
