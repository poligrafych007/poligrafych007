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

#import "RunningManAppDelegate.h"
#import <Accounts/Accounts.h>
#import <HockeySDK/HockeySDK.h>
#import <Photos/Photos.h>
#import <UserNotifications/UserNotifications.h>
#include <imhttp/MRHttpMemoryDataContainer.h>
#include <imhttp/MRHttpRequest.h>
#include <improfileslib/code/improfilesmanager.h>
#include <mprotolib/MRTimer.h>
#import <objc/runtime.h>
#import <set>
#import "ASIdentifierManager+MRCache.h"
#import "AppearanceManager.h"
#import "Brand.h"
#import "EventLogManager+Groupchat.h"
#import "ICQUIUtils.h"
#import "IMGenericNetworkingService.h"
#import "IMNetwork.h"
#import "JRSwizzle.h"
#import "LogUtils.h"
#import "MCConversationModelHelper.h"
#import "MCMessageHelper.h"
#import "MRAddressBookManager.h"
#import "MRAppCoreImpl.h"
#import "MRApplicationStartupProcess.h"
#import "MRApplicationStartupProcessDelegate.h"
#import "MRAuthenticationManager.h"
#import "MRAvatarController.h"
#import "MRBackgroundFetchController.h"
#import "MRBackgroundTaskManager.h"
#include "MRBackgroundURLSessionsHandler.h"
#import "MRChatViewController.h"
#import "MRChatsListController.h"
#import "MRCleanupManager.h"
#import "MRContactAnketaFetcher.h"
#import "MRContactListManager.h"
#import "MRCoreBuilderImpl.h"
#import "MRDatabaseStatistic.h"
#import "MRDebugCrashService.h"
#import "MRDebugPreheatTool.h"
#import "MRDebugTools.h"
#import "MRDiskSpaceStatistics.h"
#import "MRExploreLocationManager.h"
#import "MRFetchEventsProcessingManager.h"
#import "MRFileSharingManager.h"
#import "MRFilesharingStorage.h"
#import "MRGeoBadgeManager.h"
#import "MRHTTPBackdoor.h"
#import "MRHockeyAppCrashService.h"
#import "MRHttpUserAgent.h"
#include "MRIOServicePool.hpp"
#import "MRInAppNotificationHandler.h"
#import "MRInAppNotificationStatistics.h"
#import "MRInfrastructureBuilder.h"
#import "MRInviteContactOp.h"
#import "MRKeyboardAppearanceObserver.h"
#import "MRKostil.h"
#import "MRLinksHandler.h"
#import "MRLogObjc.h"
#import "MRLogsHelper.h"
#import "MRMasksManager.h"
#import "MRMediaAssetLibrary.h"
#import "MRMediaPickerItem.h"
#import "MRMessageTypeDetector.h"
#import "MRMigrationController.h"
#import "MRModules.h"
#import "MRNotificationsPrivacyDataSource.h"
#import "MROfficialAccounts.h"
#import "MROpenPublicChatOp.h"
#import "MROperationsBuilderImpl.h"
#import "MROutgoingMessagesQueue.h"
#import "MRPIDUtils.h"
#import "MRPermissionChecker.h"
#import "MRPhotosLoader.h"
#import "MRPromises.h"
#import "MRPushMessagesHandler.h"
#import "MRPushStatistics.h"
#import "MRQuickActionOp.h"
#import "MRRateVideoQualityManager.h"
#import "MRReloadOutgoingMessagesQueue.h"
#import "MRRemoteConfigImpl.h"
#import "MRRemoteFilterService.h"
#import "MRRemoteFilterServiceBuilder.h"
#import "MRRootRouter.h"
#import "MRRootViewController.h"
#import "MRRunLoopPool.h"
#import "MRSandboxAccess.h"
#import "MRScheduledFeedbackSender.h"
#import "MRScreenBuilder.h"
#import "MRSerialTaskQueue.h"
#import "MRServerPushMessagesHandler.h"
#include "MRShareController.h"
#import "MRShareRecentContactsUpdater.h"
#import "MRStatistics.h"
#import "MRStatisticsService.h"
#import "MRStickerDownloader.h"
#include "MRStickerManager.h"
#import "MRStickersContent.h"
#import "MRStorageManager.h"
#include "MRTaskQueue.h"
#import "MRTestPushBuilder.h"
#include "MRTestingHttpClient.h"
#import "MRTimeTools.h"
#import "MRTimerStatisticController.h"
#import "MRTimerStatisticService.h"
#import "MRTouchIDAvailability.h"
#import "MRURLSessionManager.h"
#import "MRUserActivityManager.h"
#import "MRVideoConverter.h"
#import "MRVoipPushWrapper.h"
#import "MRWallpaperManager.h"
#import "MRWatchdog.h"
#import "MRWindow.h"
#import "NSBundle+Utils.h"
#import "NSUserActivity_CallKit.h"
#import "NotificationTokenManager.h"
#import "OBJCClientInfo.h"
#import "Preferences.h"
#import "ProfilesManager.h"
#import "ProfilesStatus.h"
#import "Reachability.h"
#import "ThemeManager.h"
#import "UIApplication+MRState.h"
#import "UIApplication+MRTransitionHelper.h"
#import "UIDevice+Additions.h"
#import "UIDevice+MRCache.h"
#import "VoipCallManager.h"
#import "VoipHelper.h"
#import "VoipManager.h"

