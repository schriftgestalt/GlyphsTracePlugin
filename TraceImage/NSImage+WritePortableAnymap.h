//
//  NSImage+WritePortableAnymap.h
//  TraceImage
//
//  Created by Georg Seifert on 04.11.21.
//  Copyright © 2021 GeorgSeifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSImage (WritePortableAnymap)

- (NSBitmapImageRep*)bitmapImageRep;

@end

@interface NSBitmapImageRep (WritePortableAnymap)

- (BOOL)writePortableAnymap:(NSString *)filePath;

@end

NS_ASSUME_NONNULL_END
