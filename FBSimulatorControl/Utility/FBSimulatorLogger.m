/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBSimulatorLogger.h"

@interface FBSimulatorLogger_NSLog : NSObject<FBSimulatorLogger>

@property (nonatomic, copy, readonly) NSString *prefix;

@end

@implementation FBSimulatorLogger_NSLog

- (instancetype)initWithPrefix:(NSString *)prefix
{
  self = [super init];
  if (!self) {
    return nil;
  }

  _prefix = prefix;

  return self;
}

- (void)log:(NSString *)format, ...
{
  va_list args;
  va_start(args, format);
  NSString *string = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);

  [self logString:string];
}

- (void)logString:(NSString *)string
{
  if (self.prefix) {
    NSLog(@"[%@] %@", self.prefix, string);
    return;
  }
  NSLog(@"%@", string);
}

- (id<FBSimulatorLogger>)info
{
  return [[FBSimulatorLogger_NSLog alloc] initWithPrefix:@"info"];
}

- (id<FBSimulatorLogger>)debug
{
  return [[FBSimulatorLogger_NSLog alloc] initWithPrefix:@"debug"];
}

- (id<FBSimulatorLogger>)error
{
  return [[FBSimulatorLogger_NSLog alloc] initWithPrefix:@"error"];
}

@end

@implementation FBSimulatorLogger

+ (id<FBSimulatorLogger>)toNSLog
{
  return [[FBSimulatorLogger_NSLog alloc] initWithPrefix:nil];
}

@end
