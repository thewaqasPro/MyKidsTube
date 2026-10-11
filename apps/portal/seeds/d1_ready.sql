PRAGMA foreign_keys = OFF;
DROP TABLE IF EXISTS families;
CREATE TABLE families (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        parent_pin TEXT DEFAULT '1234',
        created_at TEXT NOT NULL
    );
DROP TABLE IF EXISTS categories;
CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        icon TEXT DEFAULT 'category',
        display_order INTEGER DEFAULT 0
    );
DROP TABLE IF EXISTS child_profiles;
CREATE TABLE child_profiles (
        id TEXT PRIMARY KEY,
        family_id TEXT NOT NULL,
        name TEXT NOT NULL,
        avatar_icon TEXT DEFAULT 'bear',
        age_bracket TEXT DEFAULT 'all',
        created_at TEXT NOT NULL,
        FOREIGN KEY (family_id) REFERENCES families (id)
    );
DROP TABLE IF EXISTS videos;
CREATE TABLE videos (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        duration INTEGER DEFAULT 0,
        duration_formatted TEXT DEFAULT '00:00',
        category_id TEXT NOT NULL,
        source_url TEXT,
        video_file TEXT NOT NULL,
        thumbnail_file TEXT NOT NULL,
        file_size_bytes INTEGER DEFAULT 0,
        quality TEXT DEFAULT '720p',
        created_at TEXT NOT NULL, channel_name TEXT DEFAULT '', channel_icon TEXT DEFAULT '',
        FOREIGN KEY (category_id) REFERENCES categories (id)
    );
DROP TABLE IF EXISTS devices;
CREATE TABLE devices (
        id TEXT PRIMARY KEY,
        family_id TEXT,
        profile_id TEXT,
        device_name TEXT NOT NULL,
        pairing_code TEXT UNIQUE,
        status TEXT DEFAULT 'pending', -- 'pending', 'paired', 'revoked'
        auth_token TEXT,
        expires_at TEXT,
        used INTEGER DEFAULT 0,
        raw_token_pending TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (family_id) REFERENCES families (id),
        FOREIGN KEY (profile_id) REFERENCES child_profiles (id)
    );
DROP TABLE IF EXISTS profile_video_assignments;
CREATE TABLE profile_video_assignments (
        profile_id TEXT NOT NULL,
        video_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        created_at TEXT NOT NULL,
        PRIMARY KEY (profile_id, video_id),
        FOREIGN KEY (profile_id) REFERENCES child_profiles (id),
        FOREIGN KEY (video_id) REFERENCES videos (id)
    );
DROP TABLE IF EXISTS admin_settings;
CREATE TABLE admin_settings (
        key TEXT PRIMARY KEY,
        value TEXT
    );
INSERT INTO admin_settings (key, value) VALUES ('parent_pin', '1234');
DROP TABLE IF EXISTS watch_events;
CREATE TABLE watch_events (
        id TEXT PRIMARY KEY,
        video_id TEXT NOT NULL,
        device_id TEXT,
        seconds_watched INTEGER NOT NULL DEFAULT 0,
        event_at TEXT NOT NULL,
        FOREIGN KEY (video_id) REFERENCES videos (id)
    );
CREATE INDEX IF NOT EXISTS idx_watch_events_video_id ON watch_events (video_id);
DROP TABLE IF EXISTS parent_sessions;
CREATE TABLE parent_sessions (
        token_hash TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        expires_at TEXT NOT NULL
    );
