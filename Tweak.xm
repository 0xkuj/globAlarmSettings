/* This tweak is hooking Apple's clock app to add a button to delete all alarm clocks (besides the "bed time" clock)
 * The button will appear only when in edit mode
 * Created by: 0xkuj
*/

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UITextInput.h>
#import <UIKit/UILongPressGestureRecognizer.h>
#import <UIKit/UITableView.h>
#import <UIKit/UIAlertView.h>
#import <UIKit/UIGestureRecognizer.h>
#import <UIKit/UIViewController.h>
#import <UIKit/UIActionSheet.h>

@interface NAFuture {
	NSMutableArray *_resultValue;
}
@end

/* Declared this type in order to MTAlarmDataSource be fimiliar with this type */
@interface MTAlarm
-(BOOL)allowsSnooze;
-(void)setAllowsSnooze:(BOOL)snoozeValue;
-(void)setEnabled:(BOOL)isEnabled;
-(void)setSleepSchedule:(BOOL)isSleepSchedule;
@end

@interface MTMutableAlarm : MTAlarm
@property(nonatomic, assign, readwrite, getter=isEnabled) BOOL enabled;
@property(nonatomic, assign, readwrite) BOOL allowSnooze;
@end

/* This is what actually holds all the alarms. we needed alarms to get all alarms
* we needed removeAlarm in order to remove each alarm
*/
@interface MTAlarmDataSource
-(NAFuture *)alarms;
-(MTAlarm *)sleepAlarm;
-(id)removeAlarm:(MTAlarm *)arg1;
-(id)updateAlarm:(MTAlarm *)arg1;
@end

/* this is what we actually hook. this holds a pointer to MTAalarmDataSource -> holds a pointer to alarms + remove alarm */
@interface MTAAlarmTableViewController : UITableViewController
@property(retain, nonatomic) MTAlarmDataSource *dataSource;
-(void)executeWithDialog:(NSInteger)actionNumber message:(NSString *)message;
-(void)editAllAlarms:(NSInteger) actionNumber;
@end


/* declare global backup button so we can return to that after edit mode is over */
static int firstInit = 0;
static BOOL wasEnabledToggle = 0;
static BOOL wasEnabledSnooze = 0;
UIBarButtonItem *plusButton;
NSDictionary* preferences;
#define preferencePlist @"/var/mobile/Library/Preferences/com.0xkuj.globalarmspreferences.plist"
#define DELETE_ALL_ALARMS_DISABLED_MSG @"You are about to delete:\n - All disabled alarms\n Are you sure?"
#define DELETE_ALL_ALARMS_MSG @"You are about to delete:\n - All disabled alarms\n - All enabled alarms\n Are you sure?"
#define SNOOZE_ALL_ALARMS_MSG @"You are about to snooze all alarms\n Are you sure?"
#define TOGGLE_ALL_ALARMS_MSG @"You are about to toggle all alarms\n Are you sure?"

enum actionTypes
{
	SNOOZEALL,
	TOGGLEALL,
	DELETEALLDIS,
	DELETEALL
};


/* hooking the controller, viewDidLoad after the view finished loading we save the current button for future use */
%hook MTAAlarmTableViewController

/* Overriding This function - its being called when we are in edit mode, she holds a value editing so we will know when its in edit mode and when its done */
-(void)setEditing:(BOOL)editing animated:(BOOL)animated
{ 
    %orig;

    preferences= [[NSDictionary alloc] initWithContentsOfFile:preferencePlist];
	NSNumber *isTweakEnabled = [preferences objectForKey:@"isTweakEnabled"];
	if(!isTweakEnabled) isTweakEnabled = @YES;
	/* this means the tweak is disabled */
	if (![isTweakEnabled boolValue])
		return;

	if (!firstInit) {
		/* assign the '+' button so we can change back */
		plusButton = self.navigationItem.rightBarButtonItem;
		firstInit = 1;
	}

    if (editing) {
	    /* UIBarButtonItem is the button for navigation bar. action:@selector is what we need in order to call the action when pressed) */
	    UIBarButtonItem *setAll = [[UIBarButtonItem alloc] initWithTitle:@"Set All" style:UIBarButtonItemStylePlain target:self action:@selector(showActionSheet)];			   
   		self.navigationItem.rightBarButtonItem = setAll;
	}
	else {
	   /* if not in edit mode, we will bring back the '+' button with all of his actions */
	   self.navigationItem.rightBarButtonItem = plusButton;
	}

}

/*tag a new function 
 * this function actually goes over all the alarms and delete them. will present a confirmation dialog first */
