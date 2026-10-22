import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Direct port of `src/services/data.ts`. All functions are free functions
/// operating on the shared Firestore instance, matching the original module.
FirebaseFirestore get _db => FirebaseFirestore.instance;

/// Merges a document's id into its data, matching the shape Postgrest rows
/// used to have (`id` as a plain column).
Map<String, dynamic> _withId(DocumentSnapshot<Map<String, dynamic>> doc) =>
    {...?doc.data(), 'id': doc.id};

/// Firestore's `whereIn` (including on `FieldPath.documentId`) allows at most
/// 30 values per query, so large id lists are split into chunks and fetched
/// in parallel.
Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _whereInChunked(
  Query<Map<String, dynamic>> Function(List<String> chunk) queryBuilder,
  List<String> values,
) async {
  if (values.isEmpty) return [];
  final chunks = <List<String>>[];
  for (var i = 0; i < values.length; i += 30) {
    chunks.add(values.sublist(i, min(i + 30, values.length)));
  }
  final results = await Future.wait(chunks.map((c) => queryBuilder(c).get()));
  return results.expand((r) => r.docs).toList();
}

String _nowIso() => DateTime.now().toIso8601String();

// ── Spaces ──
Future<List<DbSpace>> _attachLiveSpaceCounts(List<DbSpace> spaces) async {
  if (spaces.isEmpty) return spaces;
  final ids = spaces.map((s) => s.id).toList();
  final docs = await _whereInChunked(
    (chunk) => _db.collection('posts').where('space_id', whereIn: chunk),
    ids,
  );

  final postCounts = <String, int>{};
  final memberSets = <String, Set<String>>{};
  for (final doc in docs) {
    final row = doc.data();
    final spaceId = row['space_id'] as String;
    postCounts[spaceId] = (postCounts[spaceId] ?? 0) + 1;
    final authorId = row['author_id'] as String?;
    if (authorId != null) {
      memberSets.putIfAbsent(spaceId, () => {}).add(authorId);
    }
  }

  return spaces
      .map((s) => s.copyWith(
            postCount: postCounts[s.id] ?? 0,
            memberCount: memberSets[s.id]?.length ?? 0,
          ))
      .toList();
}

Future<List<DbSpace>> fetchSpaces() async {
  final snap = await _db.collection('spaces').orderBy('name').get();
  final spaces = snap.docs.map((d) => DbSpace.fromJson(_withId(d))).toList();
  return _attachLiveSpaceCounts(spaces);
}

Future<DbSpace> fetchSpace(String id) async {
  final doc = await _db.collection('spaces').doc(id).get();
  final withCounts =
      await _attachLiveSpaceCounts([DbSpace.fromJson(_withId(doc))]);
  return withCounts.first;
}

// ── Posts ──
Future<List<DbPost>> fetchPosts({int limit = 20, String? spaceId}) async {
  Query<Map<String, dynamic>> q = _db.collection('posts');
  if (spaceId != null) {
    q = q.where('space_id', isEqualTo: spaceId);
  }
  final snap =
      await q.orderBy('created_at', descending: true).limit(limit).get();
  return snap.docs.map((d) => DbPost.fromJson(_withId(d))).toList();
}

Future<DbPost> fetchPost(String id) async {
  final doc = await _db.collection('posts').doc(id).get();
  return DbPost.fromJson(_withId(doc));
}

Future<DbPost> createPost({
  required String spaceId,
  required String? authorId,
  required bool isAnonymous,
  required String title,
  required String body,
  required List<String> tags,
}) async {
  final resolvedAuthorId = isAnonymous ? null : authorId;
  Map<String, dynamic>? authorProfile;
  if (resolvedAuthorId != null) {
    final profileDoc =
        await _db.collection('profiles').doc(resolvedAuthorId).get();
    authorProfile = profileDoc.data();
  }

  final ref = await _db.collection('posts').add({
    'space_id': spaceId,
    'author_id': resolvedAuthorId,
    'is_anonymous': isAnonymous,
    'title': title,
    'body': body,
    'like_count': 0,
    'reply_count': 0,
    'tags': tags,
    'author_display_name': authorProfile?['display_name'],
    'author_initials': authorProfile?['initials'],
    'author_role': authorProfile?['role'],
    'created_at': _nowIso(),
  });
  final snap = await ref.get();
  return DbPost.fromJson(_withId(snap));
}

