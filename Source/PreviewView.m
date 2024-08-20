@interface
CALayer (Private)
- (void)setContentsChanged;
@end

typedef struct PointsArguments PointsArguments;
struct PointsArguments
{
	f32x2 resolution;
	f32 pointSize;
	u64 positionsAddress;
};

typedef struct ColorizeArguments ColorizeArguments;
struct ColorizeArguments
{
	f32x4 backgroundColor;
	f32x4 pointColor;
};

@implementation PreviewView
{
	NSNotificationCenter *notificationCenter;
	Config *config;

	id<MTLDevice> device;
	id<MTLCommandQueue> commandQueue;
	IOSurfaceRef iosurface;
	id<MTLTexture> texture;
	id<MTLRenderPipelineState> pointsPipelineState;
	id<MTLRenderPipelineState> colorizePipelineState;

	u64 pointCapacity;
	u64 pointCount;
	f32x2 *positions;
	id<MTLBuffer> positionsBuffer;
}

- (instancetype)initWithNotificationCenter:(NSNotificationCenter *)notificationCenter_
{
	self = [super init];

	notificationCenter = notificationCenter_;
	[notificationCenter addObserver:self
	                       selector:@selector(didChangeConfig:)
	                           name:ConfigChangedNotificationName
	                         object:nil];

	self.wantsLayer = YES;
	device = MTLCreateSystemDefaultDevice();
	commandQueue = [device newCommandQueue];

	id<MTLLibrary> library = [device newDefaultLibrary];

	{
		MTLRenderPipelineDescriptor *descriptor =
		        [[MTLRenderPipelineDescriptor alloc] init];
		descriptor.vertexFunction = [library newFunctionWithName:@"PointsVertex"];
		descriptor.fragmentFunction = [library newFunctionWithName:@"PointsFragment"];

		MTLRenderPipelineColorAttachmentDescriptor *attachmentDescriptor =
		        descriptor.colorAttachments[0];
		attachmentDescriptor.pixelFormat = MTLPixelFormatBGRA8Unorm;
		attachmentDescriptor.blendingEnabled = YES;
		attachmentDescriptor.destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
		attachmentDescriptor.destinationAlphaBlendFactor =
		        MTLBlendFactorOneMinusSourceAlpha;
		attachmentDescriptor.sourceRGBBlendFactor = MTLBlendFactorOne;
		attachmentDescriptor.sourceAlphaBlendFactor = MTLBlendFactorOne;
		pointsPipelineState = [device newRenderPipelineStateWithDescriptor:descriptor
		                                                             error:nil];
	}

	{
		MTLTileRenderPipelineDescriptor *descriptor =
		        [[MTLTileRenderPipelineDescriptor alloc] init];
		descriptor.tileFunction = [library newFunctionWithName:@"Colorize"];
		descriptor.threadgroupSizeMatchesTileSize = YES;
		descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;

		colorizePipelineState =
		        [device newRenderPipelineStateWithTileDescriptor:descriptor
		                                                 options:MTLPipelineOptionNone
		                                              reflection:nil
		                                                   error:nil];
	}

	pointCapacity = 128 * 1024;
	positionsBuffer = [device newBufferWithLength:pointCapacity * sizeof(positions[0])
	                                      options:MTLResourceCPUCacheModeDefaultCache |
	                                              MTLResourceStorageModeShared |
	                                              MTLResourceHazardTrackingModeTracked];
	positions = positionsBuffer.contents;

	[NSLayoutConstraint activateConstraints:@[
		[self.widthAnchor constraintGreaterThanOrEqualToConstant:100],
		[self.heightAnchor constraintGreaterThanOrEqualToConstant:100],
	]];

	return self;
}

- (BOOL)wantsUpdateLayer
{
	return YES;
}

- (void)updateLayer
{
	f32 scaleFactor = (f32)self.window.backingScaleFactor;

	PointsArguments pointsArguments = {0};

	NSSize resolution = [self convertSizeToBacking:self.bounds.size];
	pointsArguments.resolution.x = (f32)resolution.width;
	pointsArguments.resolution.y = (f32)resolution.height;

	pointsArguments.pointSize = config.pointSize * scaleFactor;

	f32 velocity = 0;
	f32 current = 0;
	f32 target = pointsArguments.resolution.y * 0.5f;
	f32 cursor = 0;
	f32 step = config.stepMultiplier * pointsArguments.pointSize;
	for (pointCount = 0; pointCount < pointCapacity; pointCount++)
	{
		if (cursor > pointsArguments.resolution.x + pointsArguments.pointSize / 2)
		{
			break;
		}

		positions[pointCount] = (f32x2){cursor, current};
		cursor += step;

		f32 displacement = current - target;
		f32 tensionForce = -config.tension * displacement;
		f32 frictionForce = -config.friction * velocity;
		f32 acceleration = (tensionForce + frictionForce) / config.mass;
		velocity += acceleration * step;
		current += velocity * step;
	}

	pointsArguments.positionsAddress = positionsBuffer.gpuAddress;

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
	[encoder setRenderPipelineState:pointsPipelineState];
	[encoder setVertexBytes:&pointsArguments length:sizeof(pointsArguments) atIndex:0];
	[encoder setFragmentBytes:&pointsArguments length:sizeof(pointsArguments) atIndex:0];
	[encoder drawPrimitives:MTLPrimitiveTypeTriangle
	            vertexStart:0
	            vertexCount:6
	          instanceCount:pointCount];

	ColorizeArguments colorizeArguments = {0};

	NSColor *backgroundColor =
	        [NSColor.textBackgroundColor colorUsingColorSpace:self.window.colorSpace];
	colorizeArguments.backgroundColor.r = (f32)backgroundColor.redComponent;
	colorizeArguments.backgroundColor.g = (f32)backgroundColor.greenComponent;
	colorizeArguments.backgroundColor.b = (f32)backgroundColor.blueComponent;
	colorizeArguments.backgroundColor.a = (f32)backgroundColor.alphaComponent;
	colorizeArguments.backgroundColor.rgb *= colorizeArguments.backgroundColor.a;

	NSColor *color = [NSColor.labelColor colorUsingColorSpace:self.window.colorSpace];
	colorizeArguments.pointColor.r = (f32)color.redComponent;
	colorizeArguments.pointColor.g = (f32)color.greenComponent;
	colorizeArguments.pointColor.b = (f32)color.blueComponent;
	colorizeArguments.pointColor.a = (f32)color.alphaComponent;
	colorizeArguments.pointColor.rgb *= colorizeArguments.pointColor.a;

	[encoder setRenderPipelineState:colorizePipelineState];
	[encoder setTileBytes:&colorizeArguments length:sizeof(colorizeArguments) atIndex:0];
	[encoder dispatchThreadsPerTile:MTLSizeMake(encoder.tileWidth, encoder.tileHeight, 1)];

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

- (void)didChangeConfig:(NSNotification *)notification
{
	config = notification.object;
	self.needsDisplay = YES;
}

@end
