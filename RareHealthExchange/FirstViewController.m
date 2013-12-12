//
//  FirstViewController.m
//  RareHealthExchange
//
//  Created by Matt McGlynn on 11/14/13.
//  Copyright (c) 2013 Matt McGlynn. All rights reserved.
//

#import "FirstViewController.h"

@interface FirstViewController ()
@property (weak, nonatomic) IBOutlet UITableView *ResultsTable;
@property (weak, nonatomic) IBOutlet UITextField *SearchText;
@property (weak, nonatomic) IBOutlet UILabel *PromptLabel;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIButton *AddDate;
@property NSMutableArray *testArray;
@property NSMutableDictionary *patientDictionary;
@property NSMutableDictionary *visitDates;
@property NSMutableDictionary *diseaseDictionary;
@property NSMutableDictionary *symptomNameAndID;
@property NSMutableDictionary *symptomSeverityDescriptionAndID;
@property NSMutableDictionary *symptomNameAndSeverityDescriptions;
@property NSMutableDictionary *symptomSeverityIDForSymptomID;
@property (weak, nonatomic) IBOutlet UIWebView *PatientWebView;

@property bool Authenticated;
@property NSURLRequest * FailedRequest;
@property NSString  *BaseRequest;
@property bool hasBeenDone;
@property NSString *data;
@property NSString *myPatientID;
@property NSString *myPatientName;
@property NSString *myVisitName;
@property NSString *myVisitID;
@property NSString *myDiseaseName;
@property NSString *myDiseaseID;
@property NSArray *symptomArray;
@property NSArray *jsonSymptomData;
@property NSUInteger currentSymptomIndex;
@property int mode;

@property NSString *pageHTML;
@property (weak, nonatomic) IBOutlet UIButton *BackButton;

@end

@implementation FirstViewController
- (IBAction)TextChange:(id)sender {
    
}
- (IBAction)NewTextChange:(id)sender {
    [self patientPostRequest];
}