Future<void> togglePostLike(String likerKey, String postId, bool liked) async {
  final likeRef = _db.collection('post_likes').doc('${likerKey}_$postId');
  final postRef = _db.collection('posts').doc(postId);
  final batch = _db.batch();
  if (liked) {
    batch.delete(likeRef);
    batch.update(postRef, {'like_count': FieldValue.increment(-1)});
  } else {
    batch.set(likeRef, {
      'post_id': postId,
      'liker_key': likerKey,
      'user_id': null,
      'created_at': _nowIso(),
    });
    batch.update(postRef, {'like_count': FieldValue.increment(1)});
  }
  await batch.commit();
}

Future<Set<String>> fetchPostLikes(
    String likerKey, List<String> postIds) async {
  if (postIds.isEmpty) return {};
  final ids = postIds.map((id) => '${likerKey}_$id').toList();
  final docs = await _whereInChunked(
    (chunk) =>
        _db.collection('post_likes').where(FieldPath.documentId, whereIn: chunk),
    ids,
  );
  return docs.map((d) => d.data()['post_id'] as String).toSet();
}

Future<List<DbPost>> fetchSavedPosts(String userId) async {
  final saved = await _db
      .collection('saved_posts')
      .where('user_id', isEqualTo: userId)
      .get();
  final postIds =
      saved.docs.map((d) => d.data()['post_id'] as String).toList();
  final postDocs = await _whereInChunked(
    (chunk) =>
        _db.collection('posts').where(FieldPath.documentId, whereIn: chunk),
    postIds,
  );
  return postDocs.map((d) => DbPost.fromJson(_withId(d))).toList();
}

Future<void> toggleSavedPost(String userId, String postId, bool saved) async {
  final ref = _db.collection('saved_posts').doc('${userId}_$postId');
  if (saved) {
    await ref.delete();
  } else {
    await ref.set({
      'user_id': userId,
      'post_id': postId,
      'created_at': _nowIso(),
    });
  }
}

Future<Set<String>> fetchSavedPostIds(String userId) async {
  final snap = await _db
      .collection('saved_posts')
      .where('user_id', isEqualTo: userId)
      .get();
  return snap.docs.map((d) => d.data()['post_id'] as String).toSet();
}

// ── Comments ──
Future<List<DbComment>> fetchComments(
    String targetType, String targetId) async {
  final snap = await _db
      .collection('comments')
      .where('target_type', isEqualTo: targetType)
      .where('target_id', isEqualTo: targetId)
      .orderBy('created_at')
      .get();
  return snap.docs.map((d) => DbComment.fromJson(_withId(d))).toList();
}

Future<DbComment> addComment({
  required String targetType,
  required String targetId,
  required String? authorId,
  required String authorName,
  required String text,
}) async {
  final commentRef = _db.collection('comments').doc();
  final batch = _db.batch();
  batch.set(commentRef, {
    'target_type': targetType,
    'target_id': targetId,
    'author_id': authorId,
    'author_display_name': authorName.isNotEmpty ? authorName : 'Anonymous',
    'text': text,
    'created_at': _nowIso(),
  });
  if (targetType == 'post') {
    batch.update(_db.collection('posts').doc(targetId),
        {'reply_count': FieldValue.increment(1)});
  }
  await batch.commit();
  final snap = await commentRef.get();
  return DbComment.fromJson(_withId(snap));
}

// ── Articles ──
Future<List<DbArticle>> fetchArticles() async {
  final snap = await _db
      .collection('articles')
      .orderBy('created_at', descending: true)
      .get();
  return snap.docs.map((d) => DbArticle.fromJson(_withId(d))).toList();
}

Future<DbArticle?> fetchArticle(String idOrLegacy) async {
  final doc = await _db.collection('articles').doc(idOrLegacy).get();
  if (doc.exists) return DbArticle.fromJson(_withId(doc));
  final snap = await _db
      .collection('articles')
      .where('legacy_id', isEqualTo: idOrLegacy)
      .limit(1)
      .get();
  if (snap.docs.isEmpty) return null;
  return DbArticle.fromJson(_withId(snap.docs.first));
}

