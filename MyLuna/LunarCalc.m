//
//  LunarCalc.m
//  BookItToTheMoon
//
//  Created by Froilan Yap on 22/04/2016.
//  Copyright © 2016 Aquinas Solutions. All rights reserved.
//

#import "LunarCalc.h"

#define pi (M_PI)
#define tpi (2 * pi)
#define twopi (tpi)
#define degs (180.0f / pi)
#define rads (pi / 180)

@interface LunarCalc ()

@property (strong, nonatomic) NSDateFormatter *localDateFormatter;
@property (strong, nonatomic) NSDateFormatter *utcDateFormatter;

@end

@implementation LunarCalc

@synthesize rightAscension = _rightAscension;
@synthesize declination = _declination;
@synthesize altitude = _altitude;
@synthesize azimuth = _azimuth;

- (id)init
{
    self = [super init];
    if (self) {
        // Create date formatters for supplying string representations of the observer's time
        self.localDateFormatter = [[NSDateFormatter alloc] init];
        self.localDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ssZZZZZ";
        self.utcDateFormatter = [[NSDateFormatter alloc] init];
        self.utcDateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        self.utcDateFormatter.dateFormat = @"yyyy-MM-dd HH:mm:ssZZZZZ";
        
    }
    return self;
}

- (NSString *)observerLocalDateTimeString
{
    return [self.localDateFormatter stringFromDate:self.observerDateTime];
}

- (NSString *)observerUTCDateTimeString
{
    return [self.utcDateFormatter stringFromDate:self.observerDateTime];
}

