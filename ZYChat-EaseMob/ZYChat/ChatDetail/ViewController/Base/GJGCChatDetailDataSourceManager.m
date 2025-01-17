//
//  GJGCChatDetailDataSourceManager.m
//  ZYChat
//
//  Created by ZYVincent QQ:1003081775 on 14-11-3.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJGCChatDetailDataSourceManager.h"
#import "GJGCMessageExtendModel.h"
#import "GJGCGIFLoadManager.h"
#import "EMMessage.h"
#import "Base64.h"
#import "GJGCMessageExtendContentGIFModel.h"
#import "GJGCMessageExtendMusicShareModel.h"

@interface GJGCChatDetailDataSourceManager ()<IEMChatProgressDelegate,EMChatManagerDelegate>

@property (nonatomic,strong)dispatch_queue_t messageSenderQueue;

@property (nonatomic,strong)dispatch_source_t refreshListSource;

@end

@implementation GJGCChatDetailDataSourceManager

- (instancetype)initWithTalk:(GJGCChatFriendTalkModel *)talk withDelegate:(id<GJGCChatDetailDataSourceManagerDelegate>)aDelegate
{
    if (self = [super init]) {
        
        _taklInfo = talk;
        
        _uniqueIdentifier = [NSString stringWithFormat:@"GJGCChatDetailDataSourceManager_%@",GJCFStringCurrentTimeStamp];
        
        self.delegate = aDelegate;
        
        //注册监听
        [[EaseMob sharedInstance].chatManager addDelegate:self delegateQueue:_messageSenderQueue];
        
        //清除会话的未读数
        [self.taklInfo.conversation markAllMessagesAsRead:YES];
        
        //最短消息间隔500毫秒
        self.lastSendMsgTime = 0;
        self.sendTimeLimit = 500;
        
        [self initState];
        
    }
    return self;
}

#pragma mark - 插入新消息

- (void)insertNewMessageWithStartIndex:(NSInteger)startIndex Count:(NSInteger)count
{
    NSMutableArray *willUpdateIndexPaths = [NSMutableArray array];
    for (NSInteger index = startIndex + 1; index < startIndex + count; index++ ) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [willUpdateIndexPaths addObject:indexPath];
    }
    if (willUpdateIndexPaths.count > 0) {
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(dataSourceManagerRequireUpdateListTable:insertIndexPaths:)]) {
            [self.delegate dataSourceManagerRequireUpdateListTable:self insertIndexPaths:willUpdateIndexPaths];
        }
    }
}

- (void)dealloc
{
    [[EaseMob sharedInstance].chatManager removeDelegate:self];
    [GJCFNotificationCenter removeObserver:self];
}

#pragma mark - 内部接口

- (NSArray *)heightForContentModel:(GJGCChatContentBaseModel *)contentModel
{
    if (!contentModel) {
        return nil;
    }
    
    Class cellClass;
    
    switch (contentModel.baseMessageType) {
        case GJGCChatBaseMessageTypeSystemNoti:
        {
            GJGCChatSystemNotiModel *notiModel = (GJGCChatSystemNotiModel *)contentModel;
            cellClass = [GJGCChatSystemNotiConstans classForNotiType:notiModel.notiType];
        }
            break;
        case GJGCChatBaseMessageTypeChatMessage:
        {
            GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *)contentModel;
            cellClass = [GJGCChatFriendConstans classForContentType:chatContentModel.contentType];
        }
            break;
        default:
            break;
    }
    
    GJGCChatBaseCell *baseCell = [[cellClass alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [baseCell setContentModel:contentModel];
    
    CGFloat contentHeight = [baseCell heightForContentModel:contentModel];
    CGSize  contentSize = [baseCell contentSize];
    
    return @[@(contentHeight),[NSValue valueWithCGSize:contentSize]];
}

- (void)initState
{
    if (!self.messageSenderQueue) {
        self.messageSenderQueue = dispatch_queue_create("_gjgc_message_sender_queue", DISPATCH_QUEUE_SERIAL);
    }
    
    //缓冲刷新
    if (!self.refreshListSource) {
        self.refreshListSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, _messageSenderQueue);
        dispatch_source_set_event_handler(_refreshListSource, ^{
           
            [self dispatchOptimzeRefresh];
        });
    }
    dispatch_resume(self.refreshListSource);
    
    self.isFinishFirstHistoryLoad = NO;
    
    self.chatListArray = [[NSMutableArray alloc]init];
    
    self.timeShowSubArray = [[NSMutableArray alloc]init];
}

#pragma mark - update UI By Dispatch_Source_t

#pragma mark - 公开接口

- (NSInteger)totalCount
{
    return self.chatListArray.count;
}

- (NSInteger)chatContentTotalCount
{
    return self.chatListArray.count - self.timeShowSubArray.count;
}

- (Class)contentCellAtIndex:(NSInteger)index
{
    Class resultClass;
    
    if (index > self.totalCount - 1) {
        return nil;
    }
    
    /* 分发信息 */
    GJGCChatContentBaseModel *contentModel = [self.chatListArray objectAtIndex:index];
    
    switch (contentModel.baseMessageType) {
        case GJGCChatBaseMessageTypeSystemNoti:
        {
            GJGCChatSystemNotiModel *notiModel = (GJGCChatSystemNotiModel *)contentModel;
            resultClass = [GJGCChatSystemNotiConstans classForNotiType:notiModel.notiType];
        }
            break;
        case GJGCChatBaseMessageTypeChatMessage:
        {
            GJGCChatFriendContentModel *messageModel = (GJGCChatFriendContentModel *)contentModel;
            resultClass = [GJGCChatFriendConstans classForContentType:messageModel.contentType];
        }
            break;
        default:
            
            break;
    }
    
    return resultClass;
}

