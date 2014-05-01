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

#import "WindowSizer.h"
#import <Carbon/Carbon.h>

@implementation WindowSizer

-(void)chooseScreen{
    CGDirectDisplayID tempId[2];
    CGDisplayCount tempCount;
    CGError error = CGGetDisplaysWithRect(CGRectMake(_windowPosition.x, _windowPosition.y, _windowSize.width, _windowSize.height), 2, tempId, &tempCount);
    if(error == kCGErrorSuccess){
        CGRect screenBounds = CGDisplayBounds(tempId[0]);
        if(tempCount == 1){
            _screenPosition.x = screenBounds.origin.x;
            _screenPosition.y = screenBounds.origin.y;
            _screenSize.width = screenBounds.size.width;
            _screenSize.height = screenBounds.size.height;
        }else if (tempCount == 2) {
            CGRect screenBounds1 = CGDisplayBounds(tempId[1]);
            int screenChosen = 0;
            int delta = abs(screenBounds.origin.x - (_windowPosition.x+_windowSize.width));
            int delta2 = 0;
            if(delta > screenBounds.size.width){
                delta = abs(_windowPosition.x - (screenBounds.origin.x+screenBounds.size.width));
                delta2 = abs(_windowPosition.x+_windowSize.width - screenBounds1.origin.x);
            }else {
                delta2 = abs(_windowPosition.x - (screenBounds1.origin.x+screenBounds1.size.width));
            }
            if (delta2> delta) {
                screenChosen = 1;
            }
            if(screenChosen == 0){
                _screenPosition.x = screenBounds.origin.x;
                _screenPosition.y = screenBounds.origin.y;
                _screenSize.width = screenBounds.size.width;
                _screenSize.height = screenBounds.size.height;
            }else {
                _screenPosition.x = screenBounds1.origin.x;
                _screenPosition.y = screenBounds1.origin.y;
                _screenSize.width = screenBounds1.size.width;
                _screenSize.height = screenBounds1.size.height;
            }
        }       
    }
}

-(void)getVisibleScreenParams
{
    NSArray * tempArray = [NSScreen screens];
    _numberOfScreens = [tempArray count];
    if (_numberOfScreens == 1 )
    {
        NSScreen * tempScreen = (NSScreen*)[tempArray objectAtIndex:0];
        _screenVisibleSize = tempScreen.visibleFrame.size;
        _screenVisiblePosition = tempScreen.visibleFrame.origin;
    }
    else
    {
        for(int i = 0;i<_numberOfScreens; i++)
        {
            NSScreen * tempScreen = (NSScreen*)[tempArray objectAtIndex:i];
            if (tempScreen.frame.origin.x == _screenPosition.x) 
            {
                _screenVisibleSize = tempScreen.visibleFrame.size;
                _screenVisiblePosition = tempScreen.visibleFrame.origin;
            }
            else
            {
                _otherScreenSize = tempScreen.visibleFrame.size;
                _otherScreenPosition = tempScreen.visibleFrame.origin;
            }
        }
    }

    
}

