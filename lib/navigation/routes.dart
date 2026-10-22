import 'package:flutter/material.dart';

import '../screens/article_detail_screen.dart';
import '../screens/calm_item_detail_screen.dart';
import '../screens/calm_kit_screen.dart';
import '../screens/community_guidelines_screen.dart';
import '../screens/create_article_screen.dart';
import '../screens/create_calm_item_screen.dart';
import '../screens/create_event_screen.dart';
import '../screens/create_post_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/emotional_share_replies_screen.dart';
import '../screens/emotional_support_screen.dart';
import '../screens/event_detail_screen.dart';
import '../screens/events_screen.dart';
import '../screens/home_screen.dart';
import '../screens/learn_screen.dart';
import '../screens/members_directory_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/privacy_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/report_issue_screen.dart';
import '../screens/saved_posts_screen.dart';
import '../screens/search_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/space_detail_screen.dart';
import '../screens/spaces_screen.dart';
import '../screens/therapists_screen.dart';

/// Every screen reachable from inside the four bottom-tab stacks (Home,
/// Spaces, Events, Learn), keyed by the same route names React Navigation
/// used in `AppNavigator.tsx`. Each of the four tab `Navigator`s below
/// shares this single map (with a different `initialRoute`), which is a
/// faithful enough model of React Navigation's nested stacks since routes
/// are only ever reached by an explicit `navigate(name)` call.
final Map<String, WidgetBuilder> innerScreenBuilders = {
  'Home': (_) => const HomeScreen(),
  'Profile': (_) => const ProfileScreen(),
  'Notifications': (_) => const NotificationsScreen(),
  'Search': (_) => const SearchScreen(),
  'CalmKit': (_) => const CalmKitScreen(),
  'CalmItemDetail': (_) => const CalmItemDetailScreen(),
  'CreateCalmItem': (_) => const CreateCalmItemScreen(),
  'Therapists': (_) => const TherapistsScreen(),
  'Settings': (_) => const SettingsScreen(),
  'EditProfile': (_) => const EditProfileScreen(),
  'Privacy': (_) => const PrivacyScreen(),
  'CommunityGuidelines': (_) => const CommunityGuidelinesScreen(),
  'ReportIssue': (_) => const ReportIssueScreen(),
  'SavedPosts': (_) => const SavedPostsScreen(),
  'MembersDirectory': (_) => const MembersDirectoryScreen(),
  'EmotionalSupport': (_) => const EmotionalSupportScreen(),
  'EmotionalShareReplies': (_) => const EmotionalShareRepliesScreen(),
  'PostDetail': (_) => const PostDetailScreen(),
  'EventDetail': (_) => const EventDetailScreen(),
  'SpaceDetail': (_) => const SpaceDetailScreen(),
  'ArticleDetail': (_) => const ArticleDetailScreen(),
  'Spaces': (_) => const SpacesScreen(),
  'CreatePost': (_) => const CreatePostScreen(),
  'Events': (_) => const EventsScreen(),
  'CreateEvent': (_) => const CreateEventScreen(),
  'Learn': (_) => const LearnScreen(),
  'CreateArticle': (_) => const CreateArticleScreen(),
};
