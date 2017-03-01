/*===========================================================================================
    LeaderboardScore+Util                                                               *//**

    Adds basic utilities to the LeaderboardScore class.

    @author Erick Fernandez de Arteaga - https://www.linkedin.com/in/erickfda
    @version 0.1.0
    @file

*//*=======================================================================================*/

/*===========================================================================================
	Dependencies
 ===========================================================================================*/
#import "LeaderboardScore+Util.h"

/*===========================================================================================
	LeaderboardScore+Util
 ===========================================================================================*/
/**
    Adds basic utilities to the LeaderboardScore class.
 */
@interface LeaderboardScore (Util)
{
    /*=======================================================================================
        Instance Variables
     =======================================================================================*/


}

/*===========================================================================================
    Instance Properties
 ===========================================================================================*/


@end

@implementation LeaderboardScore (Util)

/*===========================================================================================
    Property Synthesizers
 ===========================================================================================*/


/*===========================================================================================
	Class Methods
 ===========================================================================================*/
+ (LeaderboardScore *)addScoreWithValue:(int)value inManagedObjectContext:(NSManagedObjectContext *)context
{
    LeaderboardScore * newScore = nil;

    /* Create the new score and set its value. */
    newScore = [NSEntityDescription insertNewObjectForEntityForName:@"LeaderboardScore"
                                             inManagedObjectContext:context];
    newScore.score = value;

    return newScore;
}

/*===========================================================================================
	Instance Methods
 ===========================================================================================*/

@end
