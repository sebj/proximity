#import <Cocoa/Cocoa.h>
//#import <IOBluetooth/IOBluetooth.h>
//#import <IOBluetoothUI/IOBluetoothUI.h>
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>
#import <ServiceManagement/ServiceManagement.h>
#import "ProximityBluetoothMonitor.h"

typedef enum _BPStatus {
	InRange,
	OutOfRange
} BPStatus;

@interface ProximityAppController : NSObject<NSApplicationDelegate, NSWindowDelegate, ProximityBluetoothMonitorDelegate>
{
    ProximityBluetoothMonitor *monitor;
	NSStatusItem *statusItem;

    NSURL *inRangeScriptURL;
    NSURL *outOfRangeScriptURL;
	
	NSImage *outOfRangeImage;
	NSImage *outOfRangeAltImage;
	NSImage *inRangeImage;
	NSImage *inRangeAltImage;
	
    IBOutlet NSButton *checkUpdatesOnStartup;
    IBOutlet NSButton *startOnSystemStartup;
    IBOutlet NSTextField *deviceName;
    IBOutlet NSTextField *inRangeScriptPath;
    IBOutlet NSButton *monitoringEnabled;
    IBOutlet NSTextField *outOfRangeScriptPath;
    IBOutlet NSWindow *prefsWindow;
    IBOutlet NSProgressIndicator *progressIndicator;
    IBOutlet NSButton *runScriptsOnStartup;
    IBOutlet NSTextField *timerInterval;
    IBOutlet NSSlider *requiredSignalStrength;
}

// UI methods
- (IBAction)changeDevice:(id)sender;
- (IBAction)checkConnectivity:(id)sender;
- (IBAction)checkForUpdates:(id)sender;
- (IBAction)toggleStartOnSystemStartup:(id)sender;
- (IBAction)about:(id)sender;
- (IBAction)inRangeScriptChange:(id)sender;
- (IBAction)inRangeScriptClear:(id)sender;
- (IBAction)inRangeScriptTest:(id)sender;
- (IBAction)outOfRangeScriptChange:(id)sender;
- (IBAction)outOfRangeScriptClear:(id)sender;
- (IBAction)outOfRangeScriptTest:(id)sender;
- (IBAction)showWindow:(id)sender;

@end