- (NSString *)contentCellIdentifierAtIndex:(NSInteger)index
{
    if (index > self.totalCount - 1) {
        return nil;
    }
    
    NSString *resultIdentifier = nil;
    
    /* 分发信息 */
    GJGCChatContentBaseModel *contentModel = [self.chatListArray objectAtIndex:index];
    
    switch (contentModel.baseMessageType) {
        case GJGCChatBaseMessageTypeSystemNoti:
        {
            GJGCChatSystemNotiModel *notiModel = (GJGCChatSystemNotiModel *)contentModel;
            resultIdentifier = [GJGCChatSystemNotiConstans identifierForNotiType:notiModel.notiType];
        }
            break;
        case GJGCChatBaseMessageTypeChatMessage:
        {
            GJGCChatFriendContentModel *messageModel = (GJGCChatFriendContentModel *)contentModel;
            resultIdentifier = [GJGCChatFriendConstans identifierForContentType:messageModel.contentType];
        }
            break;
        default:
        
            break;
    }
    
    return resultIdentifier;
}

- (GJGCChatContentBaseModel *)contentModelAtIndex:(NSInteger)index
{
    return [self.chatListArray objectAtIndex:index];
}

- (CGFloat)rowHeightAtIndex:(NSInteger)index
{
    if (index > self.totalCount - 1) {
        return 0.f;
    }
    
    GJGCChatContentBaseModel *contentModel = [self contentModelAtIndex:index];
    
    return contentModel.contentHeight;
}

- (NSNumber *)updateContentModel:(GJGCChatContentBaseModel *)contentModel atIndex:(NSInteger)index
{
    NSArray *contentHeightArray = [self heightForContentModel:contentModel];
    contentModel.contentHeight = [[contentHeightArray firstObject] floatValue];
    contentModel.contentSize = [[contentHeightArray lastObject] CGSizeValue];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        [self updateMsgContentHeightWithContentModel:contentModel];

    });
    
    [self.chatListArray replaceObjectAtIndex:index withObject:contentModel];
    
    return @(contentModel.contentHeight);
}

- (void)updateAudioFinishRead:(NSString *)localMsgId
{
    
}

- (void)updateMsgContentHeightWithContentModel:(GJGCChatContentBaseModel *)contentModel
{
    
}

- (GJGCChatContentBaseModel *)contentModelByLocalMsgId:(NSString *)localMsgId
{
    for (int i = 0 ; i < self.chatListArray.count ; i ++) {
        
        GJGCChatContentBaseModel *contentItem = [self.chatListArray objectAtIndex:i];
        
        if ([contentItem.localMsgId isEqualToString:localMsgId]) {
            
            return contentItem;
            
            break;
        }
    }
    return nil;
}

- (void)updateContentModelValuesNotEffectRowHeight:(GJGCChatContentBaseModel *)contentModel atIndex:(NSInteger)index
{
    if ([contentModel.class isSubclassOfClass:[GJGCChatFriendContentModel class]]) {
        
        GJGCChatFriendContentModel *friendChatModel = (GJGCChatFriendContentModel *)contentModel;
        
        if (friendChatModel.contentType == GJGCChatFriendContentTypeAudio && friendChatModel.isPlayingAudio) {
            
            [self updateAudioFinishRead:friendChatModel.localMsgId];
        }
    }
    [self.chatListArray replaceObjectAtIndex:index withObject:contentModel];
}

- (NSNumber *)addChatContentModel:(GJGCChatContentBaseModel *)contentModel
{
    contentModel.contentSourceIndex = self.chatListArray.count;
    
    NSNumber *heightNew = [NSNumber numberWithFloat:contentModel.contentHeight];
    
    if (contentModel.contentHeight == 0) {
        
        NSArray *contentHeightArray = [self heightForContentModel:contentModel];
        contentModel.contentHeight = [[contentHeightArray firstObject] floatValue];
        contentModel.contentSize = [[contentHeightArray lastObject] CGSizeValue];
        
        [self updateMsgContentHeightWithContentModel:contentModel];
        
    }else{
        
        NSLog(@"不需要计算内容高度:%f",contentModel.contentHeight);
        
    }
    
    [self.chatListArray addObject:contentModel];
    
    return heightNew;
}

- (void)removeChatContentModelAtIndex:(NSInteger)index
{
    [self.chatListArray removeObjectAtIndex:index];
}

- (void)readLastMessagesFromDB
{
    
}

#pragma mark - 删除消息

