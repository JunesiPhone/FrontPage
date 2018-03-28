#include "FPRootListController.h"
#include "notify.h"

@implementation FPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}

- (void)respring {
	notify_post("com.junesiphone.frontpage.respring");
}
- (void)menu {
	notify_post("com.junesiphone.frontpage.openmenu");
}

// -(NSArray *)themeTitles {
//     NSMutableArray* files = [[[NSFileManager defaultManager]
//                               contentsOfDirectoryAtPath:@"/var/mobile/Library/iWidgets" error:nil] mutableCopy];

//     return files;
// }

// -(NSArray *)themeValues {
//     NSMutableArray* files = [[[NSFileManager defaultManager]
//                               contentsOfDirectoryAtPath:@"/var/mobile/Library/iWidgets" error:nil] mutableCopy];

//     return files;
// }

- (void)visitRepo:(id)sender {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.junesiphone.com/supersecret"]];
}

- (void)visitThemes:(id)sender {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://junesiphone.com/frontpage/themes"]];
}

- (void)visitAPI:(id)sender {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://junesiphone.com/frontpage"]];
}

- (void)visitTwitter:(id)sender {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/junesiphone"]];
}

@end
