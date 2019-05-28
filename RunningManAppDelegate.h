// ****************************************************************************
//
// Copyright (c) 2008 America Online, Inc.  All rights reserved.
// This software contains valuable confidential and proprietary information
// of America Online, Inc. and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and
// its contents is a violation of applicable laws.
//
//           A M E R I C A   O N L I N E   C O N F I D E N T I A L
//
// ****************************************************************************

@class MRPhotosLoader;
@class MROutgoingMessagesQueue;
@class MRVideoConverter;
@class MROfficialAccounts;
@class MRFilesharingStorage;
@class MRContactAnketaFetcher;
@class MRMediaAssetLibrary;
@class MRTimerStatisticController;
@class MRApplicationStartupProcess;
@class MRScreenBuilder;
@protocol MRCoreBuilder;
@protocol MRModules;
@protocol MRRemoteFilterService;

@interface RunningManAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, readonly) id<MRCoreBuilder> coreBuilder;
@property (class, nonatomic, readonly) RunningManAppDelegate *sharedInstance;
@property (nonatomic) BOOL offlineMessagesDidSave;
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, readonly) NSDate *launchTime;
@property (nonatomic, readonly) id<MRModules> modules;
@property (atomic) NSString *stickerPickerSelectedPackKey;
@property (nonatomic, readonly) NSDictionary *launchOptions;
@property (nonatomic) BOOL needManualProcessTextViewLongPress;
@property (nonatomic, readonly) MRTimerStatisticController *timerStatistic;
@property (nonatomic, readonly) MRApplicationStartupProcess *bootProcessController;
@property (nonatomic, readonly) MRScreenBuilder *screenBuilder;

- (void)showMainViewController;
- (void)invokeCompletionHandlerForSessionIdentifier:(NSString *)identifier;
- (void)stopApplication;

- (void)openAppStorePage;
- (void)showFeedbackScreen;

@end
