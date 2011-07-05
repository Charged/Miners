// Copyright © 2011, Jakob Bornecrantz.  All rights reserved.
// See copyright notice in src/charge/charge.d (GPLv2 only).


#import <Cocoa/Cocoa.h>

/**
 * The main class of the application, the application's delegate.
 */
@interface ChargeMain : NSObject
@end

/**
 * The Charge application.
 */
@interface ChargeApplication : NSApplication
@end

/**
 * Used to launch the application on mac.
 *
 * XXX: This will go away.
 */
int charge_main(int argc, char **argv);

/**
 * Use this flag to determine whether we use SDLMain.nib or not.
 */
#define		CHARGE_USE_NIB_FILE	0

/**
 * Use this flag to determine whether we use CPS (docking) or not
 */
#define		CHARGE_USE_CPS		1