- (NSArray *)deleteMessageAtIndex:(NSInteger)index
{
    BOOL isDelete = YES;//数据库完成删除动作
    GJGCChatFriendContentModel *deleteContentModel = [self.chatListArray objectAtIndex:index];
    isDelete = [self.taklInfo.conversation removeMessage:[deleteContentModel.messageBody message]];
    
    //消息删没了，把会话也删掉
    if ([self.taklInfo.conversation loadAllMessages].count == 0) {
        [[EaseMob sharedInstance].chatManager removeConversationByChatter:self.taklInfo.toId deleteMessages:YES append2Chat:YES];
    }
    
    NSMutableArray *willDeletePaths = [NSMutableArray array];
    
    if (isDelete) {
        
        /* 更新最近联系人列表得最后一条消息 */
        if (index == self.totalCount - 1 && self.chatContentTotalCount > 1) {
            
            GJGCChatFriendContentModel *lastContentAfterDelete = nil;
            lastContentAfterDelete = (GJGCChatFriendContentModel *)[self contentModelAtIndex:index-1];
            if (lastContentAfterDelete.isTimeSubModel) {
                
                if (self.chatContentTotalCount - 1 >= 1) {
                    
                    lastContentAfterDelete = (GJGCChatFriendContentModel *)[self contentModelAtIndex:index - 2];
                    
                }
                
            }
            
        }
        
        NSString *willDeleteTimeSubIdentifier = [self updateMsgContentTimeStringAtDeleteIndex:index];
        
        [self removeChatContentModelAtIndex:index];
        
        [willDeletePaths addObject:[NSIndexPath indexPathForRow:index inSection:0]];
        
        if (willDeleteTimeSubIdentifier) {
            
            [willDeletePaths addObject:[NSIndexPath indexPathForRow:index - 1 inSection:0]];
            
            [self removeTimeSubByIdentifier:willDeleteTimeSubIdentifier];
        }
    }
    
    return willDeletePaths;
}

#pragma mark - 加载历史消息

- (void)trigglePullHistoryMsgForEarly
{
    NSLog(@"聊天详情触发拉取更早历史消息 talkType:%@ toId:%@",GJGCTalkTypeString(self.taklInfo.talkType),self.taklInfo.toId);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        
        if (self.chatListArray && [self.chatListArray count] > 0) {
            
            /* 去掉时间模型，找到最上面一条消息内容 */
            GJGCChatFriendContentModel *lastMsgContent;
            for (int i = 0; i < self.totalCount ; i++) {
                GJGCChatFriendContentModel *item = (GJGCChatFriendContentModel *)[self contentModelAtIndex:i];
                
                if (!item.isTimeSubModel) {
                    lastMsgContent = item;
                    break;
                }
                
            }
            
            /* 最后一条消息的发送时间 */
            long long lastMsgSendTime;
            if (lastMsgContent) {
                lastMsgSendTime = lastMsgContent.sendTime;
            }else{
                lastMsgSendTime = 0;
            }
            
            //环信精确到毫秒所以要*1000
            NSArray *localHistroyMsgArray = [self.taklInfo.conversation loadNumbersOfMessages:20 before:lastMsgSendTime*1000];
            
            if (localHistroyMsgArray && localHistroyMsgArray.count > 0 ) {
                
                [self pushAddMoreMsg:localHistroyMsgArray];
                
            }else{
                
                self.isFinishLoadAllHistoryMsg = YES;
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    /* 悬停在第一次加载后的第一条消息上 */
                    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSourceManagerRequireFinishRefresh:)]) {
                        
                        [self.delegate dataSourceManagerRequireFinishRefresh:self];
                    }
                    
                });
            }
        }
    });
    
}

- (void)pushAddMoreMsg:(NSArray *)array
{
    
}

#pragma mark - 所有内容重排时间

- (void)resortAllChatContentBySendTime
{
    
    /* 去掉时间区间model */
    for (GJGCChatContentBaseModel *contentBaseModel in self.timeShowSubArray) {
        
        /* 去掉时间区间重新排序 */
        if (contentBaseModel.isTimeSubModel) {
            [self.chatListArray removeObject:contentBaseModel];
        }
        
    }
    
    NSArray *sortedArray = [self.chatListArray sortedArrayUsingSelector:@selector(compareContent:)];
    [self.chatListArray removeAllObjects];
    [self.chatListArray addObjectsFromArray:sortedArray];
    
    /* 重设时间区间 */
    [self updateAllMsgTimeShowString];
}

- (void)resortAllSystemNotiContentBySendTime
{
    NSArray *sortedArray = [self.chatListArray sortedArrayUsingSelector:@selector(compareContent:)];
    [self.chatListArray removeAllObjects];
    [self.chatListArray addObjectsFromArray:sortedArray];
}

#pragma mark - 重设第一条消息的msgId
- (void)resetFirstAndLastMsgId
{
    /* 重新设置第一条消息的Id */
    if (self.chatListArray.count > 0) {
        
        GJGCChatContentBaseModel *firstMsgContent = [self.chatListArray firstObject];
        
        NSInteger nextMsgIndex = 0;
        
        while (firstMsgContent.isTimeSubModel) {
            
            nextMsgIndex++;
            
            firstMsgContent = [self.chatListArray objectAtIndex:nextMsgIndex];
            
        }
        
        self.lastFirstLocalMsgId = firstMsgContent.localMsgId;
    }
}

#pragma mark - 更新所有聊天消息的时间显示块

