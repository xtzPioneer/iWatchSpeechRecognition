//
//  InterfaceController.m
//  iWatch WatchKit Extension
//
//  Created by xtz_pioneer on 2018/3/22.
//  Copyright © 2018年 zhangxiong. All rights reserved.
//

#import "InterfaceController.h"
#import <WatchConnectivity/WatchConnectivity.h>
@interface InterfaceController ()<WCSessionDelegate>
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceButton *voiceButton;
@property (nonatomic,strong)WCSession      * session;
@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    //初始化WCSession(数据交互)
    self.session =[WCSession defaultSession];
    //遵循WCSessionDelegate代理
    self.session.delegate=self;
    //必须激活session
    [self.session activateSession];


}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}
- (IBAction)voiceEvent {
    NSString * path=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString * filePath=[NSString stringWithFormat:@"%@/record.wav",path];
    NSURL * fileURL=[NSURL URLWithString:filePath];
    NSDictionary * audioOptions = @{
                                      /* 录制好之后的标题 */
                                      WKAudioRecorderControllerOptionsActionTitleKey:@"发送",
                                      /* 是否自动录制 */
                                      WKAudioRecorderControllerOptionsAutorecordKey:@YES,
                                      /* 时间 NSTimeInterval */
                                      WKAudioRecorderControllerOptionsMaximumDurationKey:@30
                                      };
    __weak typeof(self) weakSelf=self;
    [self presentAudioRecorderControllerWithOutputURL:fileURL preset:WKAudioRecorderPresetHighQualityAudio options:audioOptions completion:^(BOOL didSave, NSError * _Nullable error) {
        if (error) {
            return ;
        }
        if (didSave) {
            NSLog(@"保存成功");
            NSDictionary *infoDict = @{@"filePath":filePath};
            [weakSelf.session transferUserInfo:infoDict];
        }else{
            NSLog(@"保存失败");
        }
        
    }];
}
#pragma mark - WCSessionDelegate
//发送会失败回调
- (void)session:(WCSession *)session didFinishUserInfoTransfer:(WCSessionUserInfoTransfer *)userInfoTransfer error:(NSError *)error {
    if (!error) {
        NSLog(@"watch消息发送成功");
    }else{
        NSLog(@"watch消息发送失败:%@",error);
    }
}
@end



