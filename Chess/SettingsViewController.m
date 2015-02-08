//
//  SettingsViewController.m
//  Chess
//
//  Created by Sergey Seitov on 08.02.15.
//  Copyright (c) 2015 Sergey Seitov. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

- (IBAction)done:(id)sender;

@end

@implementation SettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)setLevel:(UISwitch*)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"strongLevel"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setSound:(UISwitch*)sender
{
	[[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"enableSound"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"settingsCell" forIndexPath:indexPath];
	UILabel *label = (UILabel*)[cell viewWithTag:1];
	UISwitch *check = (UISwitch*)[cell viewWithTag:2];
	switch (indexPath.row) {
		case 0:
			label.text = @"Strong game level";
			check.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"strongLevel"];
			if (check.allTargets.count == 0) {
				[check addTarget:self action:@selector(setLevel:) forControlEvents:UIControlEventValueChanged];
			}
			break;
		case 1:
			label.text = @"Enable sound on turn";
			check.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"enableSound"];
			if (check.allTargets.count == 0) {
				[check addTarget:self action:@selector(setSound:) forControlEvents:UIControlEventValueChanged];
			}
			break;
		default:
			break;
	}
    return cell;
}

- (IBAction)done:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:^(){}];
}

@end
