/// Direct port of the `Db*` row types in `src/services/data.ts`.
library;

class DbSpace {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final String icon;
  final String? tone;
  final int memberCount;
  final int postCount;

  DbSpace({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.icon,
    required this.tone,
    required this.memberCount,
    required this.postCount,
  });

  factory DbSpace.fromJson(Map<String, dynamic> j) => DbSpace(
        id: j['id'] as String,
        slug: j['slug'] as String,
        name: j['name'] as String,
        description: j['description'] as String?,
        icon: j['icon'] as String,
        tone: j['tone'] as String?,
        memberCount: (j['member_count'] as num?)?.toInt() ?? 0,
        postCount: (j['post_count'] as num?)?.toInt() ?? 0,
      );

  DbSpace copyWith({int? memberCount, int? postCount}) => DbSpace(
        id: id,
        slug: slug,
        name: name,
        description: description,
        icon: icon,
        tone: tone,
        memberCount: memberCount ?? this.memberCount,
        postCount: postCount ?? this.postCount,
      );
}

class DbPostAuthor {
  final String displayName;
  final String? initials;
  final String role;

  DbPostAuthor(
      {required this.displayName, required this.initials, required this.role});

  factory DbPostAuthor.fromJson(Map<String, dynamic> j) => DbPostAuthor(
        displayName: j['display_name'] as String? ?? 'Member',
        initials: j['initials'] as String?,
        role: j['role'] as String? ?? '',
      );
}

class DbPost {
  final String id;
  final String spaceId;
  final String? authorId;
  final bool isAnonymous;
  final String title;
  final String body;
  final int likeCount;
  final int replyCount;
  final String createdAt;
  final List<String> postTags;
  final DbPostAuthor? profile;

  DbPost({
    required this.id,
    required this.spaceId,
    required this.authorId,
    required this.isAnonymous,
    required this.title,
    required this.body,
    required this.likeCount,
    required this.replyCount,
    required this.createdAt,
    required this.postTags,
    required this.profile,
  });

  factory DbPost.fromJson(Map<String, dynamic> j) => DbPost(
        id: j['id'] as String,
        spaceId: j['space_id'] as String,
        authorId: j['author_id'] as String?,
        isAnonymous: j['is_anonymous'] as bool? ?? false,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        likeCount: (j['like_count'] as num?)?.toInt() ?? 0,
        replyCount: (j['reply_count'] as num?)?.toInt() ?? 0,
        createdAt:
            j['created_at'] as String? ?? DateTime.now().toIso8601String(),
        postTags:
            ((j['tags'] as List?) ?? []).map((t) => t as String).toList(),
        profile: j['author_display_name'] != null
            ? DbPostAuthor.fromJson({
                'display_name': j['author_display_name'],
                'initials': j['author_initials'],
                'role': j['author_role'],
              })
            : null,
      );
}

class DbArticle {
  final String id;
  final String? legacyId;
  final String title;
  final String category;
  final int readMin;
  final String icon;
  final String excerpt;
  final String? body;
  final String? mediumUrl;
  final String? authorId;
  final String? authorDisplayName;
  final bool isEditorial;
  final int likeCount;
  final String createdAt;

  DbArticle({
    required this.id,
    required this.legacyId,
    required this.title,
    required this.category,
    required this.readMin,
    required this.icon,
    required this.excerpt,
    required this.body,
    required this.mediumUrl,
    required this.authorId,
    required this.authorDisplayName,
    required this.isEditorial,
    required this.likeCount,
    required this.createdAt,
  });