#import "ABAvatarManager.h"
#import "MRBridgeRemoteNotificationsHandler.h"

@interface RunningManAppDelegate () <MRStateMachineDelegate, VoipPushWrapperDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, MRApplicationStartupProcessDelegate>
{
	NSMutableArray *_mLocationsArray;
	NSDate *_appActiveSince;
	BOOL _alertHanging;
	MRBackgroundURLSessionsHandler _backgroundSessionsHandler;
	MRTimerStatisticController *_timerStatistic;
}

@property (nonatomic) NSDictionary *launchOptions;

@property (nonatomic, readonly) id<MRAppCore> core;

@property (nonatomic, strong) MRRootRouter *rootRouter;

@property (nonatomic) BOOL didAppLaunched;

@property (nonatomic, strong) MRBridgeRemoteNotificationsHandler *bridgeRemoteNotificationsHandler;

@property (nonatomic, readonly) MRVoipPushWrapper *voipPushWrapper;

@property (nonatomic, readonly) id<MRPendingPromise> windowPromise;

@property (nonatomic, readonly) id<MRPendingPromise> rootRouterPromise;

@end

@implementation RunningManAppDelegate

+ (RunningManAppDelegate *)sharedInstance
{
	static RunningManAppDelegate *instance;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		instance = (RunningManAppDelegate *)[[UIApplication sharedApplication] delegate];
		NSParameterAssert([instance isKindOfClass:RunningManAppDelegate.class]);
	});

	return instance;
}

#pragma mark - UIApplication delegate

//- (void) closeActionSheets:(UIView *) view {
//	for (UIView *nextView in view.subviews) {
//		if ([nextView isKindOfClass:[UIActionSheet class]]) {
//			UIActionSheet *actSheet = (UIActionSheet *)nextView;
//			[actSheet dismissWithClickedButtonIndex:actSheet.cancelButtonIndex animated:NO];
//			return;
//		}
//		[self closeActionSheets:nextView];
//	}
//}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
	NSString *sourceApplication = options[UIApplicationOpenURLOptionsSourceApplicationKey];

	if (url == nil)
	{
		LOG_DEBUG() << "Try to open NIL URL";
		return NO;
	}

	LOG_DEBUG() << "{url:" << url << ", source:" << sourceApplication << "}";

	MRLinkSourceFrom from = MRLinkSourceOtherApp;
	if ([sourceApplication rangeOfString:@"safari" options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		from = MRLinkSourceSafari;
	}
	else if ([sourceApplication mr_isEqualToStringIgnoringCase:@"com.apple.MobileSMS"])
	{
		from = MRLinkSourceMobileSMS;
	}

	return [MRLinksHandler openURL:url useSystemLink:NO source:from];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	LOG_DEBUG() << "";

	{
		__auto_type eventId = [EventLogManager eventIdWithType:MRStatisticActivationTimeEvent];
		[[MRTimerStatisticController sharedInstance] stopTimerWithEventId:eventId info:nil];
	}
	{
		[UIDevice currentDevice].batteryMonitoringEnabled = YES;
		EventLogManager.sharedManager.batteryStateOnLaunch = [[UIDevice currentDevice] batteryLevel];
		__auto_type eventId = [EventLogManager eventIdWithType:MRStatisticAppWentToBackgroundTimeEvent];
		[[MRTimerStatisticController sharedInstance] startTimerWithEventId:eventId];
	}

	[[MRDebugPreheatTool new] preheat];
	[self applicationDidBecomeActive];
}

- (void)applicationDidBecomeActive
{
	LOG_DEBUG() << "Custom applicationDidBecomeActive.";

	NSString *themeName = [ThemeManager sharedInstance].currentTheme.name;
	if (themeName)
	{
		[[EventLogManager sharedManager] logGeneralEventOfType:kLETypeTheme subType:kLETypeThemeStartUp withInfo:@{@"theme": themeName}];
	}

	_appActiveSince = [NSDate date];

	if ([MRRootRouter currentRouter].isPasscodeScreenPresented)
	{
		[self.window endEditing:YES];
	}
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	LOG_DEBUG() << "";

	__auto_type eventId = [EventLogManager eventIdWithType:MRStatisticAppWentToBackgroundTimeEvent];
	[[MRTimerStatisticController sharedInstance] stopTimerWithEventId:eventId info:nil];

	[MRShareRecentContactsUpdater fetchEndUpdateShareExtensionRecentContacts];
}

