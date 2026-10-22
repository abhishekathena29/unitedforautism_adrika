import 'package:flutter/material.dart';
import '../utils/utils.dart';
import '../widgets/icon_badge.dart';
import 'models.dart';

/// View-model types + mapping functions, ported from `src/lib/mappers.ts`
/// and the community-hook mapped shapes in `src/lib/community.ts`.

String formatRole(String role) {
  if (role.isEmpty) return '';
  return role[0].toUpperCase() + role.substring(1);
}

const _roles = [
  'parent',
  'educator',
  'advocate',
  'therapist',
  'caregiver',
  'admin'
];

String normalizeRole(String input) {
  final lower = input.trim().toLowerCase();
  if (_roles.contains(lower)) return lower;
  return 'parent';
}

class PostView {
  final String id;
  final String spaceId;
  final String space;
  final String author;
  final bool isAnonymous;
  final String role;
  final String time;
  final String title;
  final String body;
  final int likes;
  final int replies;
  final int repliesCount;
  final List<String> tags;
  final String initials;

  PostView({
    required this.id,
    required this.spaceId,
    required this.space,
    required this.author,
    required this.isAnonymous,
    required this.role,
    required this.time,
    required this.title,
    required this.body,
    required this.likes,
    required this.replies,
    required this.repliesCount,
    required this.tags,
    required this.initials,
  });
}

PostView mapPost(DbPost post, {String spaceName = ''}) {
  final profile = post.profile;
  final authorName =
      post.isAnonymous ? 'Anonymous' : (profile?.displayName ?? 'Member');
  return PostView(
    id: post.id,
    spaceId: post.spaceId,
    space: spaceName,
    author: authorName,
    isAnonymous: post.isAnonymous,
    role: profile?.role != null && profile!.role.isNotEmpty
        ? formatRole(profile.role)
        : '',
    time: timeAgo(post.createdAt),
    title: post.title,
    body: post.body,
    likes: post.likeCount,
    replies: post.replyCount,
    repliesCount: post.replyCount,
    tags: post.postTags,
    initials: post.isAnonymous
        ? ''
        : (profile?.initials ?? initialsFromName(authorName)),
  );
}

class SpaceView {
  final String id;
  final String slug;
  final String name;
  final String description;
  final String members;
  final int memberCount;
  final int posts;
  final int postCount;
  final IconData icon;
  final String iconName;

  SpaceView({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.members,
    required this.memberCount,
    required this.posts,
    required this.postCount,
    required this.icon,
    required this.iconName,
  });
}

SpaceView mapSpace(DbSpace space) {
  return SpaceView(
    id: space.id,
    slug: space.slug,
    name: space.name,
    description: space.description ?? '',
    members: '${space.memberCount}',
    memberCount: space.memberCount,
    posts: space.postCount,
    postCount: space.postCount,
    icon: getIcon(space.icon),
    iconName: space.icon,
  );
}

class EventView {
  final String id;
  final String type;
  final String title;
  final String date;
  final String? eventDate;
  final String? eventTime;
  final String location;
  final bool isVirtual;
  final int rsvps;
  final IconData icon;
  final String host;
  final String description;

  EventView({
    required this.id,
    required this.type,
    required this.title,
    required this.date,
    required this.eventDate,
    required this.eventTime,
    required this.location,
    required this.isVirtual,
    required this.rsvps,
    required this.icon,
    required this.host,
    required this.description,
  });
}

EventView mapEvent(DbEvent event) {
  return EventView(
    id: event.id,
    type: event.type,
    title: event.title,
    date: formatEventDate(event.eventDate, event.eventTime),
    eventDate: event.eventDate,
    eventTime: event.eventTime,
    location: event.location ?? (event.isVirtual ? 'Online' : ''),
    isVirtual: event.isVirtual,
    rsvps: event.rsvpCount,
    icon: getIcon(event.icon ?? 'Calendar'),
    host: event.hostName ?? 'Community',
    description: event.description ?? '',
  );
}

class TherapistView {
  final String id;
  final String name;
  final String specialty;
  final String experience;
  final String location;
  final num rating;
  final int reviews;
  final String initials;
  final String description;
  final bool isVerified;

  TherapistView({
    required this.id,
    required this.name,
    required this.specialty,
    required this.experience,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.initials,
    required this.description,
    required this.isVerified,
  });
}

