//
//  BluetoothMonitor.h
//  Proximity
//
//  Created by Dominik Pich on 8/1/12.
//
//
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>
#import "BluetoothMonitorDelegate.h"

NS_ENUM(NSInteger, ProximityBluetoothStatus) {
    ProximityBluetoothStatusOutOfRange,
    ProximityBluetoothStatusInRange,
    ProximityBluetoothStatusUndefined
};


@interface BluetoothMonitor : NSObject

@property(weak) id<BluetoothMonitorDelegate> delegate;
@property(nonatomic, assign) NSTimeInterval timeInterval;
@property(nonatomic, assign) NSInteger inRangeDetectionCount;
@property(nonatomic, assign) NSInteger outOfRangeDetectionCount;
@property(assign) long requiredSignalStrength;
@property(retain) IOBluetoothDevice *device;

@property(readonly) enum ProximityBluetoothStatus priorStatus;
@property(readonly) enum ProximityBluetoothStatus status;
@property(readonly) enum ProximityBluetoothStatus iconStatus;

- (id)initWithDevice:(IOBluetoothDevice*)aDevice;

- (void)start;
- (void)stop;
- (void)refresh;
- (int)getRange:(BOOL)getSignal;

@end
