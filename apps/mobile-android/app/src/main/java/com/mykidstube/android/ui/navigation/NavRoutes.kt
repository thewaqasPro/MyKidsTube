package com.mykidstube.android.ui.navigation

object NavRoutes {
    const val PAIRING = "pairing"
    const val HOME = "home"
    const val PLAYER = "player/{videoId}"
    const val SHORTS = "shorts/{videoId}"
    const val PARENT_DASHBOARD = "parent_dashboard"
    const val PARENT_SECURITY = "parent_security?force={force}"
    const val PARENT_MEDIA = "parent_media"
    const val PARENT_STORAGE = "parent_storage"
    const val PARENT_SERVER = "parent_server"
    const val PARENT_ANALYTICS = "parent_analytics"

    fun player(videoId: String): String = "player/$videoId"
    fun shorts(videoId: String): String = "shorts/$videoId"
    fun parentSecurity(forceChange: Boolean = false): String = "parent_security?force=$forceChange"
}
