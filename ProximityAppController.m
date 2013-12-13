#import "ProximityAppController.h"
#import "NSWorkspace+runFileAtPath.h"

#define UD [NSUserDefaults standardUserDefaults]

@implementation ProximityAppController

#pragma mark -
#pragma mark Delegate Methods

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

    if (_monitoringEnabled.state == NSOnState && monitor.device) {
        monitor.requiredSignalStrength = _requiredSignalStrength.integerValue;
        monitor.timeInterval = _timerInterval.doubleValue;
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
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	
	// Attributes of space on status bar
	[statusItem setHighlightMode:YES];
	[statusItem setMenu:menu];

	[self outOfRange];
}

- (void)inRange {
	[statusItem setImage:inRangeImage];
    
    [self runInRangeScript:YES];
}

- (void)outOfRange {
	[statusItem setImage:outOfRangeImage];
    
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
	if ([UD stringForKey:@"_timerInterval"].length > 0 ) {
		[_timerInterval setStringValue:[UD stringForKey:@"_timerInterval"]];
        monitor.timeInterval = _timerInterval.doubleValue;
    }
    
	//require StrongSignal
	[_requiredSignalStrength setIntegerValue:[UD integerForKey:@"_requiredSignalStrength"]];
    monitor.requiredSignalStrength = _requiredSignalStrength.integerValue;

    // Device
	NSData *deviceAsData = [UD objectForKey:@"device"];
	if (deviceAsData.length > 0) {
		id device = [NSKeyedUnarchiver unarchiveObjectWithData:deviceAsData];
		[_deviceName setStringValue:[NSString stringWithFormat:@"%@ (%@)", [device name], [device addressString]]];
		
        monitor.device = device;
        //update icon
        [monitor refresh];
	}

	// Out of range script path
	if ([UD URLForKey:@"outOfRangeScriptURL"]) {
        outOfRangeScriptURL = [UD URLForKey:@"outOfRangeScriptURL"];
		[_outOfRangeScriptPath setStringValue:outOfRangeScriptURL.path];
    }
	
	// In range script path
	if ([UD URLForKey:@"inRangeScriptURL"]) {
        inRangeScriptURL = [UD URLForKey:@"inRangeScriptURL"];
		[_inRangeScriptPath setStringValue:inRangeScriptURL.path];
    }
	
	// Monitoring enabled
	BOOL monitoring = [UD boolForKey:@"enabled"];
    [_monitoringEnabled setState:monitoring ? NSOnState : NSOffState];
	
    if (monitoring && monitor.device) {
		[monitor start];
	}
}

- (void)userDefaultsSave {
	// Monitoring enabled
	BOOL monitoring = (_monitoringEnabled.state == NSOnState ? TRUE : FALSE);
	[UD setBool:monitoring forKey:@"enabled"];
	
	// Execute scripts on startup
	BOOL startup = (_runScriptsOnStartup.state == NSOnState ? TRUE : FALSE );
	[UD setBool:startup forKey:@"executeOnStartup"];
	
	// Timer interval
	[UD setObject:_timerInterval.stringValue forKey:@"_timerInterval"];

	// In range script
	[UD setURL:inRangeScriptURL forKey:@"inRangeScriptURL"];

	// Out of range script
	[UD setURL:outOfRangeScriptURL forKey:@"outOfRangeScriptURL"];
    
    [UD setInteger:_requiredSignalStrength.integerValue forKey:@"_requiredSignalStrength"];
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
    testMon.requiredSignalStrength = monitor.requiredSignalStrength = _requiredSignalStrength.integerValue;
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
		[[NSUserDefaults standardUserDefaults] setObject:deviceAsData forKey:@"device"];
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
    [_currentSignalStrength setIntegerValue:0];
	
	[monitor stop];}


@end