Future<DbArticle> createArticle({
  required String authorId,
  required String authorName,
  required String title,
  required String category,
  required int readMin,
  required String icon,
  required String excerpt,
  String? body,
  String? mediumUrl,
}) async {
  final ref = await _db.collection('articles').add({
    'title': title,
    'category': category,
    'read_min': readMin,
    'icon': icon,
    'excerpt': excerpt,
    'body': body,
    'medium_url': mediumUrl,
    'author_id': authorId,
    'author_display_name': authorName,
    'is_editorial': false,
    'like_count': 0,
    'created_at': _nowIso(),
  });
  final snap = await ref.get();
  return DbArticle.fromJson(_withId(snap));
}

Future<void> toggleArticleLike(
    String userId, String articleId, bool liked) async {
  final likeRef = _db.collection('article_likes').doc('${userId}_$articleId');
  final articleRef = _db.collection('articles').doc(articleId);
  final batch = _db.batch();
  if (liked) {
    batch.delete(likeRef);
    batch.update(articleRef, {'like_count': FieldValue.increment(-1)});
  } else {
    batch.set(likeRef, {
      'user_id': userId,
      'article_id': articleId,
      'created_at': _nowIso(),
    });
    batch.update(articleRef, {'like_count': FieldValue.increment(1)});
  }
  await batch.commit();
}

Future<Set<String>> fetchArticleLikes(
    String userId, List<String> articleIds) async {
  if (articleIds.isEmpty) return {};
  final ids = articleIds.map((id) => '${userId}_$id').toList();
  final docs = await _whereInChunked(
    (chunk) => _db
        .collection('article_likes')
        .where(FieldPath.documentId, whereIn: chunk),
    ids,
  );
  return docs.map((d) => d.data()['article_id'] as String).toSet();
}

// ── Calm Kit ──
Future<List<DbCalmKit>> fetchCalmKitItems() async {
  final snap = await _db
      .collection('calm_kit_items')
      .where('is_deleted', isEqualTo: false)
      .orderBy('created_at', descending: true)
      .get();
  return snap.docs.map((d) => DbCalmKit.fromJson(_withId(d))).toList();
}

Future<DbCalmKit?> fetchCalmKitItem(String idOrLegacy) async {
  final doc = await _db.collection('calm_kit_items').doc(idOrLegacy).get();
  if (doc.exists) return DbCalmKit.fromJson(_withId(doc));
  final snap = await _db
      .collection('calm_kit_items')
      .where('legacy_id', isEqualTo: idOrLegacy)
      .limit(1)
      .get();
  if (snap.docs.isEmpty) return null;
  return DbCalmKit.fromJson(_withId(snap.docs.first));
}

Future<DbCalmKit> createCalmKitItem({
  required String ownerId,
  required String authorName,
  required String name,
  required String why,
  required String when,
  required String icon,
  required List<String> tags,
  required bool shareToCommunity,
}) async {
  final ref = await _db.collection('calm_kit_items').add({
    'owner_id': ownerId,
    'author_display_name': authorName,
    'name': name,
    'why': why,
    'when_to_use': when,
    'icon': icon,
    'tags': tags,
    'is_community_shared': shareToCommunity,
    'is_seed': false,
    'is_deleted': false,
    'vote_count': 0,
    'created_at': _nowIso(),
  });
  final snap = await ref.get();
  return DbCalmKit.fromJson(_withId(snap));
}

Future<void> updateCalmKitItem(
  String id,
  Map<String, dynamic> patch,
  String userId,
  bool isSeed,
) async {
  if (isSeed) {
    await _db.collection('calm_kit_edits').doc('${userId}_$id').set({
      'user_id': userId,
      'seed_item_id': id,
      ...patch,
      'updated_at': _nowIso(),
    }, SetOptions(merge: true));
  } else {
    await _db.collection('calm_kit_items').doc(id).update(patch);
  }
}