-(BOOL)getWindowParameters{
    NSLog(@"Get Window Parameter");
    BOOL error = FALSE;
	AXUIElementRef _focusedApp;
	CFTypeRef _position;
	CFTypeRef _size;
    
	AXUIElementCopyAttributeValue(_systemWideElement,(CFStringRef)kAXFocusedApplicationAttribute,(CFTypeRef*)&_focusedApp);
	if(AXUIElementCopyAttributeValue((AXUIElementRef)_focusedApp,(CFStringRef)NSAccessibilityFocusedWindowAttribute,(CFTypeRef*)&_focusedWindow) == kAXErrorSuccess)
    {
		if(CFGetTypeID(_focusedWindow) == AXUIElementGetTypeID())
        {
			if(AXUIElementCopyAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)&_position) != kAXErrorSuccess)
            {
				NSLog(@"Can't Retrieve Window Position");
                error = TRUE;
			}
            else
            {
                if(AXValueGetType(_position) == kAXValueCGPointType)
                {
                    AXValueGetValue(_position, kAXValueCGPointType, (void*)&_windowPosition);
                    NSLog(@"position x:%f, y:%f", _windowPosition.x, _windowPosition.y);
                }
                else
                {
                    error = TRUE;
                }                
            }

			if(AXUIElementCopyAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)&_size) != kAXErrorSuccess)
            {
				NSLog(@"Can't Retrieve Window Size");
                error = TRUE;
			}
            else
            {
                if(AXValueGetType(_size) == kAXValueCGSizeType)
                {
                    AXValueGetValue(_size, kAXValueCGSizeType, (void*)&_windowSize);
                    NSLog(@"size width:%f, height:%f", _windowSize.width, _windowSize.height);
                }
                else
                {
                    error = TRUE;
                }
            }
		}
	}
    else
    {
		NSLog(@"Problem with App");
	}
    if(!error)
    {
		_menuBarHeight = GetMBarHeight();
        [self chooseScreen];
        NSLog(@"Get Window Parameter Success");
    }
    else
    {
        NSLog(@"Get Window Parameter Failed");
    }
    return !error;
}


bool fuzzyEquals(const float a, const float b)
{
    if( fabsf( a - b ) < 0.1f )
    {
        return true;
    }
    return false;
}


// ASH: Move windows
-(IBAction)shiftLeft:(id)sender
{
    NSLog(@"Shifting To Left Half");
	if([self getWindowParameters])
    {
		[self getVisibleScreenParams];
        CFTypeRef _position;
        CFTypeRef _size;
        
        float targetX, targetY;
		targetX = _screenVisiblePosition.x;

        float targetSizeX = _screenVisibleSize.width*0.8f;
        if( _windowSize.width == targetSizeX || targetX != _windowPosition.x || _windowSize.height != _screenVisibleSize.height )
        {
            targetSizeX = _screenVisibleSize.width*0.5f;
        }

        _windowSize.width = targetSizeX;
        _windowSize.height = _screenVisibleSize.height;

        _windowPosition.x = targetX;

		if( _screenVisiblePosition.y >= 0 )
        {
            targetY = _menuBarHeight;
        }
        else
        {
            targetY = _otherScreenSize.height + _menuBarHeight;
        }

        _windowPosition.y = targetY;
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&_windowPosition));
        
        _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&_windowSize));					
        NSLog(@"size2 width:%f, height:%f", _windowSize.width, _windowSize.height);

		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess)
        {
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess)
        {
			NSLog(@"Size cannot be modified");
		}
        
        [self getWindowParameters];
    }
    NSLog(@"Shifted To Left Half");
    _focusedWindow = NULL;
}


-(IBAction)shiftRight:(id)sender
{
    NSLog(@"Shifting To Right Half");
	if([self getWindowParameters])
    {
		[self getVisibleScreenParams];
        CFTypeRef _position;
        CFTypeRef _size;

        float targetX, targetY;
        float targetSizeX = _screenVisibleSize.width*0.8f;
        targetX = _screenVisiblePosition.x + _screenVisibleSize.width - targetSizeX;
        if( fuzzyEquals( _windowSize.width, targetSizeX ) || targetX != _windowPosition.x || _windowSize.height != _screenVisibleSize.height )
        {
            targetSizeX = _screenVisibleSize.width*0.5f;
            if( fuzzyEquals( _windowSize.width, targetSizeX ) &&
                ( _windowPosition.x > ( _windowSize.width * 0.5f ) ) &&
                ( _windowSize.height == _screenVisibleSize.height ) )
            {
                targetSizeX = _screenVisibleSize.width*0.8f;
            }
        }
        targetX = ( _screenVisiblePosition.x / 2 ) + _screenVisibleSize.width - targetSizeX;

        _windowSize.width = targetSizeX;
        _windowSize.height = _screenVisibleSize.height;
        _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&_windowSize));

		_windowPosition.x = targetX;

        if( _screenVisiblePosition.y >= 0 )
        {
            targetY = _menuBarHeight;
        }
        else
        {
            targetY = _otherScreenSize.height + _menuBarHeight;
        }

        _windowPosition.y = targetY;
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&_windowPosition));

		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess)
        {
			NSLog(@"Size cannot be modified");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess)
        {
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess)
        {
			NSLog(@"Size cannot be modified");
		}

		if([self getWindowParameters])
        {
            [self getVisibleScreenParams];

            _windowPosition.x = _screenVisiblePosition.x + _screenVisibleSize.width - _windowSize.width;
            _position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&_windowPosition));
            _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&_windowSize));
            
            if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess)
            {
                NSLog(@"Position cannot be changed");
            }
            if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess)
            {
                NSLog(@"Size cannot be modified");
            }
        }
    }
    NSLog(@"Shifted To Right Half");
    _focusedWindow = NULL;
}