- (void)_signForNotifications
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

	[notificationCenter addObserver:self selector:@selector(themeChanged) name:kThemeChangedNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(profileRemoved:) name:kNotificationProfileRemoved object:nil];
	[notificationCenter addObserver:self selector:@selector(profileActivated:) name:kNotificationProfileActivated object:nil];
	[notificationCenter addObserver:self selector:@selector(onReachabilityChanged) name:kReachabilityChangedNotification object:nil];
}

- (void)_handleOptions:(NSDictionary *)launchOptions
{
	NSDictionary *remoteNotificationDict = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
#ifdef DEBUG
	NSDictionary *testPushFromFile = [MRTestPushBuilder buildTestPushNotificationFromFile];
	if (testPushFromFile)
	{
		remoteNotificationDict = testPushFromFile;
	}
//	remoteNotificationDict = [MRTestPushBuilder buildTestMRIMCallPushNotification];
//	remoteNotificationDict = [MRTestPushBuilder buildTestMRIMPushNotification];
//	remoteNotificationDict = [MRTestPushBuilder buildTestWIMPushNotification];
//	remoteNotificationDict = [MRTestPushBuilder buildTestWIMCallPushNotification];
#endif

	if (remoteNotificationDict)
	{
		[self.modules.pushMessagesHandler didReceiveRemoteNotification:remoteNotificationDict alreadyShown:true fetchCompletionHandler:nil];

		[self.modules.outgoingMessagesQueue registerBackgroundTaskIfNeeded];

		[[NSUserDefaults standardUserDefaults] setObject:remoteNotificationDict forKey:@"push-payload"];

		LOG_DEBUG() << "OCWP, " << [MCMessageHelper obfuscatedPushPayload:remoteNotificationDict];
	}

	// Check for quick actions
	id shourtcutItem = [launchOptions objectForKey:UIApplicationLaunchOptionsShortcutItemKey];
	if (shourtcutItem)
	{
		[self handleShortcut:shourtcutItem];
	}

	// check for openURL option
	{
		NSURL *url = launchOptions[UIApplicationLaunchOptionsURLKey];
		NSString *sourceApplication = launchOptions[UIApplicationLaunchOptionsSourceApplicationKey];
		id annotation = launchOptions[UIApplicationLaunchOptionsAnnotationKey];

		if (url && [url isKindOfClass:[NSURL class]] && sourceApplication && [sourceApplication isKindOfClass:[NSString class]])
		{
			__auto_type options = [NSMutableDictionary dictionary];
			if (annotation != nil)
			{
				options[UIApplicationOpenURLOptionsAnnotationKey] = annotation;
			}

			if (sourceApplication != nil)
			{
				options[UIApplicationLaunchOptionsSourceApplicationKey] = sourceApplication;
			}

			dispatch_async(dispatch_get_main_queue(), ^{
				__auto_type application = [UIApplication sharedApplication];
				[self application:application openURL:url options:options];
			});
		}
	}
}

- (void)onReachabilityChanged
{
	[self.modules.outgoingMessagesQueue registerBackgroundTaskIfNeeded];
	if ([[Reachability sharedReachability] isReachable])
	{
		[[ProfilesManager shared] executeNextPushUnsignRequest];
	}
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	ClientInfo::registerClientInfo<OBJCClientInfo>();
	MPL::profilesManager().setBlowfishInterface(static_cast<OBJCClientInfo *>(ClientInfo::instance()));

	_voipPushWrapper = [[MRVoipPushWrapper alloc] initWithDelegate:self];
	_bridgeRemoteNotificationsHandler = [[MRBridgeRemoteNotificationsHandler alloc] init];

	LOG_DEBUG() << "hasActiveTask " << [[MRBackgroundTaskManager sharedManager] hasActiveTask];

	[self setupApplication];

	_windowPromise = [self.coreBuilder.infrastructure.promises buildPendingPromiseForValueKindOf:UIWindow.class];
	_rootRouterPromise = [self.coreBuilder.infrastructure.promises buildPendingPromiseForValueKindOf:MRRootRouter.class];

	_timerStatistic = [[MRTimerStatisticController alloc] init];

	return YES;
}

- (void)setupApplication
{
	__auto_type startTime = [MRTimeTools now_ms];

	__auto_type coreBuilder = [[MRCoreBuilderImpl alloc] init];
	__auto_type core = [[MRAppCoreImpl alloc] initWithCoreBuilder:coreBuilder];
	__auto_type screenBuilder = [[MRScreenBuilder alloc] initWithModules:core.modules appConfig:core.appConfig infrastructure:coreBuilder.infrastructure];

	[MRLogObjc debug:@"[app] Initialized application in %lld ms", ([MRTimeTools now_ms] - startTime)];

	_coreBuilder = coreBuilder;
	_core = core;
	_screenBuilder = screenBuilder;
}

