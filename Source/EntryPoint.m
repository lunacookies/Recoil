@import AppKit;
@import Metal;

#include "AppDelegate.h"
#include "MainView.h"

#include "AppDelegate.m"
#include "MainView.m"

typedef int8_t int8;
typedef int16_t int16;
typedef int32_t int32;
typedef int64_t int64;

typedef uint8_t uint8;
typedef uint16_t uint16;
typedef uint32_t uint32;
typedef uint64_t uint64;

int32
main(void)
{
	setenv("MTL_SHADER_VALIDATION", "1", 1);
	setenv("MTL_DEBUG_LAYER", "1", 1);
	setenv("MTL_DEBUG_LAYER_WARNING_MODE", "nslog", 1);

	[NSApplication sharedApplication];
	AppDelegate *delegate = [[AppDelegate alloc] init];
	NSApp.delegate = delegate;
	[NSApp run];
}
