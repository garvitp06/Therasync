//
//  Supabase.swift
//  OT main
//
//  Created by user@54 on 14/01/26.
//

import Foundation
import Supabase

final class SupabaseClientProvider {

    static let shared = SupabaseClientProvider()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://swbsmgdheozfglbckmpk.supabase.co")!,
            supabaseKey: "sb_publishable_U-h3qaFZXM268Hg1FFeEfQ_htFbWS7u"
        )
    }
}
let supabase = SupabaseClientProvider.shared.client
