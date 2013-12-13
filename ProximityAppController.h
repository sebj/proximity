#import <Cocoa/Cocoa.h>

#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>
#import "ProximityBluetoothMonitor.h"
#import "ProximityStatusItem.h"

@interface ProximityAppController : NSObject <NSApplicationDelegate, NSWindowDelegate, ProximityBluetoothMonitorDelegate> {
    ProximityBluetoothMonitor *monitor;
	ProximityStatusItem *statusItem;

    NSURL *inRangeScriptURL;
    NSURL *outOfRangeScriptURL;
}

@property (strong) IBOutlet NSWindow *prefsWindow;

@property (strong) IBOutlet NSTextField *deviceName;
@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (strong) IBOutlet NSLevelIndicator *currentSignalStrength;
@property (strong) IBOutlet NSTextField *deviceStatus;

@property (strong) IBOutlet NSTextField *inRangeScriptPath;
@property (strong) IBOutlet NSTextField *outOfRangeScriptPath;

// UI methods
- (IBAction)changeDevice:(id)sender;
- (IBAction)updateDeviceStatus:(id)sender;

- (IBAction)inRangeScriptChange:(id)sender;
- (IBAction)inRangeScriptTest:(id)sender;

- (IBAction)outOfRangeScriptChange:(id)sender;
- (IBAction)outOfRangeScriptTest:(id)sender;

- (IBAction)showWindow:(id)sender;

@end