- (void)viewDidLoad
{
    self.BackButton.hidden = true;
    self.mode = 0;
    self.testArray = [NSMutableArray new];
    self.patientDictionary = [NSMutableDictionary new];
    self.visitDates = [NSMutableDictionary new];
    self.diseaseDictionary = [NSMutableDictionary new];
    self.symptomNameAndID = [NSMutableDictionary new];
    self.symptomSeverityDescriptionAndID = [NSMutableDictionary new];
    self.symptomNameAndSeverityDescriptions = [NSMutableDictionary new];
    self.symptomSeverityIDForSymptomID = [NSMutableDictionary new];
    self.symptomArray = [NSArray new];
    self.jsonSymptomData = [NSArray new];
    self.ResultsTable.delegate = self;
    self.ResultsTable.dataSource = self;
    [self.ResultsTable reloadData];
    //NSLog@"%@",self.testArray);
    self.PatientWebView.delegate = self;
    NSString *fullURL = @"https://184.72.98.28/record.php";
    NSURL *url = [NSURL URLWithString:fullURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.PatientWebView loadRequest:requestObj];
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
   
}
- (IBAction)StartOver:(id)sender {
    [self startFresh];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)populateDiseaseDictionary{
    NSString *pageHtml = self.pageHTML;
    //NSLog@"%@",pageHtml);
    NSRange range = [pageHtml rangeOfString:@"option value=\""];
    NSString *concat = [pageHtml substringFromIndex:range.location];
    NSRange range2 = [concat rangeOfString:@"\">"];
    NSRange range3 = [concat rangeOfString:@"</option"];
    range2.location+=range.location;
    range3.location+=range.location;
    while (range.location!=NSNotFound&&range2.location!=NSNotFound&&range3.location!=NSNotFound) {
        NSRange picker;
        picker.location = range.location+range.length;
        picker.length = range2.location-picker.location;
        NSString *diseaseValue = [pageHtml substringWithRange:picker];
        picker.location = range2.location+range2.length;
        picker.length = range3.location-picker.location;
        NSString *diseaseName = [pageHtml substringWithRange:picker];
        [self.diseaseDictionary setObject:diseaseValue forKey:diseaseName];
        
        
        pageHtml = [pageHtml substringFromIndex:range3.location];
        //NSLog@"%@",pageHtml);
        range = [pageHtml rangeOfString:@"option value=\""];
        if (range.location==NSNotFound) {
            break;
        }
        concat = [pageHtml substringFromIndex:range.location];
        range2 = [concat rangeOfString:@"\">"];
        range3 = [concat rangeOfString:@"</option"];
        range2.location+=range.location;
        range3.location+=range.location;
    }
    self.testArray = [NSMutableArray arrayWithArray:[self.diseaseDictionary allKeys]];
     //NSLog@"%@",_diseaseDictionary);
    [self.ResultsTable reloadData];

}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    if (self.mode == 1) {
        ////NSLog@"Selected Cell ID %@",selectedCell.textLabel.text);
        ////NSLog@"Patient ID = %@", [self.patientDictionary valueForKey:selectedCell.textLabel.text]);
        //self.SearchText.isEnabled = false;
        self.testArray = [NSMutableArray new];
        self.SearchText.text = @"";
        self.PromptLabel.text = @"Select a Visit Date";
        self.AddDate.hidden = false;
        [[self SearchText]resignFirstResponder];
        [[self SearchText]setHidden:YES];
        self.mode = 2;
        self.myPatientName = selectedCell.textLabel.text;
        self.myPatientID = [self.patientDictionary valueForKey:selectedCell.textLabel.text];
        [self postPatientID:[self.patientDictionary valueForKey:selectedCell.textLabel.text]];
    }else if (self.mode ==2){
        self.AddDate.hidden = true;
        self.testArray = [NSMutableArray new];
        [self postVisitDate:selectedCell.textLabel.text];
        NSString *newPromptLabel = @"Please select a disease for patient ";
        newPromptLabel = [newPromptLabel stringByAppendingString:self.myPatientName];
        newPromptLabel = [newPromptLabel stringByAppendingString:@" on visit date "];
        newPromptLabel = [newPromptLabel stringByAppendingString:self.myVisitName];
        self.PromptLabel.text = newPromptLabel;
        //newPromptLabel = [newPromptLabel stringByAppendingString:@" on "];
        self.mode = 3;
        [self populateDiseaseDictionary];
    }else if (self.mode == 3){
        self.myDiseaseName = selectedCell.textLabel.text;
        self.myDiseaseID = [self.diseaseDictionary objectForKey:self.myDiseaseName];
        self.testArray = [NSMutableArray new];
        [self.ResultsTable reloadData];
        [self postDiseaseID];
        self.mode = 4;
    }else if (self.mode==4){
        self.BackButton.hidden = false;
        //Store Data in symptomSeverityIDForSymptomIDArray
        NSString *currentSID = [self.symptomArray objectAtIndex:self.currentSymptomIndex];
        //NSLog@"Symptom Severity Dictionary %@", self.symptomSeverityDescriptionAndID);
        [self.symptomSeverityIDForSymptomID setObject:[self.symptomSeverityDescriptionAndID objectForKey:selectedCell.detailTextLabel.text] forKey:currentSID];
        //NSLog@"Symptom Severity Dictionary %@", self.symptomSeverityIDForSymptomID);
        if (self.currentSymptomIndex<[self.symptomArray count]-1) {
            self.currentSymptomIndex++;
            
            
            currentSID = [self.symptomArray objectAtIndex:self.currentSymptomIndex];
            NSString *symptomName;
            self.testArray = [NSMutableArray new];
            self.symptomSeverityDescriptionAndID = [NSMutableDictionary new];
            for (NSDictionary * SS in self.jsonSymptomData) {
                NSString *symptomID = [SS objectForKey:@"SID"];
                if ([symptomID isEqualToString:currentSID]) {
                    NSString *symptomSeverityDescription = [SS objectForKey:@"description"];
                    NSString *symptomSeverityID = [SS objectForKey:@"SDID"];
                    symptomName = [SS objectForKey:@"name"];
                    [self.symptomSeverityDescriptionAndID setObject:symptomSeverityID forKey:symptomSeverityDescription];
                }
            }
            self.PromptLabel.text = [NSString stringWithFormat:@"Please rate the severity level for %@", symptomName];
            [self.testArray addObjectsFromArray:[self.symptomSeverityDescriptionAndID keysSortedByValueUsingSelector:@selector(localizedStandardCompare:)]];
            [self.ResultsTable reloadData];

        }else{
            //NSLog@"%@",self.symptomSeverityIDForSymptomID);
            [self postSymptomData];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Entry Successfully Recorded"
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            
            [self startFresh];
            //Send data
        }
    }

    
}