Future<void> deleteCalmKitItem(String id, String userId, bool isSeed) async {
  if (isSeed) {
    await _db.collection('calm_kit_deletes').doc('${userId}_$id').set({
      'user_id': userId,
      'seed_item_id': id,
    }, SetOptions(merge: true));
    await _db.collection('calm_kit_pins').doc('${userId}_$id').delete();
  } else {
    await _db.collection('calm_kit_items').doc(id).delete();
  }
}

Future<DbCalmKit> shareSeedToCommunity(
    String seedId, String userId, String authorName) async {
  final seed = await fetchCalmKitItem(seedId);
  if (seed == null) throw Exception('Item not found');
  return createCalmKitItem(
    ownerId: userId,
    authorName: authorName,
    name: seed.name,
    why: seed.why,
    when: seed.whenToUse,
    icon: seed.icon,
    tags: seed.tags,
    shareToCommunity: true,
  );
}

Future<void> toggleCalmKitVote(String userId, String kitId, bool voted) async {
  final voteRef = _db.collection('calm_kit_votes').doc('${userId}_$kitId');
  final kitRef = _db.collection('calm_kit_items').doc(kitId);
  final batch = _db.batch();
  if (voted) {
    batch.delete(voteRef);
    batch.update(kitRef, {'vote_count': FieldValue.increment(-1)});
  } else {
    batch.set(voteRef, {
      'user_id': userId,
      'calm_kit_id': kitId,
      'created_at': _nowIso(),
    });
    batch.update(kitRef, {'vote_count': FieldValue.increment(1)});
  }
  await batch.commit();
}

Future<void> toggleCalmKitPin(String userId, String kitId, bool pinned) async {
  final ref = _db.collection('calm_kit_pins').doc('${userId}_$kitId');
  if (pinned) {
    await ref.delete();
  } else {
    await ref.set({
      'user_id': userId,
      'calm_kit_id': kitId,
      'is_pinned': true,
    });
  }
}

class CalmKitUserState {
  final Set<String> myVotes;
  final Map<String, bool> pins;
  final Map<String, Map<String, dynamic>> edits;
  final Set<String> deleted;

  CalmKitUserState({
    required this.myVotes,
    required this.pins,
    required this.edits,
    required this.deleted,
  });
}

Future<CalmKitUserState> fetchCalmKitUserState(String userId) async {
  final results = await Future.wait([
    _db.collection('calm_kit_votes').where('user_id', isEqualTo: userId).get(),
    _db.collection('calm_kit_pins').where('user_id', isEqualTo: userId).get(),
    _db.collection('calm_kit_edits').where('user_id', isEqualTo: userId).get(),
    _db
        .collection('calm_kit_deletes')
        .where('user_id', isEqualTo: userId)
        .get(),
  ]);
  final votes = results[0].docs;
  final pins = results[1].docs;
  final edits = results[2].docs;
  final deletes = results[3].docs;

  return CalmKitUserState(
    myVotes: votes.map((v) => v.data()['calm_kit_id'] as String).toSet(),
    pins: {
      for (final p in pins)
        p.data()['calm_kit_id'] as String:
            p.data()['is_pinned'] as bool? ?? false
    },
    edits: {for (final e in edits) e.data()['seed_item_id'] as String: e.data()},
    deleted: deletes.map((d) => d.data()['seed_item_id'] as String).toSet(),
  );
}

// ── Events ──
Future<List<DbEvent>> fetchEvents() async {
  final snap = await _db.collection('events').orderBy('event_date').get();
  return snap.docs.map((d) => DbEvent.fromJson(_withId(d))).toList();
}

Future<DbEvent?> fetchEvent(String idOrLegacy) async {
  final doc = await _db.collection('events').doc(idOrLegacy).get();
  if (doc.exists) return DbEvent.fromJson(_withId(doc));
  final snap = await _db
      .collection('events')
      .where('legacy_id', isEqualTo: idOrLegacy)
      .limit(1)
      .get();
  if (snap.docs.isEmpty) return null;
  return DbEvent.fromJson(_withId(snap.docs.first));
}

