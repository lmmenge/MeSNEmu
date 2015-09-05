//
//  LMDropBoxBrowser.m
//  MeSNEmu
//
//  Created by Jared Egan on 8/13/15.
//  Copyright 2015 Lucas Menge. All rights reserved.
//

#import "LMDropBoxBrowserViewController.h"
#import "NITableViewSystem.h"
#import "NICellCatalog.h"
#import "LMRomInfo.h"
#import "LMEmulatorController.h"
#import "LMSaveManager.h"
#import "../SNES9XBridge/Snes9xMain.h"
#import <DropboxSDK/DropboxSDK.h>
#import "LMDBManager.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface LMDropBoxBrowserViewController() <
NITableViewSystemDelegate,
DBRestClientDelegate
>

// View
@property (nonatomic, strong) NITableViewSystem *tableSystem;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

// DropBox Info
@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, strong) NSString *dropBoxFolderPath;
@property (nonatomic, strong) DBMetadata *folderMetadata;
@property (nonatomic, strong) DBMetadata *romMetaDataToLoadAfterDownloadingEverything;
@property (nonatomic, strong) DBMetadata *initialFreezeFileMetaData;
@property (nonatomic, assign) int pendingDownloadTotal;

// File System
@property (nonatomic, readonly) NSString *localPath;

// Emulation
@property (nonatomic, strong) LMRomInfo *loadedRom;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation LMDropBoxBrowserViewController

#pragma mark -
#pragma mark Init & Factory
- (id)init {
    self = [super init];
    if (self) {
        self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.restClient.delegate = self;
        self.dropBoxFolderPath = @"/";
        _localPath = [LMDBManager localFilePath];
        NSLog(@"localpath: %@", _localPath);

        NSError *dirError = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:_localPath withIntermediateDirectories:NO
                                                   attributes:@{} error:&dirError];
        if (dirError) {
            NSLog(@"dirError: %@", dirError);
        }
        [LMSaveManager setCustomFilePath:self.localPath];
    }

    return self;
}

- (void)dealloc {

}

#pragma mark -
#pragma mark UIViewController
- (void)loadView {
    [super loadView];
    
    self.title = @"Emulation!";
    
    self.tableSystem = [[NITableViewSystem alloc] initWithTableView:[UITableView new] andDelegate:self];
    
    [self.view addSubview:self.tableSystem.tableView];
    
    self.refreshControl = [UIRefreshControl new];
    [self.refreshControl addTarget:self
                            action:@selector(loadDirContents)
                  forControlEvents:UIControlEventValueChanged];
    [self.tableSystem.tableView addSubview:self.refreshControl];
    
    
    [self refreshDatasource];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    self.tableSystem.tableView.frame = self.view.bounds;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self loadDirContents];
    
    [self configSNES9X];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self checkForFilesToUpload];
}

#pragma mark -
#pragma mark LMDropBoxBrowserViewController
- (void)checkForFilesToUpload {
    if (!self.loadedRom) {
        return;
    }
    
    NSArray *comps = [[self.loadedRom filePath] pathComponents];
    NSString *baseName = [[comps lastObject] stringByDeletingPathExtension];
    NSLog(@"baseName: %@", baseName);
    
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.localPath error:nil];

    NSLog(@"Files: ");
    NSMutableArray *filesToUpload = [NSMutableArray array];
    for (NSString *localFile in dirContents) {
        NSLog(@"  %@", localFile);
        
        // Check if the file is new
        DBMetadata *existingDropBoxFile = nil;
        for (DBMetadata *file in self.folderMetadata.contents) {
            if ([file.filename isEqualToString:localFile]) {
                existingDropBoxFile = file;
                break;
            }
        }
        if (!existingDropBoxFile) {
            [filesToUpload addObject:localFile];
            continue;
        }
        
        // Else, just look for a matching base file name and upload everything.
        // Kind of dumb logic but ¯\_(ツ)_/¯
        if ([baseName isEqualToString:[localFile stringByDeletingPathExtension]] &&
            ![LMRomInfo isROMExtension:[localFile pathExtension]]) {
            [filesToUpload addObject:localFile];
        }
    }
    
    for (NSString *localFile in filesToUpload) {
        if (![LMDBManager shouldUploadFile:localFile]) {
            NSLog(@"Not uploading %@", localFile);
            continue;
        }
        NSLog(@"Uploading %@", localFile);
        DBMetadata *existingMD = [LMDBManager metaDataForFileName:localFile];
        [self.restClient uploadFile:localFile
                             toPath:self.dropBoxFolderPath
                      withParentRev:existingMD.rev
                           fromPath:[self.localPath stringByAppendingFormat:@"/%@", localFile]];
    }
}

- (void)configSNES9X {
    NSLog(@"resourcePath: %@", self.localPath);
    SISetSystemPath([self.localPath UTF8String]);
    SISetSRAMPath([self.localPath UTF8String]);
}

