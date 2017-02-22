//
//  NSObject+Extend.m
//  ZhaoQiBangKe_E
//
//  Created by cbl on 15/12/25.
//  Copyright © 2015年 apple. All rights reserved.
//

#import "NSObject+Extend.h"

//NSString *_Nonnull NSStringFromInt(int value)
//{
//	return [NSString stringWithFormat:@"%d", value];
//}
//NSString *_Nonnull NSStringFromFloat(float value, int precision)
//{
//	NSString *str = [NSString stringWithFormat:@"%%.%df", precision];
//	return [NSString stringWithFormat:str, value];
//}
//NSString *_Nonnull NSStringFromLong(long value)
//{
//	return [NSString stringWithFormat:@"%ld", value];
//}
//NSString *_Nonnull NSStringFromNSInteger(NSInteger value)
//{
//	return [NSString stringWithFormat:@"%ld", (long)value];
//}

@implementation NSDictionary (Extend)

//-(NSString *)strForKey:(NSString *)key
//{
//	id obj = [self objectForKey:key];
//	if (obj && ![obj isEqual:[NSNull null]]) {
//		if ([obj isKindOfClass:[NSString class]]) {
//			return obj;
//		}
//		return [NSString stringWithFormat:@"%@", obj];
//	}
//	return nil;
//}
//-(int)intForKey:(NSString *)key
//{
//	return [[self strForKey:key] intValue];
//}
//-(long)longForKey:(NSString *)key
//{
//	return (long)[[self strForKey:key] longLongValue];
//}
//-(float)floatForKey:(NSString *)key
//{
//	return [[self strForKey:key] floatValue];
//}
-(nullable NSString *)toInterfaceDefinitionWithName:(NSString *)clsname
{
	NSArray *arrKey = [self allKeys];
	
	NSMutableString *strH = [[NSMutableString alloc] init];//h文件的内容
	[strH appendString:@"#pragma mark -\n"];
	[strH appendFormat:@"@interface %@ : NSObject\n", clsname];
	for (int i = 0; i < [arrKey count]; i++) {
		NSString *key = [arrKey objectAtIndex:i];
		
		NSString *first = [key substringWithRange:NSMakeRange(0, 1)];
		NSString *lowerFirst = [first lowercaseString];
		NSString *vname = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:lowerFirst];
		if ([[vname lowercaseString] hasPrefix:@"description"]) {
			vname = [NSString stringWithFormat:@"m_%@", vname];
		}
		
		id value = [self objectForKey:key];
		if ([value isKindOfClass:[NSString class]]) {
			[strH appendFormat:@"@property(nonatomic, strong)\tNSString\t*%@;\n", vname];
		} else if ([value isKindOfClass:[NSNumber class]]) {
			[strH appendFormat:@"@property(nonatomic, strong)\tNSNumber\t*%@;\n", vname];
		}  else if ([value isKindOfClass:[NSArray class]]) {
			[strH appendFormat:@"@property(nonatomic, strong)\tNSMutableArray\t*%@;\n", vname];
		} else if ([value isKindOfClass:[NSDictionary class]]) {
			[strH appendFormat:@"@property(nonatomic, strong)\tNSMutableDictionary\t*%@;\n", vname];
		}
	}
	[strH appendFormat:@"+(%@ *)genFromDic:(NSDictionary *)dic;\n@end", clsname];
	
	
	NSMutableString *strM = [[NSMutableString alloc] init];//m文件的内容
	[strM appendFormat:@"#pragma mark -\n@implementation %@ \n", clsname];
	
	//根据json dic生成对象
	[strM appendFormat:@"+(%@ *)genFromDic:(NSDictionary *)dic\n{\n", clsname];
	[strM appendString:@"\tif (dic) {\n"];
	[strM appendFormat:@"\t\t%@ *__autoreleasing temp = [[%@ alloc] init];\n", clsname, clsname];
	for (int i = 0; i < [arrKey count]; i++) {
		NSString *key = [arrKey objectAtIndex:i];
		
		NSString *first = [key substringWithRange:NSMakeRange(0, 1)];
		NSString *lowerFirst = [first lowercaseString];
		NSString *vname = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:lowerFirst];
		if ([[vname lowercaseString] hasPrefix:@"description"]) {
			vname = [NSString stringWithFormat:@"m_%@", vname];
		}
		
		id value = [self objectForKey:key];
		if ([value isKindOfClass:[NSString class]]) {
			[strM appendFormat:@"\t\ttemp.%@ = [dic strForKey:@\"%@\"];\n", vname, key];
		} else if ([value isKindOfClass:[NSNumber class]]) {
			[strM appendFormat:@"\t\ttemp.%@ = [dic objectForKey:@\"%@\"];\n", vname, key];
		} else if ([value isKindOfClass:[NSArray class]]) {
//			[strM appendFormat:@"\t\ttemp.%@ = [dic objectForKey:@\"%@\"];\n", vname, key];
			[strM appendFormat:@"\t\tNSArray *array = [dic objectForKey:@\"%@\"];\n", key];
			[strM appendFormat:@""];
			
			NSArray *sub = (NSArray *)value;
			
			NSString *subclsname = @"CLSSubs";
			
			[(NSDictionary *)[sub firstObject] toInterfaceDefinitionWithName:subclsname];
			
			[strM appendString:@"\t\tfor (int i = 0; i < [array count]; i++) {\n"];
			[strM appendString:@"\t\t\tNSDictionary *subDic = [array objectAtIndex:i];\n"];
			[strM appendFormat:@"\t\t\t%@ *subTemp = [%@ genFromDic:subDic];\n", subclsname, subclsname];
			[strM appendFormat:@"\t\t\tif (subTemp) {\n\t\t\t\t[temp.%@ addObject:subTemp];\n\t\t\t}\n", vname];
			[strM appendString:@"\t\t}\n"];
		}
		else {
			[strM appendFormat:@"\t\ttemp.%@ = [dic objectForKey:@\"%@\"];\n", vname, key];
		}
	}
	[strM appendString:@"\t\treturn temp;\n\t}\n\treturn nil;\n}\n"];
	
	//description方法
	[strM appendString:@"- (NSString *)description\n{\n"];
	[strM appendString:@"\tNSMutableString *desc = [NSMutableString string];\n"];
	for (int i = 0; i < [arrKey count]; i++) {
		NSString *key = [arrKey objectAtIndex:i];
		
		NSString *first = [key substringWithRange:NSMakeRange(0, 1)];
		NSString *lowerFirst = [first lowercaseString];
		NSString *vname = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:lowerFirst];
		if ([[vname lowercaseString] hasPrefix:@"description"]) {
			vname = [NSString stringWithFormat:@"m_%@", vname];
		}
		
		id value = [self objectForKey:key];
		if ([value isKindOfClass:[NSArray class]]) {
			[strM appendFormat:@"\t[desc appendFormat:@\"\\n\\t%@: (\"];\n", vname];
			[strM appendFormat:@"\tfor (id obj in self.%@) {\n", vname];
			[strM appendString:@"\t\t[desc appendFormat:@\"\\n\\t{\\n%@\\n\\t}\\n\", obj];\n"];
			[strM appendString:@"\t}\n"];
			[strM appendString:@"\t[desc appendFormat:@\"\\n\\t)\\n\"];\n"];
		} else {
			[strM appendFormat:@"\t[desc appendFormat:@\"\\n\\t%@:%%@--\", self.%@];\n", vname, vname];
		}
	}
	[strM appendString:@"\n\treturn desc;\n"];
	[strM appendString:@"}\n"];

	[strM appendString:@"@end"];
	