- (void)updateAllMsgTimeShowString
{
  /* 始终以当前时间为计算基准 最后最新一条时间开始往上计算*/
  [self.timeShowSubArray removeAllObjects];
  
    NSTimeInterval firstMsgTimeInterval = 0;
    
    GJGCChatFriendContentModel *currentTimeSubModel = nil;
    for (NSInteger i = 0; i < self.totalCount; i++) {
        
        GJGCChatFriendContentModel *contentModel = [self.chatListArray objectAtIndex:i];
        if (contentModel.contentType == GJGCChatFriendContentTypeTime) {
            NSLog(@"contentModel is time :%@",contentModel.uniqueIdentifier);
        }
        
        NSString *timeString = [GJGCChatSystemNotiCellStyle timeAgoStringByLastMsgTime:contentModel.sendTime lastMsgTime:firstMsgTimeInterval];
        
        if (timeString) {
            
            /* 创建时间块，插入到数据源 */
            firstMsgTimeInterval = contentModel.sendTime;
            
            GJGCChatFriendContentModel *timeSubModel = [GJGCChatFriendContentModel timeSubModel];
            timeSubModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
            timeSubModel.contentType = GJGCChatFriendContentTypeTime;
            timeSubModel.timeString = [GJGCChatSystemNotiCellStyle formateTime:timeString];
            NSArray *contentHeightArray = [self heightForContentModel:timeSubModel];
            timeSubModel.contentHeight = [[contentHeightArray firstObject] floatValue];
            timeSubModel.sendTime = contentModel.sendTime;
            timeSubModel.timeSubMsgCount = 1;
            
            currentTimeSubModel = timeSubModel;
            
            contentModel.timeSubIdentifier = timeSubModel.uniqueIdentifier;
            
            [self.chatListArray replaceObjectAtIndex:i withObject:contentModel];
            
            [self.chatListArray insertObject:timeSubModel atIndex:i];
            
            i++;
        
            [self.timeShowSubArray addObject:timeSubModel];
            
        }else{
            
            contentModel.timeSubIdentifier = currentTimeSubModel.uniqueIdentifier;
            currentTimeSubModel.timeSubMsgCount = currentTimeSubModel.timeSubMsgCount + 1;
            
            [self updateContentModelByUniqueIdentifier:contentModel];
            [self updateContentModelByUniqueIdentifier:currentTimeSubModel];
            
        }
    }
}

- (void)updateContentModelByUniqueIdentifier:(GJGCChatContentBaseModel *)contentModel
{
    for (NSInteger i = 0; i < self.totalCount ; i++) {
        
        GJGCChatContentBaseModel *itemModel = [self.chatListArray objectAtIndex:i];
        
        if ([itemModel.uniqueIdentifier isEqualToString:contentModel.uniqueIdentifier]) {
            
            [self.chatListArray replaceObjectAtIndex:i withObject:contentModel];
            
            break;
        }
    }
}

- (GJGCChatContentBaseModel *)timeSubModelByUniqueIdentifier:(NSString *)identifier
{
    for (GJGCChatContentBaseModel *timeSubModel in self.chatListArray) {
        
        if ([timeSubModel.uniqueIdentifier isEqualToString:identifier]) {
            
            return timeSubModel;
        }
    }
    return nil;
}

- (void)updateTheNewMsgTimeString:(GJGCChatContentBaseModel *)contentModel
{
    NSTimeInterval lastSubTimeInteval;
     GJGCChatFriendContentModel *lastTimeSubModel = [self.timeShowSubArray lastObject];
    if (self.timeShowSubArray.count > 0) {
        lastSubTimeInteval = lastTimeSubModel.sendTime;
    }else{
        lastSubTimeInteval = 0;
    }
    
    NSString *timeString = [GJGCChatSystemNotiCellStyle timeAgoStringByLastMsgTime:contentModel.sendTime lastMsgTime:lastSubTimeInteval];
    
    if (timeString) {
        
        GJGCChatFriendContentModel *newLastTimeSubModel = [GJGCChatFriendContentModel timeSubModel];
        newLastTimeSubModel.baseMessageType = GJGCChatBaseMessageTypeChatMessage;
        newLastTimeSubModel.contentType = GJGCChatFriendContentTypeTime;
        newLastTimeSubModel.sendTime = contentModel.sendTime;
        newLastTimeSubModel.timeString = [GJGCChatSystemNotiCellStyle formateTime:timeString];
        NSArray *contentHeightArray = [self heightForContentModel:newLastTimeSubModel];
        newLastTimeSubModel.contentHeight = [[contentHeightArray firstObject] floatValue];
        newLastTimeSubModel.timeSubMsgCount = 1;
        
        contentModel.timeSubIdentifier = newLastTimeSubModel.uniqueIdentifier;
        
        [self updateContentModelByUniqueIdentifier:contentModel];
        
        [self.chatListArray insertObject:newLastTimeSubModel atIndex:self.totalCount - 1];
        
        [self.timeShowSubArray addObject:newLastTimeSubModel];

    }else{
        
        contentModel.timeSubIdentifier = lastTimeSubModel.uniqueIdentifier;
        lastTimeSubModel.timeSubMsgCount = lastTimeSubModel.timeSubMsgCount + 1;
        
        [self updateContentModelByUniqueIdentifier:contentModel];
        [self updateContentModelByUniqueIdentifier:lastTimeSubModel];
        
    }
    
}

