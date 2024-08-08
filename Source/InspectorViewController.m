@implementation InspectorViewController
{
	NSNotificationCenter *notificationCenter;
	NSSlider *slopeSlider;
	NSSlider *tensionSlider;
	NSSlider *frictionSlider;
	NSSlider *massSlider;
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

	tensionSlider = [NSSlider sliderWithValue:1
	                                 minValue:0
	                                 maxValue:5
	                                   target:self
	                                   action:@selector(didChangeConfig:)];

	frictionSlider = [NSSlider sliderWithValue:100
	                                  minValue:0
	                                  maxValue:500
	                                    target:self
	                                    action:@selector(didChangeConfig:)];

	massSlider = [NSSlider sliderWithValue:100
	                              minValue:0
	                              maxValue:5000
	                                target:self
	                                action:@selector(didChangeConfig:)];

	pointSizeSlider = [NSSlider sliderWithValue:10
	                                   minValue:0
	                                   maxValue:100
	                                     target:self
	                                     action:@selector(didChangeConfig:)];

	stepMultiplierSlider = [NSSlider sliderWithValue:0.05
	                                        minValue:0
	                                        maxValue:0.1
	                                          target:self
	                                          action:@selector(didChangeConfig:)];

	NSGridView *gridView = [NSGridView gridViewWithViews:@[
		@[ [NSTextField labelWithString:@"Slope:"], slopeSlider ],
		@[ [NSTextField labelWithString:@"Tension:"], tensionSlider ],
		@[ [NSTextField labelWithString:@"Friction:"], frictionSlider ],
		@[ [NSTextField labelWithString:@"Mass:"], massSlider ],
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
	config.tension = tensionSlider.floatValue;
	config.friction = frictionSlider.floatValue;
	config.mass = massSlider.floatValue;
	config.pointSize = pointSizeSlider.floatValue;
	config.stepMultiplier = stepMultiplierSlider.floatValue;
	[notificationCenter postNotificationName:ConfigChangedNotificationName object:config];
}

@end
