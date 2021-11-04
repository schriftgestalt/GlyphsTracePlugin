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
	[NSBundle loadNibNamed:@"TraceImageDialog" owner:self];
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
					GSPath *path = [[GSPath alloc] initWithPathDict:pathDict];
					[path cleanUp];
					if (path && [path.nodes count] > 1) {
						pathCount++;
						for (GSNode *node in path.nodes) {
							nodeCount++;
							node.position = [transform transformPoint:node.position];
						}
						[paths addObject:path];
					}
				}
				if ([paths count] > 0) {
					[image.layer setPaths:paths];
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
	//UKLog(@"__argument: %@", arguments);
	NSMutableString *__block output = [NSMutableString stringWithCapacity:4096];
	NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
	NSString *helperApplication = [thisBundle pathForResource:Command ofType:nil];

	[self call:helperApplication arguments:arguments processLine: ^(char *line, int length) {
		//[output appendString:[NSString stringWithCString:line encoding:NSASCIIStringEncoding]];
		[output appendString:[[NSString alloc] initWithBytes:line length:length encoding:NSASCIIStringEncoding]];
		[output appendString:@"\n"];
	}];
	return output;
}

- (BOOL)call:(NSString *)helperApplication arguments:(NSArray *)arguments processLine:(void (^)(char *line, int length))processLine {
	// Test argument.
	if ([arguments count] == 0) {
		// Return on zero length input.
		return NO;
	}

	// Get C strings from helper application path and argument.
	const char *path = [helperApplication cStringUsingEncoding:NSUTF8StringEncoding];
	//const char *input = [argument cStringUsingEncoding:NSASCIIStringEncoding];

	// Create file descriptor pair for interprocess communication.
	int fd[2];
	int result = pipe(fd);
	if (result != 0) {
		// Return on error.
		return NO;
	}
	char *argv[[arguments count] + 1];
	argv[0] = (char *)path;
	int j = 1;
	for (NSString *Argument in arguments) {
		argv[j] = (char *)[Argument UTF8String];
		//UKLog(@"__argv[j]: %s", argv[j]);
		j++;
	}
	argv[j] = NULL;
	// Create child process.
	pid_t pid = vfork();
	if (pid < 0) {
		// Return on error.
		return NO;
	}

	if (pid == 0) {
		//							  //
		// *** Begin child process. *** //
		//							  //

		// Close read end of the pipe.
		if (close(fd[0]) != 0) {
			// Exit on error.
			_exit(EXIT_FAILURE);
		}
		// Route stdout to pipe.
		if (dup2(fd[1], STDOUT_FILENO) != STDOUT_FILENO) {
			// Exit on error.
			_exit(EXIT_FAILURE);
		}
		// Execute helper application.

		execv(path, argv);

		// Exit on error.
		_exit(EXIT_FAILURE);

		//							  //
		// ***  End child process.  *** //
		//							  //
	}
	// Close write end of the pipe.
	if (close(fd[1]) == 0) {
		// Allocate memory for line detection.
		size_t line_size = 8192 + 1;
		size_t line_pos = 0;
		char *line_buf = malloc(line_size);

		// Read data from child process until the pipe is closed.
		while (1) {
			char buf[8192];
			ssize_t count = read(fd[0], buf, 4096);
			if (count < 0 && errno == EINTR) {
				UKLog(@"System call has been interrupted by signal.");
				// System call has been interrupted by signal.
				continue;
			}
			else if (count < 0) {
				// Return on error.
				UKLog(@"Return on error.");
				free(line_buf);
				return NO;
			}
			else if (count == 0) {
				UKLog(@"End of file.");
				// End of file.
				break;
			}
			else {
				// Copy data to line buffer.
				if (line_pos + count + 1 > line_size) {
					line_size = line_pos + count + 1 + 4096;
					line_buf = realloc(line_buf, line_size);
				}
				memmove(line_buf + line_pos, buf, count);
				line_pos += count;
				//line_buf[line_pos] = '\0';
				// Look for end of line.
				size_t start = 0;
				for (size_t i = 0; i < line_pos; i++) {
					if (line_buf[i] == '\n') {
						line_buf[i] = '\0';
						processLine(line_buf + start, (int)(i - start));
						start = i + 1;
					}
				}
				if (start < line_pos) {
					line_pos -= start;
					memmove(line_buf, line_buf + start, line_pos + 1);
				}
				else {
					line_pos = 0;
				}
			}
		}

		free(line_buf);
	}

	// Close read end of the pipe.
	BOOL res = YES;
	if (close(fd[0]) != 0) {
		res = NO;
	}

	// Get exit code of child process, so it doesn't become a zombie process.
	int status;
	while (1) {
		pid_t code = waitpid(pid, &status, 0);
		if (code == -1 && errno == EINTR) {
			UKLog(@"System call has been interrupted by signal.");
			// System call has been interrupted by signal.
			continue;
		}
		else if (code != pid) {
			UKLog(@"Return on error.");
			// Return on error.
			return NO;
		}
		else {
			UKLog(@"Got exit code of child process.");
			// Got exit code of child process.
			break;
		}
	}

	// Test exit code of child process.
	if (!WIFEXITED(status) || WEXITSTATUS(status) != EXIT_SUCCESS) {
		UKLog(@"Test exit code of child process.");
		return NO;
	}

	// Success.
	UKLog(@"Success.");
	return res;
}

@end
