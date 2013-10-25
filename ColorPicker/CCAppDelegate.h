//
//  CCAppDelegate.h
//  ColorPicker
//
//  Created by yoshiso on 2013/10/25.
//  Copyright (c) 2013年 yoshiso. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CCAppDelegate : NSObject <NSApplicationDelegate,NSTableViewDelegate,NSTableViewDataSource>{
    NSMutableArray *items_;
    UInt8 red_;
    UInt8 green_;
    UInt8 blue_;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSImageView *imageView;
@property (weak) IBOutlet NSBox *colorBox;
@property (weak) IBOutlet NSTextField *colorLabel;
@property (weak) IBOutlet NSTableView *tableView;
- (IBAction)clearItems:(id)sender;
- (IBAction)changeColorFormat:(id)sender;
@property (weak) IBOutlet NSPopUpButton *popUp;

@end
