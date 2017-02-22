/*========================================================================================
    MainMenuViewController
	
	Displays the main menu.
	
	@author Erick Fernandez de Arteaga - https://www.linkedin.com/in/erickfda
	@version 0.1.0
	@file
	
 ========================================================================================*/

/*========================================================================================
	Dependencies
 ========================================================================================*/
#import <Foundation/Foundation.h>
#import "MainMenuViewController.h"
#import "MBQDataManager.h"
#import "LeaderboardScore+Util.h"

@interface MainMenuViewController ()
{
    /*------------------------------------------------------------------------------------
        Instance Variables
     ------------------------------------------------------------------------------------*/
    
}

/*----------------------------------------------------------------------------------------
    Instance Properties
 ----------------------------------------------------------------------------------------*/


@end

@implementation MainMenuViewController
/*----------------------------------------------------------------------------------------
    Property Synthesizers
 ----------------------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------------------
	Instance Methods
 ----------------------------------------------------------------------------------------*/
-(void)viewDidLoad
{
    /* On load, hide the navigation bar and enable swipe navigation. */
    [self.navigationController setNavigationBarHidden:YES];
    [self.navigationController.interactivePopGestureRecognizer setDelegate:nil];
}

@end
