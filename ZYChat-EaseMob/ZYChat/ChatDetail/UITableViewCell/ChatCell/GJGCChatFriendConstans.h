//
//  GJGCChatFriendAndGroupConstans.h
//  ZYChat
//
//  Created by ZYVincent QQ:1003081775 on 14-11-5.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  聊天内容类型
 */
typedef NS_ENUM(NSUInteger, GJGCChatFriendContentType) {
    
    /**
     *  未知类型
     */
    GJGCChatFriendContentTypeNotFound = 0,
    /**
     *  文本消息
     */
    GJGCChatFriendContentTypeText = 1,
    /**
     *  语音消息
     */
    GJGCChatFriendContentTypeAudio = 2,
    /**
     *  图片消息
     */
    GJGCChatFriendContentTypeImage = 3,
    /**
     *  帖子
     */
    GJGCChatFriendContentTypePost = 4,
    /**
     *  Mini Message
     */
    GJGCChatFriendContentTypeMini = 5,
    /**
     *  时间区间
     */
    GJGCChatFriendContentTypeTime = 6,
    /**
     *  新人欢迎
     */
    GJGCChatFriendContentTypeMemberWelcome = 7,
    /**
     *  群主召唤
     */
    GJGCChatFriendContentTypeGroupCall = 8,
    /**
     *  响应群主召唤
     */
    GJGCChatFriendContentTypeReplyGroupCall = 9,
    /**
     *  gif表情
     */
    GJGCChatFriendContentTypeGif = 10,
    /**
     *  漂流瓶
     */
    GJGCChatFriendContentTypeDriftBottle = 11,
    /**
     *  网页消息
     */
    GJGCChatFriendContentTypeWebPage = 12,
    /**
     *  音乐分享
     */
    GJGCChatFriendContentTypeMusicShare = 13,
    
};

#define GJGCContentTypeToString(contentType) [GJGCChatFriendConstans contentTypeToString:contentType]

@interface GJGCChatFriendConstans : NSObject

+ (NSString *)contentTypeToString:(GJGCChatFriendContentType)contentType;

+ (NSString *)identifierForContentType:(GJGCChatFriendContentType)contentType;

+ (Class)classForContentType:(GJGCChatFriendContentType)contentType;

@end