TherapistView mapTherapist(DbTherapist t) {
  return TherapistView(
    id: t.id,
    name: t.name,
    specialty: t.specialization,
    experience:
        t.experienceYears != null ? '${t.experienceYears} years exp' : '',
    location: t.city ?? '',
    rating: t.rating,
    reviews: t.reviewCount,
    initials: t.initials ?? initialsFromName(t.name),
    description: t.bio ?? '',
    isVerified: t.isVerified,
  );
}

class MemberView {
  final String id;
  final String name;
  final String role;
  final String roleKey;
  final String location;
  final String initials;
  final String bio;
  final List<String> tags;
  final bool isVerified;

  MemberView({
    required this.id,
    required this.name,
    required this.role,
    required this.roleKey,
    required this.location,
    required this.initials,
    required this.bio,
    required this.tags,
    required this.isVerified,
  });
}

MemberView mapMember(DbProfile p) {
  return MemberView(
    id: p.id,
    name: p.displayName,
    role: formatRole(p.role),
    roleKey: p.role,
    location: p.city ?? '',
    initials: p.initials ?? initialsFromName(p.displayName),
    bio: p.bio ?? '',
    tags: p.tags,
    isVerified: p.isVerified,
  );
}

/// Community (user-generated) calm kit item — ported from `CommunityCalmKit`.
class CommunityCalmKit {
  final String id;
  final String name;
  final String why;
  final String when;
  final String icon;
  final List<String> tags;
  final String author;
  final int createdAt;

  CommunityCalmKit({
    required this.id,
    required this.name,
    required this.why,
    required this.when,
    required this.icon,
    required this.tags,
    required this.author,
    required this.createdAt,
  });
}

CommunityCalmKit mapKit(DbCalmKit k) {
  return CommunityCalmKit(
    id: k.id,
    name: k.name,
    why: k.why,
    when: k.whenToUse,
    icon: k.icon,
    tags: k.tags,
    author: k.authorDisplayName ?? 'Anonymous',
    createdAt: DateTime.parse(k.createdAt).millisecondsSinceEpoch,
  );
}

/// Community (user-generated) article — ported from `CommunityArticle`.
class CommunityArticle {
  final String id;
  final String title;
  final String category;
  final int readMin;
  final String icon;
  final String excerpt;
  final String? body;
  final String? mediumUrl;
  final String author;
  final int createdAt;
  final bool isEditorial;

  CommunityArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.readMin,
    required this.icon,
    required this.excerpt,
    required this.body,
    required this.mediumUrl,
    required this.author,
    required this.createdAt,
    required this.isEditorial,
  });
}

CommunityArticle mapArticle(DbArticle a) {
  return CommunityArticle(
    id: a.id,
    title: a.title,
    category: a.category,
    readMin: a.readMin,
    icon: a.icon,
    excerpt: a.excerpt,
    body: a.body,
    mediumUrl: a.mediumUrl,
    author: a.authorDisplayName ?? 'United Editorial',
    createdAt: DateTime.parse(a.createdAt).millisecondsSinceEpoch,
    isEditorial: a.isEditorial,
  );
}

/// Comment view — ported from `Comment` in `lib/community.ts`.
class CommentView {
  final String id;
  final String targetId;
  final String author;
  final String text;
  final int createdAt;

  CommentView({
    required this.id,
    required this.targetId,
    required this.author,
    required this.text,
    required this.createdAt,
  });
}

CommentView mapComment(DbComment c) {
  return CommentView(
    id: c.id,
    targetId: c.targetId,
    author: c.authorDisplayName,
    text: c.text,
    createdAt: DateTime.parse(c.createdAt).millisecondsSinceEpoch,
  );
}

/// Patch applied to a calm kit item — mirrors `CalmKitPatch`.
class CalmKitPatch {
  final String? name;
  final String? why;
  final String? when;
  final String? icon;
  final List<String>? tags;

  CalmKitPatch({this.name, this.why, this.when, this.icon, this.tags});

  Map<String, dynamic> toDbPatch() => {
        if (name != null) 'name': name,
        if (why != null) 'why': why,
        if (when != null) 'when_to_use': when,
        if (icon != null) 'icon': icon,
        if (tags != null) 'tags': tags,
      };
}
