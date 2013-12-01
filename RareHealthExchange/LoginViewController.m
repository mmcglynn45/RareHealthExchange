//
//  LoginViewController.m
//  RareHealthExchange
//
//  Created by Matt McGlynn on 11/25/13.
//  Copyright (c) 2013 Matt McGlynn. All rights reserved.
//

#import "LoginViewController.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *UsernameText;
@property (weak, nonatomic) IBOutlet UITextField *PasswordText;
@property (weak, nonatomic) IBOutlet UILabel *WarningLabel;
@property (weak, nonatomic) IBOutlet UIWebView *PatientWebView;


@property bool Authenticated;
@property NSURLRequest * FailedRequest;
@property NSString  *BaseRequest;
@property bool hasBeenDone;
@property NSString *data;

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (IBAction)LoginAttempt:(id)sender {
    NSLog(@"Login Attempted");
    // Do any additional setup after loading the view.
    _hasBeenDone = false;
    NSString *fullURL = @"https://184.72.98.28/index.php";
    NSURL *url = [NSURL URLWithString:fullURL];
    self.PatientWebView.delegate = self;
    NSString *bodyData = @"username=";
    bodyData = [bodyData stringByAppendingString:[[self UsernameText] text]];
    bodyData = [bodyData stringByAppendingString:@"&password="];
    bodyData = [bodyData stringByAppendingString:[[self PasswordText] text]];
    
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://184.72.98.28/index.php"]];
    // Set the request's content type to application/x-www-form-urlencoded
    [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    // Designate the request a POST request and specify its body data
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:strlen([bodyData UTF8String])]];
    [_PatientWebView loadRequest:postRequest];
   
    
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        NSURL* baseURL = [NSURL URLWithString:_BaseRequest];
        if (1) {
            NSLog(@"trusting connection to host %@", challenge.protectionSpace.host);
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
        } else
            NSLog(@"Not trusting connection to host %@", challenge.protectionSpace.host);
    }
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    BOOL result = _Authenticated;
    if (!_Authenticated) {
        _FailedRequest = request;
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
    }
    return result;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"Text Field");
    [textField resignFirstResponder];
    //[textField setHidden:YES];
    
    return YES;
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)pResponse {
    _Authenticated = YES;
    [connection cancel];
    [_PatientWebView loadRequest:_FailedRequest];
    NSLog(@"Connection Succesful");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString * html = [self.PatientWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
    NSRange range = [html rangeOfString:@"patients.php"];
    if (range.location != NSNotFound) {
        [self performSegueWithIdentifier:@"LoginSuccess" sender:NULL];
    }else{
        self.WarningLabel.text = @"Login Attempt Failed";
        self.PasswordText.text = @"";
    }
    
}

@end
