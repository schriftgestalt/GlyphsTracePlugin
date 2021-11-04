//
//  TraceBackground.m
//  TraceBackground
//
//  Created by Georg Seifert on 13.1.08.
//  Copyright 2008 schriftgestaltung.de. All rights reserved.
//

#import "TraceImage.h"
#import "NSImage+WritePortableAnymap.h"
#import <GlyphsCore/GSNode.h>
#import <GlyphsCore/GSGlyph.h>
#import <GlyphsCore/GSLayer.h>
#import <GlyphsCore/GSPath.h>
#import <GlyphsCore/GSFont.h>
#import <GlyphsCore/GSBackgroundImage.h>
#import <GlyphsCore/GSNode.h>
#import <GlyphsCore/GSGeometrieHelper.h>
#import <GlyphsCore/NSStringHelpers.h>
#import <GlyphsCore/NSTask+CallCommand.h>
#import <GlyphsKit/NSBundle+NibLoading.h>

@implementation TraceImage

@synthesize tabview = _tabView;

+ (void)initialize {
	NSUserDefaults *Defaults = [NSUserDefaults standardUserDefaults];
	[Defaults registerDefaults:@{@"com.schriftgestaltung.Trace.Threshold": @128.0f,
								 @"com.schriftgestaltung.Trace.poMinElementSize": @6,
								 @"com.schriftgestaltung.Trace.Roundness": @0.75f,
								 @"com.schriftgestaltung.Trace.OptimizeCurves": @YES,
								 @"com.schriftgestaltung.Trace.OptimizationTolerance": @0.2f,
								 @"com.schriftgestaltung.Trace.CornerThreshold": @100,
								 @"com.schriftgestaltung.Trace.CornerSurround": @4,
								 @"com.schriftgestaltung.Trace.AlwaysCorner": @60,
								 @"com.schriftgestaltung.Trace.autoMinElementSize": @2,
								 }];
}
- (instancetype)init {
	self = [super init];
	[NSBundle loadNibNamed:@"TraceImageDialog" owner:self error:nil];
	return self;
}