- (void)refreshDatasource {
    NSMutableArray *objects = [NSMutableArray array];
    
//    NISubtitleCellObject *reload = [NISubtitleCellObject objectWithTitle:@"Reload" subtitle:nil];
//    [self.tableSystem.actions attachToObject:reload tapBlock:^BOOL(id object, LMDropBoxBrowserViewController *self, NSIndexPath *indexPath) {
//        [self refreshDatasource];
//        return YES;
//    }];
//    [objects addObject:reload];
    
    NISubtitleCellObject *authObj = [NISubtitleCellObject objectWithTitle:@"DropBox Auth"
                                                                 subtitle:[NSString stringWithFormat:@"Linked: %d", [[DBSession sharedSession] isLinked]]];
    [self.tableSystem.actions attachToObject:authObj tapBlock:^BOOL(id object, LMDropBoxBrowserViewController *self, NSIndexPath *indexPath) {
        if (![[DBSession sharedSession] isLinked]) {
            [[DBSession sharedSession] linkFromController:self];
        }
        
        return YES;
    }];
    [objects addObject:authObj];
    
    NISubtitleCellObject *testDBObj = [NISubtitleCellObject objectWithTitle:@"DropBox test" subtitle:nil];
    [self.tableSystem.actions attachToObject:testDBObj tapBlock:^BOOL(id object, LMDropBoxBrowserViewController *self, NSIndexPath *indexPath) {
        [self loadDirContents];
        return YES;
    }];
    [objects addObject:testDBObj];
    
    if (self.folderMetadata) {
        for (DBMetadata *file in self.folderMetadata.contents) {
            
            NISubtitleCellObject *obj = [NISubtitleCellObject objectWithTitle:file.filename
                                                                         subtitle:nil];
            [self.tableSystem.actions attachToObject:obj tapBlock:^BOOL(id object, LMDropBoxBrowserViewController *self, NSIndexPath *indexPath) {
                [self openDBMetaData:file];
                
                return YES;
            }];
            [objects addObject:obj];
        }
    }
    
    [self.tableSystem setDataSourceWithArray:objects];
    [self.tableSystem.tableView reloadData];
}

- (void)openRom:(LMRomInfo *)romInfo withInitialFreezeFile:(NSString *)freezeFile {
    LMEmulatorController* emulator = [[LMEmulatorController alloc] init];
    emulator.romFileName = romInfo.filePath;
    emulator.initialSaveFileName = freezeFile; // Set this for the Emulator controller to start with a initial freeze file
    self.loadedRom = romInfo;

    [self.navigationController presentViewController:emulator animated:YES completion:nil];
}

#pragma mark -
#pragma mark DropBox Stuff
- (void)loadDirContents {
    NSLog(@"Loading DropBox list for directory: %@", self.dropBoxFolderPath);
    [self.restClient loadMetadata:self.dropBoxFolderPath];
}

/*! Opens the specified DBMetadata if it's for a ROM. */
- (void)openDBMetaData:(DBMetadata *)metaData {
    if ([LMRomInfo isFreezeFileName:metaData.filename]) {
        self.initialFreezeFileMetaData = metaData;
    }
    
    DBMetadata *romMetadata = nil;
    
    // Download files if they aren't already downloaded
    NSMutableArray *filesToDownload = [NSMutableArray array];
    NSString *fileBaseName = [metaData.filename stringByDeletingPathExtension];
    for (DBMetadata *file in self.folderMetadata.contents) {
        
        if ([LMRomInfo isROMFileName:file.filename]) {
            romMetadata = file;
        }
        
        if ([[file.filename stringByDeletingPathExtension] isEqualToString:fileBaseName] &&
            [LMDBManager shouldDownloadFile:file]) {
            [filesToDownload addObject:file];
        }
    }
    
    if ([filesToDownload count]) {
        self.pendingDownloadTotal = [filesToDownload count];
        self.romMetaDataToLoadAfterDownloadingEverything = metaData;
        for (DBMetadata *file in filesToDownload) {
            NSString *dest = [NSString stringWithFormat:@"%@/%@",
                              self.localPath,
                              file.filename];
            [self.restClient loadFile:file.path
                             intoPath:dest];
        }
        
    } else {
        // Load the rom we already have
        [self openRomWithFileName:romMetadata.filename withInitialFreezeFile:self.initialFreezeFileMetaData.filename];
    }
}


- (BOOL)openRomWithFileName:(NSString *)fileName withInitialFreezeFile:(NSString *)freezeFile {
   
    if ([LMRomInfo isROMFileName:fileName]) {
        LMRomInfo *rom = [LMRomInfo new];
        rom.filePath = [self.localPath stringByAppendingFormat:@"/%@", fileName];
        [self openRom:rom withInitialFreezeFile:freezeFile];
        self.initialFreezeFileMetaData = nil;
        return YES;
    }
    
    return NO;
}

#pragma mark -
#pragma mark DBRestClientDelegate Download
- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    [self.refreshControl endRefreshing];

    if (metadata.isDirectory && [metadata.path isEqualToString:self.dropBoxFolderPath]) {
        self.folderMetadata = metadata;
        [self refreshDatasource];
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    [self.refreshControl endRefreshing];

    // TODO: Display error
    NSLog(@"Error loading metadata: %@", error);
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)localPath
       contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
    NSLog(@"File loaded into path: %@", localPath);
    
    self.pendingDownloadTotal--;
    
    [LMDBManager setMetaData:metadata forFileName:metadata.filename];
    
    if (self.pendingDownloadTotal == 0) {
        [self openRomWithFileName:self.romMetaDataToLoadAfterDownloadingEverything.filename withInitialFreezeFile:self.initialFreezeFileMetaData.filename];
        self.romMetaDataToLoadAfterDownloadingEverything = nil;
    }
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    NSLog(@"There was an error loading the file: %@", error);
}

#pragma mark -
#pragma mark DBRestClientDelegate Upload

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    NSLog(@"file uploaded: %@, fileName: %@", destPath, metadata.filename);
    
    [LMDBManager setMetaData:metadata forFileName:metadata.filename];
}

//- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath;
- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSLog(@"upload failed: %@", error);
}

@end
