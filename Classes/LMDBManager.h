//
//  LMDBManager.h
//  MeSNEmu
//
//  Created by Jared Egan on 9/3/15.
//  Copyright 2015 Lucas Menge. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DropboxSDK/DropboxSDK.h>

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface LMDBManager : NSObject {

}

+ (DBMetadata *)metaDataForFileName:(NSString *)fileName;
+ (void)setMetaData:(DBMetadata *)metaData forFileName:(NSString *)fileName;
+ (BOOL)shouldUploadFile:(NSString *)fileName;
+ (BOOL)shouldDownloadFile:(DBMetadata *)metaData;
+ (NSString *)localFilePath;

@end