/* 删除某条消息，更新下一条消息的区间 */
- (NSString *)updateMsgContentTimeStringAtDeleteIndex:(NSInteger)index
{
    GJGCChatContentBaseModel *contentModel = [self.chatListArray objectAtIndex:index];
    
    GJGCChatContentBaseModel *timeSubModel = [self timeSubModelByUniqueIdentifier:contentModel.timeSubIdentifier];
    timeSubModel.timeSubMsgCount = timeSubModel.timeSubMsgCount - 1;
    
    if (timeSubModel.timeSubMsgCount == 0) {
        
        return timeSubModel.uniqueIdentifier;
        
    }else{
        
        [self updateContentModelByUniqueIdentifier:timeSubModel];
        
        return nil;
    }
}

- (void)removeContentModelByIdentifier:(NSString *)identifier
{
    for (GJGCChatContentBaseModel *item in self.chatListArray) {
        
        if ([item.uniqueIdentifier isEqualToString:identifier]) {
            
            [self.chatListArray removeObject:item];
            
            break;
        }
    }
}

- (void)removeTimeSubByIdentifier:(NSString *)identifier
{
    [self removeContentModelByIdentifier:identifier];
    
    for (GJGCChatContentBaseModel *item in self.timeShowSubArray) {
        
        if ([item.uniqueIdentifier isEqualToString:identifier]) {
            
            [self.timeShowSubArray removeObject:item];
            
            break;
        }
    }
}

- (NSInteger)getContentModelIndexByLocalMsgId:(NSString *)msgId
{
    NSInteger resultIndex = NSNotFound;
 
    if (GJCFStringIsNull(msgId)) {
        return resultIndex;
    }
    
    for ( int i = 0; i < self.chatListArray.count; i++) {
        
        GJGCChatContentBaseModel *contentModel = [self.chatListArray objectAtIndex:i];
        
        if ([contentModel.localMsgId isEqualToString:msgId]) {
            
            resultIndex = i;
            
            break;
        }

    }
    
    return resultIndex;
}

- (GJGCChatContentBaseModel *)contentModelByMsgId:(NSString *)msgId
{
    NSInteger resultIndex = [self getContentModelIndexByLocalMsgId:msgId];
    
    if (resultIndex != NSNotFound) {
        
        return [self.chatListArray objectAtIndex:resultIndex];
    }
    return nil;
}

- (void)updateLastSystemMessageForRecentTalk
{

}

#pragma mark - 清除过早历史消息

- (void)clearOverEarlyMessage
{
    if (self.totalCount > 40) {
        
        [self.chatListArray removeObjectsInRange:NSMakeRange(0, self.totalCount - 40)];
        self.isFinishLoadAllHistoryMsg = NO;//重新可以数据库翻页
        [self resetFirstAndLastMsgId];
        
        dispatch_source_merge_data(_refreshListSource, 1);
    }
}

#pragma mark - 格式化消息内容

