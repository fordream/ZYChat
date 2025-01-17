//
//  GJGCChatFriendAndGroupConstans.m
//  ZYChat
//
//  Created by ZYVincent QQ:1003081775 on 14-11-5.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJGCChatFriendConstans.h"

@implementation GJGCChatFriendConstans

+ (NSDictionary *)chatCellIdentifierDict
{
    return @{
             
             @"GJGCChatFriendTextMessageCell" : @"GJGCChatFriendTextMessageCellIdentifier",
             
             @"GJGCChatFriendAudioMessageCell" : @"GJGCChatFriendAudioMessageCellIdentifier",
             
             @"GJGCChatFriendImageMessageCell" : @"GJGCChatFriendImageMessageCellIdentifier",

             @"GJGCChatFriendMiniMessageCell" : @"GJGCChatFriendMiniMessageCellIdentifier",

             @"GJGCChatFriendPostMessageCell" : @"GJGCChatFriendPostMessageCellIdentifier",

             @"GJGCChatFriendTimeCell" : @"GJGCChatFriendTimeCellIdentifier",
             
             @"GJGCChatFriendMemberWelcomeCell": @"GJGCChatFriendMemberWelcomeCellIdentifier",
             
             @"GJGCChatFriendGroupCallCell": @"GJGCChatFriendGroupCallCellIdentifier",

             @"GJGCChatFriendAcceptGroupCallCell": @"GJGCChatFriendAcceptGroupCallCellIdentifier",

             @"GJGCChatFriendGifCell": @"GJGCChatFriendGifCellIdentifier",

             @"GJGCChatFriendDriftBottleCell": @"GJGCChatFriendDriftBottleCellIdentifier",

             @"GJGCChatFriendWebPageCell": @"GJGCChatFriendWebPageCellIdentifier",

             @"GJGCChatFriendMusicShareCell": @"GJGCChatFriendMusicShareCellIdentifier",

             };
    
}

+ (NSDictionary *)chatCellContentTypeDict
{
    return @{
             
             @(GJGCChatFriendContentTypeText) : @"GJGCChatFriendTextMessageCell",
             
             @(GJGCChatFriendContentTypeAudio) : @"GJGCChatFriendAudioMessageCell",
             
             @(GJGCChatFriendContentTypeImage) : @"GJGCChatFriendImageMessageCell",
             
             @(GJGCChatFriendContentTypeMini) : @"GJGCChatFriendMiniMessageCell",

             @(GJGCChatFriendContentTypePost) : @"GJGCChatFriendPostMessageCell",

             @(GJGCChatFriendContentTypeTime) : @"GJGCChatFriendTimeCell",
             
             @(GJGCChatFriendContentTypeMemberWelcome) : @"GJGCChatFriendMemberWelcomeCell",
             
             @(GJGCChatFriendContentTypeGroupCall) : @"GJGCChatFriendGroupCallCell",
             
             @(GJGCChatFriendContentTypeReplyGroupCall) : @"GJGCChatFriendAcceptGroupCallCell",
             
             @(GJGCChatFriendContentTypeGif) : @"GJGCChatFriendGifCell",
             
             @(GJGCChatFriendContentTypeDriftBottle) : @"GJGCChatFriendDriftBottleCell",
             
             @(GJGCChatFriendContentTypeWebPage) : @"GJGCChatFriendWebPageCell",

             @(GJGCChatFriendContentTypeMusicShare) : @"GJGCChatFriendMusicShareCell",

             };
}

+ (NSString *)identifierForCellClass:(NSString *)className
{
    return  [[GJGCChatFriendConstans chatCellIdentifierDict]objectForKey:className];
}

+ (Class)classForContentType:(GJGCChatFriendContentType)contentType
{
    NSString *className = [[GJGCChatFriendConstans chatCellContentTypeDict]objectForKey:@(contentType)];
    
    return NSClassFromString(className);
}

+ (NSString *)identifierForContentType:(GJGCChatFriendContentType)contentType
{
    NSString *className = [[GJGCChatFriendConstans chatCellContentTypeDict]objectForKey:@(contentType)];
    
    return [GJGCChatFriendConstans identifierForCellClass:className];
}

+ (NSString *)contentTypeToString:(GJGCChatFriendContentType)contentType
{
    NSString *resultString = nil;
    
    switch (contentType) {
        
        case GJGCChatFriendContentTypeText:
        {
            resultString = @"text";
        }
        break;
        
        case GJGCChatFriendContentTypeAudio:
        {
            resultString = @"sound";
        }
        break;
        
        case GJGCChatFriendContentTypeImage:
        {
            resultString = @"pic";
        }
        break;
        
        case GJGCChatFriendContentTypePost:
        {
            resultString = @"url";
        }
        break;
        
        case GJGCChatFriendContentTypeMemberWelcome:
        {
            resultString = @"personalcard";
        }
        break;
        
        case GJGCChatFriendContentTypeMini:
        {
            resultString = @"mini";
        }
        break;
        
        case GJGCChatFriendContentTypeGroupCall:
        {
            resultString = @"SummonCard";
        }
        break;
        
        case GJGCChatFriendContentTypeReplyGroupCall:
        {
            resultString = @"acceptSummonCard";
        }
        break;
        
        case GJGCChatFriendContentTypeTime:
        {
            resultString = @"time";
        }
        break;
        
        case GJGCChatFriendContentTypeNotFound:
        {
            resultString = @"notFound";
        }
        break;
            
        case GJGCChatFriendContentTypeGif:
        {
            resultString = @"gif";
        }
            break;
            
        case GJGCChatFriendContentTypeDriftBottle:
        {
            resultString = @"driftbottlecard";
        }
        
            break;
        default:
        
        break;
    }
    
    return resultString;
}

@end