- (IBAction)backPress:(id)sender {
    self.currentSymptomIndex--;
    NSString *currentSID = [self.symptomArray objectAtIndex:self.currentSymptomIndex];
    NSString *symptomName;
    self.testArray = [NSMutableArray new];
    self.symptomSeverityDescriptionAndID = [NSMutableDictionary new];
    for (NSDictionary * SS in self.jsonSymptomData) {
        NSString *symptomID = [SS objectForKey:@"SID"];
        if ([symptomID isEqualToString:currentSID]) {
            NSString *symptomSeverityDescription = [SS objectForKey:@"description"];
            NSString *symptomSeverityID = [SS objectForKey:@"SDID"];
            symptomName = [SS objectForKey:@"name"];
            [self.symptomSeverityDescriptionAndID setObject:symptomSeverityID forKey:symptomSeverityDescription];
        }
    }
    self.PromptLabel.text = [NSString stringWithFormat:@"Please rate the severity level for %@", symptomName];
    [self.testArray addObjectsFromArray:[self.symptomSeverityDescriptionAndID keysSortedByValueUsingSelector:@selector(localizedStandardCompare:)]];
    [self.ResultsTable reloadData];
    
    
}
- (IBAction)dateSelected:(id)sender {
    ////NSLog@"%@",self.AddDate.titleLabel.text);
    if (self.ResultsTable.hidden==false) {
        self.datePicker.hidden = false;
        self.ResultsTable.hidden = true;
    }else{
        self.datePicker.hidden = true;
        self.AddDate.titleLabel.text = @"Add Date";
        self.AddDate.hidden = true;
        self.ResultsTable.hidden = false;
        NSString *dateToBePosted;
        //dateToBePosted = [self.datePicker.date descriptionWithLocale:nil];
        //NSRange range;
        //range = [dateToBePosted rangeOfString:@" "];
        //dateToBePosted = [dateToBePosted substringToIndex:range.location];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"MM/dd/yyyy"];
        
       dateToBePosted = [NSString stringWithFormat:@"%@",
                       [df stringFromDate:self.datePicker.date]];
        //NSLog@"%@",dateToBePosted);
        NSString *bodyData = [NSString stringWithFormat:@"patientID=%@&date=%@",self.myPatientID,dateToBePosted];
        NSString *url = [NSString stringWithFormat:@"https://184.72.98.28/patients.php?id=%@",dateToBePosted];
        NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
        // Set the request's content type to application/x-www-form-urlencoded
        [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        // Designate the request a POST request and specify its body data
        [postRequest setHTTPMethod:@"POST"];
        [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:strlen([bodyData UTF8String])]];
        NSError *errorReturned = nil;
        NSURLResponse *theResponse =[[NSURLResponse alloc]init];
        [NSURLConnection sendSynchronousRequest:postRequest returningResponse:&theResponse error:&errorReturned];
        [self postPatientID:self.myPatientID];
    }
    
}

