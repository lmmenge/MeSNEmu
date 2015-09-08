//
//  LMDBManager.m
//  MeSNEmu
//
//  Created by Jared Egan on 9/3/15.
//  Copyright 2015 Lucas Menge. All rights reserved.
//

#import "LMDBManager.h"

#define DEFAULTS [NSUserDefaults standardUserDefaults]

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface LMDBManager()

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation LMDBManager

#pragma mark -
#pragma mark Init & Factory
- (id)init {
    self = [super init];
    if (self) {
        // Custom init goes here
    }

    return self;
}

- (void)dealloc {

}

+ (NSString *)localFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    return [documentsPath stringByAppendingString:@"/db_files"];
}

+ (DBMetadata *)metaDataForFileName:(NSString *)fileName {
    NSData *data = [DEFAULTS objectForKey:fileName];
    DBMetadata *metaData = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    return metaData;
}

+ (void)setMetaData:(DBMetadata *)metaData forFileName:(NSString *)fileName {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:metaData];
    
    [DEFAULTS setObject:data forKey:fileName];
    [DEFAULTS synchronize];
}

+ (BOOL)shouldUploadFile:(NSString *)fileName {
    DBMetadata *metaData = [self metaDataForFileName:fileName];
    
    if (!metaData) {
        // New file
        return YES;
    }

    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[[self localFilePath] stringByAppendingFormat:@"/%@", fileName]
                                                                                error:nil];
    
    NSDate *localDateModifed = [attributes fileModificationDate];
    
    NSDate *dbDateModified = [metaData lastModifiedDate];
    
    NSLog(@"dbDate: %@", dbDateModified);
    NSLog(@"l Date: %@", localDateModifed);
    // TODO: I don't trust this date comparison. We're definitely uploading things more than we need to be.
    if ([dbDateModified compare:localDateModifed] != NSOrderedSame) {
        return YES;
    } else {
        NSLog(@"Date modified dates are the same. Don't upload.");
    }

    return NO;
}

+ (BOOL)shouldDownloadFile:(DBMetadata *)metaData {
    NSError *error = nil;
    NSString *filePath = [[self localFilePath] stringByAppendingString:metaData.path];
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath
                                                                                error:&error];
    NSLog(@"attributes: %@", attributes);
    if (error) {
        // Assuming no local file, so download it!
        return YES;
    }
    
    DBMetadata *existingMD = [self metaDataForFileName:metaData.path];
    NSLog(@"existingMD: %@", existingMD);
    if (!existingMD) {
        // There is a local file, but no DBMetaData, so download it
        return YES;
    }
    
    if (![existingMD.rev isEqualToString:metaData.rev]) {
        // rev is different, download it!
        return YES;
    }
    
    // Seems legit, don't download
    return NO;
}

@end

