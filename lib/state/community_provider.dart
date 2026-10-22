import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/view_models.dart';
import '../services/data_service.dart' as data;

/// Direct port of the `useCommunity()` hook in `src/lib/community.ts`,
/// reshaped as a `ChangeNotifier` so any screen can `context.watch` it.
class CommunityProvider extends ChangeNotifier {
  String? _userId;
  bool ready = false;

  List<DbArticle> _allArticles = [];
  List<DbCalmKit> _allKits = [];
  final Map<String, List<CommentView>> comments = {};
  Map<String, bool> myKitVotes = {};
  Map<String, bool> myArtLikes = {};
  Map<String, bool> kitPins = {};
  Map<String, CalmKitPatch> kitEdits = {};
  Map<String, bool> kitDeleted = {};

  List<DbCalmKit> get allKits => _allKits;

  /// Called whenever the signed-in user changes (including sign-out/guest).
  void setUserId(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    refresh();
  }

  Future<void> refresh() async {
    try {
      final results =
          await Future.wait([data.fetchArticles(), data.fetchCalmKitItems()]);
      _allArticles = results[0] as List<DbArticle>;
      _allKits = results[1] as List<DbCalmKit>;

      final uid = _userId;
      if (uid != null) {
        final state = await data.fetchCalmKitUserState(uid);
        myKitVotes = {for (final id in state.myVotes) id: true};
        kitPins = state.pins;
        kitEdits = {
          for (final entry in state.edits.entries)
            entry.key: CalmKitPatch(
              name: entry.value['name'] as String?,
              why: entry.value['why'] as String?,
              when: entry.value['when_to_use'] as String?,
              icon: entry.value['icon'] as String?,
              tags: (entry.value['tags'] as List?)
                  ?.map((t) => t as String)
                  .toList(),
            ),
        };
        kitDeleted = {for (final id in state.deleted) id: true};

        final userArticleIds =
            _allArticles.where((a) => !a.isEditorial).map((a) => a.id).toList();
        final liked = await data.fetchArticleLikes(uid, userArticleIds);
        myArtLikes = {for (final id in liked) id: true};
      } else {
        myKitVotes = {};
        kitPins = {};
        kitEdits = {};
        kitDeleted = {};
        myArtLikes = {};
      }
    } catch (_) {
      // Non-fatal: Learn/Calm Kit can retry on next focus.
    } finally {
      ready = true;
      notifyListeners();
    }
  }

  List<DbArticle> get editorialArticles =>
      _allArticles.where((a) => a.isEditorial).toList();
  List<CommunityArticle> get articles =>
      _allArticles.where((a) => !a.isEditorial).map(mapArticle).toList();
  List<DbCalmKit> get seedItems => _allKits.where((k) => k.isSeed).toList();
  List<CommunityCalmKit> get kits => _allKits
      .where((k) => k.isCommunityShared && !k.isSeed)
      .map(mapKit)
      .toList();

  Map<String, int> get artLikes =>
      {for (final a in _allArticles) a.id: a.likeCount};
  Map<String, int> get kitVotes =>
      {for (final k in _allKits) k.id: k.voteCount};

  List<CommunityArticle> get editorial =>
      editorialArticles.map(mapArticle).toList();
  List<CommunityCalmKit> get seedKits => seedItems.map(mapKit).toList();

  Future<void> loadComments(String targetId, String targetType) async {
    final rows = await data.fetchComments(targetType, targetId);
    comments[targetId] = rows.map(mapComment).toList();
    notifyListeners();
  }

  Future<CommunityCalmKit> addKit({
    required String name,
    required String why,
    required String when,
    required String icon,
    required List<String> tags,
    required String author,
    bool shareToCommunity = true,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('Sign in required');
    final item = await data.createCalmKitItem(
      ownerId: uid,
      authorName: author,
      name: name,
      why: why,
      when: when,
      icon: icon,
      tags: tags,
      shareToCommunity: shareToCommunity,
    );
    await refresh();
    return mapKit(item);
  }

  Future<void> updateKit(String id, CalmKitPatch patch) async {
    final uid = _userId;
    if (uid == null) return;
    final item = _allKits.where((k) => k.id == id).firstOrNull;
    await data.updateCalmKitItem(
        id, patch.toDbPatch(), uid, item?.isSeed ?? false);
    await refresh();
  }

  Future<void> deleteKit(String id) async {
    final uid = _userId;
    if (uid == null) return;
    final item = _allKits.where((k) => k.id == id).firstOrNull;
    await data.deleteCalmKitItem(id, uid, item?.isSeed ?? false);
    await refresh();
  }

  Future<void> togglePin(String id, {bool seedDefault = false}) async {
    final uid = _userId;
    if (uid == null) return;
    final current = kitPins.containsKey(id) ? kitPins[id]! : seedDefault;
    await data.toggleCalmKitPin(uid, id, current);
    await refresh();
  }

  bool isPinned(String id, {bool seedDefault = false}) =>
      kitPins.containsKey(id) ? kitPins[id]! : seedDefault;

  Future<CommunityCalmKit> shareSeedToCommunity(
      String seedId, String author) async {
    final uid = _userId;
    if (uid == null) throw Exception('Sign in required');
    final item = await data.shareSeedToCommunity(seedId, uid, author);
    await refresh();
    return mapKit(item);
  }

  Future<CommunityArticle> addArticle({
    required String title,
    required String category,
    required int readMin,
    required String icon,
    required String excerpt,
    required String author,
    String? body,
    String? mediumUrl,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('Sign in required');
    final item = await data.createArticle(
      authorId: uid,
      authorName: author,
      title: title,
      category: category,
      readMin: readMin,
      icon: icon,
      excerpt: excerpt,
      body: body,
      mediumUrl: mediumUrl,
    );
    await refresh();
    return mapArticle(item);
  }

  Future<void> toggleKitVote(String id) async {
    final uid = _userId;
    if (uid == null) return;
    await data.toggleCalmKitVote(uid, id, myKitVotes[id] ?? false);
    await refresh();
  }

  Future<void> toggleArticleLike(String id) async {
    final uid = _userId;
    if (uid == null) return;
    await data.toggleArticleLike(uid, id, myArtLikes[id] ?? false);
    await refresh();
  }

  Future<DbComment> addComment(String targetId, String author, String text,
      {String targetType = 'calm_kit'}) async {
    final c = await data.addComment(
      targetType: targetType,
      targetId: targetId,
      authorId: _userId,
      authorName: author,
      text: text,
    );
    final list = comments.putIfAbsent(targetId, () => []);
    list.add(mapComment(c));
    notifyListeners();
    return c;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