- (BOOL)canHandleURLFromLaunchOptions:(NSDictionary *)launchOptions
{
	NSDictionary *activityDictionary = launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey];
	return activityDictionary != nil;
}

- (void)updateCurrentScreen
{
	__auto_type profilesManager = self.modules.profilesManager;

	if (self.rootRouter == nil)
	{
		[MRLogObjc error:@"[boot][error] Current router not initialised"];
	}

	if (profilesManager.activeProfilePID != nil)
	{
		[self.rootRouter showMainController];
	}
	else if (profilesManager.profilesCount > 0)
	{
		[self.rootRouter showSignedOffController];
	}
	else
	{
		[self.rootRouter showLoginController];
	}
}

- (void)setupMainWindowWithInterfaceReadyPromise:(nonnull id<MRPromise>)interfaceReadyPromise
{
	__auto_type rootViewController = [[MRRootViewController alloc] init];

	__auto_type network = self.modules.network;
	__auto_type rootRouter = [[MRRootRouter alloc] initWithRootViewController:rootViewController interfaceReadyPromise:interfaceReadyPromise network:network];

	__auto_type windowFrame = [UIScreen mainScreen].bounds;
	__auto_type window = [[MRWindow alloc] initWithFrame:windowFrame];
	window.backgroundColor = [UIColor whiteColor];
	window.rootViewController = rootViewController;

	_rootRouter = rootRouter;
	_window = window;

	[self.windowPromise setValue:window];
	[self.rootRouterPromise setValue:rootRouter];

	[rootRouter showSplashController];
	[window makeKeyAndVisible];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.needManualProcessTextViewLongPress = YES;
	self.launchOptions = launchOptions;

#ifdef XCTEST
	return YES;
#endif

	__auto_type interfaceReadyPromise = [self.coreBuilder.infrastructure.promises buildPromiseForValueKindOf:NSNumber.class];
	__auto_type interfaceReadyFuture = [interfaceReadyPromise getFuture];
	__auto_type windowFuture = [self.windowPromise getFuture];

	[self.core startWithDelegate:self windowFuture:windowFuture interfaceReadyFuture:interfaceReadyFuture];

	[self setupMainWindowWithInterfaceReadyPromise:interfaceReadyPromise];

	if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey])
	{
		__auto_type eventId = [EventLogManager eventIdWithType:MRStatisticPushLaunchTimeEvent];
		[[MRTimerStatisticController sharedInstance] startTimerWithEventId:eventId];
	}
	else
	{
		__auto_type eventId = [EventLogManager eventIdWithType:MRStatisticLaunchTimeEvent];
		[[MRTimerStatisticController sharedInstance] startTimerWithEventId:eventId];
	}

	self.stickerPickerSelectedPackKey = kChatStickerPickerSelectedPackKey;

	LOG_DEBUG() << "Application state: " << [UIApplication sharedApplication].applicationState;

	[MRHttpUserAgent updateWithoutUID];

#ifndef APP_STORE
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefBackgroundFetchDebugNotificatonsKey])
	{
		__auto_type notificationContent = [[UNMutableNotificationContent alloc] init];
		notificationContent.body = [NSString stringWithFormat:@"Запуск %@ в бэкграунде!", [[Brand sharedInstance] applicationName]];

		__auto_type notificationTrigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
		__auto_type notificationRequest = [UNNotificationRequest requestWithIdentifier:@"опа" content:notificationContent trigger:notificationTrigger];

		[[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:notificationRequest withCompletionHandler:nil];
	}
#endif

	[[EventLogManager sharedManager] logDidStartLaunching:YES];
	[[EventLogManager sharedManager] logAppStart];

	return [self canHandleURLFromLaunchOptions:launchOptions];
}

- (void)checkBackgroundFetchMode
{
	[self.modules.backgroundFetchController checkBackgroundFetchMode];
}

- (void)showMainViewController
{
	LOG_DEBUG() << "";
	[self.rootRouter showMainController];
}

- (void)profileRemoved:(NSNotification *)notification
{
	self.offlineMessagesDidSave = NO;
}

- (void)profileActivated:(NSNotification *)notification
{
	OBJCIM_Profile *profile = notification.object;
	if (profile.pid != nil)
	{
		self.modules.crashService.userId = [MRPIDUtils profileUidFromPid:profile.pid];
	}
}

- (NSString *)dataFilePath:(NSString *)userName
{
	// Get the file-system path to data file in the application's Documents directory
	NSString *dataFilePath = nil;
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	dataFilePath = [documentsDirectory stringByAppendingPathComponent:userName];
	return dataFilePath;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	LOG_DEBUG() << "applicationWillTerminate";

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *lastMask = [defaults objectForKey:kVoipLastLoadedMask];
	if (lastMask.length)
	{
		[defaults removeObjectForKey:kVoipLastLoadedMask];
	}

	[self stopApplication];
}