-(IBAction)shiftUp:(id)sender
{
    NSLog(@"Shifting To Top Half");
	if([self getWindowParameters])
    {
		[self getVisibleScreenParams];
        CFTypeRef _position;
        CFTypeRef _size;

        float targetPositionY;
		if( _numberOfScreens > 1 && _screenVisiblePosition.y != 0.0f )
        {
            targetPositionY = _otherScreenSize.height + _menuBarHeight;
        }
        else
        {
            targetPositionY = -_screenVisiblePosition.y + _menuBarHeight;
        }

        float targetHeight = (_screenVisibleSize.height/2);

        if( _numberOfScreens > 1 && _screenVisiblePosition.y != 0.0f && _windowPosition.y == targetPositionY && _windowSize.height == targetHeight )
        {
            _windowPosition.y -= _otherScreenSize.height / 2;
            _position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&_windowPosition));

            _windowSize.height = (_screenVisibleSize.height/2);
            _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&_windowSize));

            if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess)
            {
                NSLog(@"Position cannot be changed");
            }
            if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess)
            {
                NSLog(@"Size cannot be modified");
            }

            if( _windowPosition.x < _windowSize.width/2 )
            {
                [self shiftLeft:NULL];
            }
            else
            {
                [self shiftRight:NULL];
            }
        }
        else
        {
            _windowPosition.y = targetPositionY;
            _position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&_windowPosition));
            
            _windowSize.height = targetHeight;
            _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&_windowSize));					
            
            if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess)
            {
                NSLog(@"Position cannot be changed");
            }
            if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess)
            {
                NSLog(@"Size cannot be modified");
            }
        }
    }
    NSLog(@"Shifted To Top Half");
    _focusedWindow = NULL;
    
}

-(IBAction)shiftDown:(id)sender
{
    NSLog(@"Shifting To Bottom Half");
	if([self getWindowParameters])
    {
		[self getVisibleScreenParams];
        
        CFTypeRef _position;
        CFTypeRef _size;

        float targetPositionY;
		if( _numberOfScreens > 1 && _screenVisiblePosition.y != 0.0f )
        {
            targetPositionY = _otherScreenSize.height + _menuBarHeight + (_screenVisibleSize.height/2);
        }
        else
        {
            targetPositionY = _screenVisiblePosition.y + (_screenSize.height/2);
        }

        float targetHeight = (_screenSize.height/2);

        if( _numberOfScreens > 1 && _screenVisiblePosition.y == 0.0f && _windowPosition.y == targetPositionY && _windowSize.height == targetHeight )
        {
            _windowPosition.y += _screenSize.height / 2;
            _position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&_windowPosition));

            _windowSize.height = (_screenVisibleSize.height/2);
            _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&_windowSize));

            if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess)
            {
                NSLog(@"Position cannot be changed");
            }
            if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess)
            {
                NSLog(@"Size cannot be modified");
            }

            if( _windowPosition.x < _windowSize.width/2 )
            {
                [self shiftLeft:NULL];
            }
            else
            {
                [self shiftRight:NULL];
            }
        }
        else
        {
            _windowPosition.y = targetPositionY;
            _position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&_windowPosition));
            
            _windowSize.height = targetHeight;
            _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&_windowSize));					

            if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess)
            {
                NSLog(@"Size cannot be modified");
            }
            if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess)
            {
                NSLog(@"Position cannot be changed");
            }
            if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess)
            {
                NSLog(@"Size cannot be modified");
            }
        }
    }
    NSLog(@"Shifted To Bottom Half");
    _focusedWindow = NULL;
}

