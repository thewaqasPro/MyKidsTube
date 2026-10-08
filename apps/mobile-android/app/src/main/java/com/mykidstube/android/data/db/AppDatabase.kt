package com.mykidstube.android.data.db

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [
        VideoEntity::class,
        CategoryEntity::class,
        ChildProfileEntity::class,
        WatchEventEntity::class,
        FavoriteEntity::class,
        SettingEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {
    abstract fun videoDao(): VideoDao
    abstract fun categoryDao(): CategoryDao
    abstract fun childProfileDao(): ChildProfileDao
    abstract fun watchEventDao(): WatchEventDao
    abstract fun favoriteDao(): FavoriteDao
    abstract fun settingDao(): SettingDao
}