Future<DbEvent> createEvent({
  required String hostId,
  required String hostName,
  required String type,
  required String title,
  required String description,
  required String? eventDate,
  required String eventTime,
  required String location,
  required bool isVirtual,
}) async {
  final ref = await _db.collection('events').add({
    'host_id': hostId,
    'host_name': hostName,
    'type': type,
    'title': title,
    'description': description,
    'event_date': eventDate,
    'event_time': eventTime,
    'location': location,
    'is_virtual': isVirtual,
    'icon': 'Calendar',
    'rsvp_count': 0,
  });
  final snap = await ref.get();
  return DbEvent.fromJson(_withId(snap));
}

Future<void> toggleEventRsvp(
    String userId, String eventId, bool hasRsvp) async {
  final rsvpRef = _db.collection('event_rsvps').doc('${userId}_$eventId');
  final eventRef = _db.collection('events').doc(eventId);
  final batch = _db.batch();
  if (hasRsvp) {
    batch.delete(rsvpRef);
    batch.update(eventRef, {'rsvp_count': FieldValue.increment(-1)});
  } else {
    batch.set(rsvpRef, {
      'user_id': userId,
      'event_id': eventId,
      'created_at': _nowIso(),
    });
    batch.update(eventRef, {'rsvp_count': FieldValue.increment(1)});
  }
  await batch.commit();
}

Future<Set<String>> fetchUserRsvps(String userId) async {
  final snap = await _db
      .collection('event_rsvps')
      .where('user_id', isEqualTo: userId)
      .get();
  return snap.docs.map((d) => d.data()['event_id'] as String).toSet();
}

// ── Therapists ──
Future<List<DbTherapist>> fetchTherapists() async {
  final snap = await _db
      .collection('therapists')
      .orderBy('rating', descending: true)
      .get();
  return snap.docs.map((d) => DbTherapist.fromJson(_withId(d))).toList();
}

// ── Members ──
Future<List<DbProfile>> fetchMembers() async {
  final snap = await _db.collection('profiles').orderBy('display_name').get();
  return snap.docs.map((d) => DbProfile.fromJson(_withId(d))).toList();
}

// ── Notifications ──
Future<List<DbNotification>> fetchNotifications(String userId) async {
  final snap = await _db
      .collection('notifications')
      .where('user_id', isEqualTo: userId)
      .orderBy('created_at', descending: true)
      .get();
  return snap.docs.map((d) => DbNotification.fromJson(_withId(d))).toList();
}

Future<void> markNotificationRead(String id) async {
  await _db.collection('notifications').doc(id).update({'is_read': true});
}

// ── Profile ──
Future<void> updateProfile(String userId, Map<String, dynamic> patch) async {
  await _db.collection('profiles').doc(userId).update(patch);
}

Future<DbRow> fetchPrivacySettings(String userId) async {
  final doc = await _db.collection('privacy_settings').doc(userId).get();
  return _withId(doc);
}

Future<void> updatePrivacySettings(
    String userId, Map<String, bool> patch) async {
  await _db
      .collection('privacy_settings')
      .doc(userId)
      .set(patch, SetOptions(merge: true));
}

Future<DbRow> fetchNotificationSettings(String userId) async {
  final doc = await _db.collection('notification_settings').doc(userId).get();
  return _withId(doc);
}

Future<void> updateNotificationSettings(
    String userId, Map<String, bool> patch) async {
  await _db
      .collection('notification_settings')
      .doc(userId)
      .set(patch, SetOptions(merge: true));
}

class ProfileStats {
  final int posts;
  final int comments;
  final int saved;
  ProfileStats(
      {required this.posts, required this.comments, required this.saved});
}

Future<ProfileStats> fetchProfileStats(String userId) async {
  final posts = await _db
      .collection('posts')
      .where('author_id', isEqualTo: userId)
      .count()
      .get();
  final comments = await _db
      .collection('comments')
      .where('author_id', isEqualTo: userId)
      .count()
      .get();
  final saved = await _db
      .collection('saved_posts')
      .where('user_id', isEqualTo: userId)
      .count()
      .get();
  return ProfileStats(
    posts: posts.count ?? 0,
    comments: comments.count ?? 0,
    saved: saved.count ?? 0,
  );
}

