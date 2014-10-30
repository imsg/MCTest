//
//  ViewController.m
//  MCTest
//
//  Created by Zhao Kun on 14/10/27.
//  Copyright (c) 2014年 Nuts Tech. All rights reserved.
//

#import "ViewController.h"
#import "UIView+Extension.h"

@interface ViewController () {
    PLPartyTime *_pt;
    CGSize _keyboardSize;
    CGFloat _lastLabelBottom;
}
@property (nonatomic, strong) UITableView *userTableView;
@property (weak, nonatomic) UIToolbar *inputToolbar;
@property (weak, nonatomic) UITextField *inputTextField;
@property (weak, nonatomic) UIScrollView *chatScrollView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    // Do any additional setup after loading the view, typically from a nib.
    _pt = [[PLPartyTime alloc] initWithServiceType:@"chat-files"];
    _pt.delegate = self;
    [_pt joinParty];
    
    CGRect frame = self.view.frame;
    frame.size.height = 100;
    self.userTableView = [[UITableView alloc] initWithFrame:frame];
    self.userTableView.delegate = self;
    self.userTableView.dataSource = self;
    [self.userTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.userTableView setEditing:YES animated:YES];
    self.userTableView.allowsMultipleSelectionDuringEditing = YES;
    [self.view addSubview:self.userTableView];
    [self.userTableView reloadData];
    
    __weak ViewController *weakSelf = self;
    UIScrollView *chatScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 100, self.view.width, self.view.height-100-64-44)];
    [chatScrollView setContentSize:CGSizeMake(self.view.width, 600)];
    [chatScrollView setTapActionWithBlock:^{
        [weakSelf.inputTextField resignFirstResponder];
    }];
    
    [self.view addSubview:chatScrollView];
    _chatScrollView = chatScrollView;
    
    // Toolbar
    UIToolbar *inputToolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.height-64-44, self.view.width, 44)];
//    UIBarButtonItem *iconItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Chat_Icon"] style:UIBarButtonItemStylePlain target:self action:nil];
//    iconItem.tintColor = UIColorFromRGB(0xc4c7cc);
    
    UITextField *inputTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 260, 30)];
    inputTextField.borderStyle = UITextBorderStyleRoundedRect;
    inputTextField.returnKeyType = UIReturnKeySend;
    inputTextField.delegate = self;
    UIBarButtonItem *inputItem = [[UIBarButtonItem alloc] initWithCustomView:inputTextField];
    [inputToolbar setItems:@[inputItem]];
    [self.view addSubview:inputToolbar];
    _inputToolbar = inputToolbar;
    _inputTextField = inputTextField;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Delegate

- (void)partyTime:(PLPartyTime *)partyTime peer:(MCPeerID *)peer changedState:(MCSessionState)state currentPeers:(NSArray *)currentPeers
{
    NSLog(@"ChangedState: %ld, peer count: %ld", (long)state, (unsigned long)[currentPeers count]);
    [self.userTableView reloadData];
}

- (void)partyTime:(PLPartyTime *)partyTime failedToJoinParty:(NSError *)error
{
    NSLog(@"Failed to join party, error: %@", error);
}

- (void)partyTime:(PLPartyTime *)partyTime didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"ReceivedData: %@ from %@", text, peerID.displayName);
    [self addText:text fromPeerName:peerID.displayName];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_pt.connectedPeers count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    MCPeerID *peerID = _pt.connectedPeers[indexPath.row];
    cell.textLabel.text = peerID.displayName;
    return cell;
}

#pragma mark - Notifications

- (void)keyboardWillShow:(NSNotification *)notification
{
    /* Move the toolbar to above the keyboard */
    NSDictionary* info = [notification userInfo];
    _keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    self.inputToolbar.bottom = self.view.height-_keyboardSize.height;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, _keyboardSize.height, 0.0);
    self.chatScrollView.contentInset = contentInsets;
    self.chatScrollView.scrollIndicatorInsets = contentInsets;
    CGPoint bottomOffset = CGPointMake(0, self.chatScrollView.contentSize.height - self.chatScrollView.bounds.size.height+_keyboardSize.height);
    if (bottomOffset.y > 0) {
        [self.chatScrollView setContentOffset:bottomOffset animated:YES];
    }
    [UIView commitAnimations];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    /* Move the toolbar back to bottom of the screen */
    _keyboardSize = CGSizeZero;
    NSDictionary* info = [notification userInfo];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    self.inputToolbar.bottom = self.view.height;
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.chatScrollView.contentInset = contentInsets;
    self.chatScrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    [UIView commitAnimations];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSString *text = [textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([text length] > 0) {
        NSArray *selectedArray = [self.userTableView indexPathsForSelectedRows];
        if ([selectedArray count] > 0) {
            NSMutableArray *peersArray = [NSMutableArray array];
            for (NSIndexPath *indexPath in selectedArray) {
                [peersArray addObject:_pt.connectedPeers[indexPath.row]];
            }
            NSData *dataToSend = [text dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error;
            [_pt sendData:dataToSend toPeers:peersArray withMode:MCSessionSendDataReliable error:&error];
            textField.text = @"";
            [self addText:text fromPeerName:@"I"];
        }
        return YES;
    }
    else {
        return NO;
    }
}

- (void)addText:(NSString *)text fromPeerName:(NSString *)name
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, _lastLabelBottom, self.view.width-20, 20)];
    label.text = [NSString stringWithFormat:@"%@ wrote: %@", name, text];
    label.font = [UIFont systemFontOfSize:13];
    [self.chatScrollView addSubview:label];
    _lastLabelBottom += 20;
    self.chatScrollView.contentSize = CGSizeMake(self.view.width, MAX(_lastLabelBottom, self.chatScrollView.height));
}

@end