  factory DbArticle.fromJson(Map<String, dynamic> j) => DbArticle(
        id: j['id'] as String,
        legacyId: j['legacy_id'] as String?,
        title: j['title'] as String? ?? '',
        category: j['category'] as String? ?? '',
        readMin: (j['read_min'] as num?)?.toInt() ?? 0,
        icon: j['icon'] as String? ?? 'Sparkles',
        excerpt: j['excerpt'] as String? ?? '',
        body: j['body'] as String?,
        mediumUrl: j['medium_url'] as String?,
        authorId: j['author_id'] as String?,
        authorDisplayName: j['author_display_name'] as String?,
        isEditorial: j['is_editorial'] as bool? ?? false,
        likeCount: (j['like_count'] as num?)?.toInt() ?? 0,
        createdAt:
            j['created_at'] as String? ?? DateTime.now().toIso8601String(),
      );
}

class DbCalmKit {
  final String id;
  final String? legacyId;
  final String? ownerId;
  final String name;
  final String why;
  final String whenToUse;
  final String icon;
  final List<String> tags;
  final String? authorDisplayName;
  final bool isSeed;
  final bool isCommunityShared;
  final bool isDeleted;
  final int voteCount;
  final String createdAt;

  DbCalmKit({
    required this.id,
    required this.legacyId,
    required this.ownerId,
    required this.name,
    required this.why,
    required this.whenToUse,
    required this.icon,
    required this.tags,
    required this.authorDisplayName,
    required this.isSeed,
    required this.isCommunityShared,
    required this.isDeleted,
    required this.voteCount,
    required this.createdAt,
  });

  factory DbCalmKit.fromJson(Map<String, dynamic> j) => DbCalmKit(
        id: j['id'] as String,
        legacyId: j['legacy_id'] as String?,
        ownerId: j['owner_id'] as String?,
        name: j['name'] as String? ?? '',
        why: j['why'] as String? ?? '',
        whenToUse: j['when_to_use'] as String? ?? '',
        icon: j['icon'] as String? ?? 'Sparkles',
        tags: ((j['tags'] as List?) ?? []).map((t) => t as String).toList(),
        authorDisplayName: j['author_display_name'] as String?,
        isSeed: j['is_seed'] as bool? ?? false,
        isCommunityShared: j['is_community_shared'] as bool? ?? false,
        isDeleted: j['is_deleted'] as bool? ?? false,
        voteCount: (j['vote_count'] as num?)?.toInt() ?? 0,
        createdAt:
            j['created_at'] as String? ?? DateTime.now().toIso8601String(),
      );
}

class DbComment {
  final String id;
  final String targetType;
  final String targetId;
  final String? authorId;
  final String authorDisplayName;
  final String text;
  final String createdAt;

  DbComment({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.authorId,
    required this.authorDisplayName,
    required this.text,
    required this.createdAt,
  });

  factory DbComment.fromJson(Map<String, dynamic> j) => DbComment(
        id: j['id'] as String,
        targetType: j['target_type'] as String? ?? '',
        targetId: j['target_id'] as String? ?? '',
        authorId: j['author_id'] as String?,
        authorDisplayName: j['author_display_name'] as String? ?? 'Anonymous',
        text: j['text'] as String? ?? '',
        createdAt:
            j['created_at'] as String? ?? DateTime.now().toIso8601String(),
      );
}

class DbEvent {
  final String id;
  final String? legacyId;
  final String? hostId;
  final String? hostName;
  final String type;
  final String title;
  final String? description;
  final String? eventDate;
  final String? eventTime;
  final String? location;
  final bool isVirtual;
  final String? icon;
  final int rsvpCount;

  DbEvent({
    required this.id,
    required this.legacyId,
    required this.hostId,
    required this.hostName,
    required this.type,
    required this.title,
    required this.description,
    required this.eventDate,
    required this.eventTime,
    required this.location,
    required this.isVirtual,
    required this.icon,
    required this.rsvpCount,
  });

