//
//  ProximityBluetoothMonitor.m
//  Proximity
//
//  Created by Dominik Pich on 8/1/12.
//
//

#import "ProximityBluetoothMonitor.h"

@implementation ProximityBluetoothMonitor {
	NSTimer *_timer;
    NSInteger _changedStatusCounter;
}

@synthesize inRangeDetectionCount, outOfRangeDetectionCount;

- (id)init {
    self = [super init];
    if(self) {
        _iconStatus = _priorStatus = _status = ProximityBluetoothStatusUndefined;
        _timeInterval = kDefaultPageTimeout;
        _requiredSignalStrength = NO;
    }
    return self;
}

- (void)start {
    [_timer invalidate];
    _changedStatusCounter = 0;
    _timer = [NSTimer scheduledTimerWithTimeInterval:_timeInterval
                                             target:self
                                           selector:@selector(handleTimer:)
                                           userInfo:nil
                                            repeats:YES];
}

- (void)stop {
    [_timer invalidate];
    _timer = nil;
    
    _iconStatus = _priorStatus = _status;
    _status = ProximityBluetoothStatusUndefined;
}

- (void)refresh {
    [self handleTimer:_timer];
}

- (void)setTimeInterval:(NSTimeInterval)timeInterval {
    if(_timeInterval < kDefaultPageTimeout)
        _timeInterval = kDefaultPageTimeout;
    
    _timeInterval = timeInterval;
    if(_timer) {
        [self start];
    }
}

#pragma mark

- (void)handleTimer:(NSTimer *)theTimer
{
    int inRange = [self getRange];
#ifdef DEBUG
    // 0: Out of Range, 1: In Range, 2: Not Detectable
    NSLog(@"BT device %@ inRange:%d",_device.name, inRange);
    NSLog(@"Changed counter %ld", _changedStatusCounter);
#endif
    
    _status = inRange != ProximityBluetoothStatusInRange ? ProximityBluetoothStatusOutOfRange : ProximityBluetoothStatusInRange;
    
    if( _status != _iconStatus ) {
        if( _status == ProximityBluetoothStatusInRange ) {
            [_delegate setMenuIconInRange];
        }
        else {
            [_delegate setMenuIconOutOfRange];
        }
        _iconStatus = _status;
    }
    
	if( inRange == ProximityBluetoothStatusInRange) {
		if( _priorStatus != ProximityBluetoothStatusInRange ) {
            _changedStatusCounter++;
            if(_changedStatusCounter >= inRangeDetectionCount) {
                _changedStatusCounter = 0;
                _priorStatus = ProximityBluetoothStatusInRange;
                [_delegate proximityBluetoothMonitor:self foundDevice:_device];
#ifdef DEBUG
                NSLog(@"-- found");
#endif
            }
		}
        else {
            _changedStatusCounter = 0;
        }
	}
	else {
		if( _priorStatus != ProximityBluetoothStatusOutOfRange ) {
            _changedStatusCounter++;
            if( _changedStatusCounter >= outOfRangeDetectionCount ) {
                _changedStatusCounter = 0;
                _priorStatus = ProximityBluetoothStatusOutOfRange;
                [_delegate proximityBluetoothMonitor:self lostDevice:_device];
#ifdef DEBUG
                NSLog(@"-- lost");
#endif
            }
		}
        else {
            _changedStatusCounter = 0;
        }
	}
    
    _status = inRange;
}

- (int)getRange:(BOOL)getSignal
{
    if( !_device )
        return ProximityBluetoothStatusUndefined;
    
    IOReturn br = [_device openConnection:nil withPageTimeout:kDefaultPageTimeout authenticationRequired:NO];
    
    if( br == kIOReturnSuccess ) {
//        BluetoothHCIRSSIValue rawRssi = [_device rawRSSI];
        BluetoothHCIRSSIValue rssi = [_device RSSI];
#ifdef DEBUG
//        if(rssi!=0)
            NSLog(@"RSSI of %@: %d/%d", _device.name, rssi, _requiredSignalStrength);
#endif
        BOOL inRange = rssi>=_requiredSignalStrength;
        
        [_device closeConnection];
        
        if( getSignal )
            return 50+rssi;
        
        return inRange ? ProximityBluetoothStatusInRange : ProximityBluetoothStatusOutOfRange;
    }
    
    return ProximityBluetoothStatusUndefined;
}

- (int)getRange
{
    return [self getRange:NO];
}

@end
