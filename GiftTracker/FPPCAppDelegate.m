//
//  FPPCAppDelegate.m
//  GiftTracker
//
//  Created by Jaime Ohm on 9/3/13.
//  Copyright (c) 2013 FPPC. All rights reserved.
//

#import "FPPCAppDelegate.h"
#import "TestFlight.h"

@interface FPPCAppDelegate ()

- (void)initializeCoreDataStack;
- (void)contextInitialized;
- (void)saveContext;
- (void)showErrorMessage;
- (void)mergePSCChanges:(NSNotification *)notification;

@end

@implementation FPPCAppDelegate
@synthesize managedObjectContext;

#pragma mark - Application lifecycle
#pragma

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self initializeCoreDataStack];
    
    [TestFlight takeOff:@"a5061ce9-4abd-407f-a352-983aadb23852"];
    [TestFlight passCheckpoint:@"LAUNCH APPLICATION"];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self saveContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self saveContext];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
}

- (void)dealloc {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver:self];
}

#pragma mark - Core Data
#pragma 

/**
 * Start listening for incoming iCloud changes AFTER the core data stack has been constructed
 */
- (void)contextInitialized {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self
               selector:@selector(mergePSCChanges:)
                   name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                 object:[[self managedObjectContext] persistentStoreCoordinator]];
}

/**
 * Handle NSPersistentStoreDidImportUbiquitousContentChangesNotification
 */
- (void)mergePSCChanges:(NSNotification *)notification {
    NSManagedObjectContext *moc = [self managedObjectContext];
    [moc performBlock:^{
        [moc mergeChangesFromContextDidSaveNotification:notification];
    }];
}

- (void)saveContext
{
    NSManagedObjectContext *moc = [self managedObjectContext];
    if (!moc) return;
    if (![moc hasChanges]) return;
    
    NSError *error = nil;
    if (![moc save:&error]) {
        TFLog(@"ERROR: Failed to save MOC: %@", error);
        [self showErrorMessage];
    }
}

/**
 * When an unrecoverable error occurs, tell the user to restart the application.
 */
- (void)showErrorMessage {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Uh Oh!" message:@"The database is misbehaving. Please restart this application." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
    [alert show];
}

- (void)initializeCoreDataStack
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"FPPCModel"
                                              withExtension:@"momd"];
    
    if (!modelURL) {
        TFLog(@"ERROR: Failed to find model URL.");
        [self showErrorMessage];
    }
    
    NSManagedObjectModel *mom = nil;
    mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    if (!mom) {
        TFLog(@"ERROR: Failed to initialize model.");
        [self showErrorMessage];
    }

    NSPersistentStoreCoordinator *psc = nil;
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (!psc) {
        TFLog(@"ERROR: Failed to find model URL.");
        [self showErrorMessage];
    }

    NSManagedObjectContext *moc = nil;
    moc = [NSManagedObjectContext alloc];
    moc = [moc initWithConcurrencyType:NSMainQueueConcurrencyType];
    [moc setPersistentStoreCoordinator:psc];
    
    [self setManagedObjectContext:moc];
    
    /**
     * Update iCloud token
     */
    id currentiCloudToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
    NSString *tokenKey = [NSString stringWithFormat:@"%@.UbiquityIdentityToken",[[NSBundle mainBundle] bundleIdentifier],nil];
    if (currentiCloudToken) {
        NSData *newTokenData = [NSKeyedArchiver archivedDataWithRootObject: currentiCloudToken];
        [[NSUserDefaults standardUserDefaults] setObject: newTokenData
                                                  forKey: tokenKey];
    } else {
        [[NSUserDefaults standardUserDefaults]
         removeObjectForKey: tokenKey];
    }
    
    /**
     * Add the NSPersistentStore to the NSPersistentStoreCoordinator on a background thread
     */
    dispatch_queue_t queue;
    queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        
        // Add the options to infer a mapping model and to attempt a migration automatically
        NSMutableDictionary *options = [[NSMutableDictionary alloc] init];
        [options setValue:[NSNumber numberWithBool:YES]
                   forKey:NSMigratePersistentStoresAutomaticallyOption];
        [options setValue:[NSNumber numberWithBool:YES]
                   forKey:NSInferMappingModelAutomaticallyOption];
        
        // Configure iCloud if it is enabled on this device
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (currentiCloudToken) {
            NSURL *cloudURL = [fileManager URLForUbiquityContainerIdentifier:nil];
            if (cloudURL) {
                TFLog(@"iCloud enabled: %@", cloudURL);
                
                /**
                 * We do not want to store at the root of our iCloud sandbox. Rather, we want to create a directory under the root with the same name as the document we are creating locally.
                 */
                cloudURL = [cloudURL URLByAppendingPathComponent:@"FPPCModel"];
                
                /**
                 * We use the bundle identifier as the unique key to define what data is to be shared across devices. We replace the periods with tilde's per Apple's recommendation.
                 * Discussion: https://devforums.apple.com/message/865121#865121
                 */
                [options setValue:[[[NSBundle mainBundle] bundleIdentifier] stringByReplacingOccurrencesOfString:@"." withString:@"~"] forKey:NSPersistentStoreUbiquitousContentNameKey];
                
                /**
                 * If iCloud is enabled, we need to add the iCloud URL to our options dictionary
                 */
                [options setValue:cloudURL forKey:NSPersistentStoreUbiquitousContentURLKey];
            }
            
        } else {
            TFLog(@"iCloud is not enabled");
        }
        
        NSURL *storeURL = nil;
        storeURL = [[fileManager URLsForDirectory:NSDocumentDirectory
                                        inDomains:NSUserDomainMask] lastObject];
        storeURL = [storeURL URLByAppendingPathComponent:@"FPPCModel-iCloud.sqlite"];
        NSError *error = nil;
        NSPersistentStoreCoordinator *coordinator = nil;
        coordinator = [[self managedObjectContext] persistentStoreCoordinator];
        NSPersistentStore *store = nil;
        store = [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!store) {
                TFLog(@"ERROR: Failed to create persistent store - %@", error);
                [self showErrorMessage];
            }
            
            [self contextInitialized];
        });
    });
}

@end
