@implementation AppDelegate
{
	NSWindow *window;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	window = [[NSWindow alloc]
	        initWithContentRect:NSMakeRect(0, 0, 700, 500)
	                  styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
	                            NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
	                    backing:NSBackingStoreBuffered
	                      defer:NO];
	[window center];
	[window makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
	return YES;
}

@end
