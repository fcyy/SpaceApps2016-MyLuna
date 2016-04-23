//
//  LunarCalc.h
//  BookItToTheMoon
//
//  Created by Froilan Yap on 22/04/2016.
//  Copyright © 2016 Aquinas Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LunarCalc : NSObject

- (void)calc;

@property (strong, nonatomic) NSDate *observerDateTime;
@property (nonatomic) CGFloat latitude;
@property (nonatomic) CGFloat longitude;

@property (readonly, nonatomic) CGFloat rightAscension;
@property (readonly, nonatomic) CGFloat declination;
@property (readonly, nonatomic) CGFloat altitude;
@property (readonly, nonatomic) CGFloat azimuth;

@property (readonly, nonatomic) NSString *observerLocalDateTimeString;
@property (readonly, nonatomic) NSString *observerUTCDateTimeString;

@end
