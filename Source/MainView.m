@interface
CALayer (Private)
- (void)setContentsChanged;
@end

typedef struct Arguments Arguments;
struct Arguments
{
	f32x2 resolution;
	f32x4 color;
	f32 pointSize;
	u64 positionsAddress;
};

@implementation MainView
{
	id<MTLDevice> device;
	id<MTLCommandQueue> commandQueue;
	IOSurfaceRef iosurface;
	id<MTLTexture> texture;
	id<MTLRenderPipelineState> pipelineState;

	u64 pointCapacity;
	u64 pointCount;
	f32x2 *positions;
	id<MTLBuffer> positionsBuffer;
}

- (instancetype)initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	self.wantsLayer = YES;

	device = MTLCreateSystemDefaultDevice();
	commandQueue = [device newCommandQueue];

	id<MTLLibrary> library = [device newDefaultLibrary];
	MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
	descriptor.vertexFunction = [library newFunctionWithName:@"VertexMain"];
	descriptor.fragmentFunction = [library newFunctionWithName:@"FragmentMain"];

	MTLRenderPipelineColorAttachmentDescriptor *attachmentDescriptor =
	        descriptor.colorAttachments[0];
	attachmentDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
	attachmentDescriptor.blendingEnabled = YES;
	attachmentDescriptor.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	attachmentDescriptor.destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	attachmentDescriptor.sourceRGBBlendFactor = MTLBlendFactorOne;
	attachmentDescriptor.sourceAlphaBlendFactor = MTLBlendFactorOne;
	pipelineState = [device newRenderPipelineStateWithDescriptor:descriptor error:nil];

	pointCapacity = 1024;
	positionsBuffer = [device newBufferWithLength:pointCapacity * sizeof(positions[0])
	                                      options:MTLResourceCPUCacheModeDefaultCache |
	                                              MTLResourceStorageModeShared |
	                                              MTLResourceHazardTrackingModeTracked];
	positions = positionsBuffer.contents;

	return self;
}

- (BOOL)wantsUpdateLayer
{
	return YES;
}

- (void)updateLayer
{
	f32 scaleFactor = (f32)self.window.backingScaleFactor;

	pointCount = 3;
	positions[0] = (f32x2){100, 100};
	positions[1] = (f32x2){200, 100};
	positions[2] = (f32x2){50, 300};
	for (u64 i = 0; i < pointCount; i++)
	{
		positions[i] *= scaleFactor;
	}

	Arguments arguments = {0};

	NSSize resolution = [self convertSizeToBacking:self.bounds.size];
	arguments.resolution.x = (f32)resolution.width;
	arguments.resolution.y = (f32)resolution.height;

	NSColor *color = [NSColor.labelColor colorUsingColorSpace:self.window.colorSpace];
	arguments.color.r = (f32)color.redComponent;
	arguments.color.g = (f32)color.greenComponent;
	arguments.color.b = (f32)color.blueComponent;
	arguments.color.a = (f32)color.alphaComponent;

	arguments.pointSize = 10 * scaleFactor;
	arguments.positionsAddress = positionsBuffer.gpuAddress;

	id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

	MTLRenderPassDescriptor *descriptor = [[MTLRenderPassDescriptor alloc] init];
	descriptor.colorAttachments[0].texture = texture;
	descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
	descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);

	id<MTLRenderCommandEncoder> encoder =
	        [commandBuffer renderCommandEncoderWithDescriptor:descriptor];

	[encoder useResource:positionsBuffer
	               usage:MTLResourceUsageRead
	              stages:MTLRenderStageVertex | MTLRenderStageFragment];
	[encoder setRenderPipelineState:pipelineState];
	[encoder setVertexBytes:&arguments length:sizeof(arguments) atIndex:0];
	[encoder setFragmentBytes:&arguments length:sizeof(arguments) atIndex:0];
	[encoder drawPrimitives:MTLPrimitiveTypeTriangle
	            vertexStart:0
	            vertexCount:6
	          instanceCount:pointCount];

	[encoder endEncoding];

	[commandBuffer commit];
	[commandBuffer waitUntilCompleted];
	[self.layer setContentsChanged];
}

- (void)viewDidChangeBackingProperties
{
	[super viewDidChangeBackingProperties];
	[self updateIOSurface];
	self.needsDisplay = YES;
}

- (void)setFrameSize:(NSSize)size
{
	[super setFrameSize:size];
	[self updateIOSurface];
	self.needsDisplay = YES;
}

- (void)updateIOSurface
{
	NSSize size = [self convertSizeToBacking:self.bounds.size];

	NSDictionary *properties = @{
		(__bridge NSString *)kIOSurfaceWidth : @(size.width),
		(__bridge NSString *)kIOSurfaceHeight : @(size.height),
		(__bridge NSString *)kIOSurfaceBytesPerElement : @4,
		(__bridge NSString *)kIOSurfacePixelFormat : @(kCVPixelFormatType_32BGRA),
	};

	MTLTextureDescriptor *descriptor = [[MTLTextureDescriptor alloc] init];
	descriptor.width = (uint64)size.width;
	descriptor.height = (uint64)size.height;
	descriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
	descriptor.usage = MTLTextureUsageRenderTarget;

	if (iosurface != NULL)
	{
		CFRelease(iosurface);
	}

	iosurface = IOSurfaceCreate((__bridge CFDictionaryRef)properties);
	texture = [device newTextureWithDescriptor:descriptor iosurface:iosurface plane:0];
	texture.label = @"Layer Contents";

	self.layer.contents = (__bridge id)iosurface;
}

@end