- (GJGCChatFriendContentType)formateChatFriendContent:(GJGCChatFriendContentModel *)chatContentModel withMsgModel:(EMMessage *)msgModel
{
    GJGCChatFriendContentType type = GJGCChatFriendContentTypeNotFound;
    
    NSArray *bodies = msgModel.messageBodies;
    
    id<IEMMessageBody> messageBody = [bodies firstObject];
    chatContentModel.messageBody = messageBody;
    chatContentModel.contentType = type;
    
    //普通文本消息和依靠普通文本消息扩展出来的消息类型
    GJGCMessageExtendModel *extendModel = [[GJGCMessageExtendModel alloc]initWithDictionary:msgModel.ext];
    
    switch ([messageBody messageBodyType]) {
        case eMessageBodyType_Image:
        {
            chatContentModel.contentType = GJGCChatFriendContentTypeImage;
        }
            break;
        case eMessageBodyType_Text:
        {
            NSLog(@"解析扩展内容:%@",[extendModel contentDictionary]);
            
            //普通文本消息
            if (!extendModel.isExtendMessageContent) {
                
                chatContentModel.contentType = GJGCChatFriendContentTypeText;
                
                EMTextMessageBody *textMessageBody = (EMTextMessageBody *)messageBody;
                
                if (!GJCFNSCacheGetValue(textMessageBody.text)) {
                    [GJGCChatFriendCellStyle formateSimpleTextMessage:textMessageBody.text];
                }
                chatContentModel.originTextMessage = textMessageBody.text;
                
            }
            
            //扩展消息类型
            if (extendModel.isExtendMessageContent) {
                
                chatContentModel.contentType = extendModel.chatFriendContentType;
                
                //是否支持显示的扩展消息
                if (extendModel.isSupportDisplay) {
                    
                    //进一步解析消息内容
                    switch (extendModel.chatFriendContentType) {
                        case GJGCChatFriendContentTypeGif:
                        {
                            GJGCMessageExtendContentGIFModel *gifContent = (GJGCMessageExtendContentGIFModel *)extendModel.messageContent;
                            chatContentModel.gifLocalId = gifContent.emojiCode;
                        }
                            break;
                        case GJGCChatFriendContentTypeMusicShare:
                        {
                            GJGCMessageExtendMusicShareModel  *musicContent = (GJGCMessageExtendMusicShareModel *)extendModel.messageContent;
                            chatContentModel.musicSongId = musicContent.songId;
                            chatContentModel.musicSongName = musicContent.title;
                            chatContentModel.musicSongUrl = musicContent.songUrl;
                            chatContentModel.musicSongAuthor = musicContent.author;
                        }
                            break;
                        case GJGCChatFriendContentTypeWebPage:
                        {
                            GJGCMessageExtendContentWebPageModel *webPageContent = (GJGCMessageExtendContentWebPageModel *)extendModel.messageContent;
                            chatContentModel.webPageThumbImageData = [webPageContent.thumbImageBase64 base64DecodedData];
                            chatContentModel.webPageTitle = webPageContent.title;
                            chatContentModel.webPageSumary = webPageContent.sumary;
                            chatContentModel.webPageUrl = webPageContent.url;
                            
                        }
                            break;
                        default:
                            break;
                    }
                }
                
                //如果不支持，需要将消息显示成文本消息
                if (![extendModel isSupportDisplay]) {
                    
                    chatContentModel.contentType = GJGCChatFriendContentTypeText;
                    
                    EMTextMessageBody *textMessageBody = (EMTextMessageBody *)messageBody;
                    
                    if (!GJCFNSCacheGetValue(textMessageBody.text)) {
                        [GJGCChatFriendCellStyle formateSimpleTextMessage:textMessageBody.text];
                    }
                    chatContentModel.originTextMessage = textMessageBody.text;
                }
            }
        }
            break;
        case eMessageBodyType_Command:
        {
            
        }
            break;
        case eMessageBodyType_File:
        {
            
        }
            break;
        case eMessageBodyType_Location:
        {
            
        }
            break;
        case eMessageBodyType_Video:
        {
            
        }
            break;
        case eMessageBodyType_Voice:
        {
            chatContentModel.contentType = GJGCChatFriendContentTypeAudio;
            
            EMVoiceMessageBody *voiceMessageBody = (EMVoiceMessageBody *)messageBody;
            
            chatContentModel.audioModel.localStorePath = voiceMessageBody.localPath;
            chatContentModel.audioModel.duration = voiceMessageBody.duration;
            chatContentModel.audioDuration =  [GJGCChatFriendCellStyle formateAudioDuration:GJCFStringFromInt(chatContentModel.audioModel.duration)];
        }
            break;
        default:
            break;
    }
    type = chatContentModel.contentType;
    
    //解析用户信息
    chatContentModel.headUrl = extendModel.userInfo.headThumb;
    if (chatContentModel.talkType == GJGCChatFriendTalkTypeGroup) {
        chatContentModel.senderName = [GJGCChatFriendCellStyle formateGroupChatSenderName:extendModel.userInfo.nickName];
    }
    
    return type;
}

- (BOOL)sendMesssage:(GJGCChatFriendContentModel *)messageContent
{
    /*
     * 只有文本和gif这类消息会产生速度检测，
     * 如果不加这个判定的话，在发送多张图片的时候，
     * 分割成单张，会被认为间隔时间太短
     */
     if (messageContent.contentType == GJGCChatFriendContentTypeText || messageContent.contentType == GJGCChatFriendContentTypeGif || messageContent.contentType == GJGCChatFriendContentTypeGif ) {
         if (self.lastSendMsgTime != 0) {
            
            //间隔太短
            NSTimeInterval now = [[NSDate date]timeIntervalSince1970]*1000;
            if (now - self.lastSendMsgTime < self.sendTimeLimit) {
                return NO;
            }
        }
    }
    
    messageContent.sendStatus = GJGCChatFriendSendMessageStatusSending;
    EMMessage *mesage = [self sendMessageContent:messageContent];
    messageContent.messageBody = [mesage.messageBodies firstObject];
    messageContent.localMsgId = mesage.messageId;
    messageContent.easeMessageTime = mesage.timestamp;
    messageContent.sendTime = (NSInteger)(mesage.timestamp/1000);
    [messageContent setupUserInfoByExtendUserContent:[[ZYUserCenter shareCenter]extendUserInfo]];

    //收到消息
    [self addChatContentModel:messageContent];
    
    [self updateTheNewMsgTimeString:messageContent];
    
    //缓冲刷新
    dispatch_source_merge_data(_refreshListSource, 1);
    
    self.lastSendMsgTime = [[NSDate date]timeIntervalSince1970]*1000;
    
    return YES;
}

- (void)reSendMesssage:(GJGCChatFriendContentModel *)messageContent
{
    GJCFWeakSelf weakSelf = self;
    [[EaseMob sharedInstance].chatManager asyncResendMessage:[messageContent.messageBody message] progress:self prepare:^(EMMessage *message, EMError *error) {
        
    } onQueue:_messageSenderQueue completion:^(EMMessage *message, EMError *error) {
        
        GJGCChatFriendSendMessageStatus status = GJGCChatFriendSendMessageStatusSending;
        switch (message.deliveryState) {
            case eMessageDeliveryState_Pending:
            case eMessageDeliveryState_Delivering:
            {
                status = GJGCChatFriendSendMessageStatusSending;
            }
                break;
            case eMessageDeliveryState_Delivered:
            {
                status = GJGCChatFriendSendMessageStatusSuccess;
            }
                break;
            case eMessageDeliveryState_Failure:
            {
                status = GJGCChatFriendSendMessageStatusFaild;
            }
                break;
            default:
                break;
        }
        
        [weakSelf updateMessageState:message state:status];
        
    } onQueue:_messageSenderQueue];
}

