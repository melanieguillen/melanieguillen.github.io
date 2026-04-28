#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>

static const NSInteger DefaultGlassSizeML = 300;
static const NSInteger DefaultDailyGoalML = 2000;
static const NSInteger DefaultReminderIntervalMinutes = 90;
static const NSInteger MinimumReminderIntervalMinutes = 15;
static const NSInteger MaximumReminderIntervalMinutes = 240;
static const NSInteger ReminderIntervalStepMinutes = 5;
static const NSInteger MinimumDailyGoalML = 1000;
static const NSInteger MaximumDailyGoalML = 5000;
static const NSInteger DailyGoalStepML = 100;
static const double LowWaterThreshold = 0.28;

static NSString *const RefillDateKey = @"refillDate";
static NSString *const LastReminderDateKey = @"lastReminderDate";
static NSString *const ReminderIntervalMinutesKey = @"reminderIntervalMinutes";
static NSString *const DailyGoalMLKey = @"dailyGoalML";
static NSString *const DailyIntakeMLKey = @"dailyIntakeML";
static NSString *const DailyIntakeDateKey = @"dailyIntakeDate";

static NSString *FormattedNumber(NSInteger value) {
    return [NSNumberFormatter localizedStringFromNumber:@(value) numberStyle:NSNumberFormatterDecimalStyle];
}

static NSString *FormattedML(NSInteger value) {
    return [NSString stringWithFormat:@"%@ mL", FormattedNumber(value)];
}

@interface HydrationStore : NSObject
+ (instancetype)sharedStore;
- (NSDate *)refillDate;
- (void)setRefillDate:(NSDate *)date;
- (NSDate *)lastReminderDate;
- (void)setLastReminderDate:(NSDate *)date;
- (NSInteger)reminderIntervalMinutes;
- (void)setReminderIntervalMinutes:(NSInteger)minutes;
- (NSInteger)dailyGoalML;
- (void)setDailyGoalML:(NSInteger)goalML;
- (NSInteger)glassSizeML;
- (NSInteger)todaysIntakeML;
- (void)addGlassToToday;
@end

@implementation HydrationStore
+ (instancetype)sharedStore {
    static HydrationStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[HydrationStore alloc] init];
    });
    return store;
}

- (instancetype)init {
    self = [super init];
    if (self != nil) {
        [[NSUserDefaults standardUserDefaults] registerDefaults:@{
            ReminderIntervalMinutesKey: @(DefaultReminderIntervalMinutes),
            DailyGoalMLKey: @(DefaultDailyGoalML),
        }];
    }

    return self;
}

- (NSCalendar *)calendar {
    return [NSCalendar currentCalendar];
}

- (void)ensureTodayBucket {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *savedDate = [defaults objectForKey:DailyIntakeDateKey];
    NSDate *today = [[self calendar] startOfDayForDate:[NSDate date]];

    if (savedDate == nil || ![[self calendar] isDate:savedDate inSameDayAsDate:today]) {
        [defaults setObject:today forKey:DailyIntakeDateKey];
        [defaults setInteger:0 forKey:DailyIntakeMLKey];
    }
}

- (NSDate *)refillDate {
    NSDate *savedDate = [[NSUserDefaults standardUserDefaults] objectForKey:RefillDateKey];
    return savedDate ?: [NSDate date];
}

- (void)setRefillDate:(NSDate *)date {
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:RefillDateKey];
}

- (NSDate *)lastReminderDate {
    return [[NSUserDefaults standardUserDefaults] objectForKey:LastReminderDateKey];
}

- (void)setLastReminderDate:(NSDate *)date {
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:LastReminderDateKey];
}

- (NSInteger)reminderIntervalMinutes {
    NSInteger minutes = [[NSUserDefaults standardUserDefaults] integerForKey:ReminderIntervalMinutesKey];
    return MAX(MinimumReminderIntervalMinutes, MIN(MaximumReminderIntervalMinutes, minutes));
}

- (void)setReminderIntervalMinutes:(NSInteger)minutes {
    NSInteger clamped = MAX(MinimumReminderIntervalMinutes, MIN(MaximumReminderIntervalMinutes, minutes));
    [[NSUserDefaults standardUserDefaults] setInteger:clamped forKey:ReminderIntervalMinutesKey];
}

- (NSInteger)dailyGoalML {
    NSInteger goalML = [[NSUserDefaults standardUserDefaults] integerForKey:DailyGoalMLKey];
    return MAX(MinimumDailyGoalML, MIN(MaximumDailyGoalML, goalML));
}

- (void)setDailyGoalML:(NSInteger)goalML {
    NSInteger clamped = MAX(MinimumDailyGoalML, MIN(MaximumDailyGoalML, goalML));
    [[NSUserDefaults standardUserDefaults] setInteger:clamped forKey:DailyGoalMLKey];
}

- (NSInteger)glassSizeML {
    return DefaultGlassSizeML;
}