%new 
-(void)editAllAlarms:(NSInteger) actionNumber 
{
	NSNumber *isBedTimeIncluded = [preferences objectForKey:@"isBedTimeIncluded"];
	if(!isBedTimeIncluded) isBedTimeIncluded = @YES;
	NSMutableArray *allAlarms = MSHookIvar<NSMutableArray *>([self dataSource], "_alarms");

	if (!allAlarms) {
		[self setEditing:FALSE
		 	    animated:TRUE];

		NSLog(@"[0xkuj GLOBALARM] We should not reach here. something went wrong");
	   	return;
	}

	switch (actionNumber)
	{
		case SNOOZEALL:
			for (int i=0; i<[allAlarms count]; i++) {
					[(MTAlarm *)[allAlarms objectAtIndex:i] setAllowsSnooze:wasEnabledSnooze];
					[self.dataSource updateAlarm:[allAlarms objectAtIndex:i]];
			}
			wasEnabledSnooze = !wasEnabledSnooze;
			[self setEditing:FALSE
		    	  animated:TRUE];
			break;
		case TOGGLEALL:
			for (int i=0; i<[allAlarms count]; i++) {
				[[allAlarms objectAtIndex:i] setEnabled:wasEnabledToggle];
				[self.dataSource updateAlarm:[allAlarms objectAtIndex:i]];
			}
			 

			if ([isBedTimeIncluded boolValue] && self.dataSource.sleepAlarm) {
				[self.dataSource.sleepAlarm setEnabled:wasEnabledToggle];
				[self.dataSource.sleepAlarm setSleepSchedule:wasEnabledToggle];
				[self.dataSource updateAlarm:self.dataSource.sleepAlarm];
			}

			wasEnabledToggle = !wasEnabledToggle;
			[self setEditing:FALSE
		    	  animated:TRUE];
			break;
		case DELETEALLDIS:
			for (int i=0; i<[allAlarms count];) {
				if ([[allAlarms objectAtIndex:i] isEnabled]) {
					i++;
					continue;
				}
    			[self.dataSource removeAlarm:[allAlarms objectAtIndex:i]];
			} 	
			if ([isBedTimeIncluded boolValue] && self.dataSource.sleepAlarm) {
					[self.dataSource removeAlarm:self.dataSource.sleepAlarm];
			}
			[self setEditing:FALSE
		    	  animated:TRUE];
			break;
		case DELETEALL:
			while (allAlarms.lastObject) {
    			[self.dataSource removeAlarm:allAlarms.lastObject];
			}

			if ([isBedTimeIncluded boolValue] && self.dataSource.sleepAlarm) {
				[self.dataSource removeAlarm:self.dataSource.sleepAlarm];
			}

			[self setEditing:FALSE
		    	  animated:TRUE];
			break;
	}
}

%new
-(void)executeWithDialog:(NSInteger)actionNumber message:(NSString*)message {
	UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"Confirmation"
    									                    message:message
    														preferredStyle:UIAlertControllerStyleAlert];
	/* prepare function for "yes" button */
	UIAlertAction* OKAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault
    		handler:^(UIAlertAction * action) {
				[self editAllAlarms:actionNumber];
			}];
	/* prepare function for "no" button" */
	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style: UIAlertActionStyleCancel handler:^(UIAlertAction * action) { return; }];
	/* actually assign those actions to the buttons */
	[alertController addAction:OKAction];
    [alertController addAction:cancelAction];
	/* present the dialog and wait for an answer */
	[self presentViewController:alertController animated:YES completion:nil];
	return;
}

%new
-(void)showActionSheet {

	NSString *dynamicTitleToggle;
	NSString *dynamicTitleSnooze;

	NSNumber *isDialogNeeded = [preferences objectForKey:@"isDialogNeeded"];	
	if(!isDialogNeeded) isDialogNeeded = @YES;

	NSNumber *isDialogSnooze = [preferences objectForKey:@"isDialogSnooze"];
	if(!isDialogSnooze) isDialogSnooze = @YES;

	NSNumber *isDialogToggle = [preferences objectForKey:@"isDialogToggle"];
	if(!isDialogToggle) isDialogToggle = @YES;

	NSNumber *isDialogDeleteDis = [preferences objectForKey:@"isDialogDeleteDis"];
	if(!isDialogDeleteDis) isDialogDeleteDis = @YES;

	NSNumber *isDialogDeleteAll = [preferences objectForKey:@"isDialogDeleteAll"];
	if(!isDialogDeleteAll) isDialogDeleteAll = @YES;

	/* when toggling alarm first it will be OFF */
	UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:@"GlobAlarmSettings - Choose an action" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

	[actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
	[self dismissViewControllerAnimated:YES completion:^{return;}];}]];

	dynamicTitleSnooze = [NSString stringWithFormat:@"Snooze All Alarms %s",wasEnabledSnooze ? "ON" : "OFF"];	
	[actionSheet addAction:[UIAlertAction actionWithTitle:dynamicTitleSnooze style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {	
		if ([isDialogSnooze boolValue] && [isDialogNeeded boolValue]) {
			[self executeWithDialog:SNOOZEALL
			      message:SNOOZE_ALL_ALARMS_MSG];
		}
		else {
			[self editAllAlarms:SNOOZEALL];
		}
	}]];

	dynamicTitleToggle = [NSString stringWithFormat:@"Toggle All alarms %s",wasEnabledToggle ? "ON" : "OFF"];	
	[actionSheet addAction:[UIAlertAction actionWithTitle:dynamicTitleToggle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {	
		if ([isDialogToggle boolValue] && [isDialogNeeded boolValue]) {
			[self executeWithDialog:TOGGLEALL
			      message:TOGGLE_ALL_ALARMS_MSG];
		}
		else {
			[self editAllAlarms:TOGGLEALL];
		}
		
	}]];

	[actionSheet addAction:[UIAlertAction actionWithTitle:@"Delete all Disabled Alarms"  style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
		if ([isDialogDeleteDis boolValue] && [isDialogNeeded boolValue]) {
			[self executeWithDialog:DELETEALLDIS
			      message:DELETE_ALL_ALARMS_DISABLED_MSG];
		}
		else {
			[self editAllAlarms:DELETEALLDIS];
		}
		}]];

		[actionSheet addAction:[UIAlertAction actionWithTitle:@"Delete All Alarms" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
		if ([isDialogDeleteAll boolValue] && [isDialogNeeded boolValue]) {
			[self executeWithDialog:DELETEALL
			      message:DELETE_ALL_ALARMS_MSG];
		}
		else {
			[self editAllAlarms:DELETEALL];
		}
		}]];
	
	[self presentViewController:actionSheet animated:YES completion:nil];    
	return;                    							 
}

%end