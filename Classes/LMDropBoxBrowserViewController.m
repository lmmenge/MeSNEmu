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
#import "MBProgressHUD.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface LMDropBoxBrowserViewController() <
NITableViewSystemDelegate,
DBRestClientDelegate
>

// View
@property (nonatomic, strong) NITableViewSystem *tableSystem;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) MBProgressHUD *downloadHUD;

// DropBox
@property (nonatomic, strong) DBRestClient *restClient;
@property (nonatomic, strong) NSString *dropBoxFolderPath;
@property (nonatomic, strong) DBMetadata *folderMetadata;
@property (nonatomic, strong) DBMetadata *romMetaDataToLoadAfterDownloadingEverything;
@property (nonatomic, strong) DBMetadata *initialFreezeFileMetaData;
@property (nonatomic, assign) int pendingDownloadTotal;
@property (nonatomic, strong) NSTimer *uploadTimer;

// File System
@property (nonatomic, readonly) NSString *localPath;

// Emulation
@property (nonatomic, strong) LMRomInfo *loadedRom;
@property (nonatomic, assign) BOOL playerIsPlaying;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation LMDropBoxBrowserViewController

#pragma mark -
#pragma mark Init & Factory
- (id)init {
    self = [self initWithDropBoxPath:@"/"];
    if (self) {
        
    }
    return self;
}

- (id)initWithDropBoxPath:(NSString *)dropBoxPath {
    self = [super init];
    if (self) {
        self.restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        self.restClient.delegate = self;
        self.dropBoxFolderPath = dropBoxPath;
        _localPath = [[LMDBManager localFilePath] stringByAppendingString:self.dropBoxFolderPath];
        if ([_localPath hasSuffix:@"/"]) {
            _localPath = [_localPath substringToIndex:(_localPath.length - 1)];
        }
        NSLog(@"localpath: %@", _localPath);

        NSError *dirError = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:_localPath withIntermediateDirectories:NO
                                                   attributes:@{} error:&dirError];
        NSAssert(!dirError || dirError.code == 516, @"Could not create directory. Will not be able to save files. Got error: %@", dirError);
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
    
    self.playerIsPlaying = NO;
    [self.uploadTimer invalidate];
    self.uploadTimer = nil;
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
        NSString *relativePath = [self dropBoxPathForFileName:localFile];
        if (![LMDBManager shouldUploadFile:relativePath]) {
            NSLog(@"Not uploading %@", relativePath);
            continue;
        }
        NSLog(@"Uploading %@", relativePath);
        DBMetadata *existingMD = [LMDBManager metaDataForFileName:relativePath];
        [self.restClient uploadFile:localFile
                             toPath:self.dropBoxFolderPath
                      withParentRev:existingMD.rev
                           fromPath:[self.localPath stringByAppendingFormat:@"/%@", localFile]];
    }
}

- (NSString *)dropBoxPathForFileName:(NSString *)fileName {
    NSString *result = [self.dropBoxFolderPath stringByAppendingString:fileName];

    return result;
}

- (void)configSNES9X {
    NSLog(@"resourcePath: %@", self.localPath);
    SISetSystemPath([self.localPath UTF8String]);
    SISetSRAMPath([self.localPath UTF8String]);
}

- (void)refreshDatasource {
    NSMutableArray *objects = [NSMutableArray array];
    
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
    emulator.disableSaveFileAutoLoad = YES; // TODO: Only disable if we just freshly downloaded the SRM file.
    emulator.initialSaveFileName = freezeFile;
    self.loadedRom = romInfo;

    self.playerIsPlaying = YES;
    
    // Start auto uploader for save states and SRM files.
    self.uploadTimer = [NSTimer scheduledTimerWithTimeInterval:60
                                                        target:self
                                                      selector:@selector(checkForFilesToUpload)
                                                      userInfo:nil
                                                       repeats:YES];
    [self.navigationController presentViewController:emulator animated:YES completion:nil];
}

#pragma mark -
#pragma mark DropBox Stuff
- (void)loadDirContents {
    NSLog(@"Loading DropBox list for directory: %@", self.dropBoxFolderPath);
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Loading contents";
    
    [self.restClient loadMetadata:self.dropBoxFolderPath];
}

