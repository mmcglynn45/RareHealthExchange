//
//  SecondViewController.m
//  RareHealthExchange
//
//  Created by Matt McGlynn on 11/14/13.
//  Copyright (c) 2013 Matt McGlynn. All rights reserved.
//

#import "SecondViewController.h"

@interface SecondViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *PatientWebView;
@property bool Authenticated;
@property NSURLRequest * FailedRequest;
@property NSString  *BaseRequest;
@property bool hasBeenDone;
@property NSString *data;
@end

@implementation SecondViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _hasBeenDone = false;
    NSString *fullURL = @"https://184.72.98.28/index.php";
    NSURL *url = [NSURL URLWithString:fullURL];
    self.PatientWebView.delegate = self;
    NSString *bodyData = @"username=group1&password=crnd";
    
    NSMutableURLRequest *postRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://184.72.98.28/index.php"]];
    // Set the request's content type to application/x-www-form-urlencoded
    [postRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    // Designate the request a POST request and specify its body data
    [postRequest setHTTPMethod:@"POST"];
    [postRequest setHTTPBody:[NSData dataWithBytes:[bodyData UTF8String] length:strlen([bodyData UTF8String])]];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    //[_PatientWebView loadRequest:requestObj];
    //[self.PatientWebView stringByEvaluatingJavaScriptFromString:@"document. body.style.zoom = 10.0;"];
    [_PatientWebView loadRequest:postRequest];
    
    //self.PatientWebView.scrollView.zoomScale = 1;
    self.PatientWebView.scrollView.contentScaleFactor = 5;
    //self.PatientWebView.scrollView.showsHorizontalScrollIndicator = 1;
    self.PatientWebView.scrollView.scrollEnabled = 0;
	// Do any additional setup after loading the view, typically from a nib.
    
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    BOOL result = _Authenticated;
    if (!_Authenticated) {
        _FailedRequest = request;
        [[NSURLConnection alloc] initWithRequest:request delegate:self];
    }
    return result;
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

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)pResponse {
    _Authenticated = YES;
    [connection cancel];
    [_PatientWebView loadRequest:_FailedRequest];
    NSLog(@"Something Happening");
}
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (!_hasBeenDone) {
    NSString *jsCommand = [NSString stringWithFormat:@"document.body.style.zoom = %f;",.3];
    [webView stringByEvaluatingJavaScriptFromString:jsCommand];
     NSLog(@"Done");
    NSString * html = [self.PatientWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"];
    NSRange range = [html rangeOfString:@"<title"];
    
    if(range.location != NSNotFound) {
        // Adjust style for mobile
        
        NSString *style = @"\n<meta name=\"viewport\" content=\"width=300\" />\n";
        style = @"";
        html = [NSString stringWithFormat:@"%@%@%@", [html substringToIndex:range.location], style, [html substringFromIndex:range.location]];
    }
    NSLog(@"HTML STRING:--------------------------------- %@",html);
    range = [html rangeOfString:@"<div id=\"container"];
    NSString *remaining = [html substringFromIndex:range.location];
    NSRange range2 = [remaining rangeOfString:@"<div id=\"main"];
    if(range.location != NSNotFound) {
        // Adjust style for mobile
        
        NSString *style = @"<body style=\"width:50%\"> \n ";
        html = [NSString stringWithFormat:@"%@%@%@", [html substringToIndex:range.location], style, [html substringFromIndex:range2.location+range.location]];
    }
    NSLog(@"HTML STRING:--------------------------------- %@",html);
    NSString *fullURL = @"https://184.72.98.28/patients.php";
    NSURL *url = [NSURL URLWithString:fullURL];
    
    _hasBeenDone = true;
    [webView loadHTMLString:html baseURL:url];
    
    
    NSLog(@"HTML STRING: %@",html);
    }

}
-(void)viewDidUnload {
    NSLog(@"View did unload!");
}





// Handle basic authentication challenge if needed
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    NSString *username = @"group1";
    NSString *password = @"crnd";
    
    NSURLCredential *credential = [NSURLCredential credentialWithUser:username
                                                             password:password
                                                          persistence:NSURLCredentialPersistenceForSession];
    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
    NSLog(@"Authentication Challenge");
}


@end
