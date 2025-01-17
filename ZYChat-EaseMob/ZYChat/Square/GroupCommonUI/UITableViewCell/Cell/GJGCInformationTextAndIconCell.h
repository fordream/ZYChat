//
//  GJGCInformationTextAndIconCell.h
//  GJGroupChat
//
//  Created by ZYVincent QQ:1003081775 on 14-11-6.
//  Copyright (c) 2014年 ZYV. All rights reserved.
//

#import "GJGCInformationTextCell.h"

@interface GJGCInformationTextAndIconCell : GJGCInformationTextCell

@property (nonatomic,strong)UIImageView *iconImgView;

@property (nonatomic,strong)GJGCCommonHeadView *headView;

@property (nonatomic,copy) void(^textAndIconCellHeaderClickBlock)(void);

@end