- (void)stopApplication
{
	LOG_VOIP() << "VOIP: Terminating VoipCall...";
	dispatch_semaphore_t semVoip1 = [[VoipCallManager sharedInstance] terminate];
	if (semVoip1)
	{
		LOG_VOIP() << "VOIP: Wait for VoipCall...";
		// do not stop networking while call ending...
		dispatch_semaphore_wait(semVoip1, DISPATCH_TIME_FOREVER);
		LOG_VOIP() << "VOIP: Done...";
	}

	LOG_DEBUG() << "Profiles wait for termitate...";
	[[ProfilesManager shared] terminateProfiles];
	LOG_DEBUG() << "Profiles Done...";

	[[NSNotificationCenter defaultCenter] removeObserver:self];

	LOG_DEBUG() << "terminating!";

	//	[[[NSURLSession sharedSession] delegateQueue] setSuspended:YES];
	//	[[[NSURLSession sharedSession] delegateQueue] cancelAllOperations];
	//	[[NSURLSession sharedSession] invalidateAndCancel];
	[MRURLSessionManager sharedSession].operationQueue.suspended = YES;

	MRIOServicePool::sharedPool().stop();
	cpplog::MRLogService::instance().stop();

	LOG_VOIP() << "VOIP: Terminating Voip...";
	dispatch_semaphore_t semVoip2 = [[VoipManager sharedInstance] terminate];
	if (semVoip2)
	{
		dispatch_semaphore_wait(semVoip2, DISPATCH_TIME_FOREVER);
	}
	LOG_VOIP() << "VOIP: Terminating Voip...Done";

	imstorage::contactlist::MRContactListManager::instance().stopDatabase();
	const auto &shareController = share::MRShareController::instance();
	if (shareController)
	{
		shareController->stopDatabase();
	}
	MRTaskQueue::stopInstance();
	MRPriorityTaskQueue::instance().stop();
	[MRStorageManager stopEnvironment];
	MRTimer::stopService();
	[[MRRunLoopPool sharedPool] stop];
	[[MRStickerDownloader sharedInstance] terminate];

	[[NSUserDefaults standardUserDefaults] synchronize];
	LOG_DEBUG() << "finished";
}

#pragma mark - Push Notifications

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)registeredDeviceToken
{
	LOG_DEBUG() << "APNS token " << registeredDeviceToken;
	//  ss - отсылаем токен в mrim

	[[NotificationTokenManager sharedInstance] tokenReceived:registeredDeviceToken];

	__auto_type userInfo = [[NSMutableDictionary alloc] initWithCapacity:1];
	[userInfo setValue:registeredDeviceToken forKey:@"token"];
	[[NSNotificationCenter defaultCenter] postNotificationName:MRApplicationDidFinishRegisterForAPNSNotification object:self userInfo:userInfo];

	// if the user has agreed to the OS opt-in alert for Remote Notifications or turned on notifications later,
	// remember that -- once this is set, we will default new accounts (and modify existing accounts) to use Push.
	if (![[NSUserDefaults standardUserDefaults] objectForKey:kPushOptInReceived])
	{
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:kPushOptInReceived];

		// We should also set the default settings for the user here...
		constexpr int kWIMSessionTimeoutDefault = 86400 * 30; // 24 hours * 30 days
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:/*(24*60*60)*/ kWIMSessionTimeoutDefault]
		                                          forKey:kSignOffOnExit]; // 24 hours Minute sign off by default...*30days = kWIMSessionTimeoutDefault
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:kUsePushPref]; // turn on Push Notifications
	}

	// in case the session has already started (maybe we reconnected a saved session at startup, or maybe long delay before
	// getting token) make sure the session reflects the correct state of push, and the "opt in" initial setup gets done if needed

	[[EventLogManager sharedManager] logGeneralEventOfType:kFlurryTypePushAllow subType:nil withInfo:nil];
}

- (void)application:(UIApplication *)application didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error
{
	LOG_ERROR() << "";
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	__auto_type userInfo = [[NSMutableDictionary alloc] initWithCapacity:1];
	[userInfo setValue:error forKey:@"error"];
	[[NSNotificationCenter defaultCenter] postNotificationName:MRApplicationDidFinishRegisterForAPNSNotification object:self userInfo:userInfo];

	LOG_ERROR() << "Error in notification registration. Error: " << error;
	NSString *er = error ? [error description] : @"";
	[[EventLogManager sharedManager] logGeneralEventOfType:kFlurryTypePushDeny subType:nil withInfo:@{@"error": er}];
}

