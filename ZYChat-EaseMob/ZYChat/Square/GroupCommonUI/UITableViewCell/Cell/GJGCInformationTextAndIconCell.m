//
//  GJGCInformationTextAndIconCell.m
//  GJGroupChat
//
//  Created by ZYVincent QQ:1003081775 on 14-11-6.
//  Copyright (c) 2014年 ZYV. All rights reserved.
//

#import "GJGCInformationTextAndIconCell.h"

#import "GJGCTagView.h"

@implementation GJGCInformationTextAndIconCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.iconImgView = [[UIImageView alloc]init];
        self.iconImgView.gjcf_right = self.accessoryIndicatorView.gjcf_left + self.contentMargin;
        self.iconImgView.gjcf_top = self.topBordMargin;
        self.iconImgView.gjcf_width = 22;
        self.iconImgView.gjcf_height = 22;
        [self.baseContentView addSubview:self.iconImgView];
        self.contentLabel.contentBaseWidth = self.iconImgView.gjcf_left - 3*self.contentMargin - self.tagLabel.gjcf_width;
        
        self.headView = [[GJGCCommonHeadView alloc]init];
        self.headView.gjcf_top = 33;
        self.headView.gjcf_left = self.tagLabel.gjcf_right + 16;
        self.headView.gjcf_width = 28;
        self.headView.gjcf_height = self.headView.gjcf_width;
        [self.baseContentView addSubview:self.headView];
        [self.headView addTarget:self action:@selector(headerClicked:) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return self;
}

- (void)setContentInformationModel:(GJGCInformationBaseModel *)contentModel
{
    if (!contentModel) {
        return;
    }
    
    
    [super setContentInformationModel:contentModel];
    
    GJGCInformationCellContentModel *informationModel = (GJGCInformationCellContentModel *)contentModel;
    
    /* 是否显示群主 */
    if (informationModel.isIconShowGroupOwner && informationModel.isShowOwnerIcon) {
    
        self.headView.hidden = NO;
        self.iconImgView.hidden = YES;
        [self.headView setHeadUrl:informationModel.headUrl headViewType:GJGCCommonHeadViewTypeContact];
        self.headView.enabled = YES;
        
    }else{
        if (informationModel.isShowOwnerIcon) {
            self.accessoryIndicatorView.hidden = YES;
        }
        self.headView.hidden = YES;
        self.iconImgView.hidden = NO;
        self.iconImgView.image = GJCFQuickImage(informationModel.iconImageName);
    }
    
    if (informationModel.seprateStyle == GJGCInformationSeprateLineStyleTopFullBottomFull || informationModel.seprateStyle == GJGCInformationSeprateLineStyleTopNoneBottomFull) {
        self.tagLabel.gjcf_left = 16.f;
    }else{
        self.tagLabel.gjcf_left = self.baseSeprateLine.gjcf_left;
    }
    self.tagLabel.contentAttributedString = informationModel.tag;
    self.tagLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:informationModel.tag forBaseContentSize:self.tagLabel.contentBaseSize];
    
    if (informationModel.isIconShowGroupOwner && informationModel.isShowOwnerIcon) {
        self.headView.gjcf_left = self.tagLabel.gjcf_right + 16;
        self.contentLabel.gjcf_left = self.headView.gjcf_right + 8;
        self.baseContentView.gjcf_height = self.tagLabel.gjcf_bottom + self.topBordMargin;
        self.headView.gjcf_centerY = self.baseContentView.gjcf_height/2;
    }else{
        self.contentLabel.gjcf_left = self.tagLabel.gjcf_right + 16;
        self.iconImgView.gjcf_right = self.accessoryIndicatorView.gjcf_left - 8;
        self.baseContentView.gjcf_height = self.tagLabel.gjcf_bottom + self.topBordMargin;
        self.iconImgView.gjcf_centerY = self.accessoryIndicatorView.gjcf_centerY;
    }
    
    self.topSeprateLine.gjcf_top = informationModel.topLineMargin;
    self.baseContentView.gjcf_top = self.topSeprateLine.gjcf_bottom-0.5;
    self.baseSeprateLine.gjcf_bottom = self.baseContentView.gjcf_bottom;

}

-(void)headerClicked:(UIButton*)aButton
{
    if (_textAndIconCellHeaderClickBlock) {
        _textAndIconCellHeaderClickBlock();
    }
}

@end
