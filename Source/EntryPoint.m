@import AppKit;
@import Metal;
@import simd;

typedef int8_t s8;
typedef int16_t s16;
typedef int32_t s32;
typedef int64_t s64;

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef float f32;
typedef double f64;
typedef simd_float2 f32x2;
typedef simd_float3 f32x3;
typedef simd_float4 f32x4;

#include "AppDelegate.h"
#include "MainView.h"

#include "AppDelegate.m"
#include "MainView.m"

s32
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