// ASH: Switch monitors
-(IBAction)shiftToLeftMonitor:(id)sender
{
    NSLog(@"Shifting To Left Monitor");

	if([self getWindowParameters]){
		[self getVisibleScreenParams];
        CFTypeRef _position;
        CFTypeRef _size;

		_windowPosition.x = _screenVisiblePosition.x;

        // ASH: A quick hack does the job
        _windowPosition.x = _screenVisiblePosition.x -(_screenVisibleSize.width);
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&_windowPosition));

        _windowSize.width = ((_screenVisibleSize.width));
        _windowSize.height = _screenVisibleSize.height;
        _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&_windowSize));
        NSLog(@"size2 width:%f, height:%f", _windowSize.width, _windowSize.height);

		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}

        [self fullScreen:sender];
    }
    NSLog(@"Shifted To Left Half");
    _focusedWindow = NULL;

}

-(IBAction)shiftToRightMonitor:(id)sender{
    NSLog(@"Shifting To Right Monitor");
	if([self getWindowParameters]){
		[self getVisibleScreenParams];
        CFTypeRef _position;
        CFTypeRef _size;
		_windowPosition.x = _screenVisiblePosition.x +(_screenVisibleSize.width);
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&_windowPosition));

        _windowSize.width = ((_screenVisibleSize.width));
        _windowSize.height = _screenVisibleSize.height;
        _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&_windowSize));

		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}

        [self fullScreen:sender];
    }
    NSLog(@"Shifted To Right Half");
    _focusedWindow = NULL;

}


-(IBAction)shiftToCenter:(id)sender{
    NSLog(@"Shifting To Center");
	if([self getWindowParameters]){
        [self getVisibleScreenParams];
        
        CFTypeRef _position;
        
		_windowPosition.x = _screenVisiblePosition.x+(_screenVisibleSize.width/2)-(_windowSize.width/2);
		_windowPosition.y = ((_screenVisiblePosition.x ==0)? _menuBarHeight:0)+(_screenVisibleSize.height/2)-(_windowSize.height/2);
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&_windowPosition));
        
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
    }
    NSLog(@"Shifted To Center");
    _focusedWindow = NULL;
}

-(IBAction)fullScreen:(id)sender{
    NSLog(@"Shifting To Full Screen");
	if([self getWindowParameters]){
        [self getVisibleScreenParams];
        CFTypeRef _position;
        CFTypeRef _size;
        
		_windowPosition.x = _screenVisiblePosition.x;
		if( _screenVisiblePosition.y >= 0 )
        {
            _windowPosition.y = -_screenVisiblePosition.y;
        }
        else
        {
            _windowPosition.y = _otherScreenSize.height + _menuBarHeight;
        }
		_position = (CFTypeRef)(AXValueCreate(kAXValueCGPointType, (const void *)&_windowPosition));
		
        _windowSize.width = _screenVisibleSize.width;
        _windowSize.height = _screenVisibleSize.height;
        _size = (CFTypeRef)(AXValueCreate(kAXValueCGSizeType, (const void *)&_windowSize));					
        
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilityPositionAttribute,(CFTypeRef*)_position) != kAXErrorSuccess){
			NSLog(@"Position cannot be changed");
		}
		if(AXUIElementSetAttributeValue((AXUIElementRef)_focusedWindow,(CFStringRef)NSAccessibilitySizeAttribute,(CFTypeRef*)_size) != kAXErrorSuccess){
			NSLog(@"Size cannot be modified");
		}
    }
    NSLog(@"Shifted To Full Screen");
    _focusedWindow = NULL;
}

-(WindowSizer *)init{
	if(self = [super init]){;
		_systemWideElement = AXUIElementCreateSystemWide();
        _numberOfScreens = 1;
	}
	return self;
}

@end
