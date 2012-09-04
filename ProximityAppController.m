#import "ProximityAppController.h"
#import "NSWorkspace+runFileAtPath.h"

#include <pwd.h>
#include <sys/types.h>

@implementation ProximityAppController

#pragma mark -
#pragma mark Delegate Methods

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[monitor stop];
}

- (void)awakeFromNib
{
	NSBundle *bundle = [NSBundle mainBundle];
	inRangeImage = [[NSImage alloc] initWithContentsOfFile: [bundle pathForResource: @"inRange" ofType: @"png"]];
	inRangeAltImage = [[NSImage alloc] initWithContentsOfFile: [bundle pathForResource: @"inRangeAlt" ofType: @"png"]];	
	outOfRangeImage = [[NSImage alloc] initWithContentsOfFile: [bundle pathForResource: @"outRange" ofType: @"png"]];
	outOfRangeAltImage = [[NSImage alloc] initWithContentsOfFile: [bundle pathForResource: @"outOfRange" ofType: @"png"]];	

    monitor = [[ProximityBluetoothMonitor alloc] init];
    monitor.delegate = self;

	[self createMenuBar];
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]]];
	[self userDefaultsLoad];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[self userDefaultsSave];

    if(monitoringEnabled.state == NSOnState && monitor.device) {
        monitor.requiredSignalStrength = requiredSignalStrength.integerValue;
        monitor.timeInterval = timerInterval.doubleValue;
        [monitor refresh];
        [monitor start];
    } else {
        [monitor stop];
    }
}

- (void)proximityBluetoothMonitor:(ProximityBluetoothMonitor *)monitor foundDevice:(IOBluetoothDevice *)device {
    [self setMenuIconInRange];
    [self runInRangeScript:YES];
}


- (void)proximityBluetoothMonitor:(ProximityBluetoothMonitor *)monitor lostDevice:(IOBluetoothDevice *)device {
    [self setMenuIconOutOfRange];
    [self runOutOfRangeScript:YES];
}

#pragma mark -
#pragma mark AppController Methods

- (void)setStartAtLogin:(BOOL)enabled {
#ifdef DEBUG
    NSLog(@"Cant start at login when in DEBUG mode");
#else
	// Creating helper app complete URL
    NSURL *bundleURL = [[NSBundle mainBundle] bundleURL];
	NSURL *url = [bundleURL URLByAppendingPathComponent:
                  @"Contents/Library/LoginItems/ProximityLoginHelper.app"];
    
	// Registering helper app
	if (LSRegisterURL((__bridge CFURLRef)url, true) != noErr) {
		NSLog(@"LSRegisterURL failed!");
	}
    
	// Setting login
	if (!SMLoginItemSetEnabled((CFStringRef)@"info.pich.proximityLoginHelper", enabled ? true : false)) {
		NSLog(@"SMLoginItemSetEnabled failed!");
	}
#endif
}

- (void)createMenuBar
{
	NSMenu *myMenu;
	NSMenuItem *menuItem;
	 
	// Menu for status bar item
	myMenu = [[NSMenu alloc] init];
	
	// Prefences menu item
	menuItem = [myMenu addItemWithTitle:@"Preferences" action:@selector(showWindow:) keyEquivalent:@""];
	[menuItem setTarget:self];
	
	// Quit menu item
	[myMenu addItemWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@""];
	
	// Space on status bar
	statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	
	// Attributes of space on status bar
	[statusItem setHighlightMode:YES];
	[statusItem setMenu:myMenu];

	[self setMenuIconOutOfRange];
}

- (void)setMenuIconInRange
{	
	[statusItem setImage:inRangeImage];
	[statusItem setAlternateImage:inRangeAltImage];
		
	//[statusItem	setTitle:@"O"];
}

- (void)setMenuIconOutOfRange
{
	[statusItem setImage:outOfRangeImage];
	[statusItem setAlternateImage:outOfRangeAltImage];

//	[statusItem setTitle:@"X"];
}

- (BOOL)isNewVersionAvailable
{
	NSDictionary *dict = [[NSBundle mainBundle] infoDictionary];
	NSArray *version = [[dict valueForKey:@"CFBundleVersion"] componentsSeparatedByString:@"."];
    int thisVersionMajor = [[version objectAtIndex:0] intValue];
	int thisVersionMinor = [[version objectAtIndex:1] intValue];

	NSURL *url = [NSURL URLWithString:@"https://raw.github.com/Daij-Djan/proximity/master/Info.plist"];
	dict = [NSDictionary dictionaryWithContentsOfURL:url];
	version = [[dict valueForKey:@"CFBundleVersion"] componentsSeparatedByString:@"."];
    int newVersionMajor = [[version objectAtIndex:0] intValue];
	int newVersionMinor = [[version objectAtIndex:1] intValue];
	
	if( thisVersionMajor < newVersionMajor || thisVersionMinor < newVersionMinor )
		return YES;

	return NO;
}

