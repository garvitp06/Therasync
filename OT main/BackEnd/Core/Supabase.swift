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
    
    static let url = "https://swbsmgdheozfglbckmpk.supabase.co"
    static let key = "sb_publishable_U-h3qaFZXM268Hg1FFeEfQ_htFbWS7u"

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: SupabaseClientProvider.url)!,
            supabaseKey: SupabaseClientProvider.key
        )
    }
}
let supabase = SupabaseClientProvider.shared.client
let supabaseKey = SupabaseClientProvider.key
let supabaseURL = SupabaseClientProvider.url
