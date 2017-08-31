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

@end