- (void)application:(UIApplication *)application
    didReceiveRemoteNotification:(NSDictionary *)userInfo
          fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
	LOG_DEBUG() << "UIApplicationEvents| remote notification with background fetch: " << userInfo << ", applicationState" << (long)application.applicationState;

	if (!UIApplication.mr_isStateBackground)
	{
		completionHandler(UIBackgroundFetchResultNoData);
		return;
	}

	if (self.modules != nil)
	{
		[MRPushStatistics eventTextPushDeliveredForIdentifier:nil];

		if (self.modules.profilesManager.activeProfile != nil)
		{
			__auto_type pushHandler = self.modules.pushMessagesHandler;
			[pushHandler didReceiveRemoteNotification:userInfo
			                             alreadyShown:false
			                   fetchCompletionHandler:^(UIBackgroundFetchResult result) {
				                   LOG_DEBUG() << "UIApplicationEvents| remote notification with background fetchfinished";
				                   completionHandler(result);
			                   }];
		}
		else
		{
			application.applicationIconBadgeNumber = 0;
			[self.modules.backgroundFetchController processPendingPushUnsignRequestWithCompletionHandler:^{
				completionHandler(UIBackgroundFetchResultNoData);
			}];
		}
	}
	else
	{
		completionHandler(UIBackgroundFetchResultNoData);
	}

	if ([[UIApplication sharedApplication] mr_transitOnNotificationEnabled])
	{
		[self handleRemoteNotification:userInfo];
	}
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
	LOG_DEBUG() << "UIApplicationEvents| perform fetch, applicationState" << (long)application.applicationState;
	[self.modules.backgroundFetchController handleBackgroundFetchEventWithCompletionHandler:^(UIBackgroundFetchResult result) {
		LOG_DEBUG() << "UIApplicationEvents| perform fetch finished";
		completionHandler(result);
	}];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
	LOG_DEBUG() << "UIApplicationEvents| handleEventsForBackgroundURLSession: " << identifier;
	_backgroundSessionsHandler.storeCompletionHandler(
	    ^{
		    LOG_DEBUG() << "UIApplicationEvents| handleEventsForBackgroundURLSession finished: " << identifier;
		    completionHandler();
	    },
	    identifier);
}

- (void)invokeCompletionHandlerForSessionIdentifier:(NSString *)identifier
{
	LOG_DEBUG() << "UIApplicationEvents| invokeCompletionHandlerForSessionIdentifier: " << identifier;
	_backgroundSessionsHandler.invokeCompletionHandlerForSessionIdentifier(identifier);
}

- (void)handleRemoteNotification:(NSDictionary *)userInfo
{
	//    [[MCMessageHelper defaultHelper] processPushNotification:userInfo];
}

#pragma mark - Voip Push
- (void)voipPushDidReceived:(NSDictionary *)payload;
{
	LOG_VOIP() << "VOIP:PUSH recived " << payload;

	[self.modules.pushMessagesHandler didReceiveRemoteNotification:payload alreadyShown:true fetchCompletionHandler:nil];

	[[MCMessageHelper defaultHelper] processVoipPushNotification:payload];

	if (UIApplication.mr_isStateBackground)
	{
		LOG_VOIP() << "VOIP:PUSH Init Background Fetch";
		[self.modules.backgroundFetchController workWithBackgroundFetchTime:^{
			LOG_VOIP() << "VOIP:PUSH Background Fetch done!";
		}];
	}
	else
	{
		// skip
	}
}

#if defined(__IPHONE_12_0) && (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_12_0)
- (BOOL)application:(UIApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> *_Nullable))restorationHandler
#else
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *_Nullable))restorationHandler
#endif
{
	LOG_DEBUG() << "UIApplicationEvents| activityType: " << userActivity.activityType << ", webpageURL: " << userActivity.webpageURL << ", userInfo: " << userActivity.userInfo;

	if ([userActivity.activityType isEqualToString:CSSearchableItemActionType])
	{
		NSString *chatPID = [[MRUserActivityManager sharedInstance] chatPIDFromUserActivity:userActivity];

		if (chatPID.length)
		{
			[self.rootRouter showMRChatViewControllerForPID:chatPID completion:nil];

			return YES;
		}

		return NO;
	}

	if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb])
	{
		NSURL *url = userActivity.webpageURL;
		return [MRLinksHandler openURL:url useSystemLink:NO source:MRLinkSourceUndefined];
	}

	NSString *user = userActivity.mr_callKitCallHandle;
	if (user)
	{
		BOOL video = userActivity.mr_callKitVideo;
		CXHandleType handleType = userActivity.mr_callKitHandleType;
		__auto_type voipCallManager = self.core.modules.voipCallManager;
		[voipCallManager ckWantContinueCallTo:user withVideo:video type:handleType];
		return YES;
	}

	return NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	LOG_DEBUG() << "";

	[self.modules.outgoingMessagesQueue registerBackgroundTaskIfNeeded];
	[[MRStatistics sharedService] flush];

	if ([[MRBackgroundTaskManager sharedManager] hasActiveTask])
	{
		return;
	}

	//	[self runBackgroundTask];

	if (![ProfilesManager shared].activeProfile && ![[NSUserDefaults standardUserDefaults] boolForKey:kPrefWasSuccesffullyLoggedIn])
	{
		NSString *alertBody = NSLocalizedString(@"_icq_registration_doesnt_complete", nil);
#ifndef APP_STORE
		alertBody = [@"+ " stringByAppendingString:alertBody];
#endif
		__auto_type notificationContent = [[UNMutableNotificationContent alloc] init];
		notificationContent.body = alertBody;
		notificationContent.categoryIdentifier = NSLocalizedString(@"_icq_registration_continue", nil);

		__auto_type notificationTrigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:5 * 60 repeats:NO];

		__auto_type notificationRequest = [UNNotificationRequest requestWithIdentifier:@"buddyRegistered" content:notificationContent trigger:notificationTrigger];

		[[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:notificationRequest withCompletionHandler:nil];
	}
}

