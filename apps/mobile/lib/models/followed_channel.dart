/// Represents a YouTube channel followed by parents for automated catalog rotation
class FollowedChannel {
  final String channelId;
  final String title;
  final String handle;
  final String? logoUrl;
  final bool autoSync;
  final int lastSyncedAt;
  final int addedAt;

  const FollowedChannel({
    required this.channelId,
    required this.title,
    required this.handle,
    this.logoUrl,
    this.autoSync = true,
    this.lastSyncedAt = 0,
    this.addedAt = 0,
  });

  Map<String, dynamic> toMap() => {
    'channel_id': channelId,
    'title': title,
    'handle': handle,
    'logo_url': logoUrl ?? '',
    'auto_sync': autoSync ? 1 : 0,
    'last_synced_at': lastSyncedAt,
    'added_at': addedAt,
  };

  factory FollowedChannel.fromMap(Map<String, dynamic> map) => FollowedChannel(
    channelId: map['channel_id'] as String? ?? '',
    title: map['title'] as String? ?? '',
    handle: map['handle'] as String? ?? '',
    logoUrl: (map['logo_url'] as String?)?.isNotEmpty == true ? map['logo_url'] as String : null,
    autoSync: (map['auto_sync'] as int? ?? 1) == 1,
    lastSyncedAt: (map['last_synced_at'] as num?)?.toInt() ?? 0,
    addedAt: (map['added_at'] as num?)?.toInt() ?? 0,
  );

  FollowedChannel copyWith({
    String? channelId,
    String? title,
    String? handle,
    String? logoUrl,
    bool? autoSync,
    int? lastSyncedAt,
    int? addedAt,
  }) {
    return FollowedChannel(
      channelId: channelId ?? this.channelId,
      title: title ?? this.title,
      handle: handle ?? this.handle,
      logoUrl: logoUrl ?? this.logoUrl,
      autoSync: autoSync ?? this.autoSync,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}
