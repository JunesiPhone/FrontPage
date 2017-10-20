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

		// <dict>
		// 	<key>action</key>
		// 	<string>respring</string>
		// 	<key>cell</key>
		// 	<string>PSButtonCell</string>
		// 	<key>label</key>
		// 	<string>Respring</string>
		// </dict>

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