- (void)runBackgroundTask
{
	if (self.rootRouter.isMainControllerShown && !self.rootRouter.isNavigationControllerHaveOneController)
	{
		LOG_DEBUG() << "";
		[[MRBackgroundTaskManager sharedManager] startBackgroundTaskWithDuration:30.0];
		//		[[MRBackgroundTaskManager sharedManager] startBackgroundTask];

		if (UIApplication.mr_isStateBackground)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationDidStartBackgroundTaskWhileInBackground object:nil];
		}
	}
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	LOG_DEBUG() << "";

	__auto_type eventId = [EventLogManager eventIdWithType:MRStatisticActivationTimeEvent];
	[[MRTimerStatisticController sharedInstance] startTimerWithEventId:eventId];

	[[[MRReloadOutgoingMessagesQueue alloc] initWithOutgoingQueue:self.modules.outgoingMessagesQueue] performBackendApi];

	[self.modules.pushMessagesHandler clearPendingNotifications];
	[self clearPushNotifications];
	self.needManualProcessTextViewLongPress = YES;
	[[EventLogManager sharedManager] logAppStart];

	[NSNotificationCenter.defaultCenter postNotificationName:kNotificationWillEnterForeground object:nil];
}

#pragma mark - Orientation

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
	return [self.window.rootViewController supportedInterfaceOrientations];
}

- (void)application:(UIApplication *)application didChangeStatusBarOrientation:(UIInterfaceOrientation)oldStatusBarOrientation
{
	UIInterfaceOrientation newStatusBarOrientation = application.statusBarOrientation;

	BOOL isPortraitToLandscape = UIInterfaceOrientationIsPortrait(oldStatusBarOrientation) && UIInterfaceOrientationIsLandscape(newStatusBarOrientation);
	BOOL isLandscapeToPortrait = UIInterfaceOrientationIsLandscape(oldStatusBarOrientation) && UIInterfaceOrientationIsPortrait(newStatusBarOrientation);

	if (isPortraitToLandscape)
	{
		[[EventLogManager sharedManager] logGeneralEventOfType:kLEPortraitToLandscapeEvent subType:nil withInfo:nil];
	}
	if (isLandscapeToPortrait)
	{
		[[EventLogManager sharedManager] logGeneralEventOfType:kLELandscapeToPortraitEvent subType:nil withInfo:nil];
	}
}

#pragma mark - Other stuff

- (void)themeChanged
{
	[[AppearanceManager sharedManager] applyCurrentTheme];
}

- (void)precacheABAvatars
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		dispatch_async(dispatch_get_global_queue(0, 0), ^{
			[ABAvatarManager requestABAvatars];
		});
	});
}

- (void)clearPushNotifications
{
	[self.modules.pushMessagesHandler clearDeliveredNotifications];
}

#pragma mark - Calabash replace account

/*
 aJSON ::= {"fromUIN":"<UIN>", "toUIN":"<UIN>"}
 */

- (NSString *)calabashBackdoorRepalceAccount:(NSString *)aJSON
{
	if (aJSON == nil)
	{
		return @"[ERROR] Empty json";
	}

	// Parsing json
	NSDictionary *arguments = nil;
	@try
	{
		NSError *error = nil;
		NSData *data = [aJSON dataUsingEncoding:NSUTF8StringEncoding];
		arguments = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
		if (error)
		{
			return @"[ERROR] Invalid json";
		}
	}
	@catch (NSException *exception)
	{
		return @"[ERROR] Invalid json";
	}

	NSString *fromUIN = static_cast<NSString *>(arguments[@"fromUIN"]);
	if (fromUIN == nil)
	{
		return @"[ERROR] No fromUIN";
	}

	NSString *toUIN = static_cast<NSString *>(arguments[@"toUIN"]);
	if (toUIN == nil)
	{
		return @"[ERROR] No toUIN";
	}

	OBJCWIM_Profile *profile = static_cast<OBJCWIM_Profile *>([[ProfilesManager shared] activeProfile]);
	if (profile == nil)
	{
		return @"[ERROR] Can not find profile by toUIN";
	}

	return @"[OK]";
}