-(void)startFresh{
    self.BackButton.hidden = true;
    self.testArray = [NSMutableArray new];
    self.patientDictionary = [NSMutableDictionary new];
    self.visitDates = [NSMutableDictionary new];
    self.diseaseDictionary = [NSMutableDictionary new];
    self.symptomNameAndID = [NSMutableDictionary new];
    self.symptomSeverityDescriptionAndID = [NSMutableDictionary new];
    self.symptomNameAndSeverityDescriptions = [NSMutableDictionary new];
    self.symptomSeverityIDForSymptomID = [NSMutableDictionary new];
    self.symptomArray = [NSArray new];
    self.jsonSymptomData = [NSArray new];
    self.SearchText.text = @"";
    self.PromptLabel.text = @"Select a patient";
    self.SearchText.hidden = false;
    self.mode=0;
    NSString *fullURL = @"https://184.72.98.28/record.php";
    NSURL *url = [NSURL URLWithString:fullURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.PatientWebView loadRequest:requestObj];
}

-(void)postSymptomData{
    NSString *bodyData = [NSString stringWithFormat:@"studentid=105&diseaseid=%@&visitdateid=%@&patientid=%@",self.myDiseaseID,self.myVisitID,self.myPatientID];
    for (NSString *symptomID in [self.symptomSeverityIDForSymptomID allKeys]) {
        NSString *severity = [self.symptomSeverityIDForSymptomID objectForKey:symptomID];
        bodyData = [bodyData stringByAppendingString:[NSString stringWithFormat:@"&sy%@=%@",symptomID,severity]];
    }
    //NSLog@"Final post request body = %@",bodyData);
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://184.72.98.28/record.php"]];
    // Set the request's content type to application/x-www-form-urlencoded
    [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    // Designate the request a POST request and specify its body data
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:strlen([bodyData UTF8String])]];
    NSError *errorReturned = nil;
    NSURLResponse *theResponse =[[NSURLResponse alloc]init];
    [NSURLConnection sendSynchronousRequest:postRequest returningResponse:&theResponse error:&errorReturned];

}
-(void)postVisitDate:(NSString *) visitName{
    
    ////NSLog@"Login Attempted");
    // Do any additional setup after loading the view.
    self.myVisitID = [self.visitDates objectForKey:visitName];
    self.myVisitName = visitName;
    NSString * javaScript = @"SetVDate(";
    javaScript = [javaScript stringByAppendingString:[self.visitDates objectForKey:visitName]];
    javaScript = [javaScript stringByAppendingString:@",'"];
    javaScript = [javaScript stringByAppendingString:visitName];
    javaScript = [javaScript stringByAppendingString:@"')"];
    //NSLog@"%@",javaScript);
    [self.PatientWebView stringByEvaluatingJavaScriptFromString:javaScript];
    NSString * html = [self.PatientWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
    //NSLog@"HTML IS %@",html);
}


- (void)postPatientID:(NSString *) patientID{
    
    ////NSLog@"Login Attempted");
    // Do any additional setup after loading the view.
    _hasBeenDone = false;
    NSString *fullURL = @"https://184.72.98.28/record.php?action=getvisits";
    NSURL *url = [NSURL URLWithString:fullURL];
    self.PatientWebView.delegate = self;
    NSString *bodyData = @"id=";
    bodyData = [bodyData stringByAppendingString:patientID];
    
    
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://184.72.98.28/record.php?action=getvisits"]];
    // Set the request's content type to application/x-www-form-urlencoded
    [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    // Designate the request a POST request and specify its body data
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:strlen([bodyData UTF8String])]];
    [_PatientWebView loadRequest:postRequest];
}

