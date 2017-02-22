//
//  AGHelper.h
//  AutoGenCode
//
//  Created by company on 16/11/10.
//  Copyright © 2016年 company. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MethObj;

@interface AGHelper : NSObject <NSApplicationDelegate>
- (void)genImplementation:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error;
- (void)genClass:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error;
@end

@interface VarObj : NSObject
@property(nonatomic, strong)    NSString   *type;
@property(nonatomic, strong)    NSString   *name;
@property(nonatomic, assign)	BOOL    isProperty;

@property(nonatomic, strong)    NSString	*fontSize;//label, button, textfield
@property(nonatomic, strong)    NSString	*lines;//only for label
@property(nonatomic, strong)	NSString	*alignment;//label, textfield
@property(nonatomic, strong)    NSString	*frame;
@property(nonatomic, strong)    NSArray <MethObj *>	*arrFrame;
@property(nonatomic, strong)    NSDictionary <NSString *,MethObj *>	*dicFrame;
+(VarObj *)varWithType:(NSString *)type name:(NSString *)name isPro:(BOOL)ispro;
-(NSString *)propertyName;
@end

@interface MethObj : NSObject
@property(nonatomic, strong)    NSString   *typeRet;//返回类型
@property(nonatomic, assign)    BOOL	isClass;//返回值是否是类
@property(nonatomic, strong)    NSString   *def;
@property NSString *haha;
@end

/*
 frame(必须定义在{}之内，各项之间用,隔开):
	 x:10: .frame.origin.x=10
	 y:10: .frame.origin.y=10
	 w:10: .frame.size.width=10
	 h:10: .frame.size.height=10
	 f:labXX.f: .frame = labXX.frame //可以用labXX代替labXX.f
	 f:labXX.b: .frame = labXX.bounds
	 
	 xx.x : xx.frame.origin.x
	 xx.mx : CGRectGetMaxX(xx.frame)
	 xx.y : xx.frame.origin.y
	 xx.my : CGRectGetMaxY(xx.frame)
	 xx.w : xx.frame.size.width
	 xx.h : xx.frame.size.height
	 xx.b : xx.bounds
	 xx.f : xx.frame
 
 property:
	 f/F: font
	 l/L: numberOfLines (only for uilabel)
	 a/A: textAlignment
 
 label: f, l, a  --  F:16;L:l0;A:left;{x:xxx.mx+10,y:10,w:200,h:100}，如果是单行文字，可以不指定高度h,默认为.font.lineHeight
 button: f -- F:16;{x:10,y:10,w:200,h:100}
 textfield: f, a  --  F:16;A:left;{x:10,y:10,w:200,h:100}

**** example ****************************************
 def:
	 @interface OCell : UITableViewCell
	 @property(nonatomic, readonly)    UIView   *vbg;//{f:self.f,y:5,my:self.h-5}
	 @property(nonatomic, readonly)    UILabel   *labTitle;//f:15;l:0;a:left;{x:10, y:10, mx:btnBuy.x-15}
	 @property(nonatomic, readonly)    UILabel   *labPrice;//f:15;a:center;{f:labTitle, y:labTitle.my+10}
	 @property(nonatomic, readonly)    UIButton   *btnBuy;//f:16;{w:60, h:36, mx:self.w-10, y:self.h/2-18}
	 @property(nonatomic, readonly)    UIView   *vline;//{x:10, y:self.h-0.5, w:self.w-10, h:0.5}
	 @property(nonatomic, strong)    NSArray <MethObj *>	*arrFrame;
	 @property(nonatomic, strong)    NSDictionary <NSString *,MethObj *>	*dicFrame;
	 @property NSString *haha;
	 - ( void ) a :(nsstring*)para;
	 - ( nsstring * ) b :(nsstring*)p 
	 bb:(nsstring*)pp;
	 //-(void)c:(nsstring*)para;
	 @end
**** example end ****************************************
 
 */
