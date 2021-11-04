//
//  NSImage+WritePortableAnymap.m
//  TraceImage
//
//  Created by Georg Seifert on 04.11.21.
//  Copyright © 2021 GeorgSeifert. All rights reserved.
//

#import "NSImage+WritePortableAnymap.h"

@implementation NSImage (WritePortableAnymap)

- (NSBitmapImageRep*)bitmapImageRep {
	if (self.representations.count == 1 && [self.representations.firstObject isKindOfClass:[NSBitmapImageRep class]]) {
		return (NSBitmapImageRep*)self.representations.firstObject;
	}
	return [[NSBitmapImageRep alloc] initWithData:[self TIFFRepresentation]];
}

@end

@implementation NSBitmapImageRep (WritePortableAnymap)

- (BOOL)writePortableAnymap:(NSString*)filePath {
	NSInteger rowBytes = [self bytesPerRow];
	NSInteger bpp = [self bitsPerPixel] / 8;
	FILE *file = fopen([filePath fileSystemRepresentation], "w");
	float levels = (float)(1 << self.bitsPerSample) - 1;
	fprintf(file, "P2\n%ld %ld\n%.0f\n", [self pixelsWide], [self pixelsHigh], levels);
	unsigned char* imageData = [self bitmapData];

	for (int y = 0; y < [self pixelsHigh]; y++) {
		for (int x = 0; x < [self pixelsWide]; x++) {
			float red = *(imageData + y * rowBytes + x * bpp) / levels; // Red
			float gray;
			if (self.bitsPerPixel == 24) {
				float green = *(imageData + y * rowBytes + x * bpp + 1) / levels; // Green
				float blue = *(imageData + y * rowBytes + x * bpp + 2) / levels; // Blue
				float alpha = *(imageData + y * rowBytes + x * bpp + 3) / levels; // Alpha
				//gray = (red + green + blue) / 3.0;
				float Y = 0.2126 * red + 0.7152 * green + 0.0722 * blue;
				gray = Y * alpha;
			}
			else {
				gray = red;
			}
			fprintf(file, "%d ", (int)roundf(gray * levels));

		}
		fprintf(file, "\n");
	}
	fclose(file);
	return YES;
}

@end
