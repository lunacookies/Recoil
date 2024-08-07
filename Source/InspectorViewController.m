@implementation InspectorViewController
{
	NSNotificationCenter *notificationCenter;
	NSSlider *rateSlider;
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

	rateSlider = [NSSlider sliderWithValue:0.1
	                              minValue:0
	                              maxValue:1
	                                target:self
	                                action:@selector(didChangeConfig:)];

	NSGridView *gridView = [NSGridView gridViewWithViews:@[
		@[ [NSTextField labelWithString:@"Rate:"], rateSlider ],
	]];

	gridView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:gridView];
	NSLayoutGuide *guide = self.view.layoutMarginsGuide;
	[NSLayoutConstraint activateConstraints:@[
		[gridView.topAnchor constraintEqualToAnchor:guide.topAnchor],
		[gridView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
		[gridView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
		[gridView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
		[rateSlider.widthAnchor constraintEqualToConstant:150],
	]];

	[self didChangeConfig:nil];
}

- (void)didChangeConfig:(id)sender
{
	Config *config = [[Config alloc] init];
	config.rate = rateSlider.floatValue;
	[notificationCenter postNotificationName:ConfigChangedNotificationName object:config];
}

@end