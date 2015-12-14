/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

@class FBSimulator;
@class FBSimulatorConfiguration;
@class FBSimulatorControlConfiguration;
@class FBSimulatorPool;
@class FBSimulatorTerminationStrategy;
@class SimDevice;
@class SimDeviceSet;

/**
 Options for how a pool should handle allocation & freeing.
 */
typedef NS_OPTIONS(NSUInteger, FBSimulatorAllocationOptions){
  FBSimulatorAllocationOptionsCreate = 1 << 0, /** Permit the creation of Simulators when allocating. */
  FBSimulatorAllocationOptionsReuse = 1 << 1, /** Permit the reuse of Simulators when allocating. */
  FBSimulatorAllocationOptionsShutdownOnAllocate = 1 << 2, /** Shutdown of the Simulator becomes a precondition of allocation. */
  FBSimulatorAllocationOptionsEraseOnAllocate = 1 << 4, /** Erasing of the Simulator becomes a precondition of allocation. */
  FBSimulatorAllocationOptionsDeleteOnFree = 1 << 5, /** Deleting of the Simulator becomes a postcondition of freeing. */
  FBSimulatorAllocationOptionsEraseOnFree = 1 << 6, /** Erasing of the Simulator becomes a postcondition of freeing. */
  FBSimulatorAllocationOptionsPersistHistory = 1 << 7 /** Fetch & Persist History for the allocated Simulator. */
};

@protocol FBSimulatorLogger;

/**
 A container for a collection of Simulators.
 */
@interface FBSimulatorPool : NSObject

/**
 Creates and returns an FBSimulatorPool.

 @param configuration the configuration to use.
 @param error any error that occurred during the creation of the pool.
 @returns a new FBSimulatorPool.
 */
+ (instancetype)poolWithConfiguration:(FBSimulatorControlConfiguration *)configuration error:(NSError **)error;

/**
 Returns the configuration for the reciever.
 */
@property (nonatomic, copy, readonly) FBSimulatorControlConfiguration *configuration;

/**
 An Ordered Set of the Simulators for the DeviceSet.
 This includes allocated and un-allocated Simulators.
 Ordering is based on the ordering of SimDeviceSet.
 Is an NSOrderedSet<FBSimulator>
 */
@property (nonatomic, copy, readonly) NSArray *allSimulators;

/**
 Returns the Simulator Termination Strategy associated with the reciever.
 */
@property (nonatomic, strong, readonly) FBSimulatorTerminationStrategy *terminationStrategy;

/**
 Returns a Device for the given parameters. Will create devices where necessary.
 If you plan on running multiple tests in the lifecycle of a process, you sshould use `freeDevice:error:`
 otherwise devices will continue to be allocated.

 @param configuration the Configuration of the Device to Allocate. Must not be nil.
 @param options the options for the allocation/freeing of the Simulator.
 @param error an error out for any error that occured.
 @return a FBSimulator if one could be allocated with the provided options, nil otherwise
 */
- (FBSimulator *)allocateSimulatorWithConfiguration:(FBSimulatorConfiguration *)configuration options:(FBSimulatorAllocationOptions)options error:(NSError **)error;

/**
 Marks a device that was previously returned from `allocateDeviceWithName:sdkVersion:error:` as free.
 Call this when multiple test runs, or simulators are to be re-used in a process.

 @param simulator the Device to Free.
 @param error an error out for any error that occured.
 @returns YES if the freeing of the device was successful, NO otherwise.
 */
- (BOOL)freeSimulator:(FBSimulator *)simulator error:(NSError **)error;

@end

/**
 Fetchers for Specific and Groups of Simulators
 */
@interface FBSimulatorPool (Fetchers)

/**
 An Ordered Set of the Simulators that this Pool has allocated.
 This includes only allocated simulators.
 Is an NSOrderedSet<FBSimulator>
 */
@property (nonatomic, copy, readonly) NSArray *allocatedSimulators;

/**
 An Ordered Set of the Simulators that this Pool has allocated.
 This includes only allocated simulators.
 Ordering is based on the recency of the allocation: the most recent allocated Simulator is at the end of the Set.
 Is an NSOrderedSet<FBSimulator>
 */
@property (nonatomic, copy, readonly) NSArray *unallocatedSimulators;

/**
 An Ordered Set of the Simulators that have been launched by any pool, or not by FBSimulatorControl at all.
 Is an NSOrderedSet<FBSimulator>
 */
@property (nonatomic, copy, readonly) NSArray *launchedSimulators;

@end

/**
 Helpers to Debug what is going on with the state of the world, useful after-the-fact (CI)
 */
@interface FBSimulatorPool (Debug)

/**
 A Description of the Pool, with extended debug information
 */
- (NSString *)debugDescription;

/**
 Log SimDeviceSet interactions.
 */
- (void)startLoggingSimDeviceSetInteractions:(id<FBSimulatorLogger>)logger;

@end

/**
 Enable/disable CoreSimulator debug logging and any other verbose logging we can get our hands on.
 */
void FBSetSimulatorLoggingEnabled(BOOL enabled);
