//
//  main.m
//  AutoGenCode
//
//  Created by company on 16/11/10.
//  Copyright © 2016年 company. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AGHelper.h"
int main(int argc, const char * argv[]) {
	@autoreleasepool {
		[NSApplication sharedApplication];
		
		AGHelper *controller = [[AGHelper alloc] init];
		[[NSApplication sharedApplication] setDelegate:controller];
		[NSApp run];
	}	
	return 0;
}
