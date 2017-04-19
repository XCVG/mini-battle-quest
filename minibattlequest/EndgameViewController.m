/*===========================================================================================
 EndgameViewController
 
 Displays the results of a game.
 
 @author Erick Fernandez de Arteaga - https://www.linkedin.com/in/erickfda
 @version 0.1.0
 @file
 
 ===========================================================================================*/

/*===========================================================================================
	Dependencies
 ===========================================================================================*/
#import "EndgameViewController.h"

/*===========================================================================================
	EndgameViewController
 ===========================================================================================*/
/**
	Displays the results of a game.
 */
@interface EndgameViewController ()
{
    /*=======================================================================================
        Instance Variables
     =======================================================================================*/
}

/*===========================================================================================
    Instance Properties
 ===========================================================================================*/
@property (weak, nonatomic) IBOutlet UILabel *endgameText;

@end

@implementation EndgameViewController
{
    
}

/*===========================================================================================
    Property Synthesizers
 ===========================================================================================*/

/*===========================================================================================
	Instance Methods
 ===========================================================================================*/
/**
    Display the endgame text and score;
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self)
    {
        _endgameText.text = _textToDisplay;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

/**
    Return to the main menu when the return button is tapped.
 */
- (IBAction)onReturnToMenuButton:(UIButton *)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
