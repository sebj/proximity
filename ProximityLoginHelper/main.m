//
//  main.m
//  ProximityLoginHelper
//
//  Created by Dominik Pich on 7/27/12.
//
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
    BOOL br = [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"info.pich.proximity" options:NSWorkspaceLaunchWithoutAddingToRecents|NSWorkspaceLaunchWithoutActivation additionalEventParamDescriptor:nil launchIdentifier:nil];
#ifdef DEBUG
    if(!br) NSLog(@"Couldn't launch info.pich.proximity");
#endif
    return br ? 0 : -1;
}