- (void)runScript:(NSURL*)pathUrl arguments:(NSArray*)args silent:(BOOL)silent
{
    if(!pathUrl)
        return;
    
    NSError *error = nil;
    BOOL b = [[NSWorkspace sharedWorkspace] runFileAtPath:pathUrl.path arguments:args error:&error];
    if(!silent && !b) {
        if(!error)
            error = [NSError errorWithDomain:@"NSWorkspace" code:0 userInfo:@{ NSLocalizedDescriptionKey : @"unknown error" }];
        [NSApp presentError:error];
    }
}

- (void)runInRangeScript:(BOOL)silent {
    [self runScript:inRangeScriptURL arguments:@[@"inRange"] silent:silent];
}

- (void)runOutOfRangeScript:(BOOL)silent {
    [self runScript:outOfRangeScriptURL arguments:@[@"outOfRange"] silent:silent];
}

- (void)userDefaultsLoad
{
	NSUserDefaults *defaults;
	NSData *deviceAsData;
	
	defaults = [NSUserDefaults standardUserDefaults];
		
	//Timer interval
	if( [[defaults stringForKey:@"timerInterval"] length] > 0 ) {
		[timerInterval setStringValue:[defaults stringForKey:@"timerInterval"]];
        monitor.timeInterval = timerInterval.doubleValue;
    }

	//require StrongSignal
	[requiredSignalStrength setIntegerValue:[defaults integerForKey:@"requiredSignalStrength"]];
    monitor.requiredSignalStrength = requiredSignalStrength.integerValue;

    // Device
	deviceAsData = [defaults objectForKey:@"device"];
	if( [deviceAsData length] > 0 )
	{
		id device = [NSKeyedUnarchiver unarchiveObjectWithData:deviceAsData];
		[deviceName setStringValue:[NSString stringWithFormat:@"%@ (%@)",
									[device name], [device addressString]]];
		
        monitor.device = device;
        //update icon
        [monitor refresh];
	}

	// Out of range script path
	if( [defaults URLForKey:@"outOfRangeScriptURL"] ) {
        outOfRangeScriptURL = [defaults URLForKey:@"outOfRangeScriptURL"];
		[outOfRangeScriptPath setStringValue:outOfRangeScriptURL.path];
    }
	
	// In range script path
	if( [defaults URLForKey:@"inRangeScriptURL"] ) {
        inRangeScriptURL = [defaults URLForKey:@"inRangeScriptURL"];
		[inRangeScriptPath setStringValue:inRangeScriptURL.path];
    }
	
	// Check for updates on startup
	BOOL updating = [defaults boolForKey:@"updating"];
    [checkUpdatesOnStartup setState:updating ? NSOnState : NSOffState];
	if( updating ) {
        [self checkForUpdates:nil silent:YES];
	}
	
	// Monitoring enabled
	BOOL monitoring = [defaults boolForKey:@"enabled"];
    [monitoringEnabled setState:monitoring ? NSOnState : NSOffState];
	if( monitoring && monitor.device ) {
		[monitor start];
	}
	
	// Run scripts on startup
	BOOL startup = [defaults boolForKey:@"executeOnStartup"];
    [runScriptsOnStartup setState:startup ? NSOnState : NSOffState];
	if( startup && monitor.device )
	{
		if( monitoring )
		{
            [monitor refresh];
		}
	}
	
    //autostart
	BOOL autostart = [defaults boolForKey:@"startOnSystemStartup"];
    [startOnSystemStartup setState:autostart ? NSOnState : NSOffState];
    [self setStartAtLogin:autostart];
}

- (void)userDefaultsSave
{
	NSUserDefaults *defaults;
	NSData *deviceAsData;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	// Monitoring enabled
	BOOL monitoring = ( [monitoringEnabled state] == NSOnState ? TRUE : FALSE );
	[defaults setBool:monitoring forKey:@"enabled"];
	
	// Update checking
	BOOL updating = ( [checkUpdatesOnStartup state] == NSOnState ? TRUE : FALSE );
	[defaults setBool:updating forKey:@"updating"];
	
	// Execute scripts on startup
	BOOL startup = ( [runScriptsOnStartup state] == NSOnState ? TRUE : FALSE );
	[defaults setBool:startup forKey:@"executeOnStartup"];
	
	// Timer interval
	[defaults setObject:[timerInterval stringValue] forKey:@"timerInterval"];
	
	// In range script
	[defaults setURL:inRangeScriptURL forKey:@"inRangeScriptURL"];

	// Out of range script
	[defaults setURL:outOfRangeScriptURL forKey:@"outOfRangeScriptURL"];
		
	// Device
	if( monitor.device ) {
		deviceAsData = [NSKeyedArchiver archivedDataWithRootObject:monitor.device];
		[defaults setObject:deviceAsData forKey:@"device"];
	}

	// autostart
    [defaults setBool:[startOnSystemStartup state] == NSOnState ? TRUE : FALSE forKey:@"executeOnStartup"];
    
    [defaults setInteger:requiredSignalStrength.integerValue forKey:@"requiredSignalStrength"];
    
    //persist
	[defaults synchronize];
}