  factory DbEvent.fromJson(Map<String, dynamic> j) => DbEvent(
        id: j['id'] as String,
        legacyId: j['legacy_id'] as String?,
        hostId: j['host_id'] as String?,
        hostName: j['host_name'] as String?,
        type: j['type'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        eventDate: j['event_date'] as String?,
        eventTime: j['event_time'] as String?,
        location: j['location'] as String?,
        isVirtual: j['is_virtual'] as bool? ?? false,
        icon: j['icon'] as String?,
        rsvpCount: (j['rsvp_count'] as num?)?.toInt() ?? 0,
      );
}

class DbTherapist {
  final String id;
  final String? legacyId;
  final String name;
  final String? initials;
  final String specialization;
  final String? city;
  final int? experienceYears;
  final num rating;
  final int reviewCount;
  final String? bio;
  final String? phone;
  final String? email;
  final bool isVerified;

  DbTherapist({
    required this.id,
    required this.legacyId,
    required this.name,
    required this.initials,
    required this.specialization,
    required this.city,
    required this.experienceYears,
    required this.rating,
    required this.reviewCount,
    required this.bio,
    required this.phone,
    required this.email,
    required this.isVerified,
  });

  factory DbTherapist.fromJson(Map<String, dynamic> j) => DbTherapist(
        id: j['id'] as String,
        legacyId: j['legacy_id'] as String?,
        name: j['name'] as String? ?? '',
        initials: j['initials'] as String?,
        specialization: j['specialization'] as String? ?? '',
        city: j['city'] as String?,
        experienceYears: (j['experience_years'] as num?)?.toInt(),
        rating: (j['rating'] as num?) ?? 0,
        reviewCount: (j['review_count'] as num?)?.toInt() ?? 0,
        bio: j['bio'] as String?,
        phone: j['phone'] as String?,
        email: j['email'] as String?,
        isVerified: j['is_verified'] as bool? ?? false,
      );
}

class DbNotification {
  final String id;
  final String type;
  final String title;
  final String? body;
  final String? icon;
  final bool isRead;
  final String createdAt;

  DbNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.icon,
    required this.isRead,
    required this.createdAt,
  });

  factory DbNotification.fromJson(Map<String, dynamic> j) => DbNotification(
        id: j['id'] as String,
        type: j['type'] as String? ?? '',
        title: j['title'] as String? ?? '',
        body: j['body'] as String?,
        icon: j['icon'] as String?,
        isRead: j['is_read'] as bool? ?? false,
        createdAt:
            j['created_at'] as String? ?? DateTime.now().toIso8601String(),
      );

  DbNotification copyWith({bool? isRead}) => DbNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        icon: icon,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );
}

class DbProfile {
  final String id;
  final String displayName;
  final String? initials;
  final String role;
  final String? city;
  final String? bio;
  final String? avatarUrl;
  final bool isVerified;
  final List<String> tags;

  DbProfile({
    required this.id,
    required this.displayName,
    required this.initials,
    required this.role,
    required this.city,
    required this.bio,
    required this.avatarUrl,
    required this.isVerified,
    required this.tags,
  });

  factory DbProfile.fromJson(Map<String, dynamic> j) => DbProfile(
        id: j['id'] as String,
        displayName: j['display_name'] as String? ?? '',
        initials: j['initials'] as String?,
        role: j['role'] as String? ?? 'parent',
        city: j['city'] as String?,
        bio: j['bio'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        isVerified: j['is_verified'] as bool? ?? false,
        tags: ((j['tags'] as List?) ?? []).map((t) => t as String).toList(),
      );
}

/// Generic loosely-typed row for tables without a dedicated model
/// (emotional_prompts, emotional_shares, emotional_replies, daily_affirmations,
/// community_guidelines, privacy_settings, notification_settings, ...).
typedef DbRow = Map<String, dynamic>;

class SearchResults {
  final List<DbPost> posts;
  final List<DbProfile> members;
  final List<DbArticle> articles;
  final List<DbEvent> events;
  final List<DbSpace> spaces;

  SearchResults({
    required this.posts,
    required this.members,
    required this.articles,
    required this.events,
    required this.spaces,
  });

  static SearchResults empty() => SearchResults(
        posts: [],
        members: [],
        articles: [],
        events: [],
        spaces: [],
      );
}