- (NSInteger)todaysIntakeML {
    [self ensureTodayBucket];
    return [[NSUserDefaults standardUserDefaults] integerForKey:DailyIntakeMLKey];
}

- (void)addGlassToToday {
    [self ensureTodayBucket];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger updated = [defaults integerForKey:DailyIntakeMLKey] + [self glassSizeML];
    [defaults setInteger:updated forKey:DailyIntakeMLKey];
    [defaults setObject:[[self calendar] startOfDayForDate:[NSDate date]] forKey:DailyIntakeDateKey];
}
@end

@interface StickerBackgroundView : NSView
@end

@implementation StickerBackgroundView
- (BOOL)isFlipped {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    [[NSColor clearColor] setFill];
    NSRectFill(dirtyRect);

    NSRect cardRect = NSInsetRect(self.bounds, 12.0, 12.0);
    NSBezierPath *cardPath = [NSBezierPath bezierPathWithRoundedRect:cardRect xRadius:34.0 yRadius:34.0];

    [[NSGraphicsContext currentContext] saveGraphicsState];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 28.0;
    shadow.shadowOffset = NSMakeSize(0.0, 12.0);
    shadow.shadowColor = [NSColor colorWithCalibratedRed:0.25 green:0.22 blue:0.09 alpha:0.18];
    [shadow set];
    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.10] setFill];
    [cardPath fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];

    NSGradient *backgroundGradient = [[NSGradient alloc] initWithColors:@[
        [NSColor colorWithCalibratedRed:0.996 green:0.980 blue:0.845 alpha:0.99],
        [NSColor colorWithCalibratedRed:0.988 green:0.938 blue:0.725 alpha:0.99],
    ]];
    [backgroundGradient drawInBezierPath:cardPath angle:90.0];

    [[NSColor colorWithCalibratedRed:0.90 green:0.82 blue:0.54 alpha:0.55] setStroke];
    cardPath.lineWidth = 1.2;
    [cardPath stroke];

    NSBezierPath *auraPath = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(NSMidX(cardRect) - 120.0, 112.0, 240.0, 240.0)];
    [[NSColor colorWithCalibratedRed:0.44 green:0.77 blue:0.98 alpha:0.11] setFill];
    [auraPath fill];

    NSBezierPath *accentBlob = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(NSMinX(cardRect) + 22.0, 64.0, 82.0, 50.0)];
    [[NSColor colorWithCalibratedRed:1.0 green:0.87 blue:0.73 alpha:0.36] setFill];
    [accentBlob fill];

    CGFloat foldSize = 72.0;
    NSBezierPath *foldPath = [NSBezierPath bezierPath];
    [foldPath moveToPoint:NSMakePoint(NSMaxX(cardRect) - foldSize, NSMinY(cardRect))];
    [foldPath lineToPoint:NSMakePoint(NSMaxX(cardRect), NSMinY(cardRect))];
    [foldPath lineToPoint:NSMakePoint(NSMaxX(cardRect), NSMinY(cardRect) + foldSize)];
    [foldPath closePath];
    [[NSColor colorWithCalibratedRed:1.0 green:0.93 blue:0.78 alpha:0.85] setFill];
    [foldPath fill];

    NSBezierPath *foldLine = [NSBezierPath bezierPath];
    [foldLine moveToPoint:NSMakePoint(NSMaxX(cardRect) - foldSize, NSMinY(cardRect))];
    [foldLine lineToPoint:NSMakePoint(NSMaxX(cardRect), NSMinY(cardRect) + foldSize)];
    foldLine.lineWidth = 1.0;
    [[NSColor colorWithCalibratedRed:0.92 green:0.80 blue:0.60 alpha:0.70] setStroke];
    [foldLine stroke];
}
@end

@interface ProgressBarView : NSView
@property (nonatomic) double progress;
@end

@implementation ProgressBarView
- (BOOL)isFlipped {
    return YES;
}

- (void)setProgress:(double)progress {
    _progress = MAX(0.0, MIN(1.0, progress));
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    NSBezierPath *trackPath = [NSBezierPath bezierPathWithRoundedRect:self.bounds xRadius:NSHeight(self.bounds) / 2.0 yRadius:NSHeight(self.bounds) / 2.0];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.55] setFill];
    [trackPath fill];

    if (self.progress <= 0.0) {
        return;
    }

    CGFloat fillWidth = NSWidth(self.bounds) * self.progress;
    NSRect fillRect = NSMakeRect(NSMinX(self.bounds), NSMinY(self.bounds), fillWidth, NSHeight(self.bounds));

    [[NSGraphicsContext currentContext] saveGraphicsState];
    [trackPath addClip];
    NSGradient *fillGradient = [[NSGradient alloc] initWithColors:@[
        [NSColor colorWithCalibratedRed:0.33 green:0.80 blue:0.94 alpha:1.0],
        [NSColor colorWithCalibratedRed:0.14 green:0.58 blue:0.89 alpha:1.0],
    ]];
    [fillGradient drawInRect:fillRect angle:0.0];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
}
@end