- (void)calc
{
    // Extract time components in UTC
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    unsigned calendarUnitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute;
    gregorian.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    NSDateComponents *dateComponents = [gregorian components:calendarUnitFlags
                                                    fromDate:self.observerDateTime];
    NSInteger y = dateComponents.year;
    NSInteger m = dateComponents.month;
    NSInteger day = dateComponents.day;
    NSInteger h = dateComponents.hour;
    NSInteger mins = dateComponents.minute;
    
    CGFloat hdec = h + mins / 60.0f;
    CGFloat d = 367*y - 7 * ( y + (m+9)/12 ) / 4 + 275*m/9 + day - 730530;
    d += hdec / 24.0f;
    
    // moon elements
    CGFloat Nm = FNrange((125.1228 - .0529538083 * d) * rads);
    CGFloat im = 5.1454 * rads;
    CGFloat wm = FNrange((318.0634 + .1643573223 * d) * rads);
    CGFloat am = 60.2666;
    CGFloat ecm = .0549;
    CGFloat Mm = FNrange((115.3654 + 13.0649929509 * d) * rads);
    
    // sun elements
    CGFloat Ns = 0;
    CGFloat isun = 0;
    CGFloat ws = FNrange((282.9404 + 4.70935E-05 * d) * rads);
    CGFloat asun = 1;        // (AU)
    CGFloat ecs = .016709 - 1.151E-09 * d;
    CGFloat Ms = FNrange((356.047 + .9856002585 * d) * rads);
    
    // position of Moon
    CGFloat Em = Mm + ecm * sin(Mm) * (1 + ecm * cos(Mm));
    CGFloat xv = am * (cos(Em) - ecm);
    CGFloat yv = am * (sqrt(1 - ecm * ecm) * sin(Em));
    CGFloat vm = FNatn2(yv, xv);
    CGFloat rm = sqrt(xv * xv + yv * yv);
    CGFloat xh = rm * (cos(Nm) * cos(vm + wm) - sin(Nm) * sin(vm + wm) * cos(im));
    CGFloat yh = rm * (sin(Nm) * cos(vm + wm) + cos(Nm) * sin(vm + wm) * cos(im));
    CGFloat zh = rm * (sin(vm + wm) * sin(im));
    
    // moons geocentric long and lat
    CGFloat lon = FNatn2(yh, xh);
    CGFloat lat = FNatn2(zh, sqrt(xh * xh + yh * yh));
    
    // perturbations
    //     first calculate arguments below, which should be in radians
    //  Ms, Mm             Mean Anomaly of the Sun and the Moon
    //  Nm                 Longitude of the Moon's node
    //  ws, wm             Argument of perihelion for the Sun and the Moon
    CGFloat Ls = Ms + ws;      //  Mean Longitude of the Sun  (Ns=0)
    CGFloat Lm = Mm + wm + Nm; //  Mean longitude of the Moon
    CGFloat dm = Lm - Ls;      //  Mean elongation of the Moon
    CGFloat F = Lm - Nm;       //  Argument of latitude for the Moon
    // then add the following terms to the longitude
    // note amplitudes are in degrees, convert at end
    CGFloat dlon = -1.274 * sin(Mm - 2 * dm);        // (the Evection)
    dlon = dlon + .658 * sin(2 * dm);        // (the Variation)
    dlon = dlon - .186 * sin(Ms);            // (the Yearly Equation)
    dlon = dlon - .059 * sin(2 * Mm - 2 * dm);
    dlon = dlon - .057 * sin(Mm - 2 * dm + Ms);
    dlon = dlon + .053 * sin(Mm + 2 * dm);
    dlon = dlon + .046 * sin(2 * dm - Ms);
    dlon = dlon + .041 * sin(Mm - Ms);
    dlon = dlon - .035 * sin(dm);            // (the Parallactic Equation)
    dlon = dlon - .031 * sin(Mm + Ms);
    dlon = dlon - .015 * sin(2 * F - 2 * dm);
    dlon = dlon + .011 * sin(Mm - 4 * dm);
    lon = dlon * rads + lon;
    // latitude terms
    CGFloat dlat = -.173 * sin(F - 2 * dm);
    dlat = dlat - .055 * sin(Mm - F - 2 * dm);
    dlat = dlat - .046 * sin(Mm + F - 2 * dm);
    dlat = dlat + .033 * sin(F + 2 * dm);
    dlat = dlat + .017 * sin(2 * Mm + F);
    lat = dlat * rads + lat;
    // distance terms earth radii
    rm = rm - .58 * cos(Mm - 2 * dm);
    rm = rm - .46 * cos(2 * dm);
    // next find the cartesian coordinates
    // of the geocentric lunar position
    CGFloat xg = rm * cos(lon) * cos(lat);
    CGFloat yg = rm * sin(lon) * cos(lat);
    CGFloat zg = rm * sin(lat);
    // rotate to equatorial coords
    // obliquity of ecliptic of date
    CGFloat ecl = (23.4393 - 3.563E-07 * d) * rads;
    CGFloat xe = xg;
    CGFloat ye = yg * cos(ecl) - zg * sin(ecl);
    CGFloat ze = yg * sin(ecl) + zg * cos(ecl);
    // geocentric RA and Dec
    CGFloat ra = FNatn2(ye, xe);
    CGFloat dec = atan(ze / sqrt(xe * xe + ye * ye));

    // right ascension and declination in degrees
    CGFloat RAdegrees = ra * degs;
    CGFloat DECdegrees = dec * degs;
    
    // Convert the right ascension and declination into azimuth and altitude
    CGFloat localLong = self.longitude;
    CGFloat localLat = self.latitude;
    
    // Get local siderial time
    CGFloat LST = range0to360(100.46 + 0.985647 * d + localLong + 15*hdec);
    
    // Get hour angle
    CGFloat HA = range0to360(LST - RAdegrees);
    
    // Get alt
    CGFloat alt = asin(sin(DECdegrees * rads)*sin(localLat * rads)+cos(DECdegrees * rads)*cos(localLat * rads)*cos(HA * rads)) * degs;

    // Get azimuth
    CGFloat A = acos((sin(DECdegrees * rads) - sin(alt * rads) * sin(localLat * rads)) / (cos(alt * rads) * cos(localLat * rads))) * degs;
    CGFloat AZ = sin(HA * rads) < 0 ? A : 360 - A;
    
    // Output
    _rightAscension = RAdegrees;
    _declination = DECdegrees;
    _altitude = alt;
    _azimuth = AZ;
    
//    NSLog(@"\nLST: %@\nHA: %@\nAlt: %@\nAz: %@", @(LST), @(HA), @(alt), @(AZ));
}

CGFloat FNatn2(CGFloat y, CGFloat x)
{
    CGFloat a = atan(y / x);
    if (x < 0) a = a + pi;
    if (y < 0 && x > 0) a = a + tpi;
    
    return a;
}

NSInteger FNipart(CGFloat x)
{
    NSInteger sgn = x ? (x < 0 ? -1 : +1) : 0;
    NSInteger intOnly = (NSInteger)fabs(x);
    return sgn * intOnly;
}

CGFloat FNrange(CGFloat x)
{
    CGFloat b = x / tpi;
    CGFloat a = tpi * (b - FNipart(b));
    if (a < 0) a = tpi + a;
    
    return a;
}

CGFloat range0to360(CGFloat degrees)
{
    if (degrees >= 0 && degrees <= 360) return degrees;
    
    NSInteger adj = degrees < 0 ? 360 : -360;
    CGFloat newdeg = degrees;
    while (newdeg < 0 || newdeg > 360) newdeg += adj;
    
    return newdeg;
}

@end