- (void) awakeFromNib {
	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
	[defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.Threshold" options:0 context:NULL];
	[defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.poMinElementSize" options:0 context:NULL];
	[defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.Roundness" options:0 context:NULL];
	[defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.OptimizeCurves" options:0 context:NULL];
	[defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.OptimizationTolerance" options:0 context:NULL];
	[defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.Stroke" options:0 context:NULL];
	[defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.CornerThreshold" options:0 context:NULL];
	[defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.CornerSurround" options:0 context:NULL];
	[defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.AlwaysCorner" options:0 context:NULL];
	[defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.autoMinElementSize" options:0 context:NULL];
}

- (void)dealloc {
	NSUserDefaultsController *defaults = [NSUserDefaultsController sharedUserDefaultsController];
	[defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.Threshold"];
	[defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.poMinElementSize"];
	[defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.Roundness"];
	[defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.OptimizeCurves"];
	[defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.OptimizationTolerance"];
	[defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.Stroke"];
	[defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.CornerThreshold"];
	[defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.CornerSurround"];
	[defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.AlwaysCorner"];
	[defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.autoMinElementSize"];
}

- (NSUInteger)interfaceVersion {
	return 1;
}

- (NSString *)title {
	return NSLocalizedStringFromTableInBundle(@"Trace Image", nil, [NSBundle bundleForClass:[self class]], @"Name of the Trace Image Filter");
}

- (NSString *)keyEquivalent {
	return nil;
}

- (NSString *)actionName {
	return NSLocalizedStringFromTableInBundle(@"Trace", nil, [NSBundle bundleForClass:[self class]],
											  @"Name of the Trace Image Filter Action Button");
}

- (BOOL)runFilterWithLayer:(GSLayer *)Layer error:(out NSError **)error {
	return [super runFilterWithLayer:Layer error:error];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	[self process:nil];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	[self process:nil];
}

- (BOOL)traceImage:(GSBackgroundImage *)image {
	if (!image || ![image hasImageToDraw]) {
		return YES;
	}
	NSBitmapImageRep *bitmap = [image.image bitmapImageRep];
	NSSize imageSize = image.image.size;
	CGFloat scale = bitmap.pixelsWide / imageSize.width;
	NSString *tempSaveString = [[_tempDir stringByAppendingPathComponent:_fileName] stringByAppendingString:@".pnm"];
	if (![bitmap writePortableAnymap:tempSaveString]) {
		return NO;
	}
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform setTransformStruct:image.transformStruct];
	[transform scaleBy:1.0 / scale];

	NSString *result = nil;
	NSString *identifier = [[_tabView selectedTabViewItem] identifier];
	if ([identifier isEqualToString:@"potrace"]) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		CGFloat threshold = [defaults floatForKey:@"com.schriftgestaltung.Trace.Threshold"];
		NSUInteger minElementSize = labs([defaults integerForKey:@"com.schriftgestaltung.Trace.poMinElementSize"]);
		CGFloat roundness = [defaults floatForKey:@"com.schriftgestaltung.Trace.Roundness"];
		BOOL optimize = [defaults boolForKey:@"com.schriftgestaltung.Trace.OptimizeCurves"];
		CGFloat optimizationTolerance = [defaults floatForKey:@"com.schriftgestaltung.Trace.OptimizationTolerance"];
		result = [self poTraceImage:tempSaveString withThreshold:threshold minElementSize:minElementSize roundness:roundness optimize:optimize optimizationTolerance:optimizationTolerance];
	}
	else if ([identifier isEqualToString:@"autotrace"]) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		BOOL stroke = [defaults boolForKey:@"com.schriftgestaltung.Trace.Stroke"];
		NSUInteger cornerThreshold = [defaults integerForKey:@"com.schriftgestaltung.Trace.CornerThreshold"];
		NSUInteger cornerSurround = [defaults integerForKey:@"com.schriftgestaltung.Trace.CornerSurround"];
		NSUInteger alwaysCorner = [defaults integerForKey:@"com.schriftgestaltung.Trace.AlwaysCorner"];
		NSUInteger minElementSize = [defaults integerForKey:@"com.schriftgestaltung.Trace.autoMinElementSize"];
		result = [self autoTraceImage:tempSaveString stroke:stroke cornerThreshold:cornerThreshold cornerSurround:cornerSurround alwaysCorner:alwaysCorner minElementSize:minElementSize];
		[transform translateXBy:0 yBy:imageSize.height];
		[transform scaleXBy:1 yBy:-1]; // TODO: somehow the result is flipped
	}
	[[NSFileManager defaultManager] removeItemAtPath:tempSaveString error:nil];
	[_nodeCountField setStringValue:@"No Result"];
	if ([result length] > 10) {
		@try {
			NSArray *pathArray = [result propertyList];
			NSUInteger nodeCount = 0;
			NSUInteger pathCount = 0;
			if ([pathArray count] > 0) {
				NSMutableArray *paths = [NSMutableArray array];
				for (NSDictionary *pathDict in pathArray) {
					GSPath *path = [[GSPath alloc] initWithDict:pathDict format:GSFormatVersion1];
					[path cleanUp];
					if (path && [path.nodes count] > 1) {
						pathCount++;
						for (GSNode *node in path.nodes) {
							nodeCount++;
							[node transform:transform];
						}
						[paths addObject:path];
					}
				}
				if ([paths count] > 0) {
					[image.layer setShapes:paths];
				}
			}
			[_nodeCountField setAlignment:NSCenterTextAlignment];
			[_nodeCountField setStringValue:[NSString stringWithFormat:@"%ld path with %ld nodes", pathCount, nodeCount]];

		}
		@catch (NSException *exception) {
			UKLog(@"Something went wrong: %@", result);
			[_nodeCountField setAlignment:NSLeftTextAlignment];
			[_nodeCountField setStringValue:[NSString stringWithFormat:@"Something went wrong: %@", result]];
		}
	}
}

- (void)process:(id)sender {
	for (int k = 0; k < [_shadowLayers count]; k++) {
		GSLayer *layer = _layers[k];
		if (![self traceImage:layer.backgroundImage]) {
			return;
		}
	}
}

- (NSString *)poTraceImage:(NSString *)imagePath withThreshold:(CGFloat)threshold minElementSize:(NSUInteger)minElementSize roundness:(CGFloat)roundness optimize:(BOOL)optimize optimizationTolerance:(CGFloat)optimizationTolerance {
	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:
								 @"-bGlyphs", [NSString stringWithFormat:@"-k %.2f", threshold / 0xff],
								 [NSString stringWithFormat:@"-t %d", (int)minElementSize],
								 [NSString stringWithFormat:@"-a %.3f", (roundness * ((4 / 3) + 0.01)) - 0.01],
								 imagePath, nil];
	if (!optimize) {
		[arguments insertObject:@"-n" atIndex:1];
		[arguments insertObject:[NSString stringWithFormat:@"-O %.3f", optimizationTolerance] atIndex:2];
	}
	UKLog(@"__Arguments: %@", arguments);
	return [self traceFile:arguments withCommand:@"potrace"];
}

- (NSString *)autoTraceImage:(NSString *)imagePath stroke:(BOOL)stroke cornerThreshold:(NSUInteger)cornerThreshold cornerSurround:(NSUInteger)cornerSurround alwaysCorner:(NSUInteger)alwaysCorner minElementSize:(NSUInteger)minElementSize {
	NSMutableArray *arguments = [NSMutableArray arrayWithObjects:
								 @"-color-count", @"2",
								 @"-background-color", @"FFFFFF",
								 @"-corner-threshold", [NSString hexStringFromInt:(int)cornerThreshold],
								 @"-corner-always-threshold", [NSString hexStringFromInt:(int)alwaysCorner],
								 @"-corner-surround", [NSString hexStringFromInt:(int)cornerSurround],
								 @"-despeckle-level", [NSString hexStringFromInt:(int)minElementSize],
								 @"-input-format", @"PNM",
								 imagePath, nil];
	if (stroke) {
		[arguments insertObject:@"-centerline" atIndex:0];
	}
	UKLog(@"__arguments: %@", [arguments componentsJoinedByString:@"; "]);
	return [self traceFile:arguments withCommand:@"autotrace"];
}

- (NSError *)setup {
	_tempDir = NSTemporaryDirectory();
	_fileName = [[NSProcessInfo processInfo] globallyUniqueString];
	
	[super setup];
	[self process:nil];
	return nil;
}

#pragma mark -

- (NSString *)traceFile:(NSArray *)arguments withCommand:(NSString *)Command {
	NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
	NSString *helperApplication = [thisBundle pathForResource:Command ofType:nil];
	NSData *resultData = callCommandArguments(helperApplication, arguments);
	return [[NSString alloc] initWithData:resultData encoding:NSASCIIStringEncoding];
}

@end