CREATE INDEX IF NOT EXISTS idx_parent_sessions_expires_at ON parent_sessions (expires_at);
INSERT INTO "categories" VALUES('cartoons','Cartoons','tv',1);
INSERT INTO "categories" VALUES('learning','Learning & Fun','school',2);
INSERT INTO "categories" VALUES('music','Songs & Music','music_note',3);
INSERT INTO "categories" VALUES('bedtime','Bedtime Stories','bedtime',5);
INSERT INTO "categories" VALUES('shorts','⚡ Shorts & Reels','bolt',0);
INSERT INTO "categories" VALUES('nature','Animals & Nature','pets',4);
INSERT INTO "child_profiles" VALUES('kids_all','default_family','All Kids','stars','all','2026-10-05T17:15:28.452528');
INSERT INTO "child_profiles" VALUES('kids_toddler','default_family','Little Kids','teddy','toddler','2026-10-05T17:15:28.452528');
INSERT INTO "devices" (id, family_id, profile_id, device_name, pairing_code, status, auth_token, created_at) VALUES('06a96bfc-659',NULL,NULL,'Maya Tablet','SPE-446','pending',NULL,'2026-10-05T18:04:32.919224');
INSERT INTO "devices" (id, family_id, profile_id, device_name, pairing_code, status, auth_token, created_at) VALUES('3a59866b-d0b','default_family','kids_all','Kids Tablet','HEV-811','paired','tok_1e35ea5050444baf8bf63470ce55f5ab','2026-10-05T19:42:57.351666');
INSERT INTO "devices" (id, family_id, profile_id, device_name, pairing_code, status, auth_token, created_at) VALUES('949f611b-840','default_family','kids_all','Kids Tablet','JZC-640','paired','tok_bd677b0dc61e487a977a727efcf744a8','2026-10-05T23:40:53.005893');
INSERT INTO "devices" (id, family_id, profile_id, device_name, pairing_code, status, auth_token, created_at) VALUES('5818f75e-432','default_family','kids_all','Kids Tablet','FXS-429','paired','tok_846b5843ad0f44b4a3c7280075f3d885','2026-10-06T06:04:24.370819');
INSERT INTO "families" VALUES('default_family','My Family','1234','2026-10-05T17:15:28.452528');
INSERT INTO "profile_video_assignments" VALUES('kids_all','XqZsoesa55w','music','2026-10-06T05:32:42.334654');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','XqZsoesa55w','music','2026-10-06T05:32:42.334654');
INSERT INTO "profile_video_assignments" VALUES('kids_all','e_04ZrNroTo','music','2026-10-06T05:32:43.022158');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','e_04ZrNroTo','music','2026-10-06T05:32:43.022158');
INSERT INTO "profile_video_assignments" VALUES('kids_all','WRVsOCh907o','music','2026-10-06T05:32:43.143749');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','WRVsOCh907o','music','2026-10-06T05:32:43.143749');
INSERT INTO "profile_video_assignments" VALUES('kids_all','F4tHL8reNCs','music','2026-10-06T05:32:43.834769');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','F4tHL8reNCs','music','2026-10-06T05:32:43.834769');
INSERT INTO "profile_video_assignments" VALUES('kids_all','Mh4f9AYRCZY','cartoons','2026-10-06T05:32:44.430820');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','Mh4f9AYRCZY','cartoons','2026-10-06T05:32:44.430820');
INSERT INTO "profile_video_assignments" VALUES('kids_all','eBVqcTEC3zQ','music','2026-10-06T05:32:45.145235');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','eBVqcTEC3zQ','music','2026-10-06T05:32:45.145235');
INSERT INTO "profile_video_assignments" VALUES('kids_all','020g-0hhCAU','music','2026-10-06T05:32:45.280143');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','020g-0hhCAU','music','2026-10-06T05:32:45.280143');
INSERT INTO "profile_video_assignments" VALUES('kids_all','OzKY5YHnOTg','music','2026-10-06T05:32:45.416559');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','OzKY5YHnOTg','music','2026-10-06T05:32:45.416559');
INSERT INTO "profile_video_assignments" VALUES('kids_all','KLfXETqLCiM','music','2026-10-06T05:32:45.536760');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','KLfXETqLCiM','music','2026-10-06T05:32:45.536760');
INSERT INTO "profile_video_assignments" VALUES('kids_all','4tyT9B9joDk','music','2026-10-06T05:32:45.658777');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','4tyT9B9joDk','music','2026-10-06T05:32:45.658777');
INSERT INTO "profile_video_assignments" VALUES('kids_all','qXcMNBQnQMM','music','2026-10-06T05:32:45.805422');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','qXcMNBQnQMM','music','2026-10-06T05:32:45.805422');
INSERT INTO "profile_video_assignments" VALUES('kids_all','vWtLDytxr64','music','2026-10-06T05:32:45.931524');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','vWtLDytxr64','music','2026-10-06T05:32:45.931524');
INSERT INTO "profile_video_assignments" VALUES('kids_all','LrAtBtQnvCE','music','2026-10-06T05:32:46.078734');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','LrAtBtQnvCE','music','2026-10-06T05:32:46.078734');
INSERT INTO "profile_video_assignments" VALUES('kids_all','GHj-C7TfgkE','music','2026-10-06T05:32:46.197770');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','GHj-C7TfgkE','music','2026-10-06T05:32:46.197770');
INSERT INTO "profile_video_assignments" VALUES('kids_all','EAx6VZteAwQ','music','2026-10-06T05:32:46.319953');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','EAx6VZteAwQ','music','2026-10-06T05:32:46.319953');
INSERT INTO "profile_video_assignments" VALUES('kids_all','drnBMAEA3AM','music','2026-10-06T05:32:47.076694');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','drnBMAEA3AM','music','2026-10-06T05:32:47.076694');
INSERT INTO "profile_video_assignments" VALUES('kids_all','yCjJyiqpAuU','music','2026-10-06T05:32:47.196444');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','yCjJyiqpAuU','music','2026-10-06T05:32:47.196444');
INSERT INTO "profile_video_assignments" VALUES('kids_all','4yjpV33qHCo','music','2026-10-06T05:32:47.763784');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','4yjpV33qHCo','music','2026-10-06T05:32:47.763784');
INSERT INTO "profile_video_assignments" VALUES('kids_all','n2puCPKOGFI','music','2026-10-06T05:32:47.886611');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','n2puCPKOGFI','music','2026-10-06T05:32:47.886611');
INSERT INTO "profile_video_assignments" VALUES('kids_all','UZ4LF99rDM4','music','2026-10-06T05:32:48.023904');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','UZ4LF99rDM4','music','2026-10-06T05:32:48.023904');
INSERT INTO "profile_video_assignments" VALUES('kids_all','SNeI2PMcRdA','music','2026-10-06T05:32:48.144248');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','SNeI2PMcRdA','music','2026-10-06T05:32:48.144248');
INSERT INTO "profile_video_assignments" VALUES('kids_all','_UR-l3QI2nE','music','2026-10-06T05:32:48.282609');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','_UR-l3QI2nE','music','2026-10-06T05:32:48.282609');
INSERT INTO "profile_video_assignments" VALUES('kids_all','l4WNrvVjiTw','music','2026-10-06T05:32:48.420031');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','l4WNrvVjiTw','music','2026-10-06T05:32:48.420031');
INSERT INTO "profile_video_assignments" VALUES('kids_all','pWepfJ-8XU0','music','2026-10-06T05:32:48.554437');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','pWepfJ-8XU0','music','2026-10-06T05:32:48.554437');
INSERT INTO "profile_video_assignments" VALUES('kids_all','71hqRT9U0wg','music','2026-10-06T05:32:49.119459');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','71hqRT9U0wg','music','2026-10-06T05:32:49.119459');
INSERT INTO "profile_video_assignments" VALUES('kids_all','75p-N9YKqNo','music','2026-10-06T05:32:49.606120');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','75p-N9YKqNo','music','2026-10-06T05:32:49.606120');
INSERT INTO "profile_video_assignments" VALUES('kids_all','V-_O7nl0Ii0','nature','2026-10-06T05:32:49.916512');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','V-_O7nl0Ii0','nature','2026-10-06T05:32:49.916512');
INSERT INTO "profile_video_assignments" VALUES('kids_all','1GDFa-nEzlg','music','2026-10-06T05:32:50.036691');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','1GDFa-nEzlg','music','2026-10-06T05:32:50.036691');
INSERT INTO "profile_video_assignments" VALUES('kids_all','b0NHrFNZWh0','music','2026-10-06T05:32:50.631736');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','b0NHrFNZWh0','music','2026-10-06T05:32:50.631736');
INSERT INTO "profile_video_assignments" VALUES('kids_all','fN1Cyr0ZK9M','music','2026-10-06T05:32:50.782768');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','fN1Cyr0ZK9M','music','2026-10-06T05:32:50.782768');
INSERT INTO "profile_video_assignments" VALUES('kids_all','kffacxfA7G4','cartoons','2026-10-06T05:32:51.498439');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','kffacxfA7G4','cartoons','2026-10-06T05:32:51.498439');
INSERT INTO "profile_video_assignments" VALUES('kids_all','eNo3X23tFn0','music','2026-10-06T05:32:51.636304');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','eNo3X23tFn0','music','2026-10-06T05:32:51.636304');
INSERT INTO "profile_video_assignments" VALUES('kids_all','idzvY4nyK3k','music','2026-10-06T05:32:51.766296');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','idzvY4nyK3k','music','2026-10-06T05:32:51.766296');
INSERT INTO "profile_video_assignments" VALUES('kids_all','KPh2Efv66Aw','music','2026-10-06T05:32:51.890964');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','KPh2Efv66Aw','music','2026-10-06T05:32:51.890964');
INSERT INTO "profile_video_assignments" VALUES('kids_all','WjZ2f71dFck','music','2026-10-06T05:32:52.015477');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','WjZ2f71dFck','music','2026-10-06T05:32:52.015477');
INSERT INTO "profile_video_assignments" VALUES('kids_all','LuJe0ad1Ygk','music','2026-10-06T05:32:52.156211');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','LuJe0ad1Ygk','music','2026-10-06T05:32:52.156211');
INSERT INTO "profile_video_assignments" VALUES('kids_all','GzIObE7uR8Q','music','2026-10-06T05:32:52.283328');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','GzIObE7uR8Q','music','2026-10-06T05:32:52.283328');
INSERT INTO "profile_video_assignments" VALUES('kids_all','uBweptmCYZg','music','2026-10-06T05:32:52.432512');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','uBweptmCYZg','music','2026-10-06T05:32:52.432512');
INSERT INTO "profile_video_assignments" VALUES('kids_all','2QtoaV22rpY','music','2026-10-06T05:32:52.566042');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','2QtoaV22rpY','music','2026-10-06T05:32:52.566042');
INSERT INTO "profile_video_assignments" VALUES('kids_all','lboUGzSRxiE','music','2026-10-06T05:32:52.701759');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','lboUGzSRxiE','music','2026-10-06T05:32:52.701759');
INSERT INTO "profile_video_assignments" VALUES('kids_all','hhKuZCs3Hjc','music','2026-10-06T05:32:52.824093');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','hhKuZCs3Hjc','music','2026-10-06T05:32:52.824093');
INSERT INTO "profile_video_assignments" VALUES('kids_all','4ttUV4Z0htg','music','2026-10-06T05:32:52.966519');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','4ttUV4Z0htg','music','2026-10-06T05:32:52.966519');
INSERT INTO "profile_video_assignments" VALUES('kids_all','Pn05n-RZY9s','cartoons','2026-10-06T05:32:53.233582');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','Pn05n-RZY9s','cartoons','2026-10-06T05:32:53.233582');
INSERT INTO "profile_video_assignments" VALUES('kids_all','K00RMbl7Yv0','cartoons','2026-10-06T05:32:53.447868');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','K00RMbl7Yv0','cartoons','2026-10-06T05:32:53.447868');
INSERT INTO "profile_video_assignments" VALUES('kids_all','BXuzqxFJqnI','cartoons','2026-10-06T05:32:53.666615');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','BXuzqxFJqnI','cartoons','2026-10-06T05:32:53.666615');
INSERT INTO "profile_video_assignments" VALUES('kids_all','CoEK0Foav6s','music','2026-10-06T05:32:53.789549');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','CoEK0Foav6s','music','2026-10-06T05:32:53.789549');
INSERT INTO "profile_video_assignments" VALUES('kids_all','9KrVSzLqICc','music','2026-10-06T05:32:53.925282');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','9KrVSzLqICc','music','2026-10-06T05:32:53.925282');
INSERT INTO "profile_video_assignments" VALUES('kids_all','Ee1oyg3qE98','music','2026-10-06T05:32:54.063595');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','Ee1oyg3qE98','music','2026-10-06T05:32:54.063595');
INSERT INTO "profile_video_assignments" VALUES('kids_all','lUAAU0IsP14','learning','2026-10-06T05:32:54.728200');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','lUAAU0IsP14','learning','2026-10-06T05:32:54.728200');
INSERT INTO "profile_video_assignments" VALUES('kids_all','HqzcvBQEgv0','learning','2026-10-06T05:32:54.857751');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','HqzcvBQEgv0','learning','2026-10-06T05:32:54.857751');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_amTmnnqQf_E','shorts','2026-10-06T05:32:55.465932');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_amTmnnqQf_E','shorts','2026-10-06T05:32:55.465932');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_9qroevrAOdU','shorts','2026-10-06T05:32:56.081852');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_9qroevrAOdU','shorts','2026-10-06T05:32:56.081852');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_JRdwgkjuI5o','shorts','2026-10-06T05:32:56.230363');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_JRdwgkjuI5o','shorts','2026-10-06T05:32:56.230363');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_o04HM1InBIM','shorts','2026-10-06T05:32:56.363151');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_o04HM1InBIM','shorts','2026-10-06T05:32:56.363151');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_HEC-kqlDTQs','shorts','2026-10-06T05:32:57.081803');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_HEC-kqlDTQs','shorts','2026-10-06T05:32:57.081803');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_rh6p7lI93xs','shorts','2026-10-06T05:32:57.215943');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_rh6p7lI93xs','shorts','2026-10-06T05:32:57.215943');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_WN3CMp7tPcA','shorts','2026-10-06T05:33:00.014240');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_WN3CMp7tPcA','shorts','2026-10-06T05:33:00.014240');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_0MaL5XVmiwg','shorts','2026-10-06T05:33:00.135605');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_0MaL5XVmiwg','shorts','2026-10-06T05:33:00.135605');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_B0J4bDD_9oU','shorts','2026-10-06T05:33:00.266576');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_B0J4bDD_9oU','shorts','2026-10-06T05:33:00.266576');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_fkyP5MJm55Q','shorts','2026-10-06T05:33:00.392275');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_fkyP5MJm55Q','shorts','2026-10-06T05:33:00.392275');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_q2PglyGrHqc','shorts','2026-10-06T05:33:00.514013');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_q2PglyGrHqc','shorts','2026-10-06T05:33:00.514013');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_peV2o0i5FCQ','shorts','2026-10-06T05:33:00.654991');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_peV2o0i5FCQ','shorts','2026-10-06T05:33:00.654991');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_r2R0u4CBJkc','shorts','2026-10-06T05:33:01.393512');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_r2R0u4CBJkc','shorts','2026-10-06T05:33:01.393512');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_Oqz8Ry7omUU','shorts','2026-10-06T05:33:01.528252');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_Oqz8Ry7omUU','shorts','2026-10-06T05:33:01.528252');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_t4j8JWKGjVY','shorts','2026-10-06T05:33:01.664634');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_t4j8JWKGjVY','shorts','2026-10-06T05:33:01.664634');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_iWVKbdtjKkc','shorts','2026-10-06T05:33:01.801800');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_iWVKbdtjKkc','shorts','2026-10-06T05:33:01.801800');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_h5_6Z0GJTHs','shorts','2026-10-06T05:33:01.922566');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_h5_6Z0GJTHs','shorts','2026-10-06T05:33:01.922566');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_YCPQig_V6_c','shorts','2026-10-06T05:33:02.217861');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_YCPQig_V6_c','shorts','2026-10-06T05:33:02.217861');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_v_CF13kJy0c','shorts','2026-10-06T05:33:02.343700');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_v_CF13kJy0c','shorts','2026-10-06T05:33:02.343700');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_MtzKZklySBg','shorts','2026-10-06T05:33:02.612452');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_MtzKZklySBg','shorts','2026-10-06T05:33:02.612452');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_gJ_8xQ8a7ME','shorts','2026-10-06T05:33:02.749236');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_gJ_8xQ8a7ME','shorts','2026-10-06T05:33:02.749236');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_DspTKxy0Cf0','shorts','2026-10-06T05:33:02.871706');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_DspTKxy0Cf0','shorts','2026-10-06T05:33:02.871706');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_Lgs64Lkbe4g','shorts','2026-10-06T05:33:02.991270');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_Lgs64Lkbe4g','shorts','2026-10-06T05:33:02.991270');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_DM9atLFFV80','shorts','2026-10-06T05:33:03.634679');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_DM9atLFFV80','shorts','2026-10-06T05:33:03.634679');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_qoWerlyfa1c','shorts','2026-10-06T05:33:04.454331');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_qoWerlyfa1c','shorts','2026-10-06T05:33:04.454331');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_vv_bBp9MMyA','shorts','2026-10-06T05:33:04.910741');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_vv_bBp9MMyA','shorts','2026-10-06T05:33:04.910741');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_L5E6RPC6mv8','shorts','2026-10-06T05:33:05.660793');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_L5E6RPC6mv8','shorts','2026-10-06T05:33:05.660793');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_2uHhjNOUkgE','shorts','2026-10-06T05:33:06.254013');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_2uHhjNOUkgE','shorts','2026-10-06T05:33:06.254013');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_zkSpKp-wXpg','shorts','2026-10-06T05:33:06.381336');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_zkSpKp-wXpg','shorts','2026-10-06T05:33:06.381336');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_Q4BuU5prBdk','shorts','2026-10-06T05:33:06.996016');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_Q4BuU5prBdk','shorts','2026-10-06T05:33:06.996016');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_vPwNXGpKbf4','shorts','2026-10-06T05:33:07.480762');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_vPwNXGpKbf4','shorts','2026-10-06T05:33:07.480762');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_41Z4os5q12k','shorts','2026-10-06T05:33:07.629073');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_41Z4os5q12k','shorts','2026-10-06T05:33:07.629073');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_tK5cj7K7SjE','shorts','2026-10-06T05:33:08.096712');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_tK5cj7K7SjE','shorts','2026-10-06T05:33:08.096712');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_qCo3d20_4JE','shorts','2026-10-06T05:33:08.226600');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_qCo3d20_4JE','shorts','2026-10-06T05:33:08.226600');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_YWn-x0xQCMY','shorts','2026-10-06T05:33:08.608252');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_YWn-x0xQCMY','shorts','2026-10-06T05:33:08.608252');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_8GCKhe4LK24','shorts','2026-10-06T05:33:08.997567');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_8GCKhe4LK24','shorts','2026-10-06T05:33:08.997567');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_uO2x5Ea9ugE','shorts','2026-10-06T05:33:09.779219');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_uO2x5Ea9ugE','shorts','2026-10-06T05:33:09.779219');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_Lz--qo9Ejz0','shorts','2026-10-06T05:33:10.335683');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_Lz--qo9Ejz0','shorts','2026-10-06T05:33:10.335683');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_R5bah9kgxS4','shorts','2026-10-06T05:33:10.479597');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_R5bah9kgxS4','shorts','2026-10-06T05:33:10.479597');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_ks4M9nKYplk','shorts','2026-10-06T05:33:10.930077');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_ks4M9nKYplk','shorts','2026-10-06T05:33:10.930077');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_dPc635zjBZY','shorts','2026-10-06T05:33:11.331804');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_dPc635zjBZY','shorts','2026-10-06T05:33:11.331804');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_Svoic-emxkI','shorts','2026-10-06T05:33:11.468785');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_Svoic-emxkI','shorts','2026-10-06T05:33:11.468785');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_4tyT9B9joDk','shorts','2026-10-06T05:33:11.594457');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_4tyT9B9joDk','shorts','2026-10-06T05:33:11.594457');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_KLfXETqLCiM','shorts','2026-10-06T05:33:11.720454');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_KLfXETqLCiM','shorts','2026-10-06T05:33:11.720454');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_OzKY5YHnOTg','shorts','2026-10-06T05:33:11.843544');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_OzKY5YHnOTg','shorts','2026-10-06T05:33:11.843544');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_eBVqcTEC3zQ','shorts','2026-10-06T05:33:11.965721');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_eBVqcTEC3zQ','shorts','2026-10-06T05:33:11.965721');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_GHj-C7TfgkE','shorts','2026-10-06T05:33:12.086033');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_GHj-C7TfgkE','shorts','2026-10-06T05:33:12.086033');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_drnBMAEA3AM','shorts','2026-10-06T05:33:12.206833');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_drnBMAEA3AM','shorts','2026-10-06T05:33:12.206833');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_yCjJyiqpAuU','shorts','2026-10-06T05:33:12.324109');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_yCjJyiqpAuU','shorts','2026-10-06T05:33:12.324109');
INSERT INTO "profile_video_assignments" VALUES('kids_all','short_4yjpV33qHCo','shorts','2026-10-06T05:33:12.448064');
INSERT INTO "profile_video_assignments" VALUES('kids_toddler','short_4yjpV33qHCo','shorts','2026-10-06T05:33:12.448064');
INSERT INTO "videos" VALUES('XqZsoesa55w','Baby Shark - Pinkfong Kids’ Songs & Stories • Baby Shark Dance | Most Viewed Video | Animal Songs | PINKFONG Songs for Children',187,'03:07','music','https://www.youtube.com/watch?v=XqZsoesa55w','XqZsoesa55w.mp4','XqZsoesa55w.webp',45221633,'720p','2026-10-06T05:09:58.928819','Baby Shark - Pinkfong Kids’ Songs & Stories','https://yt3.googleusercontent.com/HmRKCZ8IQxKJd39MJEVi34_zBOaQMTZVrDTgXLJ-hmT1ue0nKOHqkZLhZaGwaqjKS85uNR7glQ=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('e_04ZrNroTo','Cocomelon - Nursery Rhymes • Wheels on the Bus',194,'03:14','music','https://www.youtube.com/watch?v=e_04ZrNroTo','e_04ZrNroTo.mp4','e_04ZrNroTo.webp',45221633,'720p','2026-10-06T05:09:59.768224','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('WRVsOCh907o','Cocomelon - Nursery Rhymes • Bath Song',201,'03:21','music','https://www.youtube.com/watch?v=WRVsOCh907o','WRVsOCh907o.mp4','WRVsOCh907o.webp',45221633,'720p','2026-10-06T05:09:59.950607','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('F4tHL8reNCs','LooLoo Kids - Nursery Rhymes and Children''s Songs • Johny Johny Yes Papa 👶 THE BEST Song for Children',208,'03:28','music','https://www.youtube.com/watch?v=F4tHL8reNCs','F4tHL8reNCs.mp4','F4tHL8reNCs.webp',45221633,'720p','2026-10-06T05:10:00.721676','LooLoo Kids - Nursery Rhymes and Children''s Songs','https://yt3.googleusercontent.com/XQ8Z5bwcV4dgjWEYFI1n1M9W2lgEP6RPh8LxqUq6ScFkXWXXwZIz0TTun_B05TTiTvReU5vy=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('Mh4f9AYRCZY','BBC News • Children interrupt interview',215,'03:35','cartoons','https://www.youtube.com/watch?v=Mh4f9AYRCZY','Mh4f9AYRCZY.mp4','Mh4f9AYRCZY.webp',45221633,'720p','2026-10-06T05:10:02.213279','BBC News','https://yt3.googleusercontent.com/v4JamQ9B-PUiJHjmZQs9UwTaoLQW8vijJMMpV5QvA2wHQ6iwWM8Q1s6O4jgTl0dtDigVWAi7SA=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('eBVqcTEC3zQ','Super Simple Songs - Kids Songs • One Little Finger featuring | Kids Song | Super Simple Songs',222,'03:42','music','https://www.youtube.com/watch?v=eBVqcTEC3zQ','eBVqcTEC3zQ.mp4','eBVqcTEC3zQ.webp',45221633,'720p','2026-10-06T05:10:03.337956','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('020g-0hhCAU','Cocomelon - Nursery Rhymes • Baby Shark',229,'03:49','music','https://www.youtube.com/watch?v=020g-0hhCAU','020g-0hhCAU.mp4','020g-0hhCAU.webp',45221633,'720p','2026-10-06T05:10:03.541912','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('OzKY5YHnOTg','Super Simple Songs - Kids Songs • Who Took The Cookie?',236,'03:56','music','https://www.youtube.com/watch?v=OzKY5YHnOTg','OzKY5YHnOTg.mp4','OzKY5YHnOTg.webp',45221633,'720p','2026-10-06T05:10:03.724585','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('KLfXETqLCiM','Cocomelon - Nursery Rhymes • The Muffin Man! Super Hero Rescue 🦸 | CoComelon Nursery Rhymes & Kids Songs',243,'04:03','music','https://www.youtube.com/watch?v=KLfXETqLCiM','KLfXETqLCiM.mp4','KLfXETqLCiM.webp',45221633,'720p','2026-10-06T05:10:03.925342','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('4tyT9B9joDk','Cocomelon - Nursery Rhymes • Let''s Count 5 Little Ducks! 🐤 | CoComelon Nursery Rhymes & Kids Songs',250,'04:10','music','https://www.youtube.com/watch?v=4tyT9B9joDk','4tyT9B9joDk.mp4','4tyT9B9joDk.webp',45221633,'720p','2026-10-06T05:10:04.147201','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('qXcMNBQnQMM','Cocomelon - Nursery Rhymes • CoComelon Songs For Kids + More Nursery Rhymes & Kids Songs - CoComelon',257,'04:17','music','https://www.youtube.com/watch?v=qXcMNBQnQMM','qXcMNBQnQMM.mp4','qXcMNBQnQMM.webp',45221633,'720p','2026-10-06T05:10:04.337750','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('vWtLDytxr64','Cocomelon - Nursery Rhymes • Sharing Snacks Song + MORE CoComelon Nursery Rhymes & Animal Songs',264,'04:24','music','https://www.youtube.com/watch?v=vWtLDytxr64','vWtLDytxr64.mp4','vWtLDytxr64.webp',45221633,'720p','2026-10-06T05:10:04.531228','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('LrAtBtQnvCE','Super Simple Songs - Kids Songs • Five Little Ducks + More',271,'04:31','music','https://www.youtube.com/watch?v=LrAtBtQnvCE','LrAtBtQnvCE.mp4','LrAtBtQnvCE.webp',45221633,'720p','2026-10-06T05:10:04.695651','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('GHj-C7TfgkE','Super Simple Songs - Kids Songs • I Love The Mountains | + More Kids Songs | Super Simple Songs',278,'04:38','music','https://www.youtube.com/watch?v=GHj-C7TfgkE','GHj-C7TfgkE.mp4','GHj-C7TfgkE.webp',45221633,'720p','2026-10-06T05:10:04.937825','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('EAx6VZteAwQ','Super Simple Songs - Kids Songs • Me! (featuring Noodle & Pals) | + More Kids Songs | Super Simple Songs',285,'04:45','music','https://www.youtube.com/watch?v=EAx6VZteAwQ','EAx6VZteAwQ.mp4','EAx6VZteAwQ.webp',45221633,'720p','2026-10-06T05:10:05.125937','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('drnBMAEA3AM','Rodgers & Hammerstein • "Do-Re-Mi" - THE SOUND OF MUSIC (1965)',292,'04:52','music','https://www.youtube.com/watch?v=drnBMAEA3AM','drnBMAEA3AM.mp4','drnBMAEA3AM.webp',45221633,'720p','2026-10-06T05:10:05.881875','Rodgers & Hammerstein','https://yt3.googleusercontent.com/-rVzcEwUtuy6pciDkIGbKHyrveRGzmUuEVg8LlmLW9-tj8r6N_92WinB7AJR8Wi2OcRfUG7RZA=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('yCjJyiqpAuU','Super Simple Songs - Kids Songs • Twinkle Twinkle Little Star',299,'04:59','music','https://www.youtube.com/watch?v=yCjJyiqpAuU','yCjJyiqpAuU.mp4','yCjJyiqpAuU.webp',45221633,'720p','2026-10-06T05:10:06.061410','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('4yjpV33qHCo','Finny The Shark • Baby Shark | & Family',306,'05:06','music','https://www.youtube.com/watch?v=4yjpV33qHCo','4yjpV33qHCo.mp4','4yjpV33qHCo.webp',45221633,'720p','2026-10-06T05:10:06.806606','Finny The Shark','https://yt3.googleusercontent.com/ytc=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('n2puCPKOGFI','Cocomelon - Nursery Rhymes • Wheels on the Bus 🚌 Back to School with JJ! | CoComelon Nursery Rhymes & Kids Songs',313,'05:13','music','https://www.youtube.com/watch?v=n2puCPKOGFI','n2puCPKOGFI.mp4','n2puCPKOGFI.webp',45221633,'720p','2026-10-06T05:10:07.040861','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('UZ4LF99rDM4','Cocomelon - Nursery Rhymes • Yes Yes Finger Family Playground Song | CoComelon Nursery Rhymes & Kids Songs',320,'05:20','music','https://www.youtube.com/watch?v=UZ4LF99rDM4','UZ4LF99rDM4.mp4','UZ4LF99rDM4.webp',45221633,'720p','2026-10-06T05:10:07.327634','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('SNeI2PMcRdA','Super Simple Songs - Kids Songs • Twinkle Twinkle Little Star | Bumble Nums Version | Super Simple Songs',327,'05:27','music','https://www.youtube.com/watch?v=SNeI2PMcRdA','SNeI2PMcRdA.mp4','SNeI2PMcRdA.webp',45221633,'720p','2026-10-06T05:10:07.679103','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('_UR-l3QI2nE','Cocomelon - Nursery Rhymes • ABC SONG | ABC Songs for Children - 13 Alphabet Songs & 26 Videos',184,'03:04','music','https://www.youtube.com/watch?v=_UR-l3QI2nE','_UR-l3QI2nE.mp4','_UR-l3QI2nE.webp',45221633,'720p','2026-10-06T05:10:07.881441','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('l4WNrvVjiTw','Super Simple Songs - Kids Songs • If You''re Happy | Kids Song | Super Simple Songs',191,'03:11','music','https://www.youtube.com/watch?v=l4WNrvVjiTw','l4WNrvVjiTw.mp4','l4WNrvVjiTw.webp',45221633,'720p','2026-10-06T05:10:08.286332','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('pWepfJ-8XU0','Super Simple Songs - Kids Songs • I Have A Pet | Animal Song | Super Simple Songs',198,'03:18','music','https://www.youtube.com/watch?v=pWepfJ-8XU0','pWepfJ-8XU0.mp4','pWepfJ-8XU0.webp',45221633,'720p','2026-10-06T05:10:08.474289','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('71hqRT9U0wg','Barefoot Books • If You''re Happy and You Know It! | Singalong',205,'03:25','music','https://www.youtube.com/watch?v=71hqRT9U0wg','71hqRT9U0wg.mp4','71hqRT9U0wg.webp',45221633,'720p','2026-10-06T05:10:09.245737','Barefoot Books','https://yt3.googleusercontent.com/ytc=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('75p-N9YKqNo','KidsTV123 • The ABC Song',212,'03:32','music','https://www.youtube.com/watch?v=75p-N9YKqNo','75p-N9YKqNo.mp4','75p-N9YKqNo.webp',45221633,'720p','2026-10-06T05:10:10.450716','KidsTV123','https://yt3.googleusercontent.com/TBHmiXQeLNp5e9XbnmRlFgDXjDq14VW1Lfo3RtFAmfVYnc-c_rh9r6ynd0oXT3TESYl9r1rQ3Q=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('V-_O7nl0Ii0','John Frye • Nice Ocean Waves',219,'03:39','nature','https://www.youtube.com/watch?v=V-_O7nl0Ii0','V-_O7nl0Ii0.mp4','V-_O7nl0Ii0.webp',45221633,'720p','2026-10-06T05:10:11.651189','John Frye','https://yt3.googleusercontent.com/ytc=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('1GDFa-nEzlg','Super Simple Songs - Kids Songs • This Is The Way We Get Dressed',226,'03:46','music','https://www.youtube.com/watch?v=1GDFa-nEzlg','1GDFa-nEzlg.mp4','1GDFa-nEzlg.webp',45221633,'720p','2026-10-06T05:10:13.808140','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('b0NHrFNZWh0','Little BoBo Nursery Rhymes - FlickBox Studios • Five Little Monkeys Jumping On The Bed | Children Nursery Rhyme | Flickbox Kids Songs',233,'03:53','music','https://www.youtube.com/watch?v=b0NHrFNZWh0','b0NHrFNZWh0.mp4','b0NHrFNZWh0.webp',45221633,'720p','2026-10-06T05:10:14.707670','Little BoBo Nursery Rhymes - FlickBox Studios','https://yt3.googleusercontent.com/ytc=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('fN1Cyr0ZK9M','Super Simple Songs - Kids Songs • Hello Hello! Can You Clap Your Hands? | Original Kids Song | Super Simple Songs',240,'04:00','music','https://www.youtube.com/watch?v=fN1Cyr0ZK9M','fN1Cyr0ZK9M.mp4','fN1Cyr0ZK9M.webp',45221633,'720p','2026-10-06T05:10:15.934256','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('kffacxfA7G4','JustinBieberVEVO • Justin Bieber - Baby ft. Ludacris',247,'04:07','cartoons','https://www.youtube.com/watch?v=kffacxfA7G4','kffacxfA7G4.mp4','kffacxfA7G4.webp',45221633,'720p','2026-10-06T05:10:16.905664','JustinBieberVEVO','https://yt3.googleusercontent.com/4Mz5el_eyeB5cBod2jHMV-CC3fYiuSmDuCT9A9tGyYh03KQyVdrP04KYYMttZItBCtn4kfef=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('eNo3X23tFn0','Cocomelon - Nursery Rhymes • Ten in the Bed Counting Song & Five Little Animals! | CoComelon Nursery Rhymes & Kids Songs',254,'04:14','music','https://www.youtube.com/watch?v=eNo3X23tFn0','eNo3X23tFn0.mp4','eNo3X23tFn0.webp',45221633,'720p','2026-10-06T05:30:19.571108','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('idzvY4nyK3k','Cocomelon - Nursery Rhymes • Halloween Dance Song | Spooky Mix For Kids | CoComelon Nursery Rhymes & Kids Songs',261,'04:21','music','https://www.youtube.com/watch?v=idzvY4nyK3k','idzvY4nyK3k.mp4','idzvY4nyK3k.webp',45221633,'720p','2026-10-06T05:30:19.775034','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('KPh2Efv66Aw','Cocomelon - Nursery Rhymes • Mary Had a Little Lamb | Adventure on the Farm | CoComelon Nursery Rhymes and Kids Songs',268,'04:28','music','https://www.youtube.com/watch?v=KPh2Efv66Aw','KPh2Efv66Aw.mp4','KPh2Efv66Aw.webp',45221633,'720p','2026-10-06T05:30:20.043012','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('WjZ2f71dFck','Cocomelon - Nursery Rhymes • Jump in the Puddles | Rainy Day with Toddlers | CoComelon Nursery Rhymes & Kids Songs',275,'04:35','music','https://www.youtube.com/watch?v=WjZ2f71dFck','WjZ2f71dFck.mp4','WjZ2f71dFck.webp',45221633,'720p','2026-10-06T05:30:20.321802','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('LuJe0ad1Ygk','Super Simple Songs - Kids Songs • When We Play Hockey 🏒 | Super Simple Songs & ‪ Hockey Song for Kids',282,'04:42','music','https://www.youtube.com/watch?v=LuJe0ad1Ygk','LuJe0ad1Ygk.mp4','LuJe0ad1Ygk.webp',45221633,'720p','2026-10-06T05:30:20.514523','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('GzIObE7uR8Q','Super Simple Songs - Kids Songs • Top 20 Anniversary Hit Songs 🎶 | "20 Years of Super Simple" now on Vinyl!',289,'04:49','music','https://www.youtube.com/watch?v=GzIObE7uR8Q','GzIObE7uR8Q.mp4','GzIObE7uR8Q.webp',45221633,'720p','2026-10-06T05:30:20.723859','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('uBweptmCYZg','Super Simple Songs - Kids Songs • Our Listening Ears 👂 | Animal Sounds & Guessing Game for Kids! | Super Simple Songs',296,'04:56','music','https://www.youtube.com/watch?v=uBweptmCYZg','uBweptmCYZg.mp4','uBweptmCYZg.webp',45221633,'720p','2026-10-06T05:30:20.964920','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('2QtoaV22rpY','Super Simple Songs - Kids Songs • Top 20 Circle Time Songs ⭕️ | Kids Classroom Favorites | Super Simple''s 20th Anniversary!',303,'05:03','music','https://www.youtube.com/watch?v=2QtoaV22rpY','2QtoaV22rpY.mp4','2QtoaV22rpY.webp',45221633,'720p','2026-10-06T05:30:21.292830','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('lboUGzSRxiE','Baby Shark - Pinkfong Kids’ Songs & Stories • Boo! Hoi’s Halloween Playground Compilation | Zombie Finger Family & More | Pinkfong Halloween',310,'05:10','music','https://www.youtube.com/watch?v=lboUGzSRxiE','lboUGzSRxiE.mp4','lboUGzSRxiE.webp',45221633,'720p','2026-10-06T05:30:21.568139','Baby Shark - Pinkfong Kids’ Songs & Stories','https://yt3.googleusercontent.com/HmRKCZ8IQxKJd39MJEVi34_zBOaQMTZVrDTgXLJ-hmT1ue0nKOHqkZLhZaGwaqjKS85uNR7glQ=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('hhKuZCs3Hjc','Baby Shark - Pinkfong Kids’ Songs & Stories • [🎃NEW] Where Is My Mama? | Kids'' Halloween Songs | Pinkfong Halloween 2026',317,'05:17','music','https://www.youtube.com/watch?v=hhKuZCs3Hjc','hhKuZCs3Hjc.mp4','hhKuZCs3Hjc.webp',45221633,'720p','2026-10-06T05:30:21.772578','Baby Shark - Pinkfong Kids’ Songs & Stories','https://yt3.googleusercontent.com/HmRKCZ8IQxKJd39MJEVi34_zBOaQMTZVrDTgXLJ-hmT1ue0nKOHqkZLhZaGwaqjKS85uNR7glQ=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('4ttUV4Z0htg','Baby Shark - Pinkfong Kids’ Songs & Stories • Monsters Everywhere! | 40 Mins of Scary Monster Songs | Pinkfong Halloween',324,'05:24','music','https://www.youtube.com/watch?v=4ttUV4Z0htg','4ttUV4Z0htg.mp4','4ttUV4Z0htg.webp',45221633,'720p','2026-10-06T05:30:22.036738','Baby Shark - Pinkfong Kids’ Songs & Stories','https://yt3.googleusercontent.com/HmRKCZ8IQxKJd39MJEVi34_zBOaQMTZVrDTgXLJ-hmT1ue0nKOHqkZLhZaGwaqjKS85uNR7glQ=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('Pn05n-RZY9s','Peppa Pig! • PJ Masks in Real Life: Fixing The Boo Boo with Catboy | Halloween PJ Masks',181,'03:01','cartoons','https://www.youtube.com/watch?v=Pn05n-RZY9s','Pn05n-RZY9s.mp4','Pn05n-RZY9s.webp',45221633,'720p','2026-10-06T05:30:22.484134','Peppa Pig!','');
INSERT INTO "videos" VALUES('K00RMbl7Yv0','Peppa Pig! • PJ Masks in Real Life 🍦 Ice Cream MIND CONTROL?! 🍦 Halloween PJ Masks 🎃',188,'03:08','cartoons','https://www.youtube.com/watch?v=K00RMbl7Yv0','K00RMbl7Yv0.mp4','K00RMbl7Yv0.webp',45221633,'720p','2026-10-06T05:30:23.076953','Peppa Pig!','');
INSERT INTO "videos" VALUES('BXuzqxFJqnI','Peppa Pig! • Romeo Controls Owlette in REAL LIFE!!!',195,'03:15','cartoons','https://www.youtube.com/watch?v=BXuzqxFJqnI','BXuzqxFJqnI.mp4','BXuzqxFJqnI.webp',45221633,'720p','2026-10-06T05:30:23.577804','Peppa Pig!','');
INSERT INTO "videos" VALUES('CoEK0Foav6s','LooLoo Kids - Nursery Rhymes and Children''s Songs • Johny Johny Yes Papa + Peek A Boo - Learn Colors with HALLOWEEN Lollipop - Kids Songs',202,'03:22','music','https://www.youtube.com/watch?v=CoEK0Foav6s','CoEK0Foav6s.mp4','CoEK0Foav6s.webp',45221633,'720p','2026-10-06T05:30:23.829563','LooLoo Kids - Nursery Rhymes and Children''s Songs','https://yt3.googleusercontent.com/XQ8Z5bwcV4dgjWEYFI1n1M9W2lgEP6RPh8LxqUq6ScFkXWXXwZIz0TTun_B05TTiTvReU5vy=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('9KrVSzLqICc','LooLoo Kids - Nursery Rhymes and Children''s Songs • A Ram Sam Sam + Johny Johny Yes Papa - Learn Colors + Baby Shark and SURPRISE EGGS - Kids Songs',209,'03:29','music','https://www.youtube.com/watch?v=9KrVSzLqICc','9KrVSzLqICc.mp4','9KrVSzLqICc.webp',45221633,'720p','2026-10-06T05:30:24.165171','LooLoo Kids - Nursery Rhymes and Children''s Songs','https://yt3.googleusercontent.com/XQ8Z5bwcV4dgjWEYFI1n1M9W2lgEP6RPh8LxqUq6ScFkXWXXwZIz0TTun_B05TTiTvReU5vy=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('Ee1oyg3qE98','LooLoo Kids - Nursery Rhymes and Children''s Songs • Wheels On The Bus (Safety Rules) + Johny Johny Yes Papa (Learn Colors with Balloons) - Kids Songs',216,'03:36','music','https://www.youtube.com/watch?v=Ee1oyg3qE98','Ee1oyg3qE98.mp4','Ee1oyg3qE98.webp',45221633,'720p','2026-10-06T05:30:24.451990','LooLoo Kids - Nursery Rhymes and Children''s Songs','https://yt3.googleusercontent.com/XQ8Z5bwcV4dgjWEYFI1n1M9W2lgEP6RPh8LxqUq6ScFkXWXXwZIz0TTun_B05TTiTvReU5vy=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('lUAAU0IsP14','Blippi - Educational Videos for Kids • Blippi & Meekah Silly Spooky Stories for the Halloween King! 👑🎃',223,'03:43','learning','https://www.youtube.com/watch?v=lUAAU0IsP14','lUAAU0IsP14.mp4','lUAAU0IsP14.webp',45221633,'720p','2026-10-06T05:30:25.313412','Blippi - Educational Videos for Kids','https://yt3.googleusercontent.com/5RLphM956w5pfV843mKs401NNeshKiq70_KBwHdLVAhdTl323Q_qc1fxZcvyilx7pL_Rij3V=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('HqzcvBQEgv0','Blippi - Educational Videos for Kids • Blippi Makes Halloween Treats & Monster Cupcakes! 🧁🎃',230,'03:50','learning','https://www.youtube.com/watch?v=HqzcvBQEgv0','HqzcvBQEgv0.mp4','HqzcvBQEgv0.webp',45221633,'720p','2026-10-06T05:30:25.516210','Blippi - Educational Videos for Kids','https://yt3.googleusercontent.com/5RLphM956w5pfV843mKs401NNeshKiq70_KBwHdLVAhdTl323Q_qc1fxZcvyilx7pL_Rij3V=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_amTmnnqQf_E','NuNu Tv Nursery Rhymes • One Two Three | Learn Number | With Slide',48,'00:48','shorts','https://www.youtube.com/shorts/amTmnnqQf_E','amTmnnqQf_E.mp4','amTmnnqQf_E.webp',45221633,'720p','2026-10-06T05:30:26.251423','NuNu Tv Nursery Rhymes','https://yt3.googleusercontent.com/iLzm9sY3MDgRN_cmVWRXixikHZu51a8BWsD1ri_tdNCiEGl9NynNc-PNb7qxuGazthxAYndfIA=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_9qroevrAOdU','KidZone Kingdom - Nursery Rhymes & Kids Songs • Baby Shark | Mommy Song',51,'00:51','shorts','https://www.youtube.com/shorts/9qroevrAOdU','9qroevrAOdU.mp4','9qroevrAOdU.webp',45221633,'720p','2026-10-06T05:30:26.917453','KidZone Kingdom - Nursery Rhymes & Kids Songs','https://yt3.googleusercontent.com/vH1lhGrdXlMIvCsi-T0Db_HiDu7Iexi22DXR2ylCcM9aGoBYQcCMlEP4ZHojXbikfelm93pqxg=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_JRdwgkjuI5o','NuNu Tv Nursery Rhymes • Baby & the Duck',54,'00:54','shorts','https://www.youtube.com/shorts/JRdwgkjuI5o','JRdwgkjuI5o.mp4','JRdwgkjuI5o.webp',45221633,'720p','2026-10-06T05:30:27.053457','NuNu Tv Nursery Rhymes','https://yt3.googleusercontent.com/iLzm9sY3MDgRN_cmVWRXixikHZu51a8BWsD1ri_tdNCiEGl9NynNc-PNb7qxuGazthxAYndfIA=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_o04HM1InBIM','Cocomelon - Nursery Rhymes • Learn Colors🔴🟠🟡🟢🔵🟣 with Balls! Uh oh! Catch that ball!',57,'00:57','shorts','https://www.youtube.com/shorts/o04HM1InBIM','o04HM1InBIM.mp4','o04HM1InBIM.webp',45221633,'720p','2026-10-06T05:30:27.189938','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_HEC-kqlDTQs','Dream Team’s World • Cocomelon Deluxe Interactive JJ',60,'00:60','shorts','https://www.youtube.com/shorts/HEC-kqlDTQs','HEC-kqlDTQs.mp4','HEC-kqlDTQs.webp',45221633,'720p','2026-10-06T05:30:27.787020','Dream Team’s World','https://yt3.googleusercontent.com/iWyV21W7bGjHUV0sJ9U7ZPej3EzI2yXpBGBwimYvzob12k7ZqGqvVK0hp2qRDcApl2-MpKe_T_M=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_rh6p7lI93xs','Super Simple Songs - Kids Songs • If You''re Happy And You Know It Spin Around',63,'00:63','shorts','https://www.youtube.com/shorts/rh6p7lI93xs','rh6p7lI93xs.mp4','rh6p7lI93xs.webp',45221633,'720p','2026-10-06T05:30:27.913535','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_WN3CMp7tPcA','Super Simple ABCs • ABC Quack! Quack along to the ABC song!',66,'00:66','shorts','https://www.youtube.com/shorts/WN3CMp7tPcA','WN3CMp7tPcA.mp4','WN3CMp7tPcA.webp',45221633,'720p','2026-10-06T05:30:28.680244','Super Simple ABCs','https://yt3.googleusercontent.com/ytc=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_0MaL5XVmiwg','Super Simple Songs - Kids Songs • There''s a Monster In My Tummy',69,'00:69','shorts','https://www.youtube.com/shorts/0MaL5XVmiwg','0MaL5XVmiwg.mp4','0MaL5XVmiwg.webp',45221633,'720p','2026-10-06T05:30:28.815438','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_B0J4bDD_9oU','Super Simple Songs - Kids Songs • One Potato Two Potato!',47,'00:47','shorts','https://www.youtube.com/shorts/B0J4bDD_9oU','B0J4bDD_9oU.mp4','B0J4bDD_9oU.webp',45221633,'720p','2026-10-06T05:30:28.972168','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_fkyP5MJm55Q','Baby Shark - Pinkfong Kids’ Songs & Stories • Wait until the end 🤣',50,'00:50','shorts','https://www.youtube.com/shorts/fkyP5MJm55Q','fkyP5MJm55Q.mp4','fkyP5MJm55Q.webp',45221633,'720p','2026-10-06T05:30:29.113196','Baby Shark - Pinkfong Kids’ Songs & Stories','https://yt3.googleusercontent.com/HmRKCZ8IQxKJd39MJEVi34_zBOaQMTZVrDTgXLJ-hmT1ue0nKOHqkZLhZaGwaqjKS85uNR7glQ=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_q2PglyGrHqc','Baby Shark - Pinkfong Kids’ Songs & Stories • Baby Shark doo doo doo',53,'00:53','shorts','https://www.youtube.com/shorts/q2PglyGrHqc','q2PglyGrHqc.mp4','q2PglyGrHqc.webp',45221633,'720p','2026-10-06T05:30:29.266857','Baby Shark - Pinkfong Kids’ Songs & Stories','https://yt3.googleusercontent.com/HmRKCZ8IQxKJd39MJEVi34_zBOaQMTZVrDTgXLJ-hmT1ue0nKOHqkZLhZaGwaqjKS85uNR7glQ=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_peV2o0i5FCQ','Baby Shark - Pinkfong Kids’ Songs & Stories • Bath Baby Shark with Me 🛁🦈💦',56,'00:56','shorts','https://www.youtube.com/shorts/peV2o0i5FCQ','peV2o0i5FCQ.mp4','peV2o0i5FCQ.webp',45221633,'720p','2026-10-06T05:30:29.424314','Baby Shark - Pinkfong Kids’ Songs & Stories','https://yt3.googleusercontent.com/HmRKCZ8IQxKJd39MJEVi34_zBOaQMTZVrDTgXLJ-hmT1ue0nKOHqkZLhZaGwaqjKS85uNR7glQ=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_r2R0u4CBJkc','ChuChu TV Nursery Rhymes & Kids Songs • Johny Johny Yes Papa with Daddy',59,'00:59','shorts','https://www.youtube.com/shorts/r2R0u4CBJkc','r2R0u4CBJkc.mp4','r2R0u4CBJkc.webp',45221633,'720p','2026-10-06T05:30:30.037989','ChuChu TV Nursery Rhymes & Kids Songs','https://yt3.googleusercontent.com/9HW0sh3SxpygY7QohdMTkUfNToJHJR1M_C1UYevboxlesumkq84nMLo1RT0JI0NYb7dqv2kHUMM=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_Oqz8Ry7omUU','ChuChu TV Nursery Rhymes & Kids Songs • Planets',62,'00:62','shorts','https://www.youtube.com/shorts/Oqz8Ry7omUU','Oqz8Ry7omUU.mp4','Oqz8Ry7omUU.webp',45221633,'720p','2026-10-06T05:30:30.183893','ChuChu TV Nursery Rhymes & Kids Songs','https://yt3.googleusercontent.com/9HW0sh3SxpygY7QohdMTkUfNToJHJR1M_C1UYevboxlesumkq84nMLo1RT0JI0NYb7dqv2kHUMM=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_t4j8JWKGjVY','ChuChu TV Nursery Rhymes & Kids Songs • Endangered Animals Part-1',65,'00:65','shorts','https://www.youtube.com/shorts/t4j8JWKGjVY','t4j8JWKGjVY.mp4','t4j8JWKGjVY.webp',45221633,'720p','2026-10-06T05:30:30.318865','ChuChu TV Nursery Rhymes & Kids Songs','https://yt3.googleusercontent.com/9HW0sh3SxpygY7QohdMTkUfNToJHJR1M_C1UYevboxlesumkq84nMLo1RT0JI0NYb7dqv2kHUMM=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_iWVKbdtjKkc','ChuChu TV Nursery Rhymes & Kids Songs • Kids Boo Boo Song',68,'00:68','shorts','https://www.youtube.com/shorts/iWVKbdtjKkc','iWVKbdtjKkc.mp4','iWVKbdtjKkc.webp',45221633,'720p','2026-10-06T05:30:30.454741','ChuChu TV Nursery Rhymes & Kids Songs','https://yt3.googleusercontent.com/9HW0sh3SxpygY7QohdMTkUfNToJHJR1M_C1UYevboxlesumkq84nMLo1RT0JI0NYb7dqv2kHUMM=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_h5_6Z0GJTHs','ChuChu TV Nursery Rhymes & Kids Songs • Baa Baa Black Sheep',46,'00:46','shorts','https://www.youtube.com/shorts/h5_6Z0GJTHs','h5_6Z0GJTHs.mp4','h5_6Z0GJTHs.webp',45221633,'720p','2026-10-06T05:30:30.588892','ChuChu TV Nursery Rhymes & Kids Songs','https://yt3.googleusercontent.com/9HW0sh3SxpygY7QohdMTkUfNToJHJR1M_C1UYevboxlesumkq84nMLo1RT0JI0NYb7dqv2kHUMM=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_YCPQig_V6_c','CoComelon Dance Party • Wheels on the Monkey Bus! What a WILD ride! | CoComelon Nursery Rhymes & Kids Songs | Dance Party',49,'00:49','shorts','https://www.youtube.com/shorts/YCPQig_V6_c','YCPQig_V6_c.mp4','YCPQig_V6_c.webp',45221633,'720p','2026-10-06T05:30:30.898941','CoComelon Dance Party','');
INSERT INTO "videos" VALUES('short_v_CF13kJy0c','Cocomelon - Nursery Rhymes • CoComelon Intro!',52,'00:52','shorts','https://www.youtube.com/shorts/v_CF13kJy0c','v_CF13kJy0c.mp4','v_CF13kJy0c.webp',45221633,'720p','2026-10-06T05:30:31.027943','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_MtzKZklySBg','CoComelon Dance Party • Dance Along with JJ! Head, Shoulders, Knees and ...',55,'00:55','shorts','https://www.youtube.com/shorts/MtzKZklySBg','MtzKZklySBg.mp4','MtzKZklySBg.webp',45221633,'720p','2026-10-06T05:30:31.552604','CoComelon Dance Party','');
INSERT INTO "videos" VALUES('short_gJ_8xQ8a7ME','Cocomelon - Nursery Rhymes • Let''s Stack Healthy Fruit with JJ! 🍎🍉🍊🍍🍌',58,'00:58','shorts','https://www.youtube.com/shorts/gJ_8xQ8a7ME','gJ_8xQ8a7ME.mp4','gJ_8xQ8a7ME.webp',45221633,'720p','2026-10-06T05:30:31.849938','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_DspTKxy0Cf0','Super Simple Songs - Kids Songs • BINGO!',61,'00:61','shorts','https://www.youtube.com/shorts/DspTKxy0Cf0','DspTKxy0Cf0.mp4','DspTKxy0Cf0.webp',45221633,'720p','2026-10-06T05:30:32.054234','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_Lgs64Lkbe4g','Super Simple ABCs • Sing with Strawberry! 🍓',64,'00:64','shorts','https://www.youtube.com/shorts/Lgs64Lkbe4g','Lgs64Lkbe4g.mp4','Lgs64Lkbe4g.webp',45221633,'720p','2026-10-06T05:30:32.289463','Super Simple ABCs','https://yt3.googleusercontent.com/ytc=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_DM9atLFFV80','Pinkfong, Bebê Tubarão! Canções para Crianças • Pinkfong Bruxo Roxo',67,'00:67','shorts','https://www.youtube.com/shorts/DM9atLFFV80','DM9atLFFV80.mp4','DM9atLFFV80.webp',45221633,'720p','2026-10-06T05:30:33.160762','Pinkfong, Bebê Tubarão! Canções para Crianças','https://yt3.googleusercontent.com/MOthn2iTszZhkHWNLKncIo2TMz9dFxkF4CZUrAjA247wESc2QCl1DFAkhdk982OYxE76z8pS6g=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_qoWerlyfa1c','Hogi! Pinkfong - Learn & Play • Pinkfong''s Mealtime Moments (ALL) 😋 🍡 🥟 🍕 🍭',45,'00:45','shorts','https://www.youtube.com/shorts/qoWerlyfa1c','qoWerlyfa1c.mp4','qoWerlyfa1c.webp',45221633,'720p','2026-10-06T05:30:34.151726','Hogi! Pinkfong - Learn & Play','https://yt3.googleusercontent.com/2aD5FXlSmW-HXEUedTaebp-fCz-00CoO2ZAW91QDzIVcx1koKvkuGQud5ANMRof5tebM5cJ68j8=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_vv_bBp9MMyA','BabyBus - Cartoon TV #Shorts • Kiki Doesn''t Want to Get a Shot 2 | BabyBus | Kids Cartoon | Funny Cartoon',48,'00:48','shorts','https://www.youtube.com/shorts/vv_bBp9MMyA','vv_bBp9MMyA.mp4','vv_bBp9MMyA.webp',45221633,'720p','2026-10-06T05:30:34.880486','BabyBus - Cartoon TV #Shorts','https://yt3.googleusercontent.com/_20lOkAaZSYpShanDe4jFOOpI7LeIanEUyl0f042ERBs8VcJ7JT4D65elo5gCuZtYE6ByKmbCg=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_L5E6RPC6mv8','베이비버스 -인기 동요・동화 • 아가 도독 잡아라!',51,'00:51','shorts','https://www.youtube.com/shorts/L5E6RPC6mv8','L5E6RPC6mv8.mp4','L5E6RPC6mv8.webp',45221633,'720p','2026-10-06T05:30:35.628552','베이비버스 -인기 동요・동화','https://yt3.googleusercontent.com/ytc=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_2uHhjNOUkgE','BabyBus - Preschool Songs & Learning Cartoons • Baby was Taken by A Monster',54,'00:54','shorts','https://www.youtube.com/shorts/2uHhjNOUkgE','2uHhjNOUkgE.mp4','2uHhjNOUkgE.webp',45221633,'720p','2026-10-06T05:30:36.314620','BabyBus - Preschool Songs & Learning Cartoons','https://yt3.googleusercontent.com/h8scB8Et9ooSoeRG3goQ3spO1Hh2P8c_aJgH5MtbQ-KdrAXhrLv_RrhoiigOuuzaAMwDAQvfJw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_zkSpKp-wXpg','NuNu Tv Nursery Rhymes • Baa Baa Blue Sheep | & Kids Songs',57,'00:57','shorts','https://www.youtube.com/shorts/zkSpKp-wXpg','zkSpKp-wXpg.mp4','zkSpKp-wXpg.webp',45221633,'720p','2026-10-06T05:30:36.467968','NuNu Tv Nursery Rhymes','https://yt3.googleusercontent.com/iLzm9sY3MDgRN_cmVWRXixikHZu51a8BWsD1ri_tdNCiEGl9NynNc-PNb7qxuGazthxAYndfIA=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_Q4BuU5prBdk','Jugnu Kids - Nursery Rhymes and Best Baby Songs • Pop The Bubbles | wheels on the bus | Play Outside Bubbles Song',60,'00:60','shorts','https://www.youtube.com/shorts/Q4BuU5prBdk','Q4BuU5prBdk.mp4','Q4BuU5prBdk.webp',45221633,'720p','2026-10-06T05:30:37.174581','Jugnu Kids - Nursery Rhymes and Best Baby Songs','https://yt3.googleusercontent.com/ytc=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_vPwNXGpKbf4','Billion Surprise Toys • Wheels on the Bus with Baby Zay!',63,'00:63','shorts','https://www.youtube.com/shorts/vPwNXGpKbf4','vPwNXGpKbf4.mp4','vPwNXGpKbf4.webp',45221633,'720p','2026-10-06T05:30:37.667782','Billion Surprise Toys','https://yt3.googleusercontent.com/SGGVU_o46QpD7DG_eL_N-G_rA-KZNUHC1BYqLvZQs2HCYWfr4aBnEU5alxp6FdDCLqgAA9L3JEc=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_41Z4os5q12k','NuNu Tv Nursery Rhymes • Babies On The Bus Goes Wah Wah Wah',66,'00:66','shorts','https://www.youtube.com/shorts/41Z4os5q12k','41Z4os5q12k.mp4','41Z4os5q12k.webp',45221633,'720p','2026-10-06T05:30:37.814878','NuNu Tv Nursery Rhymes','https://yt3.googleusercontent.com/iLzm9sY3MDgRN_cmVWRXixikHZu51a8BWsD1ri_tdNCiEGl9NynNc-PNb7qxuGazthxAYndfIA=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_tK5cj7K7SjE','★ Kids Roma Show • Diana & Roma Learn English in Pop It School! 🏫🔤',69,'00:69','shorts','https://www.youtube.com/shorts/tK5cj7K7SjE','tK5cj7K7SjE.mp4','tK5cj7K7SjE.webp',45221633,'720p','2026-10-06T05:30:38.200220','★ Kids Roma Show','https://yt3.googleusercontent.com/ytc=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_qCo3d20_4JE','★ Kids Roma Show • Diana and Roma''s Cookie Baking Adventure 🍪🍪',47,'00:47','shorts','https://www.youtube.com/shorts/qCo3d20_4JE','qCo3d20_4JE.mp4','qCo3d20_4JE.webp',45221633,'720p','2026-10-06T05:30:38.336802','★ Kids Roma Show','https://yt3.googleusercontent.com/ytc=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_YWn-x0xQCMY','Lucky Hop • Diana and Roma & Vlad and Niki Transformation Coffin Dance Tiles Hop',50,'00:50','shorts','https://www.youtube.com/shorts/YWn-x0xQCMY','YWn-x0xQCMY.mp4','YWn-x0xQCMY.webp',45221633,'720p','2026-10-06T05:30:38.754848','Lucky Hop','https://yt3.googleusercontent.com/VosLviAp2pq9I_1oitfX-7TSvOgPddoAxfF2Dh5y1xUkpjGSEifctdp0s1TCrYJEGCwAGwlqYQ=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_8GCKhe4LK24','Artie''s Simple Songs For Kids • Super Simple Songs For Kids',53,'00:53','shorts','https://www.youtube.com/shorts/8GCKhe4LK24','8GCKhe4LK24.mp4','8GCKhe4LK24.webp',45221633,'720p','2026-10-06T05:30:39.121831','Artie''s Simple Songs For Kids','https://yt3.googleusercontent.com/zwI4IjcCns3MUg5wh91R2OdDOAgeoe7tz_GqpKAsAB8BTlnbZiuesJKH9ToKOUlVeCGbmIaDvA=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_uO2x5Ea9ugE','SH kids • Raise Your Hands Song',56,'00:56','shorts','https://www.youtube.com/shorts/uO2x5Ea9ugE','uO2x5Ea9ugE.mp4','uO2x5Ea9ugE.webp',45221633,'720p','2026-10-06T05:30:39.816537','SH kids','https://yt3.googleusercontent.com/XbAFCmsbpq3gv8WM7EPuZxuJwQOu21W7cKJ3d6tiP2R5D8sARr4RGBMpRvhQgATITBoA7WGTiAI=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_Lz--qo9Ejz0','Herlyne Ven 🇨🇦 • Cute & Fun Cocomelon Microphone ABC Song',59,'00:59','shorts','https://www.youtube.com/shorts/Lz--qo9Ejz0','Lz--qo9Ejz0.mp4','Lz--qo9Ejz0.webp',45221633,'720p','2026-10-06T05:30:40.345164','Herlyne Ven 🇨🇦','https://yt3.googleusercontent.com/V-zoJl1Chjk4xuhcghBDkC82cV6K1TsoTIDCjnvtvwel-oucBKvj3mmAwKrMGumCnhTd8ppacQ=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_R5bah9kgxS4','Herlyne Ven 🇨🇦 • Cocomelon Jj First Learning Phone 458',62,'00:62','shorts','https://www.youtube.com/shorts/R5bah9kgxS4','R5bah9kgxS4.mp4','R5bah9kgxS4.webp',45221633,'720p','2026-10-06T05:30:40.537435','Herlyne Ven 🇨🇦','https://yt3.googleusercontent.com/V-zoJl1Chjk4xuhcghBDkC82cV6K1TsoTIDCjnvtvwel-oucBKvj3mmAwKrMGumCnhTd8ppacQ=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_ks4M9nKYplk','Famfam Kids • ❤️ ABC Song Shorts 💚❤️ OPQRSTUVWXYZ | Super Simple Songs',65,'00:65','shorts','https://www.youtube.com/shorts/ks4M9nKYplk','ks4M9nKYplk.mp4','ks4M9nKYplk.webp',45221633,'720p','2026-10-06T05:30:40.978980','Famfam Kids','https://yt3.googleusercontent.com/1ZSmmib4x8SSKMUQDAfdCaFBIvPYQaNbz5Va2-Hx_83jiaAZhbW7PRyFbpVQy2LLr_JBoME5dA=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_dPc635zjBZY','Miniature Cakes DA • Pinkfong & Baby Shark with Satisfying Unboxing and Review ASMR Video',68,'00:68','shorts','https://www.youtube.com/shorts/dPc635zjBZY','dPc635zjBZY.mp4','dPc635zjBZY.webp',45221633,'720p','2026-10-06T05:30:41.477774','Miniature Cakes DA','https://yt3.googleusercontent.com/rVZyFHEpn20CSTHAhXVDNnj5B4_cDp6HKlhZN3kS16JBZQyOpymBt_kB0ulOFfdbcyvRfA14zA=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_Svoic-emxkI','Herlyne Ven 🇨🇦 • Perfect Fun CoComelon Pop & Play Pals',46,'00:46','shorts','https://www.youtube.com/shorts/Svoic-emxkI','Svoic-emxkI.mp4','Svoic-emxkI.webp',45221633,'720p','2026-10-06T05:30:41.617142','Herlyne Ven 🇨🇦','https://yt3.googleusercontent.com/V-zoJl1Chjk4xuhcghBDkC82cV6K1TsoTIDCjnvtvwel-oucBKvj3mmAwKrMGumCnhTd8ppacQ=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_4tyT9B9joDk','Cocomelon - Nursery Rhymes • Let''s Count 5 Little Ducks! 🐤 | CoComelon Nursery Rhymes & Kids Songs',49,'00:49','shorts','https://www.youtube.com/shorts/4tyT9B9joDk','4tyT9B9joDk.mp4','4tyT9B9joDk.webp',45221633,'720p','2026-10-06T05:30:41.749620','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_KLfXETqLCiM','Cocomelon - Nursery Rhymes • The Muffin Man! Super Hero Rescue 🦸 | CoComelon Nursery Rhymes & Kids Songs',52,'00:52','shorts','https://www.youtube.com/shorts/KLfXETqLCiM','KLfXETqLCiM.mp4','KLfXETqLCiM.webp',45221633,'720p','2026-10-06T05:30:41.877129','Cocomelon - Nursery Rhymes','https://yt3.googleusercontent.com/yiljI_XQcX8X0p_E2S0APGrUs7tHBMukf5_3dhVzhbH-z5uhzpt88tUopQa7ngVwO1nGAAnr6A=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_OzKY5YHnOTg','Super Simple Songs - Kids Songs • Who Took The Cookie?',55,'00:55','shorts','https://www.youtube.com/shorts/OzKY5YHnOTg','OzKY5YHnOTg.mp4','OzKY5YHnOTg.webp',45221633,'720p','2026-10-06T05:30:42.237180','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_eBVqcTEC3zQ','Super Simple Songs - Kids Songs • One Little Finger featuring | Kids Song | Super Simple Songs',58,'00:58','shorts','https://www.youtube.com/shorts/eBVqcTEC3zQ','eBVqcTEC3zQ.mp4','eBVqcTEC3zQ.webp',45221633,'720p','2026-10-06T05:30:42.378022','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_GHj-C7TfgkE','Super Simple Songs - Kids Songs • I Love The Mountains | + More Kids Songs | Super Simple Songs',61,'00:61','shorts','https://www.youtube.com/shorts/GHj-C7TfgkE','GHj-C7TfgkE.mp4','GHj-C7TfgkE.webp',45221633,'720p','2026-10-06T05:30:42.506760','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_drnBMAEA3AM','Rodgers & Hammerstein • "Do-Re-Mi" - THE SOUND OF MUSIC (1965)',64,'00:64','shorts','https://www.youtube.com/shorts/drnBMAEA3AM','drnBMAEA3AM.mp4','drnBMAEA3AM.webp',45221633,'720p','2026-10-06T05:30:42.635130','Rodgers & Hammerstein','https://yt3.googleusercontent.com/-rVzcEwUtuy6pciDkIGbKHyrveRGzmUuEVg8LlmLW9-tj8r6N_92WinB7AJR8Wi2OcRfUG7RZA=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_yCjJyiqpAuU','Super Simple Songs - Kids Songs • Twinkle Twinkle Little Star',67,'00:67','shorts','https://www.youtube.com/shorts/yCjJyiqpAuU','yCjJyiqpAuU.mp4','yCjJyiqpAuU.webp',45221633,'720p','2026-10-06T05:30:42.757081','Super Simple Songs - Kids Songs','https://yt3.googleusercontent.com/x7yHOvSWKX_olv_pgx1Ou4SsHI_eOg27sXy9jbNO15rHMG3y425LnmFIyoxDyvLA8Qi3k_0rWw=s900-c-k-c0x00ffffff-no-rj=s176-c-k-c0x00ffffff-no-rj');
INSERT INTO "videos" VALUES('short_4yjpV33qHCo','Finny The Shark • Baby Shark | & Family',45,'00:45','shorts','https://www.youtube.com/shorts/4yjpV33qHCo','4yjpV33qHCo.mp4','4yjpV33qHCo.webp',45221633,'720p','2026-10-06T05:30:42.890026','Finny The Shark','https://yt3.googleusercontent.com/ytc=s176-c-k-c0x00ffffff-no-rj');
PRAGMA foreign_keys = ON;