// ── Emotional support ──
List<T> _sampleRandom<T>(List<T> items, int count) {
  final copy = List<T>.from(items);
  final rand = Random();
  for (var i = copy.length - 1; i > 0; i--) {
    final j = rand.nextInt(i + 1);
    final tmp = copy[i];
    copy[i] = copy[j];
    copy[j] = tmp;
  }
  return copy.sublist(0, min(count, copy.length));
}

Future<List<DbRow>> fetchEmotionalPrompts(
    {String? userId, int limit = 3}) async {
  final snap = await _db
      .collection('emotional_prompts')
      .where('is_active', isEqualTo: true)
      .get();
  final pool = snap.docs.map(_withId).toList();
  return _sampleRandom(pool, limit);
}

const _likerKeyStorage = 'emotional_liker_key';

Future<String> getEmotionalLikerKey({String? userId}) async {
  if (userId != null) return userId;
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(_likerKeyStorage);
  if (stored != null) return stored;
  final key =
      'guest-${Random().nextInt(1 << 32).toRadixString(36)}-${DateTime.now().millisecondsSinceEpoch}';
  await prefs.setString(_likerKeyStorage, key);
  return key;
}

Future<List<DbRow>> fetchEmotionalShares() async {
  final snap = await _db
      .collection('emotional_shares')
      .orderBy('created_at', descending: true)
      .limit(20)
      .get();
  return snap.docs.map(_withId).toList();
}

Future<Map<String, List<DbRow>>> fetchEmotionalReplies(
    List<String> shareIds) async {
  if (shareIds.isEmpty) return {};
  final docs = await _whereInChunked(
    (chunk) =>
        _db.collection('emotional_replies').where('share_id', whereIn: chunk),
    shareIds,
  );
  final grouped = <String, List<DbRow>>{};
  for (final doc in docs) {
    final r = _withId(doc);
    final shareId = r['share_id'] as String;
    grouped.putIfAbsent(shareId, () => []).add(r);
  }
  for (final list in grouped.values) {
    list.sort((a, b) =>
        (a['created_at'] as String).compareTo(b['created_at'] as String));
  }
  return grouped;
}

Future<Map<String, int>> fetchEmotionalReplyCounts(
    List<String> shareIds) async {
  if (shareIds.isEmpty) return {};
  final docs = await _whereInChunked(
    (chunk) =>
        _db.collection('emotional_replies').where('share_id', whereIn: chunk),
    shareIds,
  );
  final counts = <String, int>{};
  for (final doc in docs) {
    final shareId = doc.data()['share_id'] as String;
    counts[shareId] = (counts[shareId] ?? 0) + 1;
  }
  return counts;
}

Future<DbRow> fetchEmotionalShare(String shareId) async {
  final doc = await _db.collection('emotional_shares').doc(shareId).get();
  return _withId(doc);
}

Future<List<DbRow>> fetchRepliesForShare(String shareId) async {
  final snap = await _db
      .collection('emotional_replies')
      .where('share_id', isEqualTo: shareId)
      .orderBy('created_at')
      .get();
  return snap.docs.map(_withId).toList();
}

Future<DbRow> createEmotionalShare(String body, {String? promptId}) async {
  final ref = await _db.collection('emotional_shares').add({
    'author_id': null,
    'body': body,
    'prompt_id': promptId,
    'is_anonymous': true,
    'created_at': _nowIso(),
  });
  final snap = await ref.get();
  return _withId(snap);
}

Future<DbRow> createEmotionalReply(String shareId, String body) async {
  final ref = await _db.collection('emotional_replies').add({
    'share_id': shareId,
    'author_id': null,
    'body': body,
    'created_at': _nowIso(),
  });
  final snap = await ref.get();
  return _withId(snap);
}

Future<void> toggleShareLike(
    String likerKey, String shareId, bool liked) async {
  final ref = _db.collection('hold_spaces').doc('${likerKey}_$shareId');
  if (liked) {
    await ref.delete();
  } else {
    await ref.set({
      'share_id': shareId,
      'liker_key': likerKey,
      'user_id': null,
      'created_at': _nowIso(),
    });
  }
}

