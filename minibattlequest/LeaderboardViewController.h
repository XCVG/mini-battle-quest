/*===========================================================================================
    LeaderboardViewController                                                           *//**
                                                                                        
    Displays the list of high scores in a UITableView.
                                                                                        
    @author Erick Fernandez de Arteaga - https://www.linkedin.com/in/erickfda
    @version 0.1.0
    @file
                                                                                        
*//*=======================================================================================*/

/*===========================================================================================
	Dependencies
 ===========================================================================================*/
#import <Foundation/Foundation.h>
#import "CoreDataTableViewController.h"

/*===========================================================================================
	LeaderboardViewController
 ===========================================================================================*/
/**
	Displays the list of high scores in a UITableView.
 */
@interface LeaderboardViewController : CoreDataTableViewController
{
    /*=======================================================================================
        Instance Variables
     =======================================================================================*/
    
    
}

/*===========================================================================================
    Instance Properties
 ===========================================================================================*/
@property (nonatomic, strong) UIManagedDocument *managedDocument;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

/*===========================================================================================
	Instance Methods
 ===========================================================================================*/


@end
