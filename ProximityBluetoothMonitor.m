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
    if (self) {
        [self setupVars];
    }
    return self;
}

- (id)initWithDevice:(IOBluetoothDevice*)aDevice {
    self = [super init];
    if (self) {
        [self setupVars];
        _device = aDevice;
    }
    return self;
}

- (void)setupVars {
    _iconStatus = _priorStatus = _status = ProximityBluetoothStatusUndefined;
    _timeInterval = kDefaultPageTimeout;
    _requiredSignalStrength = NO;
    inRangeDetectionCount = 1;
    outOfRangeDetectionCount = 1;
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
    if (_timeInterval < kDefaultPageTimeout)
        _timeInterval = kDefaultPageTimeout;
    
    _timeInterval = timeInterval;
    if (_timer) {
        [self start];
    }
}

#pragma mark

- (void)handleTimer:(NSTimer *)theTimer {
    int inRange = [self getRange];
#ifdef DEBUG
    // 0: Out of Range, 1: In Range, 2: Not Found
    NSLog(@"BT device %@ inRange:%d",_device.name, inRange);
    NSLog(@"Changed counter %ld", _changedStatusCounter);
#endif
    
    _status = inRange != ProximityBluetoothStatusInRange ? ProximityBluetoothStatusOutOfRange : ProximityBluetoothStatusInRange;
    
    if (_status != _iconStatus) {
        if (_status == ProximityBluetoothStatusInRange) {
            if (_delegate && [_delegate respondsToSelector:@selector(inRange)]) {
                [_delegate inRange];
            }
        } else {
            if (_delegate && [_delegate respondsToSelector:@selector(outOfRange)]) {
                [_delegate outOfRange];
            }
        }
        _iconStatus = _status;
    }
    
	if (inRange == ProximityBluetoothStatusInRange) {
		if (_priorStatus != ProximityBluetoothStatusInRange) {
            _changedStatusCounter++;
            if (_changedStatusCounter >= inRangeDetectionCount) {
                _changedStatusCounter = 0;
                _priorStatus = ProximityBluetoothStatusInRange;
                
                if (_delegate && [_delegate respondsToSelector:@selector(proximityBluetoothMonitor:foundDevice:)]) {
                    [_delegate proximityBluetoothMonitor:self foundDevice:_device];
                }
#ifdef DEBUG
                NSLog(@"Found");
#endif
            }
		} else {
            _changedStatusCounter = 0;
        }
	}
	else {
		if (_priorStatus != ProximityBluetoothStatusOutOfRange) {
            _changedStatusCounter++;
            if (_changedStatusCounter >= outOfRangeDetectionCount) {
                _changedStatusCounter = 0;
                _priorStatus = ProximityBluetoothStatusOutOfRange;
                
                if (_delegate && [_delegate respondsToSelector:@selector(proximityBluetoothMonitor:lostDevice:)]) {
                    [_delegate proximityBluetoothMonitor:self lostDevice:_device];
                }
#ifdef DEBUG
                NSLog(@"Lost");
#endif
            }
		} else {
            _changedStatusCounter = 0;
        }
	}
    
    _status = inRange;
}

- (int)getRange:(BOOL)getSignal {
    if (!_device) {
        if (getSignal)
            return 0;
        
        return ProximityBluetoothStatusUndefined;
    }
    
    IOReturn br = [_device openConnection:nil withPageTimeout:kDefaultPageTimeout authenticationRequired:NO];
    
    if (br == kIOReturnSuccess) {
//        BluetoothHCIRSSIValue rawRssi = [_device rawRSSI];
        BluetoothHCIRSSIValue rssi = _device.RSSI;
        
        [_device closeConnection];
        
        if (getSignal) {
            
#ifdef DEBUG
            NSLog(@"RSSI of %@ out of 50: %d", _device.name, 50+rssi);
#endif
            // -1 * (minimun RSSI) + rssi
            return 50+rssi;
        }

#ifdef DEBUG
        //        if(rssi!=0)
        NSLog(@"RSSI of %@: %d/%d", _device.name, rssi, _requiredSignalStrength);
#endif
        BOOL inRange = rssi>=_requiredSignalStrength;
        
        return inRange ? ProximityBluetoothStatusInRange : ProximityBluetoothStatusOutOfRange;
    }
    
    if (getSignal)
        return 0;
    
    return ProximityBluetoothStatusUndefined;
}

- (int)getRange {
    return [self getRange:NO];
}

@end
