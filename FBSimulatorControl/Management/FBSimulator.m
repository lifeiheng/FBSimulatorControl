/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSimulator.h"
#import "FBSimulator+Private.h"
#import "FBSimulatorPool+Private.h"

#import <AppKit/AppKit.h>

#import <CoreSimulator/SimDevice.h>
#import <CoreSimulator/SimDeviceSet.h>

#import "FBCompositeSimulatorEventSink.h"
#import "FBProcessInfo.h"
#import "FBProcessQuery.h"
#import "FBSimulator+Helpers.h"
#import "FBSimulatorConfiguration+CoreSimulator.h"
#import "FBSimulatorConfiguration.h"
#import "FBSimulatorControlConfiguration.h"
#import "FBSimulatorControlStaticConfiguration.h"
#import "FBSimulatorError.h"
#import "FBSimulatorEventRelay.h"
#import "FBSimulatorEventSink.h"
#import "FBSimulatorHistoryGenerator.h"
#import "FBSimulatorLaunchInfo.h"
#import "FBSimulatorLogs.h"
#import "FBSimulatorNotificationEventSink.h"
#import "FBSimulatorPool.h"
#import "FBTaskExecutor.h"

NSTimeInterval const FBSimulatorDefaultTimeout = 20;

@implementation FBSimulator

#pragma mark Lifecycle

+ (instancetype)fromSimDevice:(SimDevice *)device configuration:(FBSimulatorConfiguration *)configuration pool:(FBSimulatorPool *)pool query:(FBProcessQuery *)query
{
  return [[[FBSimulator alloc]
    initWithDevice:device
    configuration:configuration ?: [self inferSimulatorConfigurationFromDevice:device]
    pool:pool
    query:query]
    attachEventSinkComposition];
}

+ (FBSimulatorConfiguration *)inferSimulatorConfigurationFromDevice:(SimDevice *)device
{
  return [[FBSimulatorConfiguration.defaultConfiguration withDeviceType:device.deviceType] withRuntime:device.runtime];
}

- (instancetype)initWithDevice:(SimDevice *)device configuration:(FBSimulatorConfiguration *)configuration pool:(FBSimulatorPool *)pool query:(FBProcessQuery *)query
{
  self = [super init];
  if (!self) {
    return nil;
  }

  _device = device;
  _configuration = configuration;
  _pool = pool;
  _processQuery = query;

  return self;
}

- (instancetype)attachEventSinkComposition;
{
  FBSimulatorHistoryGenerator *historyGenerator = persistHistory
    ? [FBSimulatorHistoryGenerator generatorWithPersistantHistoryForSimulator:self]
    : [FBSimulatorHistoryGenerator generatorWithFreshHistoryForSimulator:self];
  FBSimulatorNotificationEventSink *notificationSink = [FBSimulatorNotificationEventSink withSimulator:self];
  FBCompositeSimulatorEventSink *compositeSink = [FBCompositeSimulatorEventSink withSinks:@[historyGenerator, notificationSink]];
  FBSimulatorEventRelay *relay = [[FBSimulatorEventRelay alloc] initWithSimDevice:self.device processQuery:self.processQuery sink:compositeSink];

  _historyGenerator = historyGenerator;
  _eventRelay = relay;

  return self;
}

#pragma mark Properties

- (NSString *)name
{
  return self.device.name;
}

- (NSString *)udid
{
  return self.device.UDID.UUIDString;
}

- (FBSimulatorState)state
{
  return (NSInteger) self.device.state;
}

- (NSString *)stateString
{
  return [FBSimulator stateStringFromSimulatorState:self.state];
}

- (FBSimulatorApplication *)simulatorApplication
{
  return self.pool.configuration.simulatorApplication;
}

- (NSString *)dataDirectory
{
  return self.device.dataPath;
}

- (BOOL)isAllocated
{
  if (!self.pool) {
    return NO;
  }
  return [self.pool.allocatedSimulators containsObject:self];
}

- (FBSimulatorLogs *)logs
{
  return [FBSimulatorLogs withSimulator:self];
}

- (FBSimulatorLaunchInfo *)launchInfo
{
  return self.eventRelay.launchInfo;
}

- (FBSimulatorHistory *)history
{
  return self.historyGenerator.history;
}

- (id<FBSimulatorEventSink>)eventSink
{
  return self.eventRelay;
}

#pragma mark NSObject

- (NSUInteger)hash
{
  return self.device.hash;
}

- (BOOL)isEqual:(FBSimulator *)simulator
{
  if (![simulator isKindOfClass:self.class]) {
    return NO;
  }
  return [self.device isEqual:simulator.device];
}

- (NSString *)description
{
  return [NSString stringWithFormat:
    @"Name %@ | UUID %@ | State %@ | %@",
    self.name,
    self.udid,
    self.device.stateString,
    self.launchInfo
  ];
}

@end
