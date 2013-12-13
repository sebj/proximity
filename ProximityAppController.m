#import <IOKit/IOKitLib.h>

#import "ProximityAppController.h"
#import "NSWorkspace+runFileAtPath.h"
#import "StatusItem.h"
#import "UDKeys.h"

#define UD [NSUserDefaults standardUserDefaults]

@implementation ProximityAppController

#pragma mark -
#pragma mark Delegate Methods

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

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[monitor stop];
}

- (void)awakeFromNib {
    inRangeImage = [NSImage imageNamed:@"inRange"];
    outOfRangeImage = [NSImage imageNamed:@"outRange"];

    monitor = [[ProximityBluetoothMonitor alloc] init];
    monitor.delegate = self;

	[self createMenuBar];
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ud" ofType:@"plist"]]];
	[self userDefaultsLoad];
}

- (void)windowWillClose:(NSNotification *)aNotification {
	[self userDefaultsSave];

    if ([UD boolForKey:UDMonitoringEnabledKey] && monitor.device) {
        monitor.requiredSignalStrength = ((NSNumber*)[UD objectForKey:UDRequiredSignalKey]).integerValue;
        monitor.timeInterval = [UD stringForKey:UDCheckIntervalKey].doubleValue;
        [monitor refresh];
        [monitor start];
    } else {
        [monitor stop];
    }
}

#pragma mark -
#pragma mark AppController Methods

- (void)createMenuBar {
	NSMenu *menu = [[NSMenu alloc] init];
	
	NSMenuItem *menuItem = [menu addItemWithTitle:@"Preferences..." action:@selector(showWindow:) keyEquivalent:@""];
	[menuItem setTarget:self];
    
    [menu addItem:[NSMenuItem separatorItem]];
	
	[menu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
	
	// Space on status bar
    statusItem = [[ProximityStatusItem alloc] initWithStandardThickness];
    statusItem.showMenuOnLeftMouseDown = YES;
    statusItem.menu = menu;

	[self outOfRange];
}

- (void)inRange {
    statusItem.inRange = YES;
    statusItem.needsDisplay = YES;
    
    [self runInRangeScript:YES];
}

- (void)outOfRange {
    statusItem.inRange = NO;
    statusItem.needsDisplay = YES;
    
    [self runOutOfRangeScript:YES];
}

- (void)runScript:(NSURL*)pathUrl arguments:(NSArray*)args silent:(BOOL)silent {
    if (!pathUrl)
        return;
    
    NSError *error = nil;
    BOOL b = [[NSWorkspace sharedWorkspace] runFileAtPath:pathUrl.path arguments:args error:&error];
    if (!silent && !b) {
        if (!error)
            error = [NSError errorWithDomain:@"NSWorkspace" code:0 userInfo:@{ NSLocalizedDescriptionKey : @"unknown error" }];
        [NSApp presentError:error];
    }
}

- (void)runInRangeScript:(BOOL)silent {
    [self runScript:inRangeScriptURL arguments:@[@"in"] silent:silent];
}

- (void)runOutOfRangeScript:(BOOL)silent {
    [self runScript:outOfRangeScriptURL arguments:@[@"out"] silent:silent];
}

- (void)userDefaultsLoad {
	//Timer interval
	if ([UD stringForKey:UDCheckIntervalKey].length > 0 ) {
        monitor.timeInterval = [UD stringForKey:UDCheckIntervalKey].doubleValue;
    }

    // Device
	NSData *deviceAsData = [UD objectForKey:UDDeviceKey];
	if (deviceAsData.length > 0) {
		id device = [NSKeyedUnarchiver unarchiveObjectWithData:deviceAsData];
		[_deviceName setStringValue:[NSString stringWithFormat:@"%@ (%@)", [device name], [device addressString]]];
		
        monitor.device = device;
        //update icon
        [monitor refresh];
	}
    
    // In range script path
	if ([UD URLForKey:UDInRangeActionKey]) {
        inRangeScriptURL = [UD URLForKey:UDInRangeActionKey];
		[_inRangeScriptPath setStringValue:inRangeScriptURL.path];
    }

	// Out of range script path
	if ([UD URLForKey:UDOutOfRangeActionKey]) {
        outOfRangeScriptURL = [UD URLForKey:UDOutOfRangeActionKey];
		[_outOfRangeScriptPath setStringValue:outOfRangeScriptURL.path];
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
        [_deviceStatus setStringValue:@"Please select a device"];
        
        return;
    }
    
    [_progressIndicator startAnimation:nil];
    
    // Refresh status
    ProximityBluetoothMonitor *testMon = [[ProximityBluetoothMonitor alloc] init];
    testMon.device = monitor.device;
    testMon.requiredSignalStrength = monitor.requiredSignalStrength = ((NSNumber*)[UD objectForKey:UDRequiredSignalKey]).integerValue;
    [testMon refresh];
    
    // Update signal bar
    [_currentSignalStrength setIntegerValue:[testMon getRange:YES]];
    
    // Update status
	if (testMon.status == ProximityBluetoothStatusInRange)  {
        [_deviceStatus setStringValue:@"In range"];
	} else if (testMon.status == ProximityBluetoothStatusOutOfRange) {
        [_deviceStatus setStringValue:@"Out of range"];
	} else if (testMon.status == ProximityBluetoothStatusUndefined) {
        [_deviceStatus setStringValue:@"Not found"];
	}
    
    [testMon stop];
    testMon = nil;
    
    [_progressIndicator stopAnimation:nil];
}


#pragma mark -
#pragma mark Interface Methods

- (IBAction)changeDevice:(id)sender {
	IOBluetoothDeviceSelectorController *deviceSelector;
	deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
	[deviceSelector runModal];
	
	NSArray *results;
	results = deviceSelector.getResults;
	
	if (!results)
		return;
	
	id device = results[0];
	
	[_deviceName setStringValue:[NSString stringWithFormat:@"%@ (%@)", [device name], [device addressString]]];
    
    monitor.device = device;
    
    [self updateDeviceStatus:nil];
    
    // Device
	if (monitor.device) {
		NSData *deviceAsData = [NSKeyedArchiver archivedDataWithRootObject:monitor.device];
		[[NSUserDefaults standardUserDefaults] setObject:deviceAsData forKey:UDDeviceKey];
	}
}

- (NSURL*)chooseScript {
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setAllowsMultipleSelection:NO];
    
	if ([op runModal] == NSOKButton) {
        NSArray *files = op.URLs;
        if (files.count)
            return files[0];
    }
    
    return nil;
}

- (IBAction)inRangeScriptChange:(id)sender {
    NSURL *file = [self chooseScript];
    if (file) {
        inRangeScriptURL = file;
        [_inRangeScriptPath setStringValue:file.path];
    }
}

- (IBAction)inRangeScriptTest:(id)sender {
    [self runInRangeScript:NO];
}

- (IBAction)outOfRangeScriptChange:(id)sender {
    NSURL *file = [self chooseScript];
    if (file) {
        outOfRangeScriptURL = file;
        [_outOfRangeScriptPath setStringValue:file.path];
    }
}

- (IBAction)outOfRangeScriptTest:(id)sender {
    [self runOutOfRangeScript:NO];
}

- (void)showWindow:(id)sender {
    [NSApp activateIgnoringOtherApps:YES];
    
	[_prefsWindow makeKeyAndOrderFront:self];
    
    // Clear out status
    [_deviceStatus setStringValue:@""];
	
	[monitor stop];
}


@end