//	NSLog(@"\n%@\n\n%@", strH, strM);
	return [strH stringByAppendingFormat:@"\n\n%@", strM];
 }

@end


#pragma mark -
@implementation NSString (Extend)
-(BOOL)isMatchRegExp:(NSString *)pattern
{
	if ([pattern length] > 0) {
		NSError *error = nil;
		NSRegularExpression *regExp = [[NSRegularExpression alloc] initWithPattern:pattern 
																		   options:NSRegularExpressionCaseInsensitive 
																			 error:&error];
		if (error == nil) {
			NSTextCheckingResult *result = [regExp firstMatchInString:self options:0 range:NSMakeRange(0, [self length])];
			if (result && result.range.location != NSNotFound) {
				return YES;
			}		
		}
	}
	return NO;
}
-(NSString *)stringByDeletingPrefix:(NSString *)prefix
{
	if ([prefix length] > 0) {
		NSString *temp = [self copy];
		while ([temp hasPrefix:prefix]) {
			temp = [temp stringByReplacingCharactersInRange:NSMakeRange(0, [prefix length]) withString:@""];
		}
		return temp;
	}
	NSString *__autoreleasing temp = [self copy];
	return temp;
}
-(NSString *)stringByDeletingSuffix:(NSString *)suffix
{
	if ([suffix length] > 0) {
		NSString *temp = [self copy];
		while ([temp hasSuffix:suffix] && !([temp length] < [suffix length])) {
			temp = [temp stringByReplacingCharactersInRange:NSMakeRange([temp length] - [suffix length], [suffix length]) withString:@""];
		}
		return temp;
	}
	NSString *__autoreleasing temp = [self copy];
	return temp;
}
-(NSString *_Nullable)stringByTrimmingSpace
{
	if ([self length] > 0) {
		NSString *temp = [self copy];
		temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
		return temp;
	}
	NSString *__autoreleasing temp = [self copy];
	return temp;
}
-(NSString *_Nullable)stringByTrimmingWhitespaceAndNewLine
{
	if ([self length] > 0) {
		NSString *temp = [self copy];
		temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		return temp;
	}
	NSString *__autoreleasing temp = [self copy];
	return temp;
}
-(NSString *_Nullable)stringByTrimmingCharactersInString:(NSString *)string
{
	if ([self length] > 0) {
		NSString *temp = [self copy];
		temp = [temp stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:string]];
		return temp;
	}
	NSString *__autoreleasing temp = [self copy];
	return temp;
}

-(NSString *)lastCharacter
{
	if ([self length] > 0) {
		return [self substringFromIndex:[self length] - 1];
	}
	return nil;
}
-(NSString *)stringByDeletingLastCharacter
{
	if ([self length] > 0) {
		return [self substringToIndex:[self length] - 1];
	}
	return nil;
}
-(NSArray *)componentsSeparatedByCharactersInString:(NSString *)string
{
	if ([string length] > 0) {
		return [self componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:string]];
	}
	return nil;
}
-(NSArray *_Nullable)componentsSeparatedByWhitespace
{
	if ([self length] > 0) {
		return [self componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	}
	return nil;
}
@end
