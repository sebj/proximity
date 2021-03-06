#import "AppController.h"
#import "NSWorkspace+runFileAtPath.h"
#import "ProximityStatusItem.h"
#import "UDKeys.h"
#import "BluetoothMonitor.h"

#define UD [NSUserDefaults standardUserDefaults]

@implementation AppController

#pragma mark -
#pragma mark Delegate Methods

- (void)awakeFromNib {
    [UD registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"userdefaults" ofType:@"plist"]]];
    
    monitor = [BluetoothMonitor new];
    monitor.delegate = self;
    
    [self userDefaultsLoad];

	[self createMenuBar];

    //update icon
    [monitor refresh];
    [monitor start];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[monitor stop];
}

- (void)windowWillClose:(NSNotification *)aNotification {
    if ([UD boolForKey:UDMonitoringEnabledKey] && monitor.device) {
        monitor.requiredSignalStrength = [[UD objectForKey:UDRequiredSignalKey] integerValue];
        monitor.timeInterval = [UD stringForKey:UDCheckIntervalKey].doubleValue;
        [monitor refresh];
        [monitor start];
        
        statusItem.paused = NO;
    } else {
        [monitor stop];
        
        statusItem.paused = YES;
    }

    [self userDefaultsSave];
}

#pragma mark -
#pragma mark AppController Methods

- (void)createMenuBar {
	NSMenu *menu = [NSMenu new];
	
	NSMenuItem *menuItem = [menu addItemWithTitle:@"Preferences..." action:@selector(showWindow:) keyEquivalent:@""];
	menuItem.target = self;
    
    [menu addItem:NSMenuItem.separatorItem];
	
	[menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
	
	// Space on status bar
    statusItem = [[ProximityStatusItem alloc] initWithStandardThickness];
    statusItem.showMenuOnLeftMouseDown = YES;
    statusItem.menu = menu;
}

- (void)inRange {
    statusItem.inRange = YES;
    
    [self runInRangeScript:YES];
}

//http://www.danandcheryl.com/2010/06/how-to-check-the-system-idle-time-using-cocoa
int64_t SystemIdleTime(void) {
    int64_t idlesecs = -1;
    io_iterator_t iter = 0;
    if (IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("IOHIDSystem"), &iter) == KERN_SUCCESS) {
        io_registry_entry_t entry = IOIteratorNext(iter);
        if (entry) {
            CFMutableDictionaryRef dict = NULL;
            if (IORegistryEntryCreateCFProperties(entry, &dict, kCFAllocatorDefault, 0) == KERN_SUCCESS) {
                CFNumberRef obj = CFDictionaryGetValue(dict, CFSTR("HIDIdleTime"));
                if (obj) {
                    int64_t nanoseconds = 0;
                    if (CFNumberGetValue(obj, kCFNumberSInt64Type, &nanoseconds)) {
                        idlesecs = (nanoseconds >> 30); // Divide by 10^9 to convert from nanoseconds to seconds.
                    }
                }
                CFRelease(dict);
            }
            IOObjectRelease(entry);
        }
        IOObjectRelease(iter);
    }
    
    return idlesecs;
}

- (void)outOfRange {
    statusItem.inRange = NO;
    
    if ([UD boolForKey:UDIdleCheckEnabledkey]) {
        
#ifdef DEBUG
        NSLog(@"Idle time: %lli",SystemIdleTime());
#endif
        
        if (SystemIdleTime() >= [[UD objectForKey:UDIdleMinTimeKey] integerValue])
            [self runOutOfRangeScript:YES];
            
    } else {
        [self runOutOfRangeScript:YES];
    }
}

- (void)runScript:(NSURL*)pathUrl arguments:(NSArray*)args silent:(BOOL)silent {
    if (!pathUrl)
        return;
    
    NSError *error;
    BOOL b = [NSWorkspace.sharedWorkspace runFileAtPath:pathUrl.path arguments:args error:&error];
    if (!silent && !b) {
        if (!error)
            error = [NSError errorWithDomain:@"NSWorkspace" code:0 userInfo:@{NSLocalizedDescriptionKey : @"unknown error"}];
        
        [NSApp presentError:error];
    }
}

- (void)runInRangeScript:(BOOL)silent {
    if (inRangeScriptURL)
        [self runScript:inRangeScriptURL arguments:@[@"in"] silent:silent];
}

- (void)runOutOfRangeScript:(BOOL)silent {
    if (outOfRangeScriptURL)
        [self runScript:outOfRangeScriptURL arguments:@[@"out"] silent:silent];
}

#pragma mark -

