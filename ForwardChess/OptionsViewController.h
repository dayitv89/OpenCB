@protocol OptionsViewControllerDelegate <NSObject>

-(void) notesDidClicked;
-(void) bookmarkDidClicked;
-(void) optionsViewControllerDismissed;
-(void) optionsViewControllerChangedBoardStyle;
-(void) optionViewControllerCoordChanged;

@end

@interface OptionsViewController : UIViewController<UITextViewDelegate>
{
    @private
        IBOutlet UISlider *fontSizeSlider;
        IBOutlet UISlider *boardSizeSlider;
        IBOutlet UISwitch *autoscrollSwitch;
        IBOutlet UISwitch *_coordSwitch;
        IBOutlet UISegmentedControl *_orientationControl;

        IBOutlet UISegmentedControl * figuresSegmentedControl;
        IBOutlet UISegmentedControl * boardSegmentedControl;
}

@property(weak) id<OptionsViewControllerDelegate> delegate;

@end