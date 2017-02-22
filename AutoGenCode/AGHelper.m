//
//  AGHelper.m
//  AutoGenCode
//
//  Created by company on 16/11/10.
//  Copyright © 2016年 company. All rights reserved.
//

#import "AGHelper.h"
#import "NSObject+Extend.h"

@implementation AGHelper
/*选中的字符串需要遵循一定的格式：
 1 以@interface开头，以@end结尾，@interface和@end都单独占一行
 2 定义的属性或者方法;之后如果带注释，不能换行
 */
- (void)genImplementation:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
	NSArray *classes = [NSArray arrayWithObject:[NSString class]];
	NSDictionary *options = [NSDictionary dictionary];
	
	if (![pboard canReadObjectForClasses:classes options:options]) {
		return;
	}
	
	NSString *pstring = [pboard stringForType:NSPasteboardTypeString];
	NSString *newString = nil;
	if ([pstring length] > 0 && [data isEqual:@"h2m"])
	{
		NSString *clsname, *superclsname;
		NSString *strTrim = [pstring stringByTrimmingWhitespaceAndNewLine];
		NSString *firstLine = [[strTrim componentsSeparatedByString:@"\n"] firstObject];
		if (firstLine && [firstLine length] > 0) {
			NSArray *array = [firstLine componentsSeparatedByString:@":"];
			if ([array count] > 1) {
				clsname = [[array firstObject] stringByTrimmingSpace]; 
				clsname = [[clsname componentsSeparatedByString:@" "] lastObject];
				
				superclsname = [[array objectAtIndex:1] stringByTrimmingSpace]; 
				superclsname = [[superclsname componentsSeparatedByString:@" "] firstObject];
			}
		}
		if ([clsname length] == 0 || [superclsname length] == 0) {
			return;
		}
		if ([[superclsname lowercaseString] hasSuffix:@"view"]) {
			newString = [self genViewImp:strTrim clsname:clsname sclsname:superclsname];
		} else if ([[superclsname lowercaseString] hasSuffix:@"cell"]) {
			newString = [self genCellImp:strTrim clsname:clsname sclsname:superclsname];
		}
		
	}
	if ([newString length] == 0) {
		return;
	}
	
	[[NSPasteboard generalPasteboard] clearContents];
	[[NSPasteboard generalPasteboard] setString:newString forType:NSPasteboardTypeString];	
}
//根据view的定义生成m文件，需要父类名中包含view, sclsname:父类名
-(NSString *)genViewImp:(NSString *)hstring clsname:(NSString *)clsname sclsname:(NSString *)sclsname
{	
	NSArray *arrDef = [self findVarsFrom:hstring];
	if ([arrDef count] == 0) {
		//没有任何属性,直接返回
		return nil;
	}
		
	NSString *strHead = [NSString stringWithFormat:@"\n@implementation %@\n", clsname];
	NSString *strEnd = @"\n@end";
	NSMutableString *strOther = [[NSMutableString alloc] init];//-init和其他按钮方法
	NSMutableString *strInitFrame = [[NSMutableString alloc] init];
	[strOther appendString:@"-(instancetype)init\n{\n\treturn [self initWithFrame:CGRectZero];\n}\n"];
	[strInitFrame appendString:@"-(instancetype)initWithFrame:(CGRect)frame\n{\n\tself = [super initWithFrame:frame];\n\tif (self) {"];
	
	NSString *codeCreate, *codeActions;
	[self genCreationCode:arrDef creationCode:&codeCreate actions:&codeActions];
	[strInitFrame appendFormat:@"%@", codeCreate];
	if ([codeActions length] > 0) {
		[strOther insertString:codeActions atIndex:0];
	}
	[strInitFrame appendString:@"\t}\n\treturn self;\n}\n"];
	
	//h文件中定义的方法
	NSArray *arrMeth = [self findMethodsFrom:hstring];
	if ([arrMeth count] > 0) {		
		NSString *strDefMeth;
		[self genMethodImp:arrMeth code:&strDefMeth];
		if ([strDefMeth length] > 0) {
			[strOther insertString:strDefMeth atIndex:0];
		}
	}
	
	NSString *strLayout = [self layoutCodeOf:arrDef];	
	return [NSString stringWithFormat:@"%@%@%@%@%@", strHead, strOther, strInitFrame, strLayout, strEnd];
}
//根据cell的定义生成m文件，需要父类名中包含Cell
-(NSString *)genCellImp:(NSString *)hstring clsname:(NSString *)clsname sclsname:(NSString *)sclsname
{
	NSArray *arrDef = [self findVarsFrom:hstring];
	if ([arrDef count] == 0) {
		//没有任何属性,直接返回
		return nil;
	}
	
	NSString *strHead = [NSString stringWithFormat:@"\n@implementation %@\n", clsname];
	NSString *strEnd = @"\n@end";
	NSMutableString *strOther = [[NSMutableString alloc] init];//按钮方法
	NSMutableString *strInitStyle = [[NSMutableString alloc] init];
	[strInitStyle appendString:@"-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier\n{\n"];
	[strInitStyle appendString:@"\tself = [super initWithStyle:style reuseIdentifier:reuseIdentifier];\n"];
	[strInitStyle appendString:@"\tif (self) {\n"];
	[strInitStyle appendString:@"\t\tself.contentView.backgroundColor = [UIColor whiteColor];\n"];
	[strInitStyle appendString:@"\t\tself.backgroundColor = [UIColor whiteColor];\n"];
	[strInitStyle appendString:@"\t\tself.selectionStyle = UITableViewCellSelectionStyleNone;\n"];
	
	NSString *codeCreate, *codeActions;
	[self genCreationCode:arrDef creationCode:&codeCreate actions:&codeActions];
	[strInitStyle appendFormat:@"\n%@", codeCreate];
	if ([codeActions length] > 0) {
		[strOther insertString:codeActions atIndex:0];
	}
	[strInitStyle appendString:@"\t}\n\treturn self;\n}\n"];
	
	//h文件中定义的方法
	NSArray *arrMeth = [self findMethodsFrom:hstring];
	if ([arrMeth count] > 0) {		
		NSString *strDefMeth;
		[self genMethodImp:arrMeth code:&strDefMeth];
		if ([strDefMeth length] > 0) {
			[strOther insertString:strDefMeth atIndex:0];
		}
	}
	
	NSString *strLayout = [self layoutCodeOf:arrDef];
	
	return [NSString stringWithFormat:@"%@%@%@%@%@", strHead, strOther, strInitStyle, strLayout, strEnd];
}
-(NSArray *)findVarsFrom:(NSString *)hstring
{
	NSArray *arrLines = [hstring componentsSeparatedByString:@"\n"];
	
	if ([arrLines count] == 0) {
		return nil;
	}
	//取出所有属性的行，包括{}之中的和@property定义的，判断标准：包含"*"和";"，且不以"^\s*//"开头
	//会忽略所有 int,bool 等标量属性, 以及id类型的
	NSMutableArray *arrVarLine = [[NSMutableArray alloc] init];
	for (int i = 1; i < [arrLines count]; i++) {
		NSString *line = [arrLines objectAtIndex:i];
		if ([line isMatchRegExp:@"^\\s*//"] == NO && [line isMatchRegExp:@"\\*+[^*)]+?;"]) {
			[arrVarLine addObject:line];
		}
	}
	if ([arrVarLine count] == 0) {
		return nil;
	}
	NSMutableArray *arrDef = [[NSMutableArray alloc] init];
	for (int i = 0; i < [arrVarLine count]; i++) {
		NSString *line = [arrVarLine objectAtIndex:i];
		VarObj *var = [self varFromLine:line];
		if (var) {
			[arrDef addObject:var];
		}
	}
	NSLog(@"%@", arrDef);
	return arrDef;
}
-(VarObj *)varFromLine:(NSString *)line
{
	BOOL isProperty = [line rangeOfString:@"@property"].location != NSNotFound;
	NSMutableArray *comp = [NSMutableArray array];
	NSRange range = [line rangeOfString:@";"]; 
	if (range.location != NSNotFound && range.location > 0) {
		[comp addObject:[line substringToIndex:[line rangeOfString:@";"].location]];
		if (range.location < [line length]-1) {
			[comp addObject:[line substringFromIndex:[line rangeOfString:@";"].location+1]];
		}
	}	
	VarObj *var = nil;
	//变量定义
	{
		NSString *temp = [comp firstObject];
		temp = [temp stringByTrimmingWhitespaceAndNewLine];
		NSString *trimProp = temp;
		if (isProperty) {
			NSString *splitter = @"@property";
			if ([temp rangeOfString:@")"].location != NSNotFound) {
				splitter = @")";
			}
			trimProp = [[[temp componentsSeparatedByString:splitter] lastObject] stringByTrimmingWhitespaceAndNewLine]; 
		}
		NSArray *arr = [trimProp componentsSeparatedByString:@"*"];
		NSString *name = [[arr lastObject] stringByTrimmingWhitespaceAndNewLine];
		NSString *type = [[arr firstObject] stringByTrimmingWhitespaceAndNewLine];
		if ([type rangeOfString:@"<"].location != NSNotFound) {
			type = [[[type componentsSeparatedByString:@"<"] firstObject] stringByTrimmingWhitespaceAndNewLine];
		}
		if ([type isEqual:@"NSString"] ||
			[type isEqual:@"NSMutableString"]) {
			NSLog(@"\n\nskipped: type=%@,  name=%@\n\n", type, name);
			return nil;
		}
		var = [VarObj varWithType:type name:name isPro:isProperty];		
	}
	//属性值
	{
		NSString *temp = [comp lastObject];
		temp = [temp stringByTrimmingWhitespaceAndNewLine];
		temp = [temp stringByTrimmingCharactersInString:@"// "];
		NSArray *arr = [temp componentsSeparatedByString:@";"];
		for (int i = 0; i < [arr count]; i++) {
			NSString *obj = [arr objectAtIndex:i];
			obj = [obj stringByTrimmingWhitespaceAndNewLine];
			if ([obj isMatchRegExp:@"^\\{.*\\}"]) {
				var.frame = [obj stringByTrimmingCharactersInString:@"{} "];
			}
			else {
				NSString *key = [[[[obj componentsSeparatedByString:@":"] firstObject] stringByTrimmingWhitespaceAndNewLine] lowercaseString];
				NSString *value = [[[obj componentsSeparatedByString:@":"] lastObject] stringByTrimmingWhitespaceAndNewLine];
				if ([key isEqual:@"f"]) {
					var.fontSize = value;
				} 
				else if ([key isEqual:@"l"]) {
					var.lines = value;
				}
				else if ([key isEqual:@"a"]) {
					var.alignment = value;
				}
			}
			
		}
	}
//	NSLog(@"%@", var);
	return var;
}
-(NSArray *)findMethodsFrom:(NSString *)hstring
{
	NSMutableArray *arrMethodLine = [[NSMutableArray alloc] init];
	NSString *reg = @"(?<!\\S)\\s*[+-]\\s*\\(.+?\\)[\\s\\S]+?;";
	NSError *error = nil;
	NSRegularExpression *regExp = [[NSRegularExpression alloc] initWithPattern:reg 
																	   options:NSRegularExpressionCaseInsensitive 
																		 error:&error];
	if (error == nil) {
		[regExp enumerateMatchesInString:hstring
								 options:0
								   range:NSMakeRange(0, [hstring length])
							  usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
								  if (result != nil) {
									  NSString *str = [hstring substringWithRange:result.range];
									  NSLog(@"***%@****", str);
									  if (str) {
										  [arrMethodLine addObject:str];
									  }
								  }
							  }];
	}
	NSLog(@"%@", arrMethodLine);
	
	if ([arrMethodLine count] == 0) {
		return nil;
	}
	NSMutableArray *arrMeth = [[NSMutableArray alloc] init];
	for (int i = 0; i < [arrMethodLine count]; i++) {
		NSString *line = [arrMethodLine objectAtIndex:i];
		MethObj *meth = [self methFromString:line];
		if (meth) {
			[arrMeth addObject:meth];
		}
	}
	return arrMeth;
}

-(MethObj *)methFromString:(NSString *)string
{
	MethObj *meth = [[MethObj alloc] init];
	meth.def = [string stringByTrimmingCharactersInString:@";"];
	NSString *first = [[meth.def componentsSeparatedByString:@":"] firstObject];
	first = [[first componentsSeparatedByString:@")"] firstObject];
	first = [[first componentsSeparatedByString:@"("] lastObject];
	first = [first stringByTrimmingWhitespaceAndNewLine];
	meth.isClass = [first rangeOfString:@"*"].location != NSNotFound;
	first = [first stringByTrimmingCharactersInString:@"*"];
	first = [[first componentsSeparatedByString:@"<"] firstObject];
	first = [first stringByTrimmingWhitespaceAndNewLine];
	meth.typeRet = first;
	NSLog(@"%@, %@", meth.def, meth.typeRet);
	return meth;
}
-(void)genMethodImp:(NSArray<MethObj *> *)array code:(NSString **)code
{
	if ([array count] == 0) {
		return;
	}
	NSMutableString *strCreate = [[NSMutableString alloc] init];
	for (int i = 0; i < [array count]; i++) {
		MethObj *obj = [array objectAtIndex:i];
		NSString *code = [self codeOfMeth:obj];
		[strCreate appendFormat:@"\n%@", code];
	}
	*code = strCreate;
}
-(void)genCreationCode:(NSArray *)array creationCode:(NSString **)code actions:(NSString **)actions
{
	if ([array count] == 0) {
		return;
	}
	NSMutableString *strCreate = [[NSMutableString alloc] init];
	NSMutableString *strActions = [[NSMutableString alloc] initWithString:@""];
	for (int i = 0; i < [array count]; i++) {
		VarObj *obj = [array objectAtIndex:i];
		NSString *code = [self codeOfVar:obj];
		if ([obj.type isEqual:@"UIButton"]) {
			NSString *action = [NSString stringWithFormat:@"\n-(void)%@Clicked:(id)sender\n{\n\n}\n", obj.name];
			[strActions insertString:action atIndex:0];
		}
		[strCreate appendFormat:@"\n%@", code];
	}
	*code = strCreate;
	if ([strActions length] > 0) {
		*actions = strActions;
	}
}
-(NSString *)layoutCodeOf:(NSArray *)arrvar
{
	NSMutableArray *arrSort = [[NSMutableArray alloc] init];
	for (int i = 0; i < [arrvar count]; i++) {
		VarObj *obj = [arrvar objectAtIndex:i];
		if ([obj.type hasPrefix:@"NS"]) {
			continue;
		}
		[arrSort addObject:obj];
	}
	for (int i = 0; i < [arrSort count]; i++) {
		VarObj *obj = [arrSort objectAtIndex:i];
		if ([obj.frame length] == 0) {
			continue;
		}
		for (int j = i+1; j < [arrSort count]; j++) {
			VarObj *compare = [arrSort objectAtIndex:j];
			if ([[obj.frame lowercaseString] rangeOfString:[compare.name lowercaseString]].location != NSNotFound) {
				[arrSort removeObject:obj];
				if (compare == [arrSort lastObject]) {
					[arrSort addObject:obj];
				} else {
					[arrSort insertObject:obj atIndex:j];
				}
				i--;
				break;
			}
		}
	}
	
	NSMutableString *strLayout = [[NSMutableString alloc] init];
	[strLayout appendString:@"\n-(void)layoutSubviews\n{\n\t[super layoutSubviews];\n\n\tCGSize vsize = self.frame.size;\n"];
	if ([arrSort count] > 0) {
		NSMutableArray *arrnames = [[NSMutableArray alloc] init];
		for (int i = 0; i < [arrSort count]; i++) {
			VarObj *obj = [arrSort objectAtIndex:i];
			if (obj.name) {
				[arrnames addObject:obj.name];
			}
		}
		for (int i = 0; i < [arrSort count]; i++) {
			VarObj *obj = [arrSort objectAtIndex:i];
			VarObj *pre = nil;
			if (i > 0) {
				pre = [arrSort objectAtIndex:i-1];
			}
			NSString *temp = [self frameStringOfVar:obj previous:pre allnames:arrnames];
			[strLayout appendFormat:@"\n%@", temp];
		}
	}
	[strLayout appendString:@"\n}\n"];
	NSLog(@"%@", strLayout);
	return strLayout;
}
-(NSString *)frameStringOfVar:(VarObj *)obj previous:(VarObj *)preVar allnames:(NSArray *)arrnames
{
	NSMutableString *strFrame = [[NSMutableString alloc] init];
	
	NSString *pname = [obj propertyName];
	NSString *lname = [obj.name lowercaseString];
	NSString *rname = [NSString stringWithFormat:@"r%@", lname];
	NSString *rx = @"0.0f", *ry = @"0.0f", *rw = @"0.0f", *rh = @"self.frame.size.height";
	if ([obj.frame length] > 0) {
		NSString *suffix = @"";
		//优先级： f，x/y/w/h/mx/my
		NSArray *arrFrame = [obj.frame componentsSeparatedByString:@","];
		NSMutableDictionary *dic = [NSMutableDictionary dictionary];
		for (int i = 0; i < [arrFrame count]; i++) {
			NSString *string = [arrFrame objectAtIndex:i];
			string = [string stringByTrimmingWhitespaceAndNewLine];
			NSString *skey = [[[[string componentsSeparatedByString:@":"] firstObject] stringByTrimmingWhitespaceAndNewLine] lowercaseString];
			NSString *svalue = [[[string componentsSeparatedByString:@":"] lastObject] stringByTrimmingWhitespaceAndNewLine];
			if (skey && svalue) {
				[dic setObject:svalue forKey:skey];
			}
		}
		NSArray *keys = [dic allKeys];
		
		//解析f
		if ([keys containsObject:@"f"]) {
			NSString *key = [dic objectForKey:@"f"];
			NSString *rect = @"frame";
			NSString *varname = key;
			if (key) {
				NSArray *arr = [key componentsSeparatedByString:@"."];
				varname = ([arr count] > 0) ? arr[0] : key;
				rect = ([arr count] > 1 && [arr[1] isEqual:@"b"]) ? @"bounds" : @"frame";
				varname = [varname hasPrefix:@"self"] ? varname : [@"_" stringByAppendingString:varname];
			}
			rx = [NSString stringWithFormat:@"%@.%@.origin.x", varname, rect];
			ry = [NSString stringWithFormat:@"%@.%@.origin.y", varname, rect];
			rw = [NSString stringWithFormat:@"%@.%@.size.width", varname, rect];
			rh = [NSString stringWithFormat:@"%@.%@.size.height", varname, rect];
		}
		
		//解析x/w/mx，得到frame的x和width的值
		if ([keys containsObject:@"x"] || [keys containsObject:@"w"] || [keys containsObject:@"mx"]) {
			NSString *x = [self parseXYWH:[dic objectForKey:@"x"]];
			NSString *w = [self parseXYWH:[dic objectForKey:@"w"]];
			NSString *mx = [self parseXYWH:[dic objectForKey:@"mx"]];
			if (x && w && mx) {
				suffix = @"//x,w,mx同时被指定，以x和mx为准，抛弃w";
				rx = x; 
				NSString *fx = [x isMatchRegExp:@"[+-]+"] ? [NSString stringWithFormat:@"(%@)", x] : x;
				rw = [NSString stringWithFormat:@"%@ - %@", mx, fx];
			} else {
				if (x && w) {
					rx = x;
					rw = w;
				} else if (x && mx) {
					rx = x; 
					NSString *fx = [x isMatchRegExp:@"[+-]+"] ? [NSString stringWithFormat:@"(%@)", x] : x;
					rw = [NSString stringWithFormat:@"%@ - %@", mx, fx];
				} else if (mx && w) {
					rw = w;
					NSString *fw = [w isMatchRegExp:@"[+-]+"] ? [NSString stringWithFormat:@"(%@)", w] : w;
					rx = [NSString stringWithFormat:@"%@ - %@", mx, fw];
				}
				else {
					if (x) {
						rx = x;
					} else if (w) {
						rw = w;
					} else if (mx) {
						//这种情况一般是前面指定了frame，以frame的x为准，修改w
						NSString *fx = [rx isMatchRegExp:@"[+-]+"] ? [NSString stringWithFormat:@"(%@)", rx] : rx;
						rw = [NSString stringWithFormat:@"%@ - %@", mx, fx];
					}
				}
			}
		} 
		//解析y/h/my，得到frame的y和height的值
		if ([keys containsObject:@"y"] || [keys containsObject:@"h"] || [keys containsObject:@"my"]) {
			NSString *y = [self parseXYWH:[dic objectForKey:@"y"]];
			NSString *h = [self parseXYWH:[dic objectForKey:@"h"]];
			NSString *my = [self parseXYWH:[dic objectForKey:@"my"]];
			if (y && h && my) {
				suffix = @"//y,h,my同时被指定，以y和my为准，抛弃h";
				ry = y; 
				NSString *fy = [y isMatchRegExp:@"[+-]+"] ? [NSString stringWithFormat:@"(%@)", y] : y;
				rh = [NSString stringWithFormat:@"%@ - %@", my, fy];
			} else {
				if (y && h) {
					ry = y;
					rh = h;
				} else if (y && my) {
					ry = y; 
					NSString *fy = [y isMatchRegExp:@"[+-]+"] ? [NSString stringWithFormat:@"(%@)", y] : y;
					rh = [NSString stringWithFormat:@"%@ - %@", my, fy];
				} else if (my && h) {
					rh = h;
					NSString *fh = [h isMatchRegExp:@"[+-]+"] ? [NSString stringWithFormat:@"(%@)", h] : h;
					ry = [NSString stringWithFormat:@"%@ - %@", my, fh];
				}
				else {
					if (y) {
						ry = y;
					} else if (h) {
						rh = h;
					} else if (my) {
						//这种情况一般是前面指定了frame，以frame的y为准，修改h
						NSString *fy = [ry isMatchRegExp:@"[+-]+"] ? [NSString stringWithFormat:@"(%@)", ry] : ry;
						rh = [NSString stringWithFormat:@"%@ - %@", my, fy];
					}
				}
				if (h == nil && (y == nil || my == nil) && [obj.type isEqual:@"UILabel"]) {					
					if (obj.lines) {
						if ([obj.lines intValue] == 0) {
							rh = [NSString stringWithFormat:@"[%@.text boundingRectWithSize:CGSizeMake(%@, CGFLOAT_MAX) options:3 attributes:@{NSFontAttributeName:%@.font} context:nil].size.height", pname, rw, pname];
						} else {
							rh = [NSString stringWithFormat:@"%@.font.lineHeight*%@", pname, obj.lines];
						}
					} else {
						rh = [NSString stringWithFormat:@"%@.font.lineHeight", pname];
					}
				}
			}
		}
		strFrame = [NSMutableString stringWithFormat:@"\t%@.frame = CGRectMake(%@, %@, %@, %@);%@", pname, rx, ry, rw, rh, suffix];
	} 
	else {
		if ([obj.type isEqual:@"UILabel"]) {
			if ([obj.lines length] > 0) {
				int line = [obj.lines intValue]; 
				if (line == 0) {
					rh = [NSString stringWithFormat:@"[%@.text boundingRectWithSize:CGSizeMake(<#width#>, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:%@.font} context:nil].size.height;", pname, pname];
				} else {
					rh = [NSString stringWithFormat:@"%@.font.lineHeight * %d", pname, line];
				}
			} else {
				rh = [NSString stringWithFormat:@"%@.font.lineHeight", pname];
			}
		}
		if (preVar) {
			ry = [NSString stringWithFormat:@"CGRectGetMaxY(%@.frame)", [preVar propertyName]];
		}
		strFrame = [NSMutableString stringWithFormat:@"\t%@.frame = CGRectMake(%@, %@, %@, %@);", pname, rx, ry, rw, rh];
	}
//	NSLog(@"%@", strFrame);
	return strFrame;
}
-(NSString *)parseXYWH:(NSString *)value
{
	if ([value length] == 0) {
		return nil;
	}
	NSString *clean = [value stringByReplacingOccurrencesOfString:@" " withString:@""];
	clean = [clean stringByReplacingOccurrencesOfString:@"\t" withString:@""];
	NSArray *arrReg = @[@"(\\S+?)\\.f(?!rame)",
						 @"(\\S+?)\\.mx",
						 @"(\\S+?)\\.x", 
						 @"(\\S+?)\\.my", 
						 @"(\\S+?)\\.y", 
						 @"(\\S+?)\\.w", 
						 @"(\\S+?)\\.h",
						 @"(\\S+?)\\.b"
						 ];
	NSArray *arrTemp = @[@"_$1.frame",
						 @"CGRectGetMaxX(_$1.frame)",
						 @"_$1.frame.origin.x", 
						 @"CGRectGetMaxY(_$1.frame)", 
						 @"_$1.frame.origin.y", 
						 @"_$1.frame.size.width", 
						 @"_$1.frame.size.height",
						 @"_$1.bounds"
						 ];
//	NSDictionary *dicRegTemp = @{@"mx\\((\\S+?)\\)" : @"CGRectGetMaxX(_$1.frame)",
//								 @"(?<![mx])x\\((\\S+?)\\)" : @"_$1.frame.origin.x", 
//								 @"my\\((\\S+?)\\)" : @"CGRectGetMaxY(_$1.frame)", 
//								 @"(?<![mx])y\\((\\S+?)\\)" : @"_$1.frame.origin.y", 
//								 @"w\\((\\S+?)\\)" : @"_$1.frame.size.width", 
//								 @"h\\((\\S+?)\\)" : @"_$1.frame.size.height",
//								 @"b\\((\\S+?)\\)" : @"_$1.bounds",
//								 @"f\\((\\S+?)\\)" : @"_$1.frame"
//								 };

	for (int i = 0; i < [arrReg count]; i++) {
		NSString *reg = [arrReg objectAtIndex:i];
		NSString *temp = [arrTemp objectAtIndex:i];
		NSError *error = nil;
		NSRegularExpression *regExp = [[NSRegularExpression alloc] initWithPattern:reg 
																		   options:NSRegularExpressionCaseInsensitive
																			 error:&error];
		if (error == nil) {
			clean = [regExp stringByReplacingMatchesInString:clean 
													 options:NSMatchingReportCompletion
													   range:NSMakeRange(0, [clean length])
												withTemplate:temp];
		}
	}
	clean = [clean stringByReplacingOccurrencesOfString:@"_self" withString:@"self"];
	return clean;
}
-(NSString *)codeOfMeth:(MethObj *)obj
{
	if ([[obj.typeRet lowercaseString] isEqual:@"void"]) {
		return [NSString stringWithFormat:@"%@\n{\n\n}", obj.def];
	} else {
		NSMutableString *code = [[NSMutableString alloc] initWithFormat:@"%@\n{\n", obj.def];
		if (obj.isClass) {
			[code appendFormat:@"\t%@ *temp = [[%@ alloc] init];\n", obj.typeRet, obj.typeRet];
		} else {
			[code appendFormat:@"\t%@ temp;\n", obj.typeRet];
		}
		[code appendFormat:@"\t\nreturn temp;\n}"];
		return code;
	}
}
-(NSString *)codeOfVar:(VarObj *)obj
{
	NSString *code = nil;
	if ([obj.type isEqual:@"UIView"]) {
		code = [self codeOfView:obj];
	}
	else if ([obj.type isEqual:@"UILabel"]) {
		code = [self codeOfLabel:obj];
	} 
	else if ([obj.type isEqual:@"UIButton"]) {
		code = [self codeOfButton:obj];
	}
	else if ([obj.type isEqual:@"UIImageView"]) {
		code = [self codeOfImageView:obj];
	}
	else if ([obj.type isEqual:@"UIScrollView"]) {
		code = [self codeOfScrollView:obj];
	}
	else if ([obj.type isEqual:@"UIActivityIndicatorView"]) {
		code = [self codeOfActivityIndicatorView:obj];
	}
	else if ([obj.type isEqual:@"UITableView"]) {
		code = [self codeOfTableView:obj];
	}
	else if ([obj.type isEqual:@"UISwitch"]) {
		code = [self codeOfSwitch:obj];
	}
	else if ([obj.type isEqual:@"UITextField"]) {
		code = [self codeOfTextField:obj];
	}
	else {
		NSString *name = [obj propertyName];
		code = [NSString stringWithFormat:@"\t\t%@ = [[%@ alloc] init];\n", name, obj.type];
		if ([obj.type rangeOfString:@"view" options:NSCaseInsensitiveSearch].location == NSNotFound) {
			if ([obj.type hasPrefix:@"NS"] == NO) {
				code = [code stringByAppendingFormat:@"//\t\t[self addSubview:%@];\n", name];
			}
		} else {
			code = [code stringByAppendingFormat:@"\t\t[self addSubview:%@];\n", name];
		}
	}
	return code;
}
-(NSString *)codeOfView:(VarObj *)var
{
	NSMutableString *code = [[NSMutableString alloc] init];
	NSString *name = [var propertyName];
	[code appendFormat:@"\t\t%@ = [[%@ alloc] init];\n", name, var.type];
	[code appendFormat:@"\t\t%@.backgroundColor = [UIColor whiteColor];\n", name];
	[code appendFormat:@"\t\t[self addSubview:%@];\n", name];
	return code;
}
-(NSString *)codeOfLabel:(VarObj *)var
{
	NSMutableString *code = [[NSMutableString alloc] init];
	NSString *name = [var propertyName];
	[code appendFormat:@"\t\t%@ = [[%@ alloc] init];\n", name, var.type];
	[code appendFormat:@"\t\t%@.backgroundColor = [UIColor clearColor];\n", name];
	[code appendFormat:@"\t\t%@.textColor = [UIColor blackColor];\n", name];
	if ([var.lines length] > 0) {
		[code appendFormat:@"\t\t%@.numberOfLines = %d;\n", name, [var.lines intValue]];
	}
	if ([var.alignment length] > 0) {
		NSString *aligment = @"NSTextAlignment<#Left#>";
		NSString *lower = [var.alignment lowercaseString]; 
		if ([lower isEqual:@"left"] || [lower isEqual:@"l"]) {
			aligment = @"NSTextAlignmentLeft";
		} else if ([lower isEqual:@"right"] || [lower isEqual:@"r"]) {
			aligment = @"NSTextAlignmentRight";
		} else if ([lower isEqual:@"center"] || [lower isEqual:@"c"]) {
			aligment = @"NSTextAlignmentCenter";
		}
		[code appendFormat:@"\t\t%@.textAlignment = %@;\n", name, aligment];
	} else {
		[code appendFormat:@"//\t\t%@.textAlignment = NSTextAlignment<#Left#>;\n", name];
	}
	if ([var.fontSize length] > 0) {
		[code appendFormat:@"\t\t%@.font = [UIFont systemFontOfSize:%.1f];\n", name, [var.fontSize floatValue]];
	} else {
		[code appendFormat:@"\t\t%@.font = [UIFont systemFontOfSize:<#14.0f#>];\n", name];
	}
	[code appendFormat:@"\t\t[self addSubview:%@];\n", name];
	return code;
}
-(NSString *)codeOfButton:(VarObj *)var
{
	NSMutableString *code = [[NSMutableString alloc] init];
	NSString *name = [var propertyName];
	NSString *method = [var.name stringByAppendingString:@"Clicked:"];
	[code appendFormat:@"\t\t%@ = [[%@ alloc] init];\n", name, var.type];
	[code appendFormat:@"\t\t%@.backgroundColor = [UIColor clearColor];\n", name];
	if ([var.fontSize length] > 0) {
		[code appendFormat:@"\t\t%@.titleLabel.font = [UIFont systemFontOfSize:%.1f];\n", name, [var.fontSize floatValue]];
	} else {
		[code appendFormat:@"\t\t%@.titleLabel.font = [UIFont systemFontOfSize:<#16.0f#>];\n", name];
	}
	[code appendFormat:@"\t\t[%@ addTarget:self action:@selector(%@) forControlEvents:UIControlEventTouchUpInside];\n", name, method];
	[code appendFormat:@"//\t\t[%@ setImage:[UIImage imageNamed:<#name#>] forState:UIControlStateNormal];\n", name];
	[code appendFormat:@"//\t\t[%@ setBackgroundImage:[UIImage imageNamed:<#name#>] forState:UIControlStateNormal];\n", name];
	[code appendFormat:@"//\t\t[%@ setTitle:<#title#> forState:UIControlStateNormal];\n", name];
	[code appendFormat:@"//\t\t[%@ setTitleColor:[UIColor <#whiteColor#>] forState:UIControlStateNormal];\n", name];
	[code appendFormat:@"\t\t[self addSubview:%@];\n", name];
	return code;	
}
-(NSString *)codeOfTextField:(VarObj *)var
{
	NSMutableString *code = [[NSMutableString alloc] init];
	NSString *name = [var propertyName];
	[code appendFormat:@"\t\t%@ = [[%@ alloc] init];\n", name, var.type];
	[code appendFormat:@"\t\t%@.backgroundColor = [UIColor clearColor];\n", name];
	[code appendFormat:@"\t\t%@.textColor = [UIColor blackColor];\n", name];
	
	if ([var.alignment length] > 0) {
		NSString *aligment = @"NSTextAlignmentLeft";
		NSString *lower = [var.alignment lowercaseString]; 
		if ([lower isEqual:@"right"] || [lower isEqual:@"r"]) {
			aligment = @"NSTextAlignmentRight";
		} else if ([lower isEqual:@"center"] || [lower isEqual:@"c"]) {
			aligment = @"NSTextAlignmentCenter";
		}
		[code appendFormat:@"\t\t%@.textAlignment = %@;\n", name, aligment];
	} else {
		[code appendFormat:@"//\t\t%@.textAlignment = NSTextAlignment<#Left#>;\n", name];
	}
	if ([var.fontSize length] > 0) {
		[code appendFormat:@"\t\t%@.font = [UIFont systemFontOfSize:%.1f];\n", name, [var.fontSize floatValue]];
	} else {
		[code appendFormat:@"\t\t%@.font = [UIFont systemFontOfSize:<#16.0f#>];\n", name];
	}
	
	[code appendFormat:@"\t\t%@.placeholder = @"";\n", name];
	[code appendFormat:@"\t\t%@.autocorrectionType = UITextAutocorrectionTypeNo;\n", name];
	[code appendFormat:@"\t\t%@.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;\n", name];
	[code appendFormat:@"//\t\t%@.keyboardType = UIKeyboardType<#NumberPad#>;\n", name];
	[code appendFormat:@"//\t\t%@.delegate = <#delegate#>;\n", name];
	[code appendFormat:@"//\t\t%@.returnKeyType = UIReturnKey<#Done#>;\n", name];
	[code appendFormat:@"//\t\t[%@ setValue:[UIColor grayColor] forKeyPath:@\"placeholderLabel.textColor\"];\n", name];
	[code appendFormat:@"\t\t[self addSubview:%@];\n", name];
	return code;
}
-(NSString *)codeOfImageView:(VarObj *)var
{
	NSMutableString *code = [[NSMutableString alloc] init];
	NSString *name = [var propertyName];
	[code appendFormat:@"\t\t%@ = [[%@ alloc] init];\n", name, var.type];
	[code appendFormat:@"\t\t%@.image = [UIImage imageNamed:<#name#>];\n", name];
	[code appendFormat:@"\t\t%@.contentMode = UIViewContentModeScaleAspectFit;\n", name];
	[code appendFormat:@"\t\t[self addSubview:%@];\n", name];
	return code;
}
-(NSString *)codeOfTableView:(VarObj *)var
{
	NSMutableString *code = [[NSMutableString alloc] init];
	NSString *name = [var propertyName];
	[code appendFormat:@"\t\t%@ = [[%@ alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];\n", name, var.type];
	[code appendFormat:@"\t\t%@.delegate = <#delegate#>;\n", name];
	[code appendFormat:@"\t\t%@.dataSource = <#delegate#>;\n", name];
	[code appendFormat:@"\t\t%@.backgroundColor = [UIColor whiteColor];\n", name];
	[code appendFormat:@"\t\t%@.separatorStyle = UITableViewCellSeparatorStyleNone;\n", name];
	[code appendFormat:@"\t\t[self addSubview:%@];\n", name];
	return code;
}
-(NSString *)codeOfActivityIndicatorView:(VarObj *)var
{
	NSMutableString *code = [[NSMutableString alloc] init];
	NSString *name = [var propertyName];
	[code appendFormat:@"\t\t%@ = [[%@ alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];\n", name, var.type];
	[code appendFormat:@"\t\t%@.hidesWhenStopped = YES;\n", name];
	[code appendFormat:@"\t\t[self addSubview:%@];\n", name];
	return code;
}
-(NSString *)codeOfScrollView:(VarObj *)var
{
	NSMutableString *code = [[NSMutableString alloc] init];
	NSString *name = [var propertyName];
	[code appendFormat:@"\t\t%@ = [[%@ alloc] init];\n", name, var.type];
	[code appendFormat:@"\t\t%@.backgroundColor = [UIColor clearColor];\n", name];
	[code appendFormat:@"//\t\t%@.bounces = NO;\n", name];
	[code appendFormat:@"//\t\t%@.pagingEnabled = YES;\n", name];
	[code appendFormat:@"//\t\t%@.delegate = self;\n", name];
	[code appendFormat:@"\t\t[self addSubview:%@];\n", name];
	return code;
}
-(NSString *)codeOfSwitch:(VarObj *)var
{
	NSMutableString *code = [[NSMutableString alloc] init];
	NSString *name = [var propertyName];
	[code appendFormat:@"\t\t%@ = [[%@ alloc] init];\n", name, var.type];
	[code appendFormat:@"//\t\t[%@ addTarget:<#target#> action:@selector(<#action#>) forControlEvents:UIControlEventValueChanged];\n", name];
	[code appendFormat:@"\t\t[self addSubview:%@];\n", name];
	return code;	
}
#pragma mark ----
/*
 可以识别两种格式
 1
   key1 = value1;
   key2 = "value2";
 
 2 {"key1":"value1","key2":"value2"}
 */