- (void)userDefaultsLoad {
	//Timer interval
	if ([UD stringForKey:UDCheckIntervalKey].length > 0 )
        monitor.timeInterval = [UD stringForKey:UDCheckIntervalKey].doubleValue;

    //signal strength
    if ([UD stringForKey:UDRequiredSignalKey].length > 0 )
        monitor.requiredSignalStrength = [[UD objectForKey:UDRequiredSignalKey] integerValue];

    // Device
	NSData *deviceAsData = [UD objectForKey:UDDeviceKey];
	if (deviceAsData.length > 0) {
		IOBluetoothDevice *device = [NSKeyedUnarchiver unarchiveObjectWithData:deviceAsData];
		_deviceName.stringValue = [NSString stringWithFormat:@"%@ (%@)", device.name, device.addressString];
		
        monitor.device = device;
	}
    
    // In range script path
	if ([UD URLForKey:UDInRangeActionKey]) {
        inRangeScriptURL = [UD URLForKey:UDInRangeActionKey];
        _inRangeScriptPath.stringValue = inRangeScriptURL.path;
    }

	// Out of range script path
	if ([UD URLForKey:UDOutOfRangeActionKey]) {
        outOfRangeScriptURL = [UD URLForKey:UDOutOfRangeActionKey];
		_outOfRangeScriptPath.stringValue = outOfRangeScriptURL.path;
    }
}

- (void)userDefaultsSave {
	// In range script
	[UD setURL:inRangeScriptURL forKey:UDInRangeActionKey];

	// Out of range script
	[UD setURL:outOfRangeScriptURL forKey:UDOutOfRangeActionKey];
    
    [UD synchronize];
}

- (IBAction)updateDeviceStatus:(id)sender {
    if (!monitor.device) {
        _deviceStatus.stringValue = @"Please select a device";
#ifdef DEBUG
        NSLog(@"No device = no status");
#endif
        return;
    }
    
    [_progressIndicator startAnimation:nil];
    
    // Refresh status
    BluetoothMonitor *testMon = [[BluetoothMonitor alloc] initWithDevice:monitor.device];
    testMon.requiredSignalStrength = monitor.requiredSignalStrength = [[UD objectForKey:UDRequiredSignalKey] integerValue];
    [testMon refresh];
    
    // Update signal bar
    _currentSignalStrength.integerValue = [testMon getRange:YES];
    
#ifdef DEBUG
    NSLog(@"Signal strength: %li",(long)_currentSignalStrength.integerValue);
#endif
    
    // Update status
    switch (testMon.status) {
        case ProximityBluetoothStatusInRange:
            _deviceStatus.stringValue = @"In range";
            break;
            
        case ProximityBluetoothStatusOutOfRange:
            _deviceStatus.stringValue = @"Out of range";
            break;
            
        case ProximityBluetoothStatusUndefined:
            _deviceStatus.stringValue = @"Not found";
            break;
    }
    
    [testMon stop];
    testMon = nil;
    
    [_progressIndicator stopAnimation:nil];
}


#pragma mark -
#pragma mark Interface Methods

- (IBAction)changeDevice:(id)sender {
	IOBluetoothDeviceSelectorController *deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
    
	[deviceSelector beginSheetModalForWindow:_prefsWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)sheetDidEnd:(IOBluetoothDeviceSelectorController *)controller returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == kIOBluetoothUISuccess) {
        IOBluetoothDevice *device = controller.getResults[0];
        
        _deviceName.stringValue = [NSString stringWithFormat:@"%@ (%@)", device.name, device.addressString];
        
        monitor.device = device;
        
        [self updateDeviceStatus:nil];
        
        // Device
        if (monitor.device) {
            NSData *deviceAsData = [NSKeyedArchiver archivedDataWithRootObject:monitor.device];
            [UD setObject:deviceAsData forKey:UDDeviceKey];
        }
    }
}

#pragma mark -

- (NSURL*)chooseScript {
    NSOpenPanel *op = NSOpenPanel.openPanel;
    op.allowsMultipleSelection = NO;
    op.canChooseDirectories = NO;
    
	if ([op runModal] == NSModalResponseOK) {
        NSArray *files = op.URLs;
        if (files.count == 1) return files[0];
    }
    
    return nil;
}

- (IBAction)inRangeScriptChange:(id)sender {
    NSURL *file = [self chooseScript];
    
    if (file) {
        inRangeScriptURL = file;
        _inRangeScriptPath.stringValue = file.path;
    }
}

- (IBAction)inRangeScriptTest:(id)sender {
    [self runInRangeScript:NO];
}

- (IBAction)outOfRangeScriptChange:(id)sender {
    NSURL *file = [self chooseScript];
    
    if (file) {
        outOfRangeScriptURL = file;
        _outOfRangeScriptPath.stringValue = file.path;
    }
}

- (IBAction)outOfRangeScriptTest:(id)sender {
    [self runOutOfRangeScript:NO];
}

#pragma mark -

- (void)showWindow:(id)sender {
	[_prefsWindow makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
    
    // Clear out status
    _deviceStatus.stringValue = @"";
	
	[monitor stop];
    
    statusItem.paused = YES;
}


@end