@interface GlassView : NSView
@property (nonatomic) double level;
@property (nonatomic) BOOL goalReached;
@property (nonatomic, copy) dispatch_block_t onRefill;
@end

@implementation GlassView
- (BOOL)isFlipped {
    return YES;
}

- (void)setLevel:(double)level {
    _level = MAX(0.0, MIN(1.0, level));
    [self setNeedsDisplay:YES];
}

- (void)setGoalReached:(BOOL)goalReached {
    _goalReached = goalReached;
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(__unused NSEvent *)event {
    if (self.onRefill != nil) {
        self.onRefill();
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [[NSColor clearColor] setFill];
    NSRectFill(dirtyRect);

    NSRect bounds = self.bounds;
    NSRect glowRect = NSInsetRect(bounds, 14.0, 12.0);
    glowRect.size.height -= 32.0;
    NSBezierPath *glowPath = [NSBezierPath bezierPathWithOvalInRect:glowRect];
    NSGradient *glowGradient = self.goalReached
        ? [[NSGradient alloc] initWithColors:@[
            [NSColor colorWithCalibratedRed:0.50 green:0.88 blue:0.72 alpha:0.22],
            [NSColor colorWithCalibratedRed:0.50 green:0.88 blue:0.72 alpha:0.02],
        ]]
        : [[NSGradient alloc] initWithColors:@[
            [NSColor colorWithCalibratedRed:0.42 green:0.82 blue:0.99 alpha:0.22],
            [NSColor colorWithCalibratedRed:0.42 green:0.82 blue:0.99 alpha:0.02],
        ]];
    [glowGradient drawInBezierPath:glowPath relativeCenterPosition:NSMakePoint(0.0, -0.2)];

    NSRect groundShadowRect = NSMakeRect(NSMidX(bounds) - 78.0, NSMaxY(bounds) - 28.0, 156.0, 18.0);
    NSBezierPath *groundShadow = [NSBezierPath bezierPathWithOvalInRect:groundShadowRect];
    [[NSColor colorWithCalibratedRed:0.16 green:0.27 blue:0.39 alpha:0.12] setFill];
    [groundShadow fill];

    CGFloat midX = NSMidX(bounds);
    CGFloat rimY = 18.0;
    CGFloat baseY = NSMaxY(bounds) - 26.0;
    CGFloat topWidth = MIN(NSWidth(bounds) - 54.0, 142.0);
    CGFloat bottomWidth = topWidth * 0.62;
    CGFloat bowlHeight = baseY - rimY;

    NSPoint topLeft = NSMakePoint(midX - topWidth / 2.0, rimY + 10.0);
    NSPoint topRight = NSMakePoint(midX + topWidth / 2.0, rimY + 10.0);
    NSPoint bottomRight = NSMakePoint(midX + bottomWidth / 2.0, baseY);
    NSPoint bottomLeft = NSMakePoint(midX - bottomWidth / 2.0, baseY);

    NSBezierPath *glassPath = [NSBezierPath bezierPath];
    [glassPath moveToPoint:topLeft];
    [glassPath lineToPoint:topRight];
    [glassPath curveToPoint:bottomRight
              controlPoint1:NSMakePoint(topRight.x - 6.0, topLeft.y + bowlHeight * 0.28)
              controlPoint2:NSMakePoint(bottomRight.x + 20.0, bottomRight.y - bowlHeight * 0.28)];
    [glassPath lineToPoint:bottomLeft];
    [glassPath curveToPoint:topLeft
              controlPoint1:NSMakePoint(bottomLeft.x - 20.0, bottomLeft.y - bowlHeight * 0.28)
              controlPoint2:NSMakePoint(topLeft.x + 6.0, topLeft.y + bowlHeight * 0.28)];
    [glassPath closePath];

    [[NSGraphicsContext currentContext] saveGraphicsState];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowBlurRadius = 24.0;
    shadow.shadowOffset = NSMakeSize(0.0, 12.0);
    shadow.shadowColor = [NSColor colorWithCalibratedRed:0.16 green:0.24 blue:0.33 alpha:0.12];
    [shadow set];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.72] setFill];
    [glassPath fill];
    [[NSGraphicsContext currentContext] restoreGraphicsState];

    NSGradient *glassGradient = [[NSGradient alloc] initWithColors:@[
        [NSColor colorWithCalibratedWhite:1.0 alpha:0.62],
        [NSColor colorWithCalibratedRed:0.92 green:0.98 blue:1.0 alpha:0.18],
    ]];
    [glassGradient drawInBezierPath:glassPath angle:90.0];

    NSBezierPath *glassStroke = [glassPath copy];
    glassStroke.lineWidth = 2.4;
    [[NSColor colorWithCalibratedRed:0.87 green:0.94 blue:0.98 alpha:0.95] setStroke];
    [glassStroke stroke];

    NSRect rimRect = NSMakeRect(midX - topWidth / 2.0 - 6.0, rimY, topWidth + 12.0, 18.0);
    NSBezierPath *rimPath = [NSBezierPath bezierPathWithOvalInRect:rimRect];
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.78] setFill];
    [rimPath fill];
    rimPath.lineWidth = 1.5;
    [[NSColor colorWithCalibratedRed:0.84 green:0.92 blue:0.98 alpha:0.95] setStroke];
    [rimPath stroke];

    CGFloat innerTopY = topLeft.y + 6.0;
    CGFloat innerBottomY = bottomRight.y - 4.0;
    CGFloat usableHeight = MAX(0.0, innerBottomY - innerTopY);
    CGFloat fillHeight = usableHeight * self.level;
    CGFloat waterTopY = innerBottomY - fillHeight;

    if (fillHeight > 0.0) {
        [[NSGraphicsContext currentContext] saveGraphicsState];
        [glassPath addClip];

        NSRect waterRect = NSMakeRect(midX - topWidth / 2.0 - 10.0, waterTopY - 12.0, topWidth + 20.0, fillHeight + 24.0);
        NSGradient *waterGradient = self.goalReached
            ? [[NSGradient alloc] initWithColors:@[
                [NSColor colorWithCalibratedRed:0.42 green:0.86 blue:0.75 alpha:0.96],
                [NSColor colorWithCalibratedRed:0.22 green:0.72 blue:0.68 alpha:1.0],
            ]]
            : [[NSGradient alloc] initWithColors:@[
                [NSColor colorWithCalibratedRed:0.39 green:0.84 blue:0.99 alpha:0.96],
                [NSColor colorWithCalibratedRed:0.17 green:0.60 blue:0.93 alpha:1.0],
            ]];
        [waterGradient drawInRect:waterRect angle:90.0];

        CGFloat waveWidth = topWidth / 1.75;
        CGFloat waveHeight = 9.0 + (1.0 - self.level) * 8.0;
        NSBezierPath *wavePath = [NSBezierPath bezierPath];
        [wavePath moveToPoint:NSMakePoint(topLeft.x - waveWidth, waterTopY)];

        for (CGFloat x = topLeft.x - waveWidth; x <= topRight.x + waveWidth; x += waveWidth) {
            [wavePath curveToPoint:NSMakePoint(x + waveWidth, waterTopY)
                     controlPoint1:NSMakePoint(x + waveWidth * 0.30, waterTopY - waveHeight)
                     controlPoint2:NSMakePoint(x + waveWidth * 0.68, waterTopY + waveHeight * 0.38)];
        }

        [wavePath lineToPoint:NSMakePoint(topRight.x + 20.0, innerBottomY + 20.0)];
        [wavePath lineToPoint:NSMakePoint(topLeft.x - 20.0, innerBottomY + 20.0)];
        [wavePath closePath];
        [[NSColor colorWithCalibratedWhite:1.0 alpha:0.22] setFill];
        [wavePath fill];

        NSArray<NSValue *> *bubbles = @[
            [NSValue valueWithPoint:NSMakePoint(midX - 32.0, innerBottomY - fillHeight * 0.28)],
            [NSValue valueWithPoint:NSMakePoint(midX + 18.0, innerBottomY - fillHeight * 0.50)],
            [NSValue valueWithPoint:NSMakePoint(midX - 6.0, innerBottomY - fillHeight * 0.74)],
        ];
        NSArray<NSNumber *> *sizes = @[@10.0, @7.0, @8.0];

        for (NSUInteger index = 0; index < bubbles.count; index += 1) {
            NSPoint bubbleCenter = bubbles[index].pointValue;
            CGFloat bubbleSize = sizes[index].doubleValue;

            if (bubbleCenter.y < waterTopY + 10.0) {
                continue;
            }

            NSRect bubbleRect = NSMakeRect(bubbleCenter.x - bubbleSize / 2.0, bubbleCenter.y - bubbleSize / 2.0, bubbleSize, bubbleSize);
            NSBezierPath *bubblePath = [NSBezierPath bezierPathWithOvalInRect:bubbleRect];
            [[NSColor colorWithCalibratedWhite:1.0 alpha:0.22] setFill];
            [bubblePath fill];
        }

        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }

    NSBezierPath *leftHighlight = [NSBezierPath bezierPath];
    [leftHighlight moveToPoint:NSMakePoint(topLeft.x + 18.0, topLeft.y + 12.0)];
    [leftHighlight curveToPoint:NSMakePoint(bottomLeft.x + 18.0, bottomLeft.y - 24.0)
                  controlPoint1:NSMakePoint(topLeft.x + 4.0, topLeft.y + bowlHeight * 0.30)
                  controlPoint2:NSMakePoint(bottomLeft.x + 2.0, bottomLeft.y - bowlHeight * 0.34)];
    leftHighlight.lineWidth = 5.0;
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.38] setStroke];
    [leftHighlight stroke];

    NSBezierPath *rightHighlight = [NSBezierPath bezierPath];
    [rightHighlight moveToPoint:NSMakePoint(topRight.x - 14.0, topRight.y + 18.0)];
    [rightHighlight curveToPoint:NSMakePoint(bottomRight.x - 16.0, bottomRight.y - 30.0)
                   controlPoint1:NSMakePoint(topRight.x - 4.0, topRight.y + bowlHeight * 0.34)
                   controlPoint2:NSMakePoint(bottomRight.x - 4.0, bottomRight.y - bowlHeight * 0.28)];
    rightHighlight.lineWidth = 2.0;
    [[NSColor colorWithCalibratedWhite:1.0 alpha:0.26] setStroke];
    [rightHighlight stroke];
}
@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, strong) NSPanel *panel;
@property (nonatomic, strong) GlassView *glassView;
@property (nonatomic, strong) NSTextField *levelLabel;
@property (nonatomic, strong) NSTextField *messageLabel;
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) NSTextField *intakeLabel;
@property (nonatomic, strong) NSTextField *progressDetailLabel;
@property (nonatomic, strong) NSTextField *intervalValueLabel;
@property (nonatomic, strong) NSTextField *goalValueLabel;
@property (nonatomic, strong) ProgressBarView *progressBar;
@property (nonatomic, strong) NSStepper *intervalStepper;
@property (nonatomic, strong) NSStepper *goalStepper;
@property (nonatomic, strong) NSButton *drinkButton;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(__unused NSNotification *)notification {
    [self buildPanel];
    [self refresh:nil];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(refresh:)
                                                userInfo:nil
                                                 repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];

    [self.panel makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(__unused NSApplication *)sender {
    return YES;
}

- (NSTextField *)singleLineLabelWithString:(NSString *)text font:(NSFont *)font color:(NSColor *)color alignment:(NSTextAlignment)alignment {
    NSTextField *label = [NSTextField labelWithString:text];
    label.font = font;
    label.textColor = color;
    label.alignment = alignment;
    label.backgroundColor = [NSColor clearColor];
    return label;
}

- (NSTextField *)wrappingLabelWithString:(NSString *)text font:(NSFont *)font color:(NSColor *)color alignment:(NSTextAlignment)alignment {
    NSTextField *label = [NSTextField wrappingLabelWithString:text];
    label.font = font;
    label.textColor = color;
    label.alignment = alignment;
    label.backgroundColor = [NSColor clearColor];
    return label;
}

- (NSView *)cardViewWithFrame:(NSRect)frame {
    NSView *cardView = [[NSView alloc] initWithFrame:frame];
    cardView.wantsLayer = YES;
    cardView.layer.backgroundColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.42].CGColor;
    cardView.layer.borderColor = [NSColor colorWithCalibratedRed:0.90 green:0.84 blue:0.62 alpha:0.55].CGColor;
    cardView.layer.borderWidth = 1.0;
    cardView.layer.cornerRadius = 24.0;
    return cardView;
}

