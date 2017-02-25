/*===========================================================================================
    LeaderboardViewController
 
    Displays the list of high scores in a UITableView.
 
    @author Erick Fernandez de Arteaga - https://www.linkedin.com/in/erickfda
    @version 0.1.0
    @file
 
 ===========================================================================================*/

/*===========================================================================================
	Dependencies
 ===========================================================================================*/
#import "LeaderboardViewController.h"
#import "LeaderboardScore+CoreDataClass.h"
#import "MBQDataManager.h"

/*===========================================================================================
	LeaderboardViewController
 ===========================================================================================*/
/**
    Displays the list of high scores in a UITableView.
 */
@interface LeaderboardViewController()
{
    /*=======================================================================================
        Instance Variables
     =======================================================================================*/
    
    
}

/*===========================================================================================
    Instance Properties
 ===========================================================================================*/

@end

@implementation LeaderboardViewController

/*===========================================================================================
    Property Synthesizers
 ===========================================================================================*/
@synthesize managedObjectContext;

/*===========================================================================================
	Instance Methods
 ===========================================================================================*/
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    /* Get the global UIManagedContext. */
    if(!managedObjectContext)
    {
        NSLog(@"Getting global UIManagedContext.");
        
        [[MBQDataManager instance] performWithDocument:^(UIManagedDocument *document) {
            [self setManagedObjectContext:document.managedObjectContext];
        }];
    }
    
    NSLog(@"Managed Object Context: %@", managedObjectContext);
}

/**
    Returns the table cell for the given row.
 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"LeaderboardScore Cell"];
    LeaderboardScore *cellScore = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%d", cellScore.score];
    
    return cell;
}

/**
    Sets the NSManagedObjectContext for this view controller
    and creates an appropriate fetch request.
 */
- (void)setManagedObjectContext:(NSManagedObjectContext *)context
{
    managedObjectContext = context;
    
    NSFetchRequest *request = [LeaderboardScore fetchRequest];
    request.predicate = nil;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"score"
                                                              ascending:NO
                                                               selector:@selector(compare:)]];
    request.fetchLimit = 50;
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc]
                                     initWithFetchRequest:request
                                     managedObjectContext:managedObjectContext
                                     sectionNameKeyPath:nil
                                     cacheName:nil];
}

@end