#ifndef APP_STORE
- (NSString *)calabashBackdoorInjectFetch:(NSString *)aJSON
{
	OBJCWIM_Profile *objcProfile = (OBJCWIM_Profile *)[[ProfilesManager shared] activeProfile];
	[objcProfile injectFetch:aJSON];
	return objcProfile ? @"[OK]" : @"[ERROR] Can not find any wim valid profile";
}
#endif

#ifdef DEBUG
- (void)calabashBackdoorSetAnimationSpeed:(float)speed
{
	UIApplication.sharedApplication.keyWindow.layer.speed = speed;
}
#endif

- (NSString *)calabashBackdoorRegisterHttpResponses:(NSString *)encodedJson
{
#ifdef DEBUG
	NSDictionary *arguments = nil;
	@try
	{
		NSError *error = nil;
		NSData *data = [encodedJson dataUsingEncoding:NSUTF8StringEncoding];
		arguments = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
		if (error)
		{
			return @"[ERROR] Invalid json";
		}
	}
	@catch (NSException *exception)
	{
		return @"[ERROR] Invalid json";
	}

	NSArray *rootObject = arguments[@"root"];
	if (!rootObject)
	{
		return @"[ERROR] Invalid json: there is no \"root\" object";
	}

	[MRHTTPBackdoor registerHttpResponses:rootObject];
	return nil;
#else
	return @"[ERROR] DEBUG disabled";
#endif
}

#pragma mark - Quick Actions

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler
{
	LOG_DEBUG() << "UIApplicationEvents| performActionForShortcutItem: " << shortcutItem.type;

	[self handleShortcut:shortcutItem];

	completionHandler(YES);
}

- (void)handleShortcut:(UIApplicationShortcutItem *)shortcutItem
{
	MRParameterAssertOrReturn(shortcutItem);

	__auto_type shortcutItemType = shortcutItem.type;
	__auto_type bundleID = [[NSBundle mainBundle] bundleIdentifier];

	__auto_type action = MRQuickActionTypeNewMessage;

	__auto_type newMessageActionString = [bundleID stringByAppendingString:@".newmessage"];
	__auto_type addContactActionString = [bundleID stringByAppendingString:@".addcontact"];

	__auto_type isAction = ^BOOL(NSString *action) {
		return [shortcutItemType compare:action options:NSBackwardsSearch] == NSOrderedSame;
	};

	if (isAction(newMessageActionString))
	{
		action = MRQuickActionTypeNewMessage;
	}
	else if (isAction(addContactActionString))
	{
		action = MRQuickActionTypeAddContact;
	}
	else
	{
		MRAssert(nil, @"Invalid shourtcut item.");
		return;
	}
	__auto_type operation = [[MRQuickActionOp alloc] initWithAction:action profile:[[ProfilesManager shared] activeProfile]];
	[operation performBackendApi];
}

- (id<MRModules>)modules
{
	return self.core.modules;
}

#pragma mark - MRApplicationStartupProcessDelegate

- (void)didBootStepFinished
{
#ifndef APP_STORE
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL crashOnStart = [defaults boolForKey:kPrefCrashOnNextStart];
	if (crashOnStart)
	{
		[defaults removeObjectForKey:kPrefCrashOnNextStart];
		[defaults synchronize];
		[[BITHockeyManager sharedHockeyManager].crashManager generateTestCrash];
	}
#endif

	[VoipHelper updateRecordPermissionGrant];

	__auto_type __weak weakSelf = self;
	dispatch_async(dispatch_get_main_queue(), ^{
		[weakSelf updateCurrentScreen];
	});

	[self checkBackgroundFetchMode];
	[self _signForNotifications];
	[self _handleOptions:self.launchOptions];

	[self.bridgeRemoteNotificationsHandler processPendingNotificationResponsesWithHandler:self.modules.pushMessagesHandler];
	self.bridgeRemoteNotificationsHandler = nil;

	[self.voipPushWrapper setNotificationTokenManager:self.modules.notificationTokenManager];
}

- (void)didInterfaceDidReadyToUseStepFinished
{
}

- (void)didFinishedSyncedWithServerOnLaunchStep
{
}

- (void)didFinishedSyncedWithServerOnProfileLoginStep
{
}

- (void)applicationStartupShowOutOfSpaceScreen
{
	[self.rootRouter showOutOfStorageViewController];
}

- (BOOL)isChatsListScreenVisible
{
	return self.rootRouter.chatsListControllerVisible;
}

#pragma mark - Navigation requests

- (void)openAppStorePage
{
	NSString *appStoreURLFormat = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@";
	NSString *appStoreID = [Brand sharedInstance].iTunesConnectAppId;
	NSString *appStoreUrlString = [NSString stringWithFormat:appStoreURLFormat, appStoreID];
	NSURL *url = [NSURL URLWithString:appStoreUrlString];
	[UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
}

- (void)showFeedbackScreen
{
	LOG_DEBUG() << "";
	[self.rootRouter showFeedbackController];
}

@end
