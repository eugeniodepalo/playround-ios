//
//  PRPlayViewController.m
//  Playround
//
//  Created by Eugenio Depalo on 5/27/13.
//  Copyright (c) 2013 Eugenio Depalo. All rights reserved.
//

#import "PRPlayViewController.h"
#import "PRGame.h"
#import "PRRound.h"
#import "PRTeam.h"
#import "PRPickerTableViewCell.h"
#import "PRSegmentedTableViewCell.h"

enum {
    kGameSection = 0,
    kTeamSection,
    kPlayersSection
};

@interface PRPlayViewController ()

@property (nonatomic, strong) PRRound *round;
@property (nonatomic, strong) PRGame *game;
@property (nonatomic, strong) NSArray *games;
@property (nonatomic, strong) NSArray *sections;
@property (nonatomic, weak) PRPickerTableViewCell *gamePickerCell;
@property (nonatomic, weak) PRSegmentedTableViewCell *teamCell;

- (IBAction)didTouchCancelBarButtonItem:(id)sender;
- (void)updateTeamsAnimated:(BOOL)animated previousGame:(PRGame *)game;
- (void)updateTeamSegments;
- (void)setGame:(PRGame *)game animated:(BOOL)animated;

@end

@implementation PRPlayViewController

- (PRGame *)game {
    return self.round.game;
}

- (void)setGame:(PRGame *)game {
    [self setGame:game animated:NO];
}

- (void)setGame:(PRGame *)game animated:(BOOL)animated {
    PRGame *previousGame = self.round.game;
    self.round.game = game;
    
    if(![previousGame.objectID isEqualToString:game.objectID])
        [self updateTeamsAnimated:animated previousGame:previousGame];
}

- (void)awakeFromNib {
    self.round = [[PRRound alloc] init];
}

- (IBAction)didTouchCancelBarButtonItem:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)updateTeamsAnimated:(BOOL)animated previousGame:(PRGame *)previousGame {
    if([self.tableView.visibleCells containsObject:self.teamCell]) {
        [self updateTeamSegments];
    }
    
    NSInteger sectionsToAdd = self.game.teams.count - previousGame.teams.count;
    NSInteger sectionsToReload = previousGame.teams.count;
    
    [self.tableView beginUpdates];
    
    if(sectionsToAdd > 0) {
        [self.tableView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(previousGame.teams.count - 1 + kPlayersSection, sectionsToAdd)] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        NSMutableArray *rowIndexPaths = [NSMutableArray array];
        
        for(NSInteger i = previousGame.teams.count; i < previousGame.teams.count + sectionsToAdd; i++) {
            PRTeam *team = self.game.teams[i];
            
            for(NSInteger j = 0; j < team.numberOfPlayers; j++)
                [rowIndexPaths addObject:[NSIndexPath indexPathForRow:j inSection:i + kPlayersSection]];
        }
        
        [self.tableView insertRowsAtIndexPaths:rowIndexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else if(sectionsToAdd < 0) {
        sectionsToReload += sectionsToAdd;
        
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(previousGame.teams.count - 1 + sectionsToAdd + kPlayersSection, sectionsToAdd)] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    if(sectionsToReload > 0)
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(kPlayersSection, sectionsToReload)] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.tableView endUpdates];
}

- (void)updateTeamSegments {
    [self.teamCell.segmentedControl removeAllSegments];
    
    for(NSInteger i = 0; i < self.game.teams.count; i++) {
        PRTeam *team = self.game.teams[i];
        [self.teamCell.segmentedControl insertSegmentWithTitle:team.displayName atIndex:i animated:YES];
    }
    
    self.teamCell.segmentedControl.selectedSegmentIndex = 0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(!self.games) {
        [PRGame allWithCompletion:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult, NSError *error) {
            if(!error) {
                self.games = mappingResult.array;
                self.game = self.games[0];
                
                if([self.tableView.visibleCells containsObject:self.gamePickerCell])
                    [self.gamePickerCell.pickerView reloadAllComponents];
            } else {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error while fetching games"
                                                                    message:error.localizedDescription
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                
                [alertView show];
            }
        }];
    }
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.games.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    PRGame *game = self.games[row];
    return game.displayName;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.game = self.games[row];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2 + self.game.teams.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch(section) {
        case kGameSection: return 1;
        case kTeamSection: return 1;
        default: {
            PRTeam *team = self.game.teams[section - 2];
            return 1 + team.numberOfPlayers;
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch(section) {
        case kGameSection: return @"Game";
        case kTeamSection: return @"Your Team";
        default: {
            PRTeam *team = self.game.teams[section - 2];
            return team.displayName;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    switch(indexPath.section) {
        case kGameSection: {
            PRPickerTableViewCell *pickerCell = [tableView dequeueReusableCellWithIdentifier:@"Game" forIndexPath:indexPath];
            
            pickerCell.pickerView.delegate = self;
            pickerCell.pickerView.dataSource = self;
            
            cell = pickerCell;
            self.gamePickerCell = pickerCell;
            
            break;
        }
        case kTeamSection: {
            PRSegmentedTableViewCell *segmentedCell = [tableView dequeueReusableCellWithIdentifier:@"Team" forIndexPath:indexPath];
            
            cell = segmentedCell;
            self.teamCell = segmentedCell;
            [self updateTeamSegments];
            
            break;
        }
        default: {
            if(indexPath.row == 0)
                cell = [tableView dequeueReusableCellWithIdentifier:@"Players" forIndexPath:indexPath];
            else
                cell = [UITableViewCell new];
            
            break;
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch(indexPath.section) {
        case kGameSection: return 216;
        default: return 44;
    }
}

@end
