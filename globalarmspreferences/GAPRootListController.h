#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

// Additional features:
// Localizes specifiers
// nestedEntryCount for more dynamic preferences
// version specific specifiers
// method to open twitter account

@interface GAPRootListController : PSListController {
    NSArray* _allSpecifiers;
}
- (void)applyModificationsToSpecifiers:(NSMutableArray*)specifiers;
- (void)removeDisabledGroups:(NSMutableArray*)specifiers;
- (void)openTwitter;
- (void)respring:(id)sender;
- (void)donationLink;
@end
