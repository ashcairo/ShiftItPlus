/*
 ShiftIt: Resize windows with Hotkeys
 Copyright (C) 2010  Aravind
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 */


#import "Preferences.h"

OSStatus winSizer(EventHandlerCallRef nextHandler,EventRef theEvent,void *userData){
	//Do something once the key is pressed
	EventHotKeyID hotKeyID;
	GetEventParameter(theEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,sizeof(hotKeyID),NULL,&hotKeyID);
	int temphotKeyId = hotKeyID.id;
	switch (temphotKeyId) {

            // ASH: Link keys to window movement
		case 1:
			[(WindowSizer*)userData shiftLeft:NULL];
			break;
		case 2:
			[(WindowSizer*)userData shiftRight:NULL];
			break;
		case 3:
			[(WindowSizer*)userData shiftUp:NULL];
			break;
		case 4:
			[(WindowSizer*)userData shiftDown:NULL];
			break;
        case 5:
			[(WindowSizer*)userData shiftToLeftMonitor:NULL];
			break;
        case 6:
			[(WindowSizer*)userData shiftToRightMonitor:NULL];
            break;

		case 9:
			[(WindowSizer*)userData shiftToCenter:NULL];
			break;
		case 10:
			[(WindowSizer*)userData fullScreen:NULL];
			break;
		default:
			break;
	}	
	return noErr;
}

@implementation Preferences

-(id)init{
	if(self == [super init]){
		_hKeyController = [hKController getInstance];
		_winSizer = [[WindowSizer alloc] init];
		_eventType.eventClass = kEventClassKeyboard;
		_eventType.eventKind = kEventHotKeyPressed;
		InstallApplicationEventHandler(&winSizer,1,&_eventType,_winSizer,NULL);
        [self registerDefaults];
	}
	return self;
}

-(void)registerDefaults{
    [NSUserDefaults resetStandardUserDefaults];
    NSLog(@"Registering default");
    
    
    _userDefaultsValuesDict = [NSMutableDictionary dictionary];
    
    // ASH: Customize keys and switch monitors
    int leftKey = 123;          // <-
    int rightKey = 124;         // ->
    int topKey = 126;           // /\/
    int bottomKey = 125;        // \/
    
    // For splitting screen
    {
        NSNumber *triggerKeys = [NSNumber numberWithUnsignedInt:(NSControlKeyMask+NSAlternateKeyMask)];
        
        NSDictionary * leftHalf = [NSDictionary dictionaryWithObjectsAndKeys:
                                   triggerKeys,HotKeyModifers,
                                   [NSNumber numberWithUnsignedInt:leftKey],HotKeyCodes,
                                   nil];
        [_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:1 
                                                                    keyCode:leftKey 
                                                                   modCombo:triggerKeys]];
        [_userDefaultsValuesDict setObject:leftHalf forKey:@"leftHalf"];
        
        NSDictionary * rightHalf = [NSDictionary dictionaryWithObjectsAndKeys:
                                    triggerKeys,HotKeyModifers,
                                    [NSNumber numberWithUnsignedInt:rightKey],HotKeyCodes,
                                    nil];
        [_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:2 
                                                                    keyCode:rightKey 
                                                                   modCombo:triggerKeys]];
        [_userDefaultsValuesDict setObject:rightHalf forKey:@"rightHalf"];
    }
    
    {
        NSNumber *triggerKeys = [NSNumber numberWithUnsignedInt:(NSControlKeyMask+NSAlternateKeyMask)];
        
        NSDictionary * topHalf = [NSDictionary dictionaryWithObjectsAndKeys:
                                    triggerKeys,HotKeyModifers,
                                    [NSNumber numberWithUnsignedInt:rightKey],HotKeyCodes,
                                    nil];
        [_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:3
                                                                    keyCode:topKey 
                                                                   modCombo:triggerKeys]];
        [_userDefaultsValuesDict setObject:topHalf forKey:@"topHalf"];
        
        NSDictionary * bottomHalf = [NSDictionary dictionaryWithObjectsAndKeys:
                                  triggerKeys,HotKeyModifers,
                                  [NSNumber numberWithUnsignedInt:rightKey],HotKeyCodes,
                                  nil];
        [_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:4
                                                                    keyCode:bottomKey 
                                                                   modCombo:triggerKeys]];
        [_userDefaultsValuesDict setObject:bottomHalf forKey:@"bottomHalf"];
    }
    
    // For moving to secondary monitor
    {
        NSNumber *triggerKeys = [NSNumber numberWithUnsignedInt:(NSControlKeyMask+NSAlternateKeyMask+NSCommandKeyMask)];
        
        NSDictionary * leftHalf = [NSDictionary dictionaryWithObjectsAndKeys:
                                   triggerKeys,HotKeyModifers,
                                   [NSNumber numberWithUnsignedInt:leftKey],HotKeyCodes,
                                   nil];
        [_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:5 keyCode:leftKey modCombo:triggerKeys]];
        [_userDefaultsValuesDict setObject:leftHalf forKey:@"leftHalf"];
        
        NSDictionary * rightHalf = [NSDictionary dictionaryWithObjectsAndKeys:
                                    triggerKeys,HotKeyModifers,
                                    [NSNumber numberWithUnsignedInt:rightKey],HotKeyCodes,
                                    nil];
        [_hKeyController registerHotKey:[[SIHotKey alloc]initWithIdentifier:6 keyCode:rightKey modCombo:triggerKeys]];
        [_userDefaultsValuesDict setObject:rightHalf forKey:@"rightHalf"];
    }
	
    [_userDefaultsValuesDict setObject:[NSNumber numberWithBool:YES] forKey:@"shiftItstartLogin"];
    [_userDefaultsValuesDict setObject:[NSNumber numberWithBool:YES] forKey:@"shiftItshowMenu"];
	
	[[NSUserDefaults standardUserDefaults] registerDefaults:_userDefaultsValuesDict];
	[[NSUserDefaults standardUserDefaults] synchronize];
    
    NSArray *resettableUserDefaultsKeys;
    NSDictionary * initialValuesDict;
    resettableUserDefaultsKeys=[NSArray arrayWithObjects:@"leftHalf",@"topHalf",@"bottomHalf",@"rightHalf",@"bottomLeft",@"bottomRight",@"topLeft",@"topRight",@"fullScreen",@"center",nil];
	
    initialValuesDict=[[NSUserDefaults standardUserDefaults] dictionaryWithValuesForKeys:resettableUserDefaultsKeys];
    
    // Set the initial values in the shared user defaults controller
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:initialValuesDict];
	
    
}

-(void)modifyHotKey:(NSInteger)newKey modiferKeys:(NSInteger)modKeys key:(NSString*)keyCode{
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:newKey] forKey:[@"hkc" stringByAppendingString:keyCode]];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:modKeys] forKey:[@"hkm" stringByAppendingString:keyCode]];
	[_hKeyController modifyHotKey:[[SIHotKey alloc]initWithIdentifier:[[_userDefaultsValuesDict objectForKey:keyCode] intValue] keyCode:newKey modCombo:[NSNumber numberWithUnsignedInt:modKeys]]];
	[[NSUserDefaults standardUserDefaults] synchronize];	
}

-(void)dealloc{
    [_winSizer release];
    [_hKeyController release];
	[_userDefaultsValuesDict release];
    [super dealloc];
}
@end
