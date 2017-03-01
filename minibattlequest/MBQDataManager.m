/*========================================================================================
    MBQDataManager
	
	Provides global access to a common UIManagedDocument context.
	
	@author Erick Fernandez de Arteaga - https://www.linkedin.com/in/erickfda
	@version 0.1.0
	@file
	
 ========================================================================================*/

/*========================================================================================
	Dependencies
 ========================================================================================*/
#import "MBQDataManager.h"
#import <CoreData/CoreData.h>

/*========================================================================================
	MBQDataManager
 ========================================================================================*/
/**
 Provides global access to a common UIManagedDocument context.
 */
@interface MBQDataManager()
{
    /*------------------------------------------------------------------------------------
        Instance Variables
     ------------------------------------------------------------------------------------*/
    
    
}

/*----------------------------------------------------------------------------------------
    Instance Properties
 ----------------------------------------------------------------------------------------*/


/*----------------------------------------------------------------------------------------
    Private Instance Methods
 ----------------------------------------------------------------------------------------*/
- (void)objectsDidChange:(NSNotification *)notification;
- (void)contextDidSave:(NSNotification *)notification;

@end

@implementation MBQDataManager

/*----------------------------------------------------------------------------------------
    Property Synthesizers
 ----------------------------------------------------------------------------------------*/
@synthesize document;
static MBQDataManager *_sharedInstance;

/*----------------------------------------------------------------------------------------
	Class Methods
 ----------------------------------------------------------------------------------------*/
/**
    Returns a pointer to the singleton MBQDataManager instance.
 */
+ (MBQDataManager *)instance
{
    /* Initialize the shared instance only once. */
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

/*----------------------------------------------------------------------------------------
	Instance Methods
 ----------------------------------------------------------------------------------------*/
/**
    Set up the UIManagedDocument instance when the MBQDataManager instance is initialized.
 */
- (id)init
{
    self = [super init];
    if (self)
    {
        NSLog(@"Initializing MBQDataManager.");
        
        /* Initialize the document instance with its URL. */
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory
                                                             inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:@"MBQData.md"];
        self.document = [[UIManagedDocument alloc] initWithFileURL:url];
        NSLog(@"Global Managed Document: %@", self.document);
        
        /* Enable automatic migrations. */
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        self.document.persistentStoreOptions = options;
        
        /* Subscribe to notifications for when the shared context changes or is saved. */
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(objectsDidChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:self.document.managedObjectContext];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:self.document.managedObjectContext];
    }
    
    return self;
}

/**
    Performs the given block with the shared UIManagedDocument.
 */
- (void)performWithDocument:(OnDocumentReady)onDocumentReady
{
    void (^OnDocumentDidLoad) (BOOL) = ^(BOOL success)
    {
        onDocumentReady(self.document);
    };
    
    /* Create, open, and use the file for the shared UIManagedDocument. */
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.document.fileURL path]])
    {
        [self.document saveToURL:self.document.fileURL
                forSaveOperation:UIDocumentSaveForCreating
               completionHandler:OnDocumentDidLoad];
    }
    else if (self.document.documentState == UIDocumentStateClosed)
    {
        [self.document openWithCompletionHandler:OnDocumentDidLoad];
    }
    else if (self.document.documentState == UIDocumentStateNormal)
    {
        OnDocumentDidLoad(YES);
    }
}

/**
    Event handler for NSManagedObjectContextObjectsDidChangeNotification.
 */
- (void)objectsDidChange:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"NSManagedObjects did change.");
#endif
}

/**
    Event handler for NSManagedObjectContextDidSaveNotification.
 */
- (void)contextDidSave:(NSNotification *)notification
{
#ifdef DEBUG
    NSLog(@"NSManagedContext did save.");
#endif
}

@end