/*! Opens the specified DBMetadata if it's for a ROM. */
- (void)openDBMetaData:(DBMetadata *)metaData {
    if ([LMRomInfo isFreezeFileName:metaData.filename] ||
        [LMRomInfo isSRMFileName:metaData.filename] ||
        [LMRomInfo isROMFileName:metaData.filename]) {
        [self openRomRelatedMetaData:metaData];
    } else if (metaData.isDirectory) {
        LMDropBoxBrowserViewController *db = [[LMDropBoxBrowserViewController alloc] initWithDropBoxPath:metaData.path];
        [self.navigationController pushViewController:db animated:YES];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Wha?"
                                                                       message:[NSString stringWithFormat:@"Don't know how to open %@", metaData.filename]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)openRomRelatedMetaData:(DBMetadata *)metaData {
    NSString *fileBaseName = [metaData.filename stringByDeletingPathExtension];
    
    if ([LMRomInfo isFreezeFileName:metaData.filename]) {
        // save state files are "basename.000.frz", so this is a special case.
        fileBaseName = [[metaData.filename stringByDeletingPathExtension] stringByDeletingPathExtension];
        self.initialFreezeFileMetaData = metaData;
    }
    
    DBMetadata *romMetadata = nil;
    
    // Download files if they aren't already downloaded
    NSMutableArray *filesToDownload = [NSMutableArray array];
    for (DBMetadata *file in self.folderMetadata.contents) {
        if (![[file.filename stringByDeletingPathExtension] isEqualToString:fileBaseName]) {
            continue;
        }
        
        if ([LMRomInfo isROMFileName:file.filename]) {
            romMetadata = file;
        }
        
        if ([LMDBManager shouldDownloadFile:file]) {
            [filesToDownload addObject:file];
        }
    }
    
    if ([filesToDownload count]) {
        self.pendingDownloadTotal = [filesToDownload count];
        self.romMetaDataToLoadAfterDownloadingEverything = metaData;
        
        [self.downloadHUD hide:NO];
        self.downloadHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        self.downloadHUD.labelText = [NSString stringWithFormat:@"Downloading %d file(s)", self.pendingDownloadTotal];
        
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
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];

    if (metadata.isDirectory && [metadata.path isEqualToString:self.dropBoxFolderPath]) {
        self.folderMetadata = metadata;
        [self refreshDatasource];
    }
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    [self.refreshControl endRefreshing];
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];

    NSLog(@"Error loading metadata: %@", error);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Couldn't get DropBox data."
                                                                   message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Retry"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
                                                [self loadDirContents];
                                            }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)localPath
       contentType:(NSString *)contentType metadata:(DBMetadata *)metadata {
    NSLog(@"File loaded into path: %@", localPath);
    
    self.pendingDownloadTotal--;
    
    [LMDBManager setMetaData:metadata forFileName:metadata.path];
    
    if (self.pendingDownloadTotal == 0) {
        [self.downloadHUD hide:YES];
        self.downloadHUD = nil;

        [self openRomWithFileName:self.romMetaDataToLoadAfterDownloadingEverything.filename withInitialFreezeFile:self.initialFreezeFileMetaData.filename];
        self.romMetaDataToLoadAfterDownloadingEverything = nil;
    } else {
        self.downloadHUD.labelText = [NSString stringWithFormat:@"Downloading %d file(s)", self.pendingDownloadTotal];
    }
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error {
    NSLog(@"There was an error loading the file: %@", error);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Download error. Please retry."
                                                                   message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark -
#pragma mark DBRestClientDelegate Upload

- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    NSLog(@"file uploaded: %@, fileName: %@", destPath, metadata.filename);
    
    [LMDBManager setMetaData:metadata forFileName:metadata.path];
    
}

//- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath;
- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSLog(@"upload failed: %@", error);
    
    if (!self.playerIsPlaying) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Upload error."
                                                                       message:[error localizedDescription] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Retry"
                                                  style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action) {
                                                    // This is a little too agressive, we may start uploading files that haven't failed or completed yet unnecessarily.
                                                    [self checkForFilesToUpload];
                                                }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