Future<Set<String>> fetchLikedShareIds(String likerKey) async {
  final snap = await _db
      .collection('hold_spaces')
      .where('liker_key', isEqualTo: likerKey)
      .get();
  return snap.docs.map((d) => d.data()['share_id'] as String).toSet();
}

// ── Misc ──
T? _pickAffirmationForUser<T>(
    List<T> items, String? userId, String Function(T) idOf) {
  if (items.isEmpty) return null;
  final key =
      '${userId ?? 'guest'}-${DateTime.now().toIso8601String().substring(0, 10)}';
  var hash = 0;
  for (final codeUnit in key.codeUnits) {
    hash = (hash * 31 + codeUnit) & 0xFFFFFFFF;
  }
  return items[hash % items.length];
}

Future<DbRow?> fetchDailyAffirmation({String? userId}) async {
  final poolSnap = await _db
      .collection('daily_affirmations')
      .where('active_date', isEqualTo: null)
      .get();
  final poolRows = poolSnap.docs.map(_withId).toList();
  final picked =
      _pickAffirmationForUser(poolRows, userId, (r) => r['id'] as String);
  if (picked != null) return picked;

  final latestSnap = await _db
      .collection('daily_affirmations')
      .orderBy('created_at', descending: true)
      .limit(1)
      .get();
  if (latestSnap.docs.isEmpty) return null;
  return _withId(latestSnap.docs.first);
}

Future<List<DbRow>> fetchGuidelines() async {
  final snap = await _db
      .collection('community_guidelines')
      .orderBy('sort_order')
      .get();
  return snap.docs.map(_withId).toList();
}

Future<void> submitIssueReport({
  required String? userId,
  required String issueType,
  required String subject,
  required String details,
}) async {
  await _db.collection('issue_reports').add({
    'user_id': userId,
    'issue_type': issueType,
    'subject': subject,
    'details': details,
    'created_at': _nowIso(),
  });
}

Future<bool> toggleConnection(String requesterId, String recipientId) async {
  final existing = await _db
      .collection('connections')
      .where('requester_id', isEqualTo: requesterId)
      .where('recipient_id', isEqualTo: recipientId)
      .limit(1)
      .get();
  if (existing.docs.isNotEmpty) {
    await existing.docs.first.reference.delete();
    return false;
  }
  await _db.collection('connections').add({
    'requester_id': requesterId,
    'recipient_id': recipientId,
    'status': 'connected',
    'created_at': _nowIso(),
  });
  return true;
}

Future<Set<String>> fetchUserConnections(String userId) async {
  final results = await Future.wait([
    _db
        .collection('connections')
        .where('requester_id', isEqualTo: userId)
        .where('status', isEqualTo: 'connected')
        .get(),
    _db
        .collection('connections')
        .where('recipient_id', isEqualTo: userId)
        .where('status', isEqualTo: 'connected')
        .get(),
  ]);
  final ids = <String>{};
  for (final doc in results[0].docs) {
    ids.add(doc.data()['recipient_id'] as String);
  }
  for (final doc in results[1].docs) {
    ids.add(doc.data()['requester_id'] as String);
  }
  return ids;
}

Future<SearchResults> searchCommunity(String query) async {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return SearchResults.empty();

  bool match(String? text) => (text ?? '').toLowerCase().contains(q);

  final results = await Future.wait([
    fetchPosts(limit: 50),
    fetchMembers(),
    fetchArticles(),
    fetchEvents(),
    fetchSpaces(),
  ]);
  final posts = results[0] as List<DbPost>;
  final members = results[1] as List<DbProfile>;
  final articles = results[2] as List<DbArticle>;
  final events = results[3] as List<DbEvent>;
  final spaces = results[4] as List<DbSpace>;

  return SearchResults(
    posts: posts.where((p) => match(p.title) || match(p.body)).toList(),
    members: members
        .where((m) =>
            match(m.displayName) || match(m.bio) || m.tags.any((t) => match(t)))
        .toList(),
    articles: articles
        .where((a) => match(a.title) || match(a.excerpt) || match(a.category))
        .toList(),
    events: events
        .where((e) => match(e.title) || match(e.description) || match(e.type))
        .toList(),
    spaces: spaces.where((s) => match(s.name) || match(s.description)).toList(),
  );
}
