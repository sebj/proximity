#import "AppController.h"
#import "NSWorkspace+runFileAtPath.h"

@implementation AppController

#pragma mark -
#pragma mark Delegate Methods

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[self stopMonitoring];
}

- (void)awakeFromNib
{
	NSBundle *bundle = [NSBundle mainBundle];
	inRangeImage = [[NSImage alloc] initWithContentsOfFile: [bundle pathForResource: @"inRange" ofType: @"png"]];
	inRangeAltImage = [[NSImage alloc] initWithContentsOfFile: [bundle pathForResource: @"inRangeAlt" ofType: @"png"]];	
	outOfRangeImage = [[NSImage alloc] initWithContentsOfFile: [bundle pathForResource: @"outRange" ofType: @"png"]];
	outOfRangeAltImage = [[NSImage alloc] initWithContentsOfFile: [bundle pathForResource: @"outOfRange" ofType: @"png"]];	

	priorStatus = OutOfRange;
	
	[self createMenuBar];
	[self userDefaultsLoad];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	[self userDefaultsSave];
	[self stopMonitoring];
	[self startMonitoring];
}


#pragma mark -
#pragma mark AppController Methods

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
	[statusItem retain];
	
	// Attributes of space on status bar
	[statusItem setHighlightMode:YES];
	[statusItem setMenu:myMenu];

	[self menuIconOutOfRange];	
}

- (void)handleTimer:(NSTimer *)theTimer
{
	if( [self isInRange] )
	{
		if( priorStatus == OutOfRange )
		{
			priorStatus = InRange;
			
			[self menuIconInRange];
            [self runInRangeScript:YES];
		}
	}
	else
	{
		if( priorStatus == InRange )
		{
			priorStatus = OutOfRange;
			
			[self menuIconOutOfRange];
            [self runOutOfRangeScript:YES];
		}
	}
	
	[self startMonitoring];
}

- (BOOL)isInRange
{
   int repeat_count = 3;
    do {
        if( device && [device remoteNameRequest:nil] == kIOReturnSuccess ) {
                return true;
        }
        usleep(500000L);
    } while(--repeat_count);

    return false;
}

- (void)menuIconInRange
{	
	[statusItem setImage:inRangeImage];
	[statusItem setAlternateImage:inRangeAltImage];
		
	//[statusItem	setTitle:@"O"];
}

- (void)menuIconOutOfRange
{
	[statusItem setImage:outOfRangeImage];
	[statusItem setAlternateImage:outOfRangeAltImage];

//	[statusItem setTitle:@"X"];
}

- (BOOL)newVersionAvailable
{
	NSDictionary *dict = [[NSBundle mainBundle] infoDictionary];
	NSArray *version = [[dict valueForKey:@"CFBundleVersion"] componentsSeparatedByString:@"."];

    int thisVersionMajor = 1;
    int thisVersionMinor = 6;

	NSURL *url = [NSURL URLWithString:@"https://raw.github.com/Daij-Djan/proximity/master/Info.plist"];
	dict = [NSDictionary dictionaryWithContentsOfURL:url];
	version = [[dict valueForKey:@"CFBundleVersion"] componentsSeparatedByString:@"."];
    int newVersionMajor = [[version objectAtIndex:0] intValue];
	int newVersionMinor = [[version objectAtIndex:1] intValue];
	
	if( thisVersionMajor < newVersionMajor || thisVersionMinor < newVersionMinor )
		return YES;

	return NO;
}

- (void)runScript:(NSString*)path arguments:(NSArray*)args silent:(BOOL)silent
{
    if(!path.length)
        return;
    
    NSError *error = nil;
    BOOL b = [[NSWorkspace sharedWorkspace] runFileAtPath:path arguments:args error:&error];
    if(!silent && !b) {
        if(!error)
            error = [NSError errorWithDomain:@"NSWorkspace" code:0 userInfo:@{ NSLocalizedDescriptionKey : @"unknown error" }];
        [NSApp presentError:error];
    }
}

- (void)runInRangeScript:(BOOL)silent {
    [self runScript:[inRangeScriptPath stringValue] arguments:@[@"inRange"] silent:silent];
}

- (void)runOutOfRangeScript:(BOOL)silent {
    [self runScript:[outOfRangeScriptPath stringValue] arguments:@[@"outOfRange"] silent:silent];
}

- (void)startMonitoring
{
	if( [monitoringEnabled state] == NSOnState )
	{
		timer = [NSTimer scheduledTimerWithTimeInterval:[timerInterval intValue]
												 target:self
											   selector:@selector(handleTimer:)
											   userInfo:nil
												repeats:NO];
		[timer retain];
	}		
}

