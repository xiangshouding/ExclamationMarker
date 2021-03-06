//
//  ViewController.m
//  ExclamationMarker
//
//  Created by shouding on 9/17/15.
//  Copyright © 2015 shouding. All rights reserved.
//

#import "ViewController.h"
#import "EMUploader.h"
#import "EMConfig.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void) openFile:(void (^) (NSURL *)) onComplete {
    // init
    [self showError:@""];
    [[self showUrl] setStringValue: @""];
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles: YES];
    [panel setCanCreateDirectories: NO];
    [panel setCanChooseDirectories: NO];
    [panel setAllowedFileTypes:@[@"jpg", @"jpeg", @"png", @"gif"]];

    [panel beginSheetModalForWindow: [[self view] window] completionHandler: ^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            onComplete([panel URLs][0]);
        }
    }];
}

- (void) showError: (NSString *) err {
    [[self errorContainer] setStringValue:err];
}

- (IBAction)uploadAction:(id)sender {

    void (^onComplete) (NSURL *) = ^(NSURL * url) {

        EMConfig *config = [[EMConfig alloc] init];

        NSURL * serverUrl = [NSURL URLWithString: [config getServerUrl]];

        EMUploader *uploader = [[EMUploader alloc] init];

        void (^onReady) (NSData *, NSURLResponse *, NSError *) = ^(NSData *onData, NSURLResponse *res, NSError *err) {

            if (err != nil) {
                [self showError: [NSString stringWithFormat:@"%@", err]];
                return;
            }
            NSHTTPURLResponse *response = (NSHTTPURLResponse *) res;
            if ([response statusCode] != 200) {
                [self showError:[NSString stringWithFormat:@"HTTP Status code: %ld", [response statusCode]]];
                return;
            }
            
#ifdef DEBUG
            NSLog(@"onReady");
            NSLog(@"%@", [[NSString alloc] initWithData: onData encoding: NSUTF8StringEncoding]);
#endif

            NSMutableArray *json = [NSJSONSerialization JSONObjectWithData: onData options: NSJSONReadingMutableContainers error: nil];

#ifdef DEBUG
            NSLog(@"prefix %@, %@", [config getUrlPrefix], json);
#endif
            NSInteger code = [[json valueForKey: @"code"] integerValue];

            if (code == 0) {
                NSString *strUrl = [NSString stringWithFormat: @"%@%@", [config getUrlPrefix], [json valueForKey:@"url"]];
                // the link copy the pasteboard of system
                [[NSPasteboard generalPasteboard] clearContents];
                [[NSPasteboard generalPasteboard] setString: strUrl forType: NSStringPboardType];
                [[self showUrl] setStringValue: strUrl];
            } else {
                [self showError:@"Server error."];
            }
        };

        [uploader uploadFile: serverUrl filepath: [url path] onReady: onReady];
    };

    [self openFile: onComplete];

}


@end
