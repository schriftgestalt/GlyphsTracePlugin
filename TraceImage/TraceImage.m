//
//  TraceBackground.m
//  TraceBackground
//
//  Created by Georg Seifert on 13.1.08.
//  Copyright 2008 schriftgestaltung.de. All rights reserved.
//

#import "TraceImage.h"
#import <GlyphsCore/GSNode.h>
#import <GlyphsCore/GSGlyph.h>
#import <GlyphsCore/GSLayer.h>
#import <GlyphsCore/GSPath.h>
#import <GlyphsCore/GSFont.h>
#import <GlyphsCore/GSBackgroundImage.h>
#import <GlyphsCore/GSNode.h>
#import <GlyphsCore/GSGeometrieHelper.h>

#import "NSImage+BMP.h"

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
	NSUserDefaultsController *Defaults = [NSUserDefaultsController sharedUserDefaultsController];
	[Defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.Threshold" options:0 context:NULL];
	[Defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.poMinElementSize" options:0 context:NULL];
	[Defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.Roundness" options:0 context:NULL];
	[Defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.OptimizeCurves" options:0 context:NULL];
	[Defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.OptimizationTolerance" options:0 context:NULL];
	[Defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.Stroke" options:0 context:NULL];
	[Defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.CornerThreshold" options:0 context:NULL];
	[Defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.CornerSurround" options:0 context:NULL];
	[Defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.AlwaysCorner" options:0 context:NULL];
	[Defaults addObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.autoMinElementSize" options:0 context:NULL];

}

- (void)dealloc {
	NSUserDefaultsController *Defaults = [NSUserDefaultsController sharedUserDefaultsController];
	[Defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.Threshold"];
	[Defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.poMinElementSize"];
	[Defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.Roundness"];
	[Defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.OptimizeCurves"];
	[Defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.OptimizationTolerance"];
	[Defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.Stroke"];
	[Defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.CornerThreshold"];
	[Defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.CornerSurround"];
	[Defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.AlwaysCorner"];
	[Defaults removeObserver:self forKeyPath:@"values.com.schriftgestaltung.Trace.autoMinElementSize"];
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

- (void)process:(id)sender {
	for (int k = 0; k < [_shadowLayers count]; k++) {
		GSLayer *Layer = _layers[k];
		GSBackgroundImage *Image = [Layer backgroundImage];
		if (Image && [Image hasImageToDraw]) {
			NSBitmapImageRep *bitmap = [Image.image flatImageRep];
			
			CGFloat Scale = [bitmap pixelsWide] / [Image.image size].width;
			NSString *TempSaveString = [[_tempDir stringByAppendingPathComponent:_fileName] stringByAppendingString:@".bmp"];
			
			NSData *BMPData = [bitmap representationUsingType:NSBMPFileType properties:nil];
			if (BMPData) {
				[BMPData writeToFile:TempSaveString atomically:NO];
				NSString *Result = nil;
				if ([[[_tabView selectedTabViewItem] identifier] isEqualToString:@"potrace"]) {
					NSUserDefaults *Defaults = [NSUserDefaults standardUserDefaults];
					CGFloat Threshold = [Defaults floatForKey:@"com.schriftgestaltung.Trace.Threshold"];
					NSUInteger MinElementSize = labs([Defaults integerForKey:@"com.schriftgestaltung.Trace.poMinElementSize"]);
					CGFloat Roundness = [Defaults floatForKey:@"com.schriftgestaltung.Trace.Roundness"];
					BOOL Optimize = [Defaults boolForKey:@"com.schriftgestaltung.Trace.OptimizeCurves"];
					CGFloat OptimizationTolerance = [Defaults floatForKey:@"com.schriftgestaltung.Trace.OptimizationTolerance"];
					Result = [self poTraceImage:TempSaveString withThreshold:Threshold minElementSize:MinElementSize roundness:Roundness optimize:Optimize optimizationTolerance:OptimizationTolerance];
				}
				else if ([[[_tabView selectedTabViewItem] identifier] isEqualToString:@"autotrace"]) {
					NSUserDefaults *Defaults = [NSUserDefaults standardUserDefaults];
					BOOL Stroke = [Defaults boolForKey:@"com.schriftgestaltung.Trace.Stroke"];
					NSUInteger CornerThreshold = [Defaults integerForKey:@"com.schriftgestaltung.Trace.CornerThreshold"];
					NSUInteger CornerSurround = [Defaults integerForKey:@"com.schriftgestaltung.Trace.CornerSurround"];
					NSUInteger AlwaysCorner = [Defaults integerForKey:@"com.schriftgestaltung.Trace.AlwaysCorner"];
					NSUInteger MinElementSize = [Defaults integerForKey:@"com.schriftgestaltung.Trace.autoMinElementSize"];

					Result = [self autoTraceImage:TempSaveString stroke:Stroke cornerThreshold:CornerThreshold cornerSurround:CornerSurround alwaysCorner:AlwaysCorner minElementSize:MinElementSize];

				}
				[[NSFileManager defaultManager] removeItemAtPath:TempSaveString error:nil];
				[_nodeCountField setStringValue:@""];
				if ([Result length] > 10) {
					@try {
						NSArray *PathArray = [Result propertyList];
						NSUInteger nodeCount = 0;
						NSUInteger pathCount = 0;
						if ([PathArray count] > 0) {
							NSMutableArray *Paths = [NSMutableArray array];
							NSAffineTransform *Transform = [NSAffineTransform transform];
							[Transform setTransformStruct:[Image transformStruct]];
							[Transform scaleBy:1.0f / Scale];
							for (NSDictionary *PathDict in PathArray) {
								GSPath *Path = [[GSPath alloc] initWithPathDict:PathDict];
								[Path cleanUp];
								if (Path && [Path.nodes count] > 1) {
									pathCount++;
									for (GSNode *Node in Path.nodes) {
										nodeCount++;
										Node.position = [Transform transformPoint:Node.position];
									}
									[Paths addObject:Path];
								}
							}
							if ([Paths count] > 0) {
								[Layer setPaths:Paths];
							}
						}
						[_nodeCountField setAlignment:NSCenterTextAlignment];
						[_nodeCountField setStringValue:[NSString stringWithFormat:@"%ld path with %ld nodes", pathCount, nodeCount]];
						
					}
					@catch (NSException *exception) {
						UKLog(@"Something went wrong: %@", Result);
						[_nodeCountField setAlignment:NSLeftTextAlignment];
						[_nodeCountField setStringValue:[NSString stringWithFormat:@"Something went wrong: %@", Result]];
					}
				}
			}
		}
	}
}

- (NSString *)poTraceImage:(NSString *)ImagePath withThreshold:(CGFloat)Threshold minElementSize:(NSUInteger)MinElementSize roundness:(CGFloat)Roundness optimize:(BOOL)Optimize optimizationTolerance:(CGFloat)OptimizationTolerance {
	NSMutableArray *Arguments = [NSMutableArray arrayWithObjects:
								 @"-bGlyphs", [NSString stringWithFormat:@"-k %.2f", Threshold / 0xff],
								 [NSString stringWithFormat:@"-t %d", (int)MinElementSize],
								 [NSString stringWithFormat:@"-a %.3f", (Roundness * ((4 / 3) + 0.01)) - 0.01],
								 ImagePath, nil];
	if (!Optimize) {
		[Arguments insertObject:@"-n" atIndex:1];
		[Arguments insertObject:[NSString stringWithFormat:@"-O %.3f", OptimizationTolerance] atIndex:2];
	}
	UKLog(@"__Arguments: %@", Arguments);
	return [self traceFile:Arguments withCommand:@"potrace"];
}

- (NSString *)autoTraceImage:(NSString *)ImagePath stroke:(BOOL)Stroke cornerThreshold:(NSUInteger)CornerThreshold cornerSurround:(NSUInteger)cornerSurround alwaysCorner:(NSUInteger)AlwaysCorner minElementSize:(NSUInteger)MinElementSize {
	NSMutableArray *Arguments = [NSMutableArray arrayWithObjects:
								 @"-color-count", @"2",
								 @"-background-color", @"FFFFFF",
								 @"-corner-threshold", [NSString stringWithFormat:@"%d", (int)CornerThreshold],
								 @"-corner-always-threshold", [NSString stringWithFormat:@"%d", (int)AlwaysCorner],
								 @"-corner-surround", [NSString stringWithFormat:@"%d", (int)cornerSurround],
								 @"-despeckle-level", [NSString stringWithFormat:@"%d", (int)MinElementSize],
								 @"-input-format", @"BMP",
								 ImagePath, nil];
	if (Stroke) {
		[Arguments insertObject:@"-centerline" atIndex:0];
	}
	UKLog(@"__arguments: %@", [Arguments componentsJoinedByString:@"; "]);
	return [self traceFile:Arguments withCommand:@"autotrace"];
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
