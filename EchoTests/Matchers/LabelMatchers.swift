//
// Created by Adam Price on 28/01/2017.
// Copyright (c) 2017 BBC. All rights reserved.
//

import Hamcrest

func containsLabels(_ labels: [String: String?]) -> Matcher<[String: String?]> {
    return Matcher("Contains labels") {
        (value) -> MatchResult in
        var missing: [String: String?] = [:]
        for (k, v) in labels {
            if let val = value[k], val != v {
                missing[k] = v
            } else if value[k] == nil {
                let empty: String? = nil
                missing[k] = empty
            }
        }

        if !missing.isEmpty { return .mismatch("\(missing) missing from labels")}
        return .match
    }
}
