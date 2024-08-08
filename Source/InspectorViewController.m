@implementation InspectorViewController
{
	NSNotificationCenter *notificationCenter;
	NSSlider *slopeSlider;
	NSSlider *pointSizeSlider;
	NSSlider *stepMultiplierSlider;
}

- (instancetype)initWithNotificationCenter:(NSNotificationCenter *)notificationCenter_
{
	self = [super init];
	notificationCenter = notificationCenter_;
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	slopeSlider = [NSSlider sliderWithValue:100
	                               minValue:0
	                               maxValue:500
	                                 target:self
	                                 action:@selector(didChangeConfig:)];

	pointSizeSlider = [NSSlider sliderWithValue:10
	                                   minValue:0
	                                   maxValue:100
	                                     target:self
	                                     action:@selector(didChangeConfig:)];

	stepMultiplierSlider = [NSSlider sliderWithValue:1.5
	                                        minValue:0
	                                        maxValue:4
	                                          target:self
	                                          action:@selector(didChangeConfig:)];

	NSGridView *gridView = [NSGridView gridViewWithViews:@[
		@[ [NSTextField labelWithString:@"Slope:"], slopeSlider ],
		@[ [NSTextField labelWithString:@"Point Size:"], pointSizeSlider ],
		@[ [NSTextField labelWithString:@"Step Multiplier:"], stepMultiplierSlider ],
	]];

	gridView.rowAlignment = NSGridRowAlignmentFirstBaseline;
	[gridView columnAtIndex:0].xPlacement = NSGridCellPlacementTrailing;

	gridView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:gridView];
	NSLayoutGuide *guide = self.view.layoutMarginsGuide;
	[NSLayoutConstraint activateConstraints:@[
		[gridView.topAnchor constraintEqualToAnchor:guide.topAnchor],
		[gridView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
		[gridView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
		[guide.bottomAnchor constraintGreaterThanOrEqualToAnchor:gridView.bottomAnchor],
		[slopeSlider.widthAnchor constraintEqualToConstant:150],
	]];

	[self didChangeConfig:nil];
}

- (void)didChangeConfig:(id)sender
{
	Config *config = [[Config alloc] init];
	config.slope = slopeSlider.floatValue;
	config.pointSize = pointSizeSlider.floatValue;
	config.stepMultiplier = stepMultiplierSlider.floatValue;
	[notificationCenter postNotificationName:ConfigChangedNotificationName object:config];
}

@end
