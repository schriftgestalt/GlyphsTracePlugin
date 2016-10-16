//
//  NSImage+BMP.m
//  TraceBackground
//
//  Created by Georg Seifert on 04.07.12.
//  Copyright (c) 2012 schriftgestaltung.de. All rights reserved.
//

#import "NSImage+BMP.h"

@implementation NSImage (BMP)

- (NSBitmapImageRep *)flatImageRep {
	NSSize imageSize = [self size];

	NSInteger width, height;

	width = imageSize.width;   // + 4;
	height = imageSize.height; // + 4;

	// make an 8-bit representation of the image which is a little larger than this, so that there
	// is a clear border around the pixels.

	NSBitmapImageRep *b24 =
		[[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
												pixelsWide:width
												pixelsHigh:height
											 bitsPerSample:8
										   samplesPerPixel:1
												  hasAlpha:NO
												  isPlanar:NO
											colorSpaceName:NSCalibratedWhiteColorSpace
											  bitmapFormat:0
											   bytesPerRow:0
											  bitsPerPixel:0];

	UKLog(@"24-bit image: %@", b24);

	NSRect hr = NSMakeRect(0, 0, width, height);

	// copy the image to the bitmap, converting it to the 8-bit rep as we go

	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithBitmapImageRep:b24]];
	[[NSGraphicsContext currentContext] setShouldAntialias:YES];
	//[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];

	// fill background - has pixel value FFFFFF

	[[NSColor whiteColor] set];
	NSRectFill(hr);

	[self drawAtPoint:NSMakePoint(0, 0)
			 fromRect:NSZeroRect
			operation:NSCompositeSourceOver
			 fraction:1];
	//[self drawInRect: hr fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];

	[NSGraphicsContext restoreGraphicsState];

	return b24;
}

@end