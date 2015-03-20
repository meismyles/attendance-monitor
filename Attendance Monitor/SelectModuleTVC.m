//
//  SelectModuleTVC.m
//  Attendance Monitor
//
//  Created by Myles Ringle on 29/03/2014.
//  Copyright (c) 2014 Myles Ringle. All rights reserved.
//

#import "SelectModuleTVC.h"

@interface SelectModuleTVC () {
    NSMutableArray *yearsArray;
}

@property (strong, nonatomic) NSMutableArray *moduleList;

@end

@implementation SelectModuleTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    [[self navigationItem] setTitle:@"Select Modules"];
    
    _yearPicker.bounds = CGRectMake([self yearPicker].frame.origin.x, [self yearPicker].frame.origin.x,
               [self yearPicker].frame.size.width, 162);
    _yearPicker.backgroundColor = [UIColor groupTableViewBackgroundColor];
    _yearPicker.delegate = self;
    _yearPicker.dataSource = self;
    yearsArray = [[NSMutableArray alloc] init];
    for (int i = 1; i <= [[self totalModuleList] count]; i++) {
        [yearsArray addObject:[NSString stringWithFormat:@"Year %d", i]];
    }
    
    [self setModuleList:[[self totalModuleList] objectAtIndex:[[self yearPicker] selectedRowInComponent:0]]];
    
    // Adding done button to the navigation controller to return to the main views.
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                   target:[self delegate] action:@selector(doneSelectModuleList:)];
    [[self navigationItem] setRightBarButtonItem:doneButton];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[[self moduleList] objectAtIndex:section] count];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    // Re-use table view cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSArray *semesterArray;
    if ([indexPath section] == 0) {
        // Get the semester array containing modules
        semesterArray = [[self moduleList] objectAtIndex:[indexPath section]];
    }
    else {
        // Get the semester array containing modules
        semesterArray = [[self moduleList] objectAtIndex:[indexPath section]];
    }
    NSDictionary *moduleDict = [semesterArray objectAtIndex:[indexPath row]];
    
    // Set the main text to be the module code and the subtitle to be the module title.
    [[cell textLabel] setText:[moduleDict objectForKey:@"code"]];
    [[cell detailTextLabel] setText:[moduleDict objectForKey:@"title"]];
    
    
    // Check if the module array's 3rd item is 0 or 1 to determine whether to display a
    // checkmark or not.
    if ([[moduleDict objectForKey:@"cmark"] intValue] == 1) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
    else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    // Set the title for each section
    NSString *sectionTitle = [NSString stringWithFormat:@"Semester %d", (int)section+1];
    return sectionTitle;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Get the array containing module details
    NSMutableArray *semesterArray = [[self moduleList] objectAtIndex:[indexPath section]];
    NSMutableDictionary *moduleDict = [semesterArray objectAtIndex:[indexPath row]];
    
    // Check if the module array's 3rd item is 0 or 1 to determine whether to display a
    // checkmark or not.
    if ([[moduleDict objectForKey:@"cmark"] intValue] == 1) {
        [moduleDict setObject:[NSNumber numberWithInt:0] forKey:@"cmark"];
    }
    else {
        [moduleDict setObject:[NSNumber numberWithInt:1] forKey:@"cmark"];
    }
    
    [[self tableView] reloadData];
}

#pragma mark - UIPickerView DataSource
// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [yearsArray count];
}

#pragma mark - UIPickerView Delegate
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    return 30.0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [yearsArray objectAtIndex:row];
}

//If the user chooses from the pickerview, it calls this function;
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    int selectedYear = (int)[[self yearPicker] selectedRowInComponent:0];
    [self setModuleList:[[self totalModuleList] objectAtIndex:selectedYear]];
    
    [[self tableView] reloadData];
    
}

@end