- (void)postDiseaseID{
    
    ////NSLog@"Login Attempted");
    // Do any additional setup after loading the view.
    //_hasBeenDone = false;
    //NSString *fullURL = @"https://184.72.98.28/record.php?action=getvisits";
    //NSURL *url = [NSURL URLWithString:fullURL];
    self.PatientWebView.delegate = self;
    NSString *bodyData = @"diseaseid=";
    bodyData = [bodyData stringByAppendingString:self.myDiseaseID];
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://184.72.98.28/record.php?action=getsymptoms"]];
    // Set the request's content type to application/x-www-form-urlencoded
    [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    // Designate the request a POST request and specify its body data
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:strlen([bodyData UTF8String])]];
    NSError *errorReturned = nil;
    NSURLResponse *theResponse =[[NSURLResponse alloc]init];
    NSData *data = [NSURLConnection sendSynchronousRequest:postRequest returningResponse:&theResponse error:&errorReturned];
    
    if (errorReturned) {
        // Handle error.
    }
    else
    {
        NSError *jsonParsingError = nil;
        self.jsonSymptomData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers|NSJSONReadingAllowFragments error:&jsonParsingError];
        if (self.jsonSymptomData.count > 0) {
            
            NSDictionary *firstDictionary = [self.jsonSymptomData objectAtIndex:0];
            NSString * CurrentSymptomID = [firstDictionary objectForKey:@"SID"];
            self.symptomArray = [self.symptomArray arrayByAddingObject:CurrentSymptomID];
            for (NSDictionary * SS in self.jsonSymptomData) {
                NSString *symptomID = [SS objectForKey:@"SID"];
                if (![symptomID isEqualToString:CurrentSymptomID]) {
                    self.symptomArray = [self.symptomArray arrayByAddingObject:symptomID];
                    CurrentSymptomID = symptomID;
                }
            }
            //NSLog@"Symptom IDs %@", self.symptomArray);
            //NSLog@"Entire Symptom JSON %@", self.jsonSymptomData);
            self.currentSymptomIndex = 0;
            NSString *currentSID = [self.symptomArray objectAtIndex:self.currentSymptomIndex];
            NSString *symptomName;
            self.testArray = [NSMutableArray new];
            for (NSDictionary * SS in self.jsonSymptomData) {
                NSString *symptomID = [SS objectForKey:@"SID"];
                if ([symptomID isEqualToString:currentSID]) {
                    NSString *symptomSeverityDescription = [SS objectForKey:@"description"];
                    NSString *symptomSeverityID = [SS objectForKey:@"SDID"];
                    symptomName = [SS objectForKey:@"name"];
                    [self.symptomSeverityDescriptionAndID setObject:symptomSeverityID forKey:symptomSeverityDescription];
                }
            }
            self.PromptLabel.text = [NSString stringWithFormat:@"Please rate the severity level for %@", symptomName];
            [self.testArray addObjectsFromArray:[self.symptomSeverityDescriptionAndID allKeys]];
            [self.ResultsTable reloadData];

            
        }
        
        
    }
    //[_PatientWebView loadRequest:postRequest];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //NSLog@"Table Call");
    return [self.testArray count];

}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //NSLog@"Table Call");
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    cell.detailTextLabel.font = [[UIFont new] fontWithSize:2];
    if(cell == nil)
    {
        cell = [[UITableViewCell new] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
    }
    if (self.mode==4) {
        NSString *s = [NSString stringWithFormat:@"Severity %i", indexPath.row];
        //cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
        cell.textLabel.font = [UIFont boldSystemFontOfSize:12];
        cell.textLabel.text = s;
        cell.textLabel.textColor = [UIColor colorWithRed:1.0*indexPath.row/[self.testArray count]  green:.8*([self.testArray count]-indexPath.row)/[self.testArray count] blue:0 alpha:1];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:11];
        
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0 green:0 blue:1.0 alpha:1];
        cell.detailTextLabel.numberOfLines = 10;
        //cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
        cell.detailTextLabel.text = [self.testArray objectAtIndex:indexPath.row];
        
        
       
    }else{
        cell = [[UITableViewCell new] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        cell.textLabel.text = [self.testArray objectAtIndex:indexPath.row];
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    //[textField setHidden:YES];
    //NSLog@"Text Field");
    return YES;
}
- (IBAction)DoneUsing:(id)sender {
    [self.SearchText resignFirstResponder];
}

//NSURL Stuff
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)pResponse {
    _Authenticated = YES;
    [connection cancel];
    [_PatientWebView loadRequest:_FailedRequest];
    //NSLog@"Connection Succesful");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if(self.mode == 0){
        self.pageHTML = [self.PatientWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
        //NSLog@"%@",self.pageHTML);
        self.mode = 1;
    }
    if (self.mode==1) {
        self.testArray = [NSMutableArray new];
        NSString * html = [self.PatientWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
        //NSLog@"%@",html);
        NSRange range = [html rangeOfString:@"name\":\""];
        NSRange range2 = [html rangeOfString:@"\",\"patientid\":\""];
        NSRange range3 = [html rangeOfString:@"}"];
        while (range.location!=NSNotFound&&range2.location!=NSNotFound&&range3.location!=NSNotFound) {
            NSRange nameR = [html rangeOfString:@"name\":\""];
            nameR.location=range.location+7;
            nameR.length = range2.location-nameR.location;
            ////NSLog@"Range Length: %i",nameR.length);
            NSString *name = [html substringWithRange:nameR];
            
            nameR.location=range2.location+15;
            nameR.length = range3.location-nameR.location-1;
            
            NSString *patientID = [html substringWithRange:nameR];
            
            ////NSLog@"Patient ID: %@",patientID);
            [self.testArray addObject:name];
            [self.patientDictionary setObject:patientID forKey:name];
            html = [html substringFromIndex:range3.location+1];
            range = [html rangeOfString:@"name\":\""];
            ////NSLog@"Range Length: %i",range.length);
            range2 = [html rangeOfString:@"\",\"patientid\":\""];
            range3 = [html rangeOfString:@"}"];
            ////NSLog@"%@",html);
        }


    }
    if(self.mode==2){
        self.testArray = [NSMutableArray new];
        NSString * html = [self.PatientWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
        //NSLog@"%@",html);
        NSRange range = [html rangeOfString:@"VDATE\":\""];
        NSRange range2 = [html rangeOfString:@"\",\"VDID\":\""];
        NSRange range3 = [html rangeOfString:@"}"];
        while (range.location!=NSNotFound&&range2.location!=NSNotFound&&range3.location!=NSNotFound) {
            NSRange dateR = [html rangeOfString:@"name\":\""];
            dateR.location=range.location+8;
            dateR.length = range2.location-dateR.location;
            ////NSLog@"Range Length: %i",nameR.length);
            NSString *dateName = [html substringWithRange:dateR];
            
            dateR.location=range2.location+10;
            dateR.length = range3.location-dateR.location-1;
            
            NSString *dateID = [html substringWithRange:dateR];
            //NSLog@"Date Name: %@",dateName);
            //NSLog@"Date ID: %@",dateID);
            [self.testArray addObject:dateName];
            [self.visitDates setObject:dateID forKey:dateName];
            html = [html substringFromIndex:range3.location+1];
            range = [html rangeOfString:@"VDATE\":\""];
            ////NSLog@"Range Length: %i",range.length);
            range2 = [html rangeOfString:@"\",\"VDID\":\""];
            range3 = [html rangeOfString:@"}"];
            ////NSLog@"%@",html);
        }

    }
    if (self.mode==4) {
        NSString * html = [self.PatientWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
        //NSLog@"%@",html);
    
        //NSArray *result = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&localError];
        
    }


[[self ResultsTable] reloadData];

}

-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURL* baseURL = [NSURL URLWithString:_BaseRequest];
        if (1) {
            ////NSLog@"trusting connection to host %@", challenge.protectionSpace.host);
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        } else {
            //NSLog@"Not trusting connection to host %@", challenge.protectionSpace.host);
        }
    }
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

-(void)patientPostRequest{
    ////NSLog@"Login Attempted");
    // Do any additional setup after loading the view.
    _hasBeenDone = false;
    self.PatientWebView.delegate = self;
    NSString *bodyData = @"q=";
    bodyData = [bodyData stringByAppendingString:[[self SearchText] text]];

    
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://184.72.98.28/patients.php?action=search"]];
    // Set the request's content type to application/x-www-form-urlencoded
    [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    // Designate the request a POST request and specify its body data
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:strlen([bodyData UTF8String])]];
    [_PatientWebView loadRequest:postRequest];
}

@end