#pragma mark - 收环信消息到数据源，子类具体实现
- (GJGCChatFriendContentModel *)addEaseMessage:(EMMessage *)aMessage
{
    return nil;
}

#pragma mark -  环信发送消息过程

- (EMMessage *)sendMessageContent:(GJGCChatFriendContentModel *)messageContent
{
    //如果当前会话信息不存在，创建一个
    if (!self.taklInfo.conversation) {
        EMConversationType conversationType;
        switch (self.taklInfo.talkType) {
            case GJGCChatFriendTalkTypePrivate:
                conversationType = eConversationTypeChat;
                break;
            case GJGCChatFriendTalkTypeGroup:
                conversationType = eConversationTypeGroupChat;
                break;
            default:
                break;
        }
        self.taklInfo.conversation = [[EaseMob sharedInstance].chatManager conversationForChatter:messageContent.toId conversationType:conversationType];
    }
    
    EMMessage *sendMessage = nil;
    switch (messageContent.contentType) {
        case GJGCChatFriendContentTypeText:
        {
            sendMessage = [self sendTextMessage:messageContent];
        }
            break;
        case GJGCChatFriendContentTypeAudio:
        {
            sendMessage = [self sendAudioMessage:messageContent];
        }
            break;
        case GJGCChatFriendContentTypeImage:
        {
            sendMessage = [self sendImageMessage:messageContent];
        }
            break;
        default:
            break;
    }
    
    //添加用户扩展信息
    GJGCMessageExtendModel *extendInfo = [[GJGCMessageExtendModel alloc]init];
    extendInfo.userInfo = [[ZYUserCenter shareCenter]extendUserInfo];
    extendInfo.isExtendMessageContent = NO;
    sendMessage.ext = [extendInfo contentDictionary];
    
    //添加群组扩展信息
    if (self.taklInfo.talkType == GJGCChatFriendTalkTypeGroup) {
        GJGCMessageExtendGroupModel *groupInfo = [[GJGCMessageExtendGroupModel alloc]init];
        
        //是否有扩展信息
        if (self.taklInfo.groupInfo) {
            
            groupInfo.groupName = self.taklInfo.groupInfo.groupName;
            groupInfo.groupHeadThumb = self.taklInfo.groupInfo.groupHeadThumb;
            
        }else{
            
            groupInfo.groupName = self.taklInfo.toUserName;
            groupInfo.groupHeadThumb = @"";
            
        }
        

        extendInfo.isGroupMessage = YES;
        extendInfo.groupInfo = groupInfo;
    }
    
    //发送扩展类型的消息
    switch (messageContent.contentType) {
        case GJGCChatFriendContentTypeGif:
        {
            extendInfo.isExtendMessageContent = YES;
            
            GJGCMessageExtendContentGIFModel *gifContent = [[GJGCMessageExtendContentGIFModel alloc]init];
            gifContent.emojiCode = messageContent.gifLocalId;
            gifContent.emojiVersion = GJCFSystemAppStringVersion;
            gifContent.displayText = [GJGCGIFLoadManager gifNameById:messageContent.gifLocalId];
            gifContent.notSupportDisplayText = [NSString stringWithFormat:@"[GIF:%@]请更新你的源代码以支持此表情显示",gifContent.displayText];
            
            messageContent.originTextMessage = gifContent.notSupportDisplayText;
            sendMessage = [self sendTextMessage:messageContent];
            
            extendInfo.messageContent = gifContent;
            extendInfo.chatFriendContentType = messageContent.contentType;
        }
            break;
        case GJGCChatFriendContentTypeMini:
        {
            
        }
            break;
        default:
            break;
    }
    
    //设置消息类型
    switch (messageContent.talkType) {
        case GJGCChatFriendTalkTypePrivate:
            sendMessage.messageType = eMessageTypeChat;
            break;
        case GJGCChatFriendTalkTypeGroup:
            sendMessage.messageType = eMessageTypeGroupChat;
            break;
        default:
            break;
    }
    sendMessage.ext = [extendInfo contentDictionary];
    NSLog(@"sendMessage Ext:%@",sendMessage.ext);
    
    GJCFWeakSelf weakSelf = self;
    EMMessage *resultMessage = [[EaseMob sharedInstance].chatManager asyncSendMessage:sendMessage progress:self prepare:^(EMMessage *message, EMError *error) {
        
    } onQueue:_messageSenderQueue completion:^(EMMessage *message, EMError *error) {
        
        GJGCChatFriendSendMessageStatus status = GJGCChatFriendSendMessageStatusSending;
        switch (message.deliveryState) {
            case eMessageDeliveryState_Pending:
            case eMessageDeliveryState_Delivering:
            {
                status = GJGCChatFriendSendMessageStatusSending;
            }
                break;
            case eMessageDeliveryState_Delivered:
            {
                status = GJGCChatFriendSendMessageStatusSuccess;
            }
                break;
            case eMessageDeliveryState_Failure:
            {
                status = GJGCChatFriendSendMessageStatusFaild;
            }
                break;
            default:
                break;
        }
        
        [weakSelf updateMessageState:message state:status];
        
    } onQueue:_messageSenderQueue];
        
    return resultMessage;
}