#pragma mark -
#pragma mark Interface Methods

- (IBAction)changeDevice:(id)sender
{
	IOBluetoothDeviceSelectorController *deviceSelector;
	deviceSelector = [IOBluetoothDeviceSelectorController deviceSelector];
	[deviceSelector runModal];
	
	NSArray *results;
	results = [deviceSelector getResults];
	
	if( !results )
		return;
	
	id device = [results objectAtIndex:0];
	
	[deviceName setStringValue:[NSString stringWithFormat:@"%@ (%@)",
								[device name],
								[device addressString]]];
    
    monitor.device = device;
}

- (IBAction)checkConnectivity:(id)sender
{
    if(!monitor.device) {
		NSRunAlertPanel( @"Unknown", @"Please select a bluetooth device", nil, nil, nil, nil );
        return;
    }
    
	[progressIndicator startAnimation:nil];
	
    ProximityBluetoothMonitor *testMon = [[ProximityBluetoothMonitor alloc] init];
    testMon.device = monitor.device;
    testMon.requiredSignalStrength = monitor.requiredSignalStrength;
    [testMon refresh];
    
	if( testMon.status == ProximityBluetoothStatusInRange )
	{
		NSRunAlertPanel( @"Found", @"Device is powered on and in range", nil, nil, nil, nil );
	}
	else
	{
		NSRunAlertPanel( @"Not Found", @"Device is powered off or out of range", nil, nil, nil, nil );
	}
    [progressIndicator stopAnimation:nil];
}

- (void)checkForUpdates:(id)sender silent:(BOOL)silent
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL br = [self isNewVersionAvailable];
        dispatch_sync(dispatch_get_main_queue(), ^{
            if( br ) {
                if( NSRunAlertPanel( @"Proximity", @"A new version of Proximity is available for download.",
                                    @"Close", @"Download", nil, nil ) == NSAlertAlternateReturn )
                {
                    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/Daij-Djan/proximity"]];
                }
            }
            else {
                if(!silent) {
                    NSRunAlertPanel( @"Proximity", @"You have the latest version.", @"Close", nil, nil, nil );
                }
            }
        });
    });
}

- (IBAction)checkForUpdates:(id)sender
{
    [self checkForUpdates:sender silent:NO];
}

- (IBAction)toggleStartOnSystemStartup:(id)sender {
    BOOL autostart = ([startOnSystemStartup state]==NSOnState);
    [self setStartAtLogin:autostart];
}

- (IBAction)about:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/Daij-Djan/proximity/blob/master/README.md"]];
}

- (NSURL*)chooseScript {
    NSString *homePath = [NSString stringWithUTF8String:getpwuid(getuid())->pw_dir];
	NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setDirectoryURL:[NSURL fileURLWithPath:homePath]];
    [op setAllowsMultipleSelection:NO];
	if([op runModal]==NSOKButton) {
        NSArray *files = [op URLs];
        if([files count])
            return [files objectAtIndex:0];
    }
    
    return nil;
}

- (IBAction)inRangeScriptChange:(id)sender
{
    NSURL *file = [self chooseScript];
    if(file) {
        inRangeScriptURL = file;
        [inRangeScriptPath setStringValue:file.path];
    }
}

- (IBAction)inRangeScriptClear:(id)sender
{
	[inRangeScriptPath setStringValue:@""];
}

- (IBAction)inRangeScriptTest:(id)sender
{
    [self runInRangeScript:NO];
}

- (IBAction)outOfRangeScriptChange:(id)sender
{
    NSURL *file = [self chooseScript];
    if(file) {
        outOfRangeScriptURL = file;
        [outOfRangeScriptPath setStringValue:file.path];
    }
}

- (IBAction)outOfRangeScriptClear:(id)sender
{
	[outOfRangeScriptPath setStringValue:@""];
}

- (IBAction)outOfRangeScriptTest:(id)sender
{
    [self runOutOfRangeScript:NO];
}

- (void)showWindow:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
    
	[prefsWindow makeKeyAndOrderFront:self];
	[prefsWindow center];
	
	[monitor stop];
}


@end
