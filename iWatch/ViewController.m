//
//  ViewController.m
//  iWatch
//
//  Created by xtz_pioneer on 2018/3/22.
//  Copyright © 2018年 zhangxiong. All rights reserved.
//

#import "ViewController.h"
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>
#import <WatchConnectivity/WatchConnectivity.h>

@interface ViewController ()<SFSpeechRecognizerDelegate>
@property (nonatomic,strong)SFSpeechRecognizer * speechRecognizer;
@property (nonatomic,strong)AVAudioEngine      * audioEngine;
@property (nonatomic,strong)SFSpeechRecognitionTask * speechRecognitionTask;
@property (nonatomic,strong)SFSpeechAudioBufferRecognitionRequest * speechAudioBufferRecognitionRequest;
@property (nonatomic,weak)UILabel * promptLabel;
@property (nonatomic,weak)UITextView * resultTextView;
@property (nonatomic,weak)UIButton * localButton;
@property (nonatomic,weak)UIButton * recordingButton;
@property (nonatomic,strong)WCSession * session;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //布局视图
    [self layoutView];
    //检测语音权限
    __weak typeof(self) weakSelf=self;
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                    weakSelf.recordingButton.enabled = NO;
                    [weakSelf.recordingButton setTitle:@"语音识别未授权" forState:UIControlStateDisabled];
                    break;
                case SFSpeechRecognizerAuthorizationStatusDenied:
                    
                    weakSelf.recordingButton.enabled = NO;
                    [weakSelf.recordingButton setTitle:@"用户未授权使用语音识别" forState:UIControlStateDisabled];
                    break;
                case SFSpeechRecognizerAuthorizationStatusRestricted:
                    weakSelf.recordingButton.enabled = NO;
                    [weakSelf.recordingButton setTitle:@"语音识别在这台设备上受到限制" forState:UIControlStateDisabled];
                    break;
                case SFSpeechRecognizerAuthorizationStatusAuthorized:
                    weakSelf.recordingButton.enabled = YES;
                    [weakSelf.recordingButton setTitle:@"开始录音" forState:UIControlStateNormal];
                    break;
                default:
                    break;
            }
        });
    }];
    //初始化WCSession(数据交互)
    self.session=[WCSession defaultSession];
    //遵循WCSessionDelegate代理
    self.session.delegate=self;
    //必须激活session
    [self.session activateSession];
    
    //禁止点击
    self.recordingButton.enabled = NO;
    // Do any additional setup after loading the view, typically from a nib.
}
#pragma mark- 布局视图
- (void)layoutView{
    
    UILabel * promptLabel=[[UILabel alloc]init];
    promptLabel.textColor=[UIColor blackColor];
    promptLabel.text=@"识别结果:";
    promptLabel.font=[UIFont systemFontOfSize:17];
    promptLabel.frame=CGRectMake(20, 40, 120, 20);
    self.promptLabel=promptLabel;
    [self.view addSubview:promptLabel];
    
    UITextView * resultTextView=[[UITextView alloc]init];
    resultTextView.textColor=[UIColor blackColor];
    resultTextView.text=@"";
    resultTextView.font=[UIFont systemFontOfSize:15];
    resultTextView.frame=CGRectMake(20, CGRectGetMaxY(self.promptLabel.frame)+20, self.view.frame.size.width-20*2, 150);
    resultTextView.layer.borderColor=[UIColor grayColor].CGColor;
    resultTextView.layer.borderWidth=1;
    resultTextView.editable=NO;
    self.resultTextView=resultTextView;
    [self.view addSubview:resultTextView];
    
    UIButton * localButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [localButton setTitle:@"识别本地音频文件" forState:UIControlStateNormal];
    [localButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [localButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    localButton.backgroundColor=[UIColor redColor];
    localButton.frame=CGRectMake(20, self.view.frame.size.height-50*4, self.view.frame.size.width-20*2, 50);
    [localButton addTarget:self action:@selector(localEvent:) forControlEvents:UIControlEventTouchUpInside];
    self.localButton=localButton;
    [self.view addSubview:localButton];
    
    UIButton * recordingButton=[UIButton buttonWithType:UIButtonTypeCustom];
    [recordingButton setTitle:@"开始录音" forState:UIControlStateNormal];
    [recordingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [recordingButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    recordingButton.backgroundColor=[UIColor blueColor];
    recordingButton.frame=CGRectMake(20, self.view.frame.size.height-50*2, self.view.frame.size.width-20*2, 50);
    [recordingButton addTarget:self action:@selector(recordingEvent:) forControlEvents:UIControlEventTouchUpInside];
    self.recordingButton=recordingButton;
    [self.view addSubview:recordingButton];
    

}
#pragma mark- 识别本地音频
//识别本地音频
- (void)localEvent:(id)sender{
    NSURL *url =[[NSBundle mainBundle] URLForResource:@"录音.m4a" withExtension:nil];
    [self speechRecognition:url];
}
#pragma mark- 接收数据回调
//接收数据回调
- (void)session:(WCSession *)session didReceiveUserInfo:(NSDictionary<NSString *,id> *)userInfo{
    if (userInfo) {
        NSLog(@"iOS接收到消息:%@",userInfo);
        __weak typeof(self) weakSelf=self;
        dispatch_async(dispatch_get_main_queue(),^{
            NSURL *url =[NSURL fileURLWithPath:userInfo[@"filePath"]];
            [weakSelf speechRecognition:url];
        });
    }else{
        NSLog(@"iOS没有接收到消息");
    }
}
#pragma mark- 识别本地音频(核心)
//识别本地音频
- (void)speechRecognition:(NSURL*)url{
    NSLog(@"识别本地音频");
    NSLocale * locale=[[NSLocale alloc]initWithLocaleIdentifier:@"zh_CN"];
    SFSpeechRecognizer * localRecognizer=[[SFSpeechRecognizer alloc]initWithLocale:locale];
    if (!url) return;
    SFSpeechURLRecognitionRequest * res=[[SFSpeechURLRecognitionRequest alloc]initWithURL:url];
    __weak typeof(self) weakSelf=self;
    [localRecognizer recognitionTaskWithRequest:res resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        if (error) {
            NSLog(@"语音识别解析失败,%@",error);
        }
        else{
            weakSelf.resultTextView.text = result.bestTranscription.formattedString;
        }
    }];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark- 开始录音/停止录音
//开始录音/停止录音
- (void)recordingEvent:(id)sender{
    NSLog(@"开始录音/停止录音");
    if (self.audioEngine.isRunning) {
        [self.audioEngine stop];
        if (_speechRecognizer) {
            [_speechAudioBufferRecognitionRequest endAudio];
        }
        self.recordingButton.enabled = NO;
        [self.recordingButton setTitle:@"正在停止" forState:UIControlStateDisabled];
    }
    else{
        [self startRecording];
        [self.recordingButton setTitle:@"停止录音" forState:UIControlStateNormal];
        
    }
}
#pragma mark- 开始录音
- (void)startRecording{
    if (_speechRecognitionTask) {
        [_speechRecognitionTask cancel];
        _speechRecognitionTask = nil;
    }
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    NSParameterAssert(!error);
    [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
    NSParameterAssert(!error);
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    NSParameterAssert(!error);
    
    _speechAudioBufferRecognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    NSAssert(inputNode, @"录入设备没有准备好");
    NSAssert(_speechAudioBufferRecognitionRequest, @"请求初始化失败");
    _speechAudioBufferRecognitionRequest.shouldReportPartialResults = YES;
    __weak typeof(self) weakSelf = self;
    _speechRecognitionTask = [self.speechRecognizer recognitionTaskWithRequest:_speechAudioBufferRecognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        BOOL isFinal = NO;
        if (result) {
            strongSelf.resultTextView.text = result.bestTranscription.formattedString;
            isFinal = result.isFinal;
        }
        if (error || isFinal) {
            [self.audioEngine stop];
            [inputNode removeTapOnBus:0];
            strongSelf.speechRecognitionTask = nil;
            strongSelf.speechAudioBufferRecognitionRequest = nil;
            strongSelf.recordingButton.enabled = YES;
            [strongSelf.recordingButton setTitle:@"开始录音" forState:UIControlStateNormal];
        }
        
    }];
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    //在添加tap之前先移除上一个  不然有可能报"Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio',"之类的错误
    [inputNode removeTapOnBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.speechAudioBufferRecognitionRequest) {
            [strongSelf.speechAudioBufferRecognitionRequest appendAudioPCMBuffer:buffer];
        }
    }];
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
    NSParameterAssert(!error);
    self.resultTextView.text = @"正在录音。。。";
}
#pragma mark - lazyload
- (AVAudioEngine *)audioEngine{
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return _audioEngine;
}
- (SFSpeechRecognizer *)speechRecognizer{
    if (!_speechRecognizer) {
        //腰围语音识别对象设置语言，这里设置的是中文
        NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        _speechRecognizer =[[SFSpeechRecognizer alloc] initWithLocale:local];
        _speechRecognizer.delegate = self;
    }
    return _speechRecognizer;
}
#pragma mark - SFSpeechRecognizerDelegate
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available{
    if (available) {
        self.recordingButton.enabled = YES;
        [self.recordingButton setTitle:@"开始录音" forState:UIControlStateNormal];
    }
    else{
        self.recordingButton.enabled = NO;
        [self.recordingButton setTitle:@"语音识别不可用" forState:UIControlStateDisabled];
    }
}
@end
