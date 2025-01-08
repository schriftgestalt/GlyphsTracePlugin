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

- (NSImage *)flattenedGrayscaleImageFromImage {
	// Create a CGImage representation of the NSImage
	CGImageRef cgImage = [self CGImageForProposedRect:NULL context:NULL hints:NULL];
	if (!cgImage) {
		NSLog(@"Error: Unable to create CGImage from NSImage.");
		return nil;
	}

	size_t width = CGImageGetWidth(cgImage);
	size_t height = CGImageGetHeight(cgImage);

	// Define the color space and bitmap info
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	size_t bytesPerPixel = 1; // 1 byte per pixel for grayscale
	size_t bytesPerRow = width * bytesPerPixel;

	// Allocate memory for image data
	unsigned char *imageData = calloc(height, bytesPerRow);
	if (!imageData) {
		CGColorSpaceRelease(colorSpace);
		NSLog(@"Error: Unable to allocate memory for image data.");
		return nil;
	}

	// Create a bitmap context
	CGContextRef context = CGBitmapContextCreate(imageData, width, height, 8, bytesPerRow, colorSpace, kCGImageAlphaNone);
	CGColorSpaceRelease(colorSpace);

	if (!context) {
		free(imageData);
		NSLog(@"Error: Unable to create CGContext.");
		return nil;
	}

	if (CGImageGetAlphaInfo(cgImage) != kCGImageAlphaNone) {
		CGContextSetGrayFillColor(context, 1.0, 1.0); // White color
		CGContextFillRect(context, CGRectMake(0, 0, width, height));
	}
	// Draw the image into the context
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);

	// Create a new CGImage from the grayscale bitmap
	CGImageRef grayImage = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	free(imageData);

	if (!grayImage) {
		NSLog(@"Error: Unable to create grayscale CGImage.");
		return nil;
	}

	// Wrap the CGImage in an NSImage
	NSImage *grayscaleImage = [[NSImage alloc] initWithCGImage:grayImage size:self.size];
	CGImageRelease(grayImage);

	return grayscaleImage;
}

@end

@implementation NSBitmapImageRep (WritePortableAnymap)

- (BOOL)writePortableAnymap:(NSString *)filePath {
	// Calculate necessary image data attributes
	NSInteger rowBytes = [self bytesPerRow];
	NSInteger bpp = [self bitsPerPixel] / 8; // Bytes per pixel
	float maxPixelValue = (float)((1 << [self bitsPerSample]) - 1); // Max grayscale level

	// Open the file for writing
	FILE *file = fopen([filePath fileSystemRepresentation], "w");
	if (!file) {
		NSLog(@"Error: Could not open file for writing at path: %@", filePath);
		return NO;
	}

	// Write PGM header
	fprintf(file, "P2\n%ld %ld\n%.0f\n", [self pixelsWide], [self pixelsHigh], maxPixelValue);

	unsigned char *imageData = [self bitmapData];

	// Iterate through pixels to write grayscale values
	for (int y = 0; y < [self pixelsHigh]; y++) {
		unsigned char *rowPtr = imageData + y * rowBytes; // Pointer to start of the current row
		for (int x = 0; x < [self pixelsWide]; x++) {
			unsigned char *pixelPtr = rowPtr + x * bpp; // Pointer to the current pixel

			float red = pixelPtr[0] / maxPixelValue; // Normalize red component
			float gray;

			if (bpp >= 3) {
				// If RGB(A), calculate luminance
				float green = pixelPtr[1] / maxPixelValue;
				float blue = pixelPtr[2] / maxPixelValue;
				float alpha = (bpp > 3) ? (pixelPtr[3] / maxPixelValue) : 1.0; // Normalize alpha if available

				// Use the Rec. 709 luma formula (linear RGB approximation)
				float luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue;
				gray = luminance * alpha; // Incorporate alpha channel
			}
			else {
				// If grayscale, use red channel
				gray = red;
			}

			// Clamp and scale grayscale value to integer range
			int grayValue = (int)roundf(gray * maxPixelValue);
			fprintf(file, "%d ", grayValue);
		}
		fprintf(file, "\n"); // End of row
	}

	fclose(file); // Close the file
	return YES;
}

@end
