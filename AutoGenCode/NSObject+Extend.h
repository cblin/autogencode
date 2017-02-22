//
//  NSObject+Extend.h
//  ZhaoQiBangKe_E
//
//  Created by cbl on 15/12/25.
//  Copyright © 2015年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>

//NSString *_Nonnull NSStringFromInt(int value);
//NSString *_Nonnull NSStringFromFloat(float value, int precision);//precision:精确到小数点后的位数
//NSString *_Nonnull NSStringFromLong(long value);
//NSString *_Nonnull NSStringFromNSInteger(NSInteger value);

//#define CheckNull(obj) ([obj isEqual:[NSNull null]] ? nil : obj)

@interface NSDictionary (Extend)

//主要用来解析server返回的json
//-(NSString *_Nullable)strForKey:(NSString *_Nonnull)key;
//-(int)intForKey:(NSString *_Nonnull)key;
//-(long)longForKey:(NSString *_Nonnull)key;
//-(float)floatForKey:(NSString *_Nonnull)key;

/* 将server返回的json中的字典转换成类的定义, 
   只解析一层，如果元素存在字典/数据，不对其中的内容做处理
 */
-(nullable NSString *)toInterfaceDefinitionWithName:(NSString *_Nonnull)clsname;

@end

@interface NSString (Extend)
-(BOOL)isMatchRegExp:(NSString *_Nonnull)regExp;
-(NSString *_Nullable)stringByDeletingPrefix:(NSString *_Nonnull)prefix;//循环去掉前缀prefix
-(NSString *_Nonnull)stringByDeletingSuffix:(NSString *_Nonnull)suffix;//循环去掉后缀suffix
-(NSString *_Nullable)stringByTrimmingSpace;//去掉首尾所有的空格
-(NSString *_Nullable)stringByTrimmingWhitespaceAndNewLine;
-(NSString *_Nullable)stringByTrimmingCharactersInString:(NSString *_Nonnull)string;

-(NSString *_Nullable)lastCharacter;//最后一个字符
-(NSString *_Nullable)stringByDeletingLastCharacter;

-(NSArray *_Nullable)componentsSeparatedByCharactersInString:(NSString *_Nullable)string;
-(NSArray *_Nullable)componentsSeparatedByWhitespace;

@end

