/**
* Copyright IBM Corporation 2017, 2018
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
**/

import Foundation

/// State
public enum State {

  /// The circuit is open i.e. broken
  case open

  /// The circuit is half-open i.e. experiencing errors
  case halfopen

  /// The circuit is closed i.e functioning normally
  case closed
}

extension Date {
  public static func currentTimeMillis() -> UInt64 {
    let timeInMillis = UInt64(NSDate().timeIntervalSince1970 * 1000.0)
    return timeInMillis
  }
}