- (EMMessage *)sendTextMessage:(GJGCChatFriendContentModel *)messageContent
{
    EMChatText *chatText = [[EMChatText alloc]initWithText:messageContent.originTextMessage];
    EMTextMessageBody *messageBody = [[EMTextMessageBody alloc]initWithChatObject:chatText];
    EMMessage *aMessage = [[EMMessage alloc]initWithReceiver:messageContent.toId bodies:@[messageBody]];
    
    return aMessage;
}

- (EMMessage *)sendAudioMessage:(GJGCChatFriendContentModel *)messageContent
{
    EMChatVoice *voice = [[EMChatVoice alloc] initWithFile:messageContent.audioModel.localStorePath displayName:@"[语音]"];
    voice.duration = messageContent.audioModel.duration;
    EMVoiceMessageBody *body = [[EMVoiceMessageBody alloc] initWithChatObject:voice];
    
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:messageContent.toId bodies:@[body]];
    
    return message;
}

- (EMMessage *)sendImageMessage:(GJGCChatFriendContentModel *)messageContent
{
    NSString *filePath = [[GJCFCachePathManager shareManager]mainImageCacheFilePath:messageContent.imageLocalCachePath];
    EMChatImage *imgChat = [[EMChatImage alloc] initWithUIImage:[UIImage imageWithContentsOfFile:filePath] displayName:@"[图片]"];
    EMImageMessageBody *body = [[EMImageMessageBody alloc] initWithChatObject:imgChat];
    
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:messageContent.toId bodies:@[body]];
    
    return message;
}

#pragma mark - 聊天消息发送回调

- (void)setProgress:(float)progress forMessage:(EMMessage *)message forMessageBody:(id<IEMMessageBody>)messageBody
{
    
}

- (void)updateMessageState:(EMMessage *)theMessage state:(GJGCChatFriendSendMessageStatus)status
{
    GJGCChatFriendContentModel *findContent = nil;
    NSInteger findIndex = NSNotFound;
    
    for (NSInteger index =0 ;index < self.chatListArray.count;index++) {
        
        GJGCChatFriendContentModel *content = [self.chatListArray objectAtIndex:index];
        
        if (content.easeMessageTime == theMessage.timestamp) {
            
            findContent = content;
            findIndex = index;
            
            break;
        }
    }
    
    if (findContent && findIndex !=NSNotFound) {
        
        findContent.sendStatus = status;
        [self.chatListArray replaceObjectAtIndex:findIndex withObject:findContent];
        
        [self.delegate dataSourceManagerRequireUpdateListTable:self reloadAtIndex:findIndex];
    }
}

#pragma mark - Dispatch 缓冲刷新会话列表

- (void)dispatchOptimzeRefresh
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(dataSourceManagerRequireUpdateListTable:)]) {
        
        [self.delegate dataSourceManagerRequireUpdateListTable:self];
    }
}

#pragma mark - 接收消息回调

- (void)didReceiveMessage:(EMMessage *)message
{
    if ([message.from isEqualToString:self.taklInfo.toId]) {
        
        GJGCChatContentBaseModel *contenModel = [self addEaseMessage:message];
        
        [self updateTheNewMsgTimeString:contenModel];
        
        dispatch_source_merge_data(_refreshListSource, 1);
    }
}

- (void)didReceiveMessageId:(NSString *)messageId chatter:(NSString *)conversationChatter error:(EMError *)error
{
    
}

- (void)didReceiveOfflineMessages:(NSArray *)offlineMessages
{
    
}

#pragma mark - 检测网络变化

- (void)didConnectionStateChanged:(EMConnectionState)connectionState
{
    if (connectionState == eEMConnectionDisconnected) {
        
        //把所有发送状态的消息改为失败
        for (NSInteger index = 0; index < self.chatListArray.count; index++) {
            
            GJGCChatFriendContentModel *contentModel = self.chatListArray[index];
            
            if (contentModel.sendStatus == GJGCChatFriendSendMessageStatusSending) {
                
                contentModel.sendStatus = GJGCChatFriendSendMessageStatusFaild;
                
                [[contentModel.messageBody message] updateMessageStatusFailedToDB];
                
                [self.chatListArray replaceObjectAtIndex:index withObject:contentModel];
            }
        }
        
        dispatch_source_merge_data(self.refreshListSource, 1);
    }
}


- (NSDictionary *)easeMessageStateRleations
{
    return @{
             @(eMessageDeliveryState_Delivered):@(GJGCChatFriendSendMessageStatusSuccess),
             @(eMessageDeliveryState_Delivering):@(GJGCChatFriendSendMessageStatusSending),
             @(eMessageDeliveryState_Pending):@(GJGCChatFriendSendMessageStatusSending),
             @(eMessageDeliveryState_Failure):@(GJGCChatFriendSendMessageStatusFaild),
             };
}

#pragma mark 音乐播放

- (void)tapMusicPlayAtIndexPath:(NSIndexPath *)indexPath
{
    GJGCChatFriendContentModel *chatModel = (GJGCChatFriendContentModel *)[self.chatListArray objectAtIndex:indexPath.row];
    chatModel.isMusicPlaying = !chatModel.isMusicPlaying;
    
    
    [self.delegate dataSourceManagerRequireUpdateListTable:self reloadAtIndex:indexPath.row];
}

@end