- (void)buildPanel {
    NSRect frame = NSMakeRect(0.0, 0.0, 400.0, 720.0);
    self.panel = [[NSPanel alloc] initWithContentRect:frame
                                            styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskFullSizeContentView)
                                              backing:NSBackingStoreBuffered
                                                defer:NO];
    self.panel.titleVisibility = NSWindowTitleHidden;
    self.panel.titlebarAppearsTransparent = YES;
    self.panel.floatingPanel = YES;
    self.panel.level = NSFloatingWindowLevel;
    self.panel.movableByWindowBackground = YES;
    self.panel.collectionBehavior = NSWindowCollectionBehaviorCanJoinAllSpaces | NSWindowCollectionBehaviorFullScreenAuxiliary;
    self.panel.backgroundColor = [NSColor clearColor];
    self.panel.opaque = NO;
    self.panel.hasShadow = NO;
    [self.panel center];

    [[self.panel standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    [[self.panel standardWindowButton:NSWindowZoomButton] setHidden:YES];

    StickerBackgroundView *contentView = [[StickerBackgroundView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 400.0, 720.0)];
    contentView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.panel.contentView = contentView;

    NSTextField *titleLabel = [self singleLineLabelWithString:@"Hydration Note"
                                                         font:[NSFont systemFontOfSize:31.0 weight:NSFontWeightBold]
                                                        color:[NSColor colorWithCalibratedRed:0.34 green:0.24 blue:0.07 alpha:1.0]
                                                    alignment:NSTextAlignmentCenter];
    titleLabel.frame = NSMakeRect(34.0, 24.0, 332.0, 34.0);

    NSTextField *subtitleLabel = [self wrappingLabelWithString:@"A prettier little desk reminder. Tap the glass after each 300 mL drink and adjust the rhythm to fit your day."
                                                           font:[NSFont systemFontOfSize:14.0 weight:NSFontWeightMedium]
                                                          color:[NSColor colorWithCalibratedRed:0.48 green:0.38 blue:0.17 alpha:1.0]
                                                      alignment:NSTextAlignmentCenter];
    subtitleLabel.frame = NSMakeRect(42.0, 62.0, 316.0, 42.0);

    self.glassView = [[GlassView alloc] initWithFrame:NSMakeRect(86.0, 112.0, 228.0, 238.0)];
    __weak typeof(self) weakSelf = self;
    self.glassView.onRefill = ^{
        [weakSelf logGlass];
    };

    self.levelLabel = [self singleLineLabelWithString:@""
                                                 font:[NSFont systemFontOfSize:30.0 weight:NSFontWeightSemibold]
                                                color:[NSColor colorWithCalibratedRed:0.08 green:0.34 blue:0.48 alpha:1.0]
                                            alignment:NSTextAlignmentCenter];
    self.levelLabel.frame = NSMakeRect(36.0, 360.0, 328.0, 30.0);

    self.messageLabel = [self singleLineLabelWithString:@""
                                                   font:[NSFont systemFontOfSize:15.0 weight:NSFontWeightMedium]
                                                  color:[NSColor colorWithCalibratedRed:0.47 green:0.37 blue:0.15 alpha:1.0]
                                              alignment:NSTextAlignmentCenter];
    self.messageLabel.frame = NSMakeRect(42.0, 394.0, 316.0, 22.0);

    self.statusLabel = [self singleLineLabelWithString:@""
                                                  font:[NSFont systemFontOfSize:12.5 weight:NSFontWeightRegular]
                                                 color:[NSColor colorWithCalibratedRed:0.52 green:0.42 blue:0.19 alpha:1.0]
                                             alignment:NSTextAlignmentCenter];
    self.statusLabel.frame = NSMakeRect(46.0, 418.0, 308.0, 18.0);

    self.drinkButton = [[NSButton alloc] initWithFrame:NSMakeRect(112.0, 446.0, 176.0, 42.0)];
    self.drinkButton.bezelStyle = NSBezelStyleRounded;
    self.drinkButton.bezelColor = [NSColor colorWithCalibratedRed:0.21 green:0.61 blue:0.92 alpha:1.0];
    self.drinkButton.contentTintColor = [NSColor whiteColor];
    self.drinkButton.font = [NSFont systemFontOfSize:15.0 weight:NSFontWeightSemibold];
    self.drinkButton.target = self;
    self.drinkButton.action = @selector(refillButtonPressed:);

    NSView *progressCard = [self cardViewWithFrame:NSMakeRect(28.0, 504.0, 344.0, 104.0)];
    NSTextField *progressTitleLabel = [self singleLineLabelWithString:@"Today"
                                                                 font:[NSFont systemFontOfSize:13.0 weight:NSFontWeightBold]
                                                                color:[NSColor colorWithCalibratedRed:0.41 green:0.33 blue:0.12 alpha:0.95]
                                                            alignment:NSTextAlignmentLeft];
    progressTitleLabel.frame = NSMakeRect(18.0, 14.0, 80.0, 16.0);

    self.intakeLabel = [self singleLineLabelWithString:@""
                                                  font:[NSFont systemFontOfSize:29.0 weight:NSFontWeightBold]
                                                 color:[NSColor colorWithCalibratedRed:0.10 green:0.30 blue:0.42 alpha:1.0]
                                             alignment:NSTextAlignmentLeft];
    self.intakeLabel.frame = NSMakeRect(18.0, 30.0, 306.0, 32.0);

    self.progressBar = [[ProgressBarView alloc] initWithFrame:NSMakeRect(18.0, 68.0, 308.0, 12.0)];

    self.progressDetailLabel = [self singleLineLabelWithString:@""
                                                          font:[NSFont systemFontOfSize:12.5 weight:NSFontWeightMedium]
                                                         color:[NSColor colorWithCalibratedRed:0.43 green:0.38 blue:0.23 alpha:1.0]
                                                     alignment:NSTextAlignmentLeft];
    self.progressDetailLabel.frame = NSMakeRect(18.0, 84.0, 308.0, 16.0);

    [progressCard addSubview:progressTitleLabel];
    [progressCard addSubview:self.intakeLabel];
    [progressCard addSubview:self.progressBar];
    [progressCard addSubview:self.progressDetailLabel];

    NSView *settingsCard = [self cardViewWithFrame:NSMakeRect(28.0, 622.0, 344.0, 82.0)];
    NSTextField *settingsNoteLabel = [self singleLineLabelWithString:@"Each tap logs 300 mL."
                                                                font:[NSFont systemFontOfSize:12.5 weight:NSFontWeightMedium]
                                                               color:[NSColor colorWithCalibratedRed:0.48 green:0.38 blue:0.16 alpha:1.0]
                                                           alignment:NSTextAlignmentLeft];
    settingsNoteLabel.frame = NSMakeRect(18.0, 10.0, 180.0, 16.0);

    NSTextField *intervalTitleLabel = [self singleLineLabelWithString:@"Drink every"
                                                                 font:[NSFont systemFontOfSize:13.5 weight:NSFontWeightSemibold]
                                                                color:[NSColor colorWithCalibratedRed:0.34 green:0.27 blue:0.09 alpha:1.0]
                                                            alignment:NSTextAlignmentLeft];
    intervalTitleLabel.frame = NSMakeRect(18.0, 32.0, 108.0, 20.0);

    self.intervalValueLabel = [self singleLineLabelWithString:@""
                                                         font:[NSFont monospacedDigitSystemFontOfSize:13.5 weight:NSFontWeightSemibold]
                                                        color:[NSColor colorWithCalibratedRed:0.09 green:0.35 blue:0.50 alpha:1.0]
                                                    alignment:NSTextAlignmentRight];
    self.intervalValueLabel.frame = NSMakeRect(184.0, 32.0, 96.0, 20.0);

    self.intervalStepper = [[NSStepper alloc] initWithFrame:NSMakeRect(292.0, 28.0, 20.0, 24.0)];
    self.intervalStepper.minValue = MinimumReminderIntervalMinutes;
    self.intervalStepper.maxValue = MaximumReminderIntervalMinutes;
    self.intervalStepper.increment = ReminderIntervalStepMinutes;
    self.intervalStepper.valueWraps = NO;
    self.intervalStepper.target = self;
    self.intervalStepper.action = @selector(intervalStepperChanged:);

    NSTextField *goalTitleLabel = [self singleLineLabelWithString:@"Daily goal"
                                                             font:[NSFont systemFontOfSize:13.5 weight:NSFontWeightSemibold]
                                                            color:[NSColor colorWithCalibratedRed:0.34 green:0.27 blue:0.09 alpha:1.0]
                                                        alignment:NSTextAlignmentLeft];
    goalTitleLabel.frame = NSMakeRect(18.0, 54.0, 108.0, 20.0);

    self.goalValueLabel = [self singleLineLabelWithString:@""
                                                     font:[NSFont monospacedDigitSystemFontOfSize:13.5 weight:NSFontWeightSemibold]
                                                    color:[NSColor colorWithCalibratedRed:0.09 green:0.35 blue:0.50 alpha:1.0]
                                                alignment:NSTextAlignmentRight];
    self.goalValueLabel.frame = NSMakeRect(160.0, 54.0, 120.0, 20.0);

    self.goalStepper = [[NSStepper alloc] initWithFrame:NSMakeRect(292.0, 50.0, 20.0, 24.0)];
    self.goalStepper.minValue = MinimumDailyGoalML;
    self.goalStepper.maxValue = MaximumDailyGoalML;
    self.goalStepper.increment = DailyGoalStepML;
    self.goalStepper.valueWraps = NO;
    self.goalStepper.target = self;
    self.goalStepper.action = @selector(goalStepperChanged:);

    [settingsCard addSubview:settingsNoteLabel];
    [settingsCard addSubview:intervalTitleLabel];
    [settingsCard addSubview:self.intervalValueLabel];
    [settingsCard addSubview:self.intervalStepper];
    [settingsCard addSubview:goalTitleLabel];
    [settingsCard addSubview:self.goalValueLabel];
    [settingsCard addSubview:self.goalStepper];

    [contentView addSubview:titleLabel];
    [contentView addSubview:subtitleLabel];
    [contentView addSubview:self.glassView];
    [contentView addSubview:self.levelLabel];
    [contentView addSubview:self.messageLabel];
    [contentView addSubview:self.statusLabel];
    [contentView addSubview:self.drinkButton];
    [contentView addSubview:progressCard];
    [contentView addSubview:settingsCard];
}

- (NSTimeInterval)glassDurationSeconds {
    return [HydrationStore sharedStore].reminderIntervalMinutes * 60.0;
}

- (NSTimeInterval)reminderCooldownSeconds {
    NSTimeInterval dynamicCooldown = [self glassDurationSeconds] * 0.45;
    return MAX(15.0 * 60.0, MIN(45.0 * 60.0, dynamicCooldown));
}

- (double)currentLevelAtDate:(NSDate *)date {
    NSTimeInterval elapsed = [date timeIntervalSinceDate:[[HydrationStore sharedStore] refillDate]];
    NSTimeInterval duration = MAX(1.0, [self glassDurationSeconds]);
    return MAX(0.0, MIN(1.0, 1.0 - (elapsed / duration)));
}

- (void)refillButtonPressed:(__unused id)sender {
    [self logGlass];
}

- (void)logGlass {
    HydrationStore *store = [HydrationStore sharedStore];
    [store addGlassToToday];
    [store setRefillDate:[NSDate date]];
    [store setLastReminderDate:nil];
    [self refresh:nil];
}

- (void)intervalStepperChanged:(NSStepper *)sender {
    HydrationStore *store = [HydrationStore sharedStore];
    NSInteger snappedValue = (NSInteger)sender.integerValue;
    [store setReminderIntervalMinutes:snappedValue];
    [store setRefillDate:[NSDate date]];
    [store setLastReminderDate:nil];
    [self refresh:nil];
}

- (void)goalStepperChanged:(NSStepper *)sender {
    [[HydrationStore sharedStore] setDailyGoalML:(NSInteger)sender.integerValue];
    [self refresh:nil];
}

- (void)refreshSettingsFromStore {
    HydrationStore *store = [HydrationStore sharedStore];
    self.intervalStepper.integerValue = store.reminderIntervalMinutes;
    self.goalStepper.integerValue = store.dailyGoalML;
    self.intervalValueLabel.stringValue = [NSString stringWithFormat:@"%ld min", (long)store.reminderIntervalMinutes];
    self.goalValueLabel.stringValue = FormattedML(store.dailyGoalML);
    self.drinkButton.title = [NSString stringWithFormat:@"Log %ld mL", (long)store.glassSizeML];
}

- (void)refresh:(__unused id)sender {
    HydrationStore *store = [HydrationStore sharedStore];
    NSDate *now = [NSDate date];
    NSInteger intakeML = store.todaysIntakeML;
    NSInteger goalML = store.dailyGoalML;
    NSInteger glassesCount = intakeML / store.glassSizeML;
    NSInteger remainingML = MAX(goalML - intakeML, 0);
    double goalProgress = goalML > 0 ? MIN(1.0, (double)intakeML / (double)goalML) : 0.0;
    double level = [self currentLevelAtDate:now];

    [self refreshSettingsFromStore];

    self.glassView.level = level;
    self.glassView.goalReached = intakeML >= goalML;
    self.progressBar.progress = goalProgress;
    self.levelLabel.stringValue = [NSString stringWithFormat:@"%d%% until next drink", (int)lrint(level * 100.0)];
    self.intakeLabel.stringValue = [NSString stringWithFormat:@"%@ / %@ today", FormattedML(intakeML), FormattedML(goalML)];

    if (intakeML >= goalML) {
        self.intakeLabel.textColor = [NSColor colorWithCalibratedRed:0.16 green:0.56 blue:0.42 alpha:1.0];
        self.progressDetailLabel.stringValue = [NSString stringWithFormat:@"Goal reached with %ld glasses logged.", (long)glassesCount];
        self.messageLabel.stringValue = @"Daily goal reached. Nice work.";
        self.messageLabel.textColor = [NSColor colorWithCalibratedRed:0.18 green:0.54 blue:0.40 alpha:1.0];
    } else {
        self.intakeLabel.textColor = [NSColor colorWithCalibratedRed:0.10 green:0.30 blue:0.42 alpha:1.0];
        self.progressDetailLabel.stringValue = [NSString stringWithFormat:@"%@ left today • %ld glasses logged.", FormattedML(remainingML), (long)glassesCount];

        if (level > 0.66) {
            self.messageLabel.stringValue = @"Glass full and ready.";
            self.messageLabel.textColor = [NSColor colorWithCalibratedRed:0.43 green:0.37 blue:0.16 alpha:1.0];
        } else if (level > 0.33) {
            self.messageLabel.stringValue = @"A hydration check-in is coming up.";
            self.messageLabel.textColor = [NSColor colorWithCalibratedRed:0.49 green:0.39 blue:0.14 alpha:1.0];
        } else if (level > 0.0) {
            self.messageLabel.stringValue = @"Almost time for your next 300 mL.";
            self.messageLabel.textColor = [NSColor colorWithCalibratedRed:0.74 green:0.46 blue:0.09 alpha:1.0];
        } else {
            self.messageLabel.stringValue = @"Time to drink and refill the glass.";
            self.messageLabel.textColor = [NSColor colorWithCalibratedRed:0.78 green:0.24 blue:0.18 alpha:1.0];
        }
    }

    NSDate *emptyDate = [store.refillDate dateByAddingTimeInterval:[self glassDurationSeconds]];
    NSRelativeDateTimeFormatter *formatter = [[NSRelativeDateTimeFormatter alloc] init];
    formatter.unitsStyle = NSRelativeDateTimeFormatterUnitsStyleFull;

    if (level > 0.0) {
        self.statusLabel.stringValue = [NSString stringWithFormat:@"Next drink %@", [formatter localizedStringForDate:emptyDate relativeToDate:now]];
    } else {
        self.statusLabel.stringValue = @"Tap the glass after you finish this one.";
    }

    [self maybeNotifyForLevel:level now:now];
}

- (void)maybeNotifyForLevel:(double)level now:(NSDate *)now {
    if (level > LowWaterThreshold) {
        return;
    }

    HydrationStore *store = [HydrationStore sharedStore];
    NSDate *lastReminder = store.lastReminderDate;

    if (lastReminder != nil && [now timeIntervalSinceDate:lastReminder] < [self reminderCooldownSeconds]) {
        return;
    }

    [store setLastReminderDate:now];
    [NSApp requestUserAttention:NSInformationalRequest];
    [self.panel orderFrontRegardless];
    [NSApp activateIgnoringOtherApps:YES];
}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        (void)argc;
        (void)argv;

        NSApplication *app = [NSApplication sharedApplication];
        static AppDelegate *delegate = nil;
        delegate = [[AppDelegate alloc] init];
        NSApp.delegate = delegate;
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        [app run];
    }

    return EXIT_SUCCESS;
}
