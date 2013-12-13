#import <Cocoa/Cocoa.h>
//#import <IOBluetooth/IOBluetooth.h>
//#import <IOBluetoothUI/IOBluetoothUI.h>
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>
#import "ProximityBluetoothMonitor.h"

@interface ProximityAppController : NSObject <NSApplicationDelegate, NSWindowDelegate, ProximityBluetoothMonitorDelegate> {
    ProximityBluetoothMonitor *monitor;
	NSStatusItem *statusItem;

    NSURL *inRangeScriptURL;
    NSURL *outOfRangeScriptURL;
	
	NSImage *outOfRangeImage;
	NSImage *inRangeImage;
}

@property (strong) IBOutlet NSTextField *deviceName;
@property (strong) IBOutlet NSTextField *inRangeScriptPath;
@property (strong) IBOutlet NSButton *monitoringEnabled;
@property (strong) IBOutlet NSTextField *outOfRangeScriptPath;
@property (strong) IBOutlet NSWindow *prefsWindow;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (strong) IBOutlet NSButton *runScriptsOnStartup;
@property (strong) IBOutlet NSTextField *timerInterval;
@property (strong) IBOutlet NSSlider *requiredSignalStrength;
@property (strong) IBOutlet NSLevelIndicator *currentSignalStrength;
@property (strong) IBOutlet NSTextField *deviceStatus;

// UI methods
- (IBAction)changeDevice:(id)sender;
- (IBAction)updateDeviceStatus:(id)sender;
- (IBAction)inRangeScriptChange:(id)sender;
- (IBAction)inRangeScriptTest:(id)sender;
- (IBAction)outOfRangeScriptChange:(id)sender;
- (IBAction)outOfRangeScriptTest:(id)sender;
- (IBAction)showWindow:(id)sender;

@end