- (void)genClass:(NSPasteboard *)pboard userData:(NSString *)data error:(NSString **)error
{
	NSArray *classes = [NSArray arrayWithObject:[NSString class]];
	NSDictionary *options = [NSDictionary dictionary];
	
	if (![pboard canReadObjectForClasses:classes options:options]) {
		return;
	}
	
	NSString *pstring = [pboard stringForType:NSPasteboardTypeString];
	NSString *newString = nil;
	if ([data isEqual:@"d2c"])
	{
		//去掉两端的空白或者换行
		NSString *strTrim = [pstring stringByTrimmingWhitespaceAndNewLine]; 
		NSDictionary *dicResult = nil;
		int format = 1;
		//判断是否合法
		BOOL valid = [self isFormat1:pstring];
		if (valid == NO) {
			format = 2;
			dicResult = [self checkFormat2:pstring];
			valid = dicResult != nil;
		}
		if (valid == NO) {
			return;
		}
		if (format == 1) {
			dicResult = [self dicFromFormat1:strTrim];
		}
		newString = [dicResult toInterfaceDefinitionWithName:@"<#class#>"];
	}
	if ([newString length] == 0) {
		return;
	}
	
	[[NSPasteboard generalPasteboard] clearContents];
	[[NSPasteboard generalPasteboard] setString:newString forType:NSPasteboardTypeString];	
}
-(BOOL)isFormat1:(NSString *)string
{
	NSString *strTrim = [string stringByTrimmingWhitespaceAndNewLine];
	strTrim = [strTrim stringByTrimmingCharactersInString:@"{};"];
	NSArray *array = [strTrim componentsSeparatedByString:@";"];
	
	BOOL valid = YES;
	for (int i = 0; i < [array count]; i++) {
		NSString *sub = [array objectAtIndex:i];
		if ([sub rangeOfString:@"="].location == NSNotFound) {
			if ([sub isMatchRegExp:@"^[)}\\s]+$"] == NO) {
				valid = NO;
				break;
			}
		}
	}
	return valid;
}
-(NSDictionary *)dicFromFormat1:(NSString *)formatString
{
	NSString *strRest = formatString;
	NSMutableDictionary *dicRet = [NSMutableDictionary dictionary];
	while ([strRest length] > 0) {
		strRest = [strRest stringByTrimmingWhitespaceAndNewLine];
		strRest = [strRest stringByTrimmingCharactersInString:@"{};"];
		
		NSRange range = [strRest rangeOfString:@"="];
		if (range.location == 0) {
			break;
		}
		NSString *part1 = [strRest substringToIndex:range.location];
		part1 = [part1 stringByTrimmingWhitespaceAndNewLine];
		part1 = [part1 stringByTrimmingCharactersInString:@" \"\""];
		if ([part1 length] == 0) {
			strRest = [strRest substringFromIndex:range.location];
			continue;
		}
		int braceOpen=0;//大括号开始
		int braceClose=0;//大括号结束
		int parenthesesOpen=0;//小括号开始
		int parenthesesClose=0;//小括号结束
		int type=0;//0-string,1-nsnumber,2-array,3-dictionary
		int idx = -1;
		for (int i = (int)range.location; i < [strRest length]; i++) {
			NSString *achar = [strRest substringWithRange:NSMakeRange(i, 1)];
			if ([achar isEqual:@"{"]) {
				braceOpen++;
				if (type == 0) {
					type = 3;
				}
			} else if ([achar isEqual:@"}"]) {
				braceClose++;
			} else if ([achar isEqual:@"("]) {
				parenthesesOpen++;
				if (type == 0) {
					type = 2;
				}
			} else if ([achar isEqual:@")"]) {
				parenthesesClose++;
			} else if ([achar isEqual:@";"]) {
				if ((braceOpen == braceClose) && (parenthesesOpen == parenthesesClose)) {
					idx=i;
					break;
				}
			}
		}
		if (type == 1) {
			[dicRet setObject:[NSNumber numberWithFloat:0] forKey:part1];
		} else if (type == 2) {
			[dicRet setObject:[NSArray array] forKey:part1];
		} else if (type == 3) {
			[dicRet setObject:[NSDictionary dictionary] forKey:part1];
		} else {
			[dicRet setObject:@" " forKey:part1];
		}  
		if (idx > 0) {
			strRest = [strRest substringFromIndex:idx];
		} else {
			strRest = nil;
		}
	}
	return dicRet;
}
-(id)checkFormat2:(NSString *)string
{
	NSString *strTrim = [string stringByTrimmingWhitespaceAndNewLine];
	if ([strTrim hasPrefix:@"{"] == NO || [strTrim hasSuffix:@"}"] == NO) {
		return NO;
	}
	return [NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:1 error:nil];
}
#pragma mark ----
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[NSApp setServicesProvider:self];
}
@end


#pragma mark -
@implementation VarObj
+(VarObj *)varWithType:(NSString *)type name:(NSString *)name isPro:(BOOL)ispro
{
	VarObj *temp = [[VarObj alloc] init];
	temp.type = type;
	temp.name = name;
	temp.isProperty = ispro;
	return temp;
}
-(NSString *)propertyName
{
	if (_name) {
		return _isProperty ? [NSString stringWithFormat:@"_%@", _name] : _name;
	}
	return nil;
}
-(NSString *)description
{
	return [NSString stringWithFormat:@"%@ *%@, %d, %@, %@, %@", _type, _name, _isProperty, _lines, _fontSize, _frame];
}
@end

@implementation MethObj
@end
