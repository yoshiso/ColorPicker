//
//  CCAppDelegate.m
//  ColorPicker
//
//  Created by yoshiso on 2013/10/25.
//  Copyright (c) 2013年 yoshiso. All rights reserved.
//

#import "CCAppDelegate.h"

@interface CCAppDelegate()

- (void)globalMouseMoved:(NSEvent *)event;
- (void)globalMouseDown:(NSEvent *)event;

@end

@implementation CCAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    //tableviewの各種処理と表示管理を自分侍史員が担当する
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    //マウスの移動を監視
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSMouseMovedMask handler:^(NSEvent *event) {
        [self globalMouseMoved:event];
    }];
    
    //マウスのクリックダウンを監視
    [NSEvent addGlobalMonitorForEventsMatchingMask:NSLeftMouseDownMask handler:^(NSEvent *event) {
        [self globalMouseDown:event];
    }];
    
    //色を保持する配列
    items_ = [NSMutableArray array];
    
    //設定ファイルに選択肢が保存されていた場合はPopUpに反映する
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey:@"ColorFormatIndex"];
    if(index){
        [self.popUp selectItemAtIndex:index];
    }
    
    //ダブルクリックアクションを監視
    self.tableView.target = self;
    self.tableView.doubleAction = @selector(pasteToClipBoard);
}

- (void)pasteToClipBoard{
    //クリックされたrowのrgb値を文字列としてPasteboardにコピーする
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    [pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:self];
    [pb setString:[[items_ objectAtIndex:self.tableView.clickedRow] objectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"ColorFormatIndex"]] forType:NSStringPboardType];
}


- (void)globalMouseDown:(NSEvent *)event
{
    //自分がアクティブか非表示なら何もしない
    if([self.window isKeyWindow] || ![self.window isVisible]){
        return;
    }
    
    //RGBの16進数文字列
    NSString *hex = [NSString stringWithFormat:@"#%x%x%x",red_,green_,blue_];
    
    //RGBの10進数
    NSString *decimal = [NSString stringWithFormat:@"rgb(%d,%d,%d)",red_,green_,blue_];
    
    //NSColorオブジェクト
    NSColor *color = [NSColor colorWithDeviceRed:red_/255.0 green:green_/255.0 blue:blue_/255.0 alpha:1.0];
    //直前の色と同じではない場合のみ追加
    if (items_.count == 0 || !([[[items_ objectAtIndex:0]lastObject] isEqualTo:color])){
        NSArray *item = [NSArray arrayWithObjects:hex, decimal, color,nil];
        [items_ insertObject:item atIndex:0];
    }
    //テーブルビューの更新
    [self.tableView reloadData];
}



- (void)globalMouseMoved:(NSEvent *)event
{
    // 左下原点座標を取得
    CGEventRef eventRef = CGEventCreate(NULL);
    CGPoint point = CGEventGetLocation(eventRef);
    
    //CGEventRefの解放
    CFRelease(eventRef);
    
    //ログ
    NSLog(@"globalMouseModed: x = %f, y = %f",point.x, point.y);
    
    //キャプチャサイズ
    int size = 11;
    
    //真ん中の座標
    int center = floor(size/2.0);
    
    //マウスの座標を中心とした矩形作成
    CGRect captureRect = CGRectMake(point.x - center, point.y - center, size, size);
    
    //画面キャプチャ
    CGImageRef cgImageRef = CGWindowListCreateImage(
        captureRect,
        kCGWindowListOptionOnScreenOnly,
        kCGNullWindowID,
        kCGWindowImageBoundsIgnoreFraming
    );
    
    //表示するためのNSImageを生成
    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithCGImage:cgImageRef];
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation:bitmap];
    
    //ImageWallに設定
    self.imageView.image = image;
    
    //CGImageRefからビットマップデータを取得
    CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImageRef);
    CFDataRef data = CGDataProviderCopyData(dataProvider);
    UInt8 *buffer = (uint8 *)CFDataGetBytePtr(data);
    
    size_t bytesPerRow = CGImageGetBytesPerRow(cgImageRef);
    
    //中心のビットマップを取得
    int x = center;
    int y = center;
    UInt8 *index = buffer + x * 4 + y * bytesPerRow;
    
    //BGRA
    UInt8 r = *(index + 2);
    UInt8 g = *(index + 1);
    UInt8 b = *(index + 0);
    
    //Boxの背景色、Labelのテキストを設定
    if([[NSUserDefaults standardUserDefaults] integerForKey:@"ColorFormatIndex"]==1){
       self.colorLabel.stringValue = [NSString stringWithFormat:@"rgb(%d,%d,%d)",r,g,b]; 
    }else{
        self.colorLabel.stringValue = [NSString stringWithFormat:@"#%x%x%x",r,g,b];
    }
    self.colorBox.fillColor = [NSColor colorWithDeviceRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1.0];
    
    red_ = r;
    green_ = g;
    blue_ = b;
    
}

- (IBAction)clearItems:(id)sender
{
    [items_ removeAllObjects];
    [self.tableView reloadData];
}

- (IBAction)changeColorFormat:(id)sender {
    //現在の状態を設定ファイル(NSUserDefault)に保存
    [[NSUserDefaults standardUserDefaults] setInteger:[sender indexOfSelectedItem] forKey:@"ColorFormatIndex"];
    //TableViewを更新
    [self.tableView reloadData];
}

#pragma mark TableView
//TableViewの行数
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return items_.count;
}

//TableViewの表示内容
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    //何列目か
    switch ([tableColumn.identifier intValue]) {
        //2列目の場合はitems_[raw][0]を表示
        case 1:
            return [[items_ objectAtIndex:row]objectAtIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"ColorFormatIndex"]];
            break;
        //その他は表示無し
        default:
            return @"";
            break;
    }
}



//TableViewの表示直前に呼ばれる
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    //1列目なら
    if ([tableColumn.identifier isEqualToString:@"0"]) {
        //背景色をitem_[raw][last]に
        [cell setBackgroundColor:[[items_ objectAtIndex:row]lastObject]];
    }
}



//Dockがクリックされたときにウインドウを再表示する
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    //自動でwindowを手前に
    [self.window makeKeyAndOrderFront:nil];
    
    return NO;
}

@end