- (void)stopMonitoring
{
	[timer invalidate];
}

- (void)userDefaultsLoad
{
	NSUserDefaults *defaults;
	NSData *deviceAsData;
	
	defaults = [NSUserDefaults standardUserDefaults];
	
	// Device
	deviceAsData = [defaults objectForKey:@"device"];
	if( [deviceAsData length] > 0 )
	{
		device = [NSKeyedUnarchiver unarchiveObjectWithData:deviceAsData];
		[device retain];
		[deviceName setStringValue:[NSString stringWithFormat:@"%@ (%@)",
									[device getName], [device getAddressString]]];
		
		if( [self isInRange] )
		{			
			priorStatus = InRange;
			[self menuIconInRange];
		}
		else
		{
			priorStatus = OutOfRange;
			[self menuIconOutOfRange];
		}
	}
	
	//Timer interval
	if( [[defaults stringForKey:@"timerInterval"] length] > 0 )
		[timerInterval setStringValue:[defaults stringForKey:@"timerInterval"]];
	
	// Out of range script path
	if( [[defaults stringForKey:@"outOfRangeScriptPath"] length] > 0 )
		[outOfRangeScriptPath setStringValue:[defaults stringForKey:@"outOfRangeScriptPath"]];
	
	// In range script path
	if( [[defaults stringForKey:@"inRangeScriptPath"] length] > 0 )
		[inRangeScriptPath setStringValue:[defaults stringForKey:@"inRangeScriptPath"]];
	
	// Check for updates on startup
	BOOL updating = [defaults boolForKey:@"updating"];
	if( updating ) {
		[checkUpdatesOnStartup setState:NSOnState];
        [self checkForUpdates:nil silent:YES];
	}
	
	// Monitoring enabled
	BOOL monitoring = [defaults boolForKey:@"enabled"];
	if( monitoring ) {
		[monitoringEnabled setState:NSOnState];
		[self startMonitoring];
	}
	
	// Run scripts on startup
	BOOL startup = [defaults boolForKey:@"executeOnStartup"];
	if( startup )
	{
		[runScriptsOnStartup setState:NSOnState];
		
		if( monitoring )
		{
			if( [self isInRange] ) {
				[self runInRangeScript:YES];
			} else {
				[self runOutOfRangeScript:YES];
			}
		}
	}
	
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
	[defaults setObject:[inRangeScriptPath stringValue] forKey:@"inRangeScriptPath"];

	// Out of range script
	[defaults setObject:[outOfRangeScriptPath stringValue] forKey:@"outOfRangeScriptPath"];
		
	// Device
	if( device ) {
		deviceAsData = [NSKeyedArchiver archivedDataWithRootObject:device];
		[defaults setObject:deviceAsData forKey:@"device"];
	}
	
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
	
	device = [results objectAtIndex:0];
	[device retain];
	
	[deviceName setStringValue:[NSString stringWithFormat:@"%@ (%@)",
								[device getName],
								[device getAddressString]]];    
}

- (IBAction)checkConnectivity:(id)sender
{
	[progressIndicator startAnimation:nil];
	
	if( [self isInRange] )
	{
		[progressIndicator stopAnimation:nil];
		NSRunAlertPanel( @"Found", @"Device is powered on and in range", nil, nil, nil, nil );
	}
	else
	{
		[progressIndicator stopAnimation:nil];
		NSRunAlertPanel( @"Not Found", @"Device is powered off or out of range", nil, nil, nil, nil );
	}
}

- (void)checkForUpdates:(id)sender silent:(BOOL)silent
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL br = [self newVersionAvailable];
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

- (IBAction)about:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/Daij-Djan/proximity/README"]];
}

- (IBAction)enableMonitoring:(id)sender
{
	// See windowWillClose: method
}

- (IBAction)inRangeScriptChange:(id)sender
{
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op runModalForDirectory:@"~" file:nil types:nil]; //[NSArray arrayWithObject:@"scpt"]
	
	NSArray *filenames = [op filenames];
    if([filenames count])
        [inRangeScriptPath setStringValue:[filenames objectAtIndex:0]];
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
	NSOpenPanel *op = [NSOpenPanel openPanel];
	[op runModalForDirectory:@"~" file:nil types:nil]; //[NSArray arrayWithObject:@"scpt"]
	
	NSArray *filenames = [op filenames];
    if([filenames count])
        [outOfRangeScriptPath setStringValue:[filenames objectAtIndex:0]];
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
	
	[self stopMonitoring];
}


@end
