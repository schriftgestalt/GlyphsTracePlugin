//
//  TraceImage.h
//  TraceImage
//
//  Created by Georg Seifert on 13.1.08.
//  Copyright 2008 schriftgestaltung.de. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <GlyphsCore/GSFilterPlugin.h>

@interface TraceImage : GSFilterPlugin <NSTabViewDelegate> {
	NSTabView __unsafe_unretained *_tabView;
@private
	NSString *_tempDir;
	NSString *_fileName;
}

@property (nonatomic, assign) IBOutlet NSTabView *tabview;
@property (nonatomic, assign) IBOutlet NSTextField *nodeCountField;

@end
