//
//  GJGCInformationGroupShowCell.m
//  GJGroupChat
//
//  Created by ZYVincent QQ:1003081775 on 14-11-6.
//  Copyright (c) 2014年 ZYV. All rights reserved.
//

#import "GJGCInformationGroupShowCell.h"

#define GJGCInformationGroupShowCellTag 112244330

@implementation GJGCInformationGroupShowCell



- (CGFloat)setupGroupItemWithArray:(NSArray *)groupItems
{
    CGFloat baseOriginY = 0.5f;
    for (UIView *tempView in self.baseContentView.subviews) {
        if ([tempView isKindOfClass:[GJGCInformationGroupShowItem class]]) {
            [tempView removeFromSuperview];
        }
    }
        
    for (int i = 0 ; i < groupItems.count; i++) {
        
        GJGCInformationGroupShowItemModel *itemModel = [groupItems objectAtIndex:i];

        GJGCInformationGroupShowItem *item = (GJGCInformationGroupShowItem *)[self.baseContentView viewWithTag:GJGCInformationGroupShowCellTag + i];
        if (!item) {
            // 向右箭头图片
            UIImage *arrowImg = [UIImage imageNamed:@"按钮箭头"];
            // 加入群组
            item = [[GJGCInformationGroupShowItem alloc]init];
            item.gjcf_left = self.tagLabel.gjcf_right + 13;
            item.gjcf_top = baseOriginY + 46*i;
            item.gjcf_width = GJCFSystemScreenWidth - 13 - 16 - 64;
            item.gjcf_height = 46;
            item.tag = GJGCInformationGroupShowCellTag + i;
            item.nameLabel.numberOfLines = 0;
            item.nameLabel.isTailMode = YES;
            item.nameLabel.isOneLineTailMode = YES;
            item.nameLabel.contentBaseWidth = item.nameLabel.gjcf_width - arrowImg.size.width - 16*3;
            [item setBackgroundImage:GJCFQuickImageByColorWithSize([GJGCCommonFontColorStyle tapHighlightColor], item.gjcf_size) forState:UIControlStateHighlighted];
            [item addTarget:self action:@selector(tapOnGroupItem:) forControlEvents:UIControlEventTouchUpInside];
            [self.baseContentView addSubview:item];
            
            // 箭头
            UIImageView *_arrImageView = [[UIImageView alloc] init];
            [self.baseContentView addSubview:_arrImageView];
            _arrImageView.image = arrowImg;
            
        }
        item.gjcf_left = self.tagLabel.gjcf_right + 13;
        item.gjcf_top = baseOriginY + 46*i - 0.5;
        item.showBottomSeprateLine = YES;
        [item setGroupItem:itemModel];
        item.nameLabel.isOneLineTailMode = YES;
        item.nameLabel.numberOfLines = 0;
        item.nameLabel.isTailMode = YES;
        item.nameLabel.isOneLineTailMode = YES;

        if (i == groupItems.count - 1) {
            item.showBottomSeprateLine = NO;
            return item.gjcf_bottom;
        }
    }
    return 10.f;
}

- (void)tapOnGroupItem:(GJGCInformationGroupShowItem *)sender
{
    NSInteger index = sender.tag - GJGCInformationGroupShowCellTag;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(informationGroupShowCell:didTapOnGroupItemIndex:)]) {
        [self.delegate informationGroupShowCell:self didTapOnGroupItemIndex:index];
    }
}

- (void)setContentInformationModel:(GJGCInformationBaseModel *)contentModel
{
    if (!contentModel) {
        return;
    }
    [super setContentInformationModel:contentModel];
    
    GJGCInformationCellContentModel *informationModel = (GJGCInformationCellContentModel *)contentModel;
    
    if (informationModel.seprateStyle == GJGCInformationSeprateLineStyleTopFullBottomFull || informationModel.seprateStyle == GJGCInformationSeprateLineStyleTopNoneBottomFull) {
        self.tagLabel.gjcf_left = 16.f;
    }else{
        self.tagLabel.gjcf_left = self.baseSeprateLine.gjcf_left;
    }
    self.tagLabel.contentAttributedString = informationModel.tag;
    self.tagLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:informationModel.tag forBaseContentSize:self.tagLabel.contentBaseSize];
    self.contentLabel.hidden = YES;
    
   CGFloat itemBottom = [self setupGroupItemWithArray:informationModel.personShowGroupArray];
    self.baseContentView.gjcf_height = itemBottom;
    
    self.topSeprateLine.gjcf_top = informationModel.topLineMargin;
    self.baseContentView.gjcf_top = self.topSeprateLine.gjcf_bottom-0.5;
    self.baseSeprateLine.gjcf_bottom = self.baseContentView.gjcf_bottom;
    
    self.accessoryIndicatorView.gjcf_centerY = self.contentMargin + self.contentLabel.gjcf_height/2;
}

@end
