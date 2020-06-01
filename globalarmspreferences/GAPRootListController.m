#include "GAPRootListController.h"
#import <spawn.h>

@implementation GAPRootListController

/* load all specifiers from plist file */
- (NSMutableArray*)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
		[self applyModificationsToSpecifiers:(NSMutableArray*)_specifiers];
	}

	return (NSMutableArray*)_specifiers;
}

/* save a copy of those specifications so we can retrieve them later */
- (void)applyModificationsToSpecifiers:(NSMutableArray*)specifiers
{
	_allSpecifiers = [specifiers copy];
	[self removeDisabledGroups:specifiers];
}

/* actually remove them when disabled */
- (void)removeDisabledGroups:(NSMutableArray*)specifiers;
{
	for(PSSpecifier* specifier in [specifiers reverseObjectEnumerator])
	{
		NSNumber* nestedEntryCount = [[specifier properties] objectForKey:@"nestedEntryCount"];
		if(nestedEntryCount)
		{
			BOOL enabled = [[self readPreferenceValue:specifier] boolValue];
			if(!enabled)
			{
				NSMutableArray* nestedEntries = [[_allSpecifiers subarrayWithRange:NSMakeRange([_allSpecifiers indexOfObject:specifier]+1, [nestedEntryCount intValue])] mutableCopy];

				BOOL containsNestedEntries = NO;

				for(PSSpecifier* nestedEntry in nestedEntries)	{
					NSNumber* nestedNestedEntryCount = [[nestedEntry properties] objectForKey:@"nestedEntryCount"];
					if(nestedNestedEntryCount)	{
						containsNestedEntries = YES;
						break;
					}
				}

				if(containsNestedEntries)	{
					[self removeDisabledGroups:nestedEntries];
				}

				[specifiers removeObjectsInArray:nestedEntries];
			}
		}
	}
}

/* what happens when we are inside the preferences and messing around with the cells */
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier
{
	[super setPreferenceValue:value specifier:specifier];

	if(specifier.cellType == PSSwitchCell)	{
		NSNumber* numValue = (NSNumber*)value;
		NSNumber* nestedEntryCount = [[specifier properties] objectForKey:@"nestedEntryCount"];
		if(nestedEntryCount)	{
			NSInteger index = [_allSpecifiers indexOfObject:specifier];
			NSMutableArray* nestedEntries = [[_allSpecifiers subarrayWithRange:NSMakeRange(index + 1, [nestedEntryCount intValue])] mutableCopy];
			[self removeDisabledGroups:nestedEntries];

			if([numValue boolValue])  {
				[self insertContiguousSpecifiers:nestedEntries afterSpecifier:specifier animated:YES];
			}
			else  {
				[self removeContiguousSpecifiers:nestedEntries animated:YES];
			}
		}
	}
}

- (void)respring:(id)sender {
	pid_t pid;
	const char* args[] = {"killall", "backboardd", NULL};
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
}

-(void)openTwitter {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.twitter.com/omrkujman"]];
}

-(void)donationLink {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.paypal.me/0xkuj"]];
}

@end
