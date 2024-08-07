@implementation MainViewController
{
	NSNotificationCenter *notificationCenter;
}

- (instancetype)init
{
	self = [super init];
	notificationCenter = [[NSNotificationCenter alloc] init];
	self.title = @"Recoil";
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	InspectorViewController *inspectorViewController =
	        [[InspectorViewController alloc] initWithNotificationCenter:notificationCenter];
	[self addChildViewController:inspectorViewController];

	NSBox *separator = [[NSBox alloc] init];
	separator.boxType = NSBoxSeparator;

	PreviewView *previewView =
	        [[PreviewView alloc] initWithNotificationCenter:notificationCenter];

	NSStackView *stackView = [NSStackView
	        stackViewWithViews:@[ inspectorViewController.view, separator, previewView ]];
	stackView.spacing = 0;

	stackView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.view addSubview:stackView];
	[NSLayoutConstraint activateConstraints:@[
		[stackView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
		[stackView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
		[stackView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
		[stackView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
	]];
}

@end
