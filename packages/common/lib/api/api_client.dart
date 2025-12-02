// import 'dart:convert';

// import 'package:flutter/foundation.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart' as http;
// import 'package:web_socket_channel/web_socket_channel.dart';

// class ApiClientException implements Exception {
//   ApiClientException(this.message);

//   final String message;

//   @override
//   String toString() => 'ApiClientException: $message';
// }

// enum WellnessTaskCategory { daily, evening }

// extension WellnessTaskCategoryX on WellnessTaskCategory {
//   String get apiValue => switch (this) {
//         WellnessTaskCategory.daily => 'daily',
//         WellnessTaskCategory.evening => 'evening',
//       };

//   String get displayLabel => switch (this) {
//         WellnessTaskCategory.daily => 'Daily Tasks',
//         WellnessTaskCategory.evening => 'Evening Reflection',
//       };

//   static WellnessTaskCategory fromApi(String value) {
//     switch (value) {
//       case 'evening':
//         return WellnessTaskCategory.evening;
//       case 'daily':
//       default:
//         return WellnessTaskCategory.daily;
//     }
//   }
// }

// class WellnessTaskItem {
//   const WellnessTaskItem({
//     required this.id,
//     required this.title,
//     required this.category,
//     required this.isCompleted,
//     required this.order,
//   });

//   factory WellnessTaskItem.fromJson(Map<String, dynamic> json) {
//     return WellnessTaskItem(
//       id: json['id'] as int,
//       title: (json['title'] as String?)?.trim() ?? '',
//       category:
//           WellnessTaskCategoryX.fromApi(json['category'] as String? ?? 'daily'),
//       isCompleted: json['is_completed'] as bool? ?? false,
//       order: json['order'] as int? ?? 0,
//     );
//   }

//   final int id;
//   final String title;
//   final WellnessTaskCategory category;
//   final bool isCompleted;
//   final int order;

//   WellnessTaskItem copyWith({
//     String? title,
//     WellnessTaskCategory? category,
//     bool? isCompleted,
//     int? order,
//   }) {
//     return WellnessTaskItem(
//       id: id,
//       title: title ?? this.title,
//       category: category ?? this.category,
//       isCompleted: isCompleted ?? this.isCompleted,
//       order: order ?? this.order,
//     );
//   }
// }

// class WellnessTaskSummary {
//   const WellnessTaskSummary({
//     required this.total,
//     required this.completed,
//   });

//   final int total;
//   final int completed;

//   double get completionRatio => total == 0 ? 0 : completed / total;
// }

// class WellnessTasksResponse {
//   const WellnessTasksResponse({
//     required this.daily,
//     required this.evening,
//     required this.summary,
//   });

//   final List<WellnessTaskItem> daily;
//   final List<WellnessTaskItem> evening;
//   final WellnessTaskSummary summary;
// }

// class WellnessJournalEntry {
//   WellnessJournalEntry({
//     required this.id,
//     required this.title,
//     required this.note,
//     required this.mood,
//     required this.entryType,
//     required this.formattedDate,
//     this.createdAt,
//   });

//   factory WellnessJournalEntry.fromJson(Map<String, dynamic> json) {
//     return WellnessJournalEntry(
//       id: json['id'] as int,
//       title: (json['title'] as String?)?.trim() ?? '',
//       note: (json['note'] as String?)?.trim() ?? '',
//       mood: (json['mood'] as String?)?.trim() ?? '',
//       entryType: (json['entry_type'] as String?)?.trim() ?? '',
//       formattedDate: (json['formatted_date'] as String?)?.trim() ?? '',
//       createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
//     );
//   }

//   final int id;
//   final String title;
//   final String note;
//   final String mood;
//   final String entryType;
//   final String formattedDate;
//   final DateTime? createdAt;

//   WellnessJournalEntry copyWith({
//     String? title,
//     String? note,
//     String? mood,
//     String? entryType,
//     String? formattedDate,
//     DateTime? createdAt,
//   }) {
//     return WellnessJournalEntry(
//       id: id,
//       title: title ?? this.title,
//       note: note ?? this.note,
//       mood: mood ?? this.mood,
//       entryType: entryType ?? this.entryType,
//       formattedDate: formattedDate ?? this.formattedDate,
//       createdAt: createdAt ?? this.createdAt,
//     );
//   }
// }

// enum SupportGroupAction { join, leave }

// class SupportGroupItem {
//   const SupportGroupItem({
//     required this.slug,
//     required this.name,
//     required this.description,
//     required this.icon,
//     required this.isJoined,
//   });

//   factory SupportGroupItem.fromJson(Map<String, dynamic> json) {
//     return SupportGroupItem(
//       slug: (json['slug'] as String?)?.trim() ?? '',
//       name: (json['name'] as String?)?.trim() ?? '',
//       description: (json['description'] as String?)?.trim() ?? '',
//       icon: (json['icon'] as String?)?.trim() ?? '',
//       isJoined: json['is_joined'] as bool? ?? false,
//     );
//   }

//   final String slug;
//   final String name;
//   final String description;
//   final String icon;
//   final bool isJoined;

//   SupportGroupItem copyWith({
//     bool? isJoined,
//   }) {
//     return SupportGroupItem(
//       slug: slug,
//       name: name,
//       description: description,
//       icon: icon,
//       isJoined: isJoined ?? this.isJoined,
//     );
//   }
// }

// enum SessionType { oneOnOne, group, workshop, webinar }

// extension SessionTypeX on SessionType {
//   String get apiValue => switch (this) {
//         SessionType.oneOnOne => 'one_on_one',
//         SessionType.group => 'group',
//         SessionType.workshop => 'workshop',
//         SessionType.webinar => 'webinar',
//       };

//   String get displayLabel => switch (this) {
//         SessionType.oneOnOne => 'One-on-One',
//         SessionType.group => 'Group',
//         SessionType.workshop => 'Workshop',
//         SessionType.webinar => 'Webinar',
//       };

//   static SessionType fromApi(String value) {
//     switch (value) {
//       case 'group':
//         return SessionType.group;
//       case 'workshop':
//         return SessionType.workshop;
//       case 'webinar':
//         return SessionType.webinar;
//       case 'one_on_one':
//       default:
//         return SessionType.oneOnOne;
//     }
//   }
// }

// class UpcomingSessionItem {
//   UpcomingSessionItem({
//     required this.id,
//     required this.title,
//     required this.sessionType,
//     required this.startTime,
//     required this.counsellorName,
//     required this.notes,
//     required this.isConfirmed,
//   });

//   factory UpcomingSessionItem.fromJson(Map<String, dynamic> json) {
//     return UpcomingSessionItem(
//       id: json['id'] as int,
//       title: (json['title'] as String?)?.trim() ?? '',
//       sessionType:
//           SessionTypeX.fromApi(json['session_type'] as String? ?? 'one_on_one'),
//       startTime: DateTime.tryParse(json['start_time'] as String? ?? '') ??
//           DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
//       counsellorName: (json['counsellor_name'] as String?)?.trim() ?? '',
//       notes: (json['notes'] as String?)?.trim() ?? '',
//       isConfirmed: json['is_confirmed'] as bool? ?? true,
//     );
//   }

//   final int id;
//   final String title;
//   final SessionType sessionType;
//   final DateTime startTime;
//   final String counsellorName;
//   final String notes;
//   final bool isConfirmed;

//   UpcomingSessionItem copyWith({
//     String? title,
//     SessionType? sessionType,
//     DateTime? startTime,
//     String? counsellorName,
//     String? notes,
//     bool? isConfirmed,
//   }) {
//     return UpcomingSessionItem(
//       id: id,
//       title: title ?? this.title,
//       sessionType: sessionType ?? this.sessionType,
//       startTime: startTime ?? this.startTime,
//       counsellorName: counsellorName ?? this.counsellorName,
//       notes: notes ?? this.notes,
//       isConfirmed: isConfirmed ?? this.isConfirmed,
//     );
//   }
// }

// class WalletInfo {
//   const WalletInfo({
//     required this.balance,
//     required this.rates,
//     required this.minimumBalance,
//   });

//   factory WalletInfo.fromJson(Map<String, dynamic> json) {
//     final ratesJson = json['rates'] as Map<String, dynamic>? ?? const {};
//     final minimumJson = json['minimum_balance'] as Map<String, dynamic>? ?? const {};
//     Map<String, int> _mapToInt(Map<String, dynamic> source) {
//       return {
//         for (final entry in source.entries) entry.key: (entry.value as num?)?.toInt() ?? 0,
//       };
//     }

//     return WalletInfo(
//       balance: json['wallet_minutes'] as int? ?? 0,
//       rates: _mapToInt(ratesJson),
//       minimumBalance: _mapToInt(minimumJson),
//     );
//   }

//   final int balance;
//   final Map<String, int> rates;
//   final Map<String, int> minimumBalance;

//   int get amount => balance;
//   int get minutes => balance;
// }

// class UserSettings {
//   const UserSettings({
//     this.fullName,
//     this.nickname,
//     this.phone,
//     this.age,
//     this.gender,
//     required this.notificationsEnabled,
//     required this.prefersDarkMode,
//     required this.language,
//   });

//   factory UserSettings.fromJson(Map<String, dynamic> json) {
//     return UserSettings(
//       fullName: (json['full_name'] as String?)?.trim(),
//       nickname: (json['nickname'] as String?)?.trim(),
//       phone: (json['phone'] as String?)?.trim(),
//       age: json['age'] as int?,
//       gender: (json['gender'] as String?)?.trim(),
//       notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
//       prefersDarkMode: json['prefers_dark_mode'] as bool? ?? false,
//       language: (json['language'] as String?)?.trim() ?? 'English',
//     );
//   }

//   final String? fullName;
//   final String? nickname;
//   final String? phone;
//   final int? age;
//   final String? gender;
//   final bool notificationsEnabled;
//   final bool prefersDarkMode;
//   final String language;

//   Map<String, dynamic> toJson() {
//     return {
//       'full_name': fullName,
//       'nickname': nickname,
//       'phone': phone,
//       'age': age,
//       'gender': gender,
//       'notifications_enabled': notificationsEnabled,
//       'prefers_dark_mode': prefersDarkMode,
//       'language': language,
//     }..removeWhere((key, value) => value == null);
//   }

//   UserSettings copyWith({
//     String? fullName,
//     String? nickname,
//     String? phone,
//     int? age,
//     String? gender,
//     bool? notificationsEnabled,
//     bool? prefersDarkMode,
//     String? language,
//   }) {
//     return UserSettings(
//       fullName: fullName ?? this.fullName,
//       nickname: nickname ?? this.nickname,
//       phone: phone ?? this.phone,
//       age: age ?? this.age,
//       gender: gender ?? this.gender,
//       notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
//       prefersDarkMode: prefersDarkMode ?? this.prefersDarkMode,
//       language: language ?? this.language,
//     );
//   }
// }

// enum MoodUpdateStatus { ok, limitReached }

// class MoodUpdateResult {
//   const MoodUpdateResult({
//     required this.status,
//     this.updatesUsed,
//     this.updatesRemaining,
//     this.resetAtLocal,
//     this.timezone,
//   });

//   factory MoodUpdateResult.success(Map<String, dynamic> json) {
//     return MoodUpdateResult(
//       status: MoodUpdateStatus.ok,
//       updatesUsed: json['updates_used'] as int?,
//       updatesRemaining: json['updates_remaining'] as int?,
//     );
//   }

//   factory MoodUpdateResult.limit(Map<String, dynamic> json) {
//     return MoodUpdateResult(
//       status: MoodUpdateStatus.limitReached,
//       resetAtLocal: json['reset_at_local'] as String?,
//       timezone: json['timezone'] as String?,
//       updatesUsed: json['updates_used'] as int?,
//       updatesRemaining: json['updates_remaining'] as int?,
//     );
//   }

//   final MoodUpdateStatus status;
//   final int? updatesUsed;
//   final int? updatesRemaining;
//   final String? resetAtLocal;
//   final String? timezone;
// }

// class AnalyticsMoodPoint {
//   const AnalyticsMoodPoint({
//     required this.date,
//     required this.average,
//     required this.count,
//   });

//   factory AnalyticsMoodPoint.fromJson(Map<String, dynamic> json) {
//     return AnalyticsMoodPoint(
//       date: DateTime.tryParse(json['date'] as String? ?? ''),
//       average: (json['average'] as num?)?.toDouble() ?? 0,
//       count: json['count'] as int? ?? 0,
//     );
//   }

//   final DateTime? date;
//   final double average;
//   final int count;
// }

// class AnalyticsReport {
//   const AnalyticsReport({
//     required this.weeklyMood,
//     required this.monthlyMood,
//     required this.tasks,
//     required this.sessions,
//     required this.walletMinutes,
//     required this.insight,
//   });

//   factory AnalyticsReport.fromJson(Map<String, dynamic> json) {
//     final moodJson = json['mood'] as Map<String, dynamic>? ?? {};
//     final tasksJson = json['tasks'] as Map<String, dynamic>? ?? {};
//     final sessionsJson = json['sessions'] as Map<String, dynamic>? ?? {};
//     final walletJson = json['wallet'] as Map<String, dynamic>? ?? {};
//     return AnalyticsReport(
//       weeklyMood: (moodJson['weekly'] as List<dynamic>? ?? [])
//           .whereType<Map<String, dynamic>>()
//           .map(AnalyticsMoodPoint.fromJson)
//           .toList(growable: false),
//       monthlyMood: (moodJson['monthly'] as List<dynamic>? ?? [])
//           .whereType<Map<String, dynamic>>()
//           .map(AnalyticsMoodPoint.fromJson)
//           .toList(growable: false),
//       tasks: TasksAnalytics.fromJson(tasksJson),
//       sessions: SessionsAnalytics.fromJson(sessionsJson),
//       walletMinutes: walletJson['minutes'] as int? ?? 0,
//       insight: (json['insight'] as String?)?.trim() ?? '',
//     );
//   }

//   final List<AnalyticsMoodPoint> weeklyMood;
//   final List<AnalyticsMoodPoint> monthlyMood;
//   final TasksAnalytics tasks;
//   final SessionsAnalytics sessions;
//   final int walletMinutes;
//   final String insight;
// }

// class TasksAnalytics {
//   const TasksAnalytics({
//     required this.total,
//     required this.completed,
//     required this.completionRate,
//     required this.byCategory,
//     required this.topTasks,
//   });

//   factory TasksAnalytics.fromJson(Map<String, dynamic> json) {
//     final categoryJson = json['by_category'] as Map<String, dynamic>? ?? {};
//     final topJson = json['top_tasks'] as List<dynamic>? ?? const [];
//     return TasksAnalytics(
//       total: json['total'] as int? ?? 0,
//       completed: json['completed'] as int? ?? 0,
//       completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
//       byCategory: {
//         for (final entry in categoryJson.entries)
//           entry.key.toString(): entry.value as int? ?? 0,
//       },
//       topTasks: topJson
//           .whereType<Map<String, dynamic>>()
//           .map((item) => TaskSummary(
//                 title: (item['title'] as String?)?.trim() ?? '',
//                 total: item['total'] as int? ?? 0,
//               ))
//           .toList(growable: false),
//     );
//   }

//   final int total;
//   final int completed;
//   final double completionRate;
//   final Map<String, int> byCategory;
//   final List<TaskSummary> topTasks;
// }

// class TaskSummary {
//   const TaskSummary({required this.title, required this.total});

//   final String title;
//   final int total;
// }

// class SessionsAnalytics {
//   const SessionsAnalytics({
//     required this.total,
//     required this.upcoming,
//     required this.completed,
//   });

//   factory SessionsAnalytics.fromJson(Map<String, dynamic> json) {
//     return SessionsAnalytics(
//       total: json['total'] as int? ?? 0,
//       upcoming: json['upcoming'] as int? ?? 0,
//       completed: json['completed'] as int? ?? 0,
//     );
//   }

//   final int total;
//   final int upcoming;
//   final int completed;
// }

// class GuidanceResourceItem {
//   const GuidanceResourceItem({
//     required this.id,
//     required this.type,
//     required this.title,
//     required this.subtitle,
//     required this.summary,
//     required this.category,
//     required this.duration,
//     required this.mediaUrl,
//     required this.thumbnail,
//     required this.isFeatured,
//   });

//   factory GuidanceResourceItem.fromJson(Map<String, dynamic> json) {
//     return GuidanceResourceItem(
//       id: json['id'] as int,
//       type: (json['resource_type'] as String?)?.trim() ?? 'article',
//       title: (json['title'] as String?)?.trim() ?? '',
//       subtitle: (json['subtitle'] as String?)?.trim() ?? '',
//       summary: (json['summary'] as String?)?.trim() ?? '',
//       category: (json['category'] as String?)?.trim() ?? '',
//       duration: (json['duration'] as String?)?.trim() ?? '',
//       mediaUrl: (json['media_url'] as String?)?.trim() ?? '',
//       thumbnail: (json['thumbnail'] as String?)?.trim() ?? '',
//       isFeatured: json['is_featured'] as bool? ?? false,
//     );
//   }

//   final int id;
//   final String type;
//   final String title;
//   final String subtitle;
//   final String summary;
//   final String category;
//   final String duration;
//   final String mediaUrl;
//   final String thumbnail;
//   final bool isFeatured;
// }

// class GuidanceResponse {
//   const GuidanceResponse({required this.resources, required this.categories});

//   factory GuidanceResponse.fromJson(Map<String, dynamic> json) {
//     final resources = (json['resources'] as List<dynamic>? ?? [])
//         .whereType<Map<String, dynamic>>()
//         .map(GuidanceResourceItem.fromJson)
//         .toList(growable: false);
//     final categories = (json['categories'] as List<dynamic>? ?? [])
//         .whereType<String>()
//         .toList(growable: false);
//     return GuidanceResponse(resources: resources, categories: categories);
//   }

//   final List<GuidanceResourceItem> resources;
//   final List<String> categories;
// }

// class MusicTrackItem {
//   const MusicTrackItem({
//     required this.id,
//     required this.title,
//     required this.description,
//     required this.durationSeconds,
//     required this.durationFormatted,
//     required this.audioUrl,
//     required this.mood,
//     required this.thumbnail,
//   });

//   factory MusicTrackItem.fromJson(Map<String, dynamic> json) {
//     return MusicTrackItem(
//       id: json['id'] as int,
//       title: (json['title'] as String?)?.trim() ?? '',
//       description: (json['description'] as String?)?.trim() ?? '',
//       durationSeconds: json['duration_seconds'] as int? ?? 0,
//       durationFormatted: (json['duration'] as String?)?.trim() ?? '',
//       audioUrl: (json['audio_url'] as String?)?.trim() ?? '',
//       mood: (json['mood'] as String?)?.trim() ?? '',
//       thumbnail: (json['thumbnail'] as String?)?.trim() ?? '',
//     );
//   }

//   final int id;
//   final String title;
//   final String description;
//   final int durationSeconds;
//   final String durationFormatted;
//   final String audioUrl;
//   final String mood;
//   final String thumbnail;
// }

// class MusicTracksResponse {
//   const MusicTracksResponse({
//     required this.tracks,
//     required this.moods,
//     required this.count,
//   });

//   final List<MusicTrackItem> tracks;
//   final List<String> moods;
//   final int count;
// }

// class MindCareBoosterItem {
//   const MindCareBoosterItem({
//     required this.id,
//     required this.title,
//     required this.subtitle,
//     required this.description,
//     required this.category,
//     required this.icon,
//     required this.actionLabel,
//     required this.prompt,
//     required this.estimatedSeconds,
//     required this.resourceUrl,
//   });

//   factory MindCareBoosterItem.fromJson(Map<String, dynamic> json) {
//     return MindCareBoosterItem(
//       id: json['id'] as int,
//       title: (json['title'] as String?)?.trim() ?? '',
//       subtitle: (json['subtitle'] as String?)?.trim() ?? '',
//       description: (json['description'] as String?)?.trim() ?? '',
//       category: (json['category'] as String?)?.trim() ?? '',
//       icon: (json['icon'] as String?)?.trim() ?? '',
//       actionLabel: (json['action_label'] as String?)?.trim() ?? 'Start',
//       prompt: (json['prompt'] as String?)?.trim() ?? '',
//       estimatedSeconds: json['estimated_seconds'] as int? ?? 0,
//       resourceUrl: (json['resource_url'] as String?)?.trim() ?? '',
//     );
//   }

//   final int id;
//   final String title;
//   final String subtitle;
//   final String description;
//   final String category;
//   final String icon;
//   final String actionLabel;
//   final String prompt;
//   final int estimatedSeconds;
//   final String resourceUrl;
// }

// class MindCareBoostersResponse {
//   const MindCareBoostersResponse({
//     required this.boosters,
//     required this.categories,
//     required this.groupedByCategory,
//   });

//   final List<MindCareBoosterItem> boosters;
//   final List<String> categories;
//   final Map<String, List<MindCareBoosterItem>> groupedByCategory;
// }

// class MeditationSessionItem {
//   const MeditationSessionItem({
//     required this.id,
//     required this.title,
//     required this.subtitle,
//     required this.description,
//     required this.category,
//     required this.durationMinutes,
//     required this.difficulty,
//     required this.audioUrl,
//     required this.videoUrl,
//     required this.isFeatured,
//     required this.thumbnail,
//   });

//   factory MeditationSessionItem.fromJson(Map<String, dynamic> json) {
//     return MeditationSessionItem(
//       id: json['id'] as int,
//       title: (json['title'] as String?)?.trim() ?? '',
//       subtitle: (json['subtitle'] as String?)?.trim() ?? '',
//       description: (json['description'] as String?)?.trim() ?? '',
//       category: (json['category'] as String?)?.trim() ?? '',
//       durationMinutes: json['duration_minutes'] as int? ?? 0,
//       difficulty: (json['difficulty'] as String?)?.trim() ?? '',
//       audioUrl: (json['audio_url'] as String?)?.trim() ?? '',
//       videoUrl: (json['video_url'] as String?)?.trim() ?? '',
//       isFeatured: json['is_featured'] as bool? ?? false,
//       thumbnail: (json['thumbnail'] as String?)?.trim() ?? '',
//     );
//   }

//   final int id;
//   final String title;
//   final String subtitle;
//   final String description;
//   final String category;
//   final int durationMinutes;
//   final String difficulty;
//   final String audioUrl;
//   final String videoUrl;
//   final bool isFeatured;
//   final String thumbnail;
// }

// class MeditationSessionsResponse {
//   const MeditationSessionsResponse({
//     required this.sessions,
//     required this.categories,
//     required this.groupedByCategory,
//     required this.featured,
//   });

//   final List<MeditationSessionItem> sessions;
//   final List<String> categories;
//   final Map<String, List<MeditationSessionItem>> groupedByCategory;
//   final List<MeditationSessionItem> featured;
// }

// class LegacyGuidelineSection {
//   const LegacyGuidelineSection({
//     required this.title,
//     required this.bullets,
//   });

//   factory LegacyGuidelineSection.fromJson(Map<String, dynamic> json) {
//     final bullets = (json['bullets'] as List<dynamic>? ?? [])
//         .whereType<String>()
//         .toList(growable: false);
//     return LegacyGuidelineSection(
//       title: (json['title'] as String?)?.trim() ?? '',
//       bullets: bullets,
//     );
//   }

//   final String title;
//   final List<String> bullets;
// }

// class LegacyGuidelinesResponse {
//   const LegacyGuidelinesResponse({required this.sections});

//   factory LegacyGuidelinesResponse.fromJson(Map<String, dynamic> json) {
//     final sections = (json['sections'] as List<dynamic>? ?? [])
//         .whereType<Map<String, dynamic>>()
//         .map(LegacyGuidelineSection.fromJson)
//         .toList(growable: false);
//     return LegacyGuidelinesResponse(sections: sections);
//   }

//   final List<LegacyGuidelineSection> sections;
// }

// class LegacyCounsellor {
//   const LegacyCounsellor({
//     required this.name,
//     required this.expertise,
//     required this.rating,
//     required this.languages,
//     required this.tagline,
//     required this.isAvailableNow,
//   });

//   factory LegacyCounsellor.fromJson(Map<String, dynamic> json) {
//     return LegacyCounsellor(
//       name: (json['name'] as String?)?.trim() ?? '',
//       expertise: (json['expertise'] as List<dynamic>? ?? [])
//           .whereType<String>()
//           .toList(growable: false),
//       rating: (json['rating'] as num?)?.toDouble() ?? 0,
//       languages: (json['languages'] as List<dynamic>? ?? [])
//           .whereType<String>()
//           .toList(growable: false),
//       tagline: (json['tagline'] as String?)?.trim() ?? '',
//       isAvailableNow: json['is_available_now'] as bool? ?? false,
//     );
//   }

//   final String name;
//   final List<String> expertise;
//   final double rating;
//   final List<String> languages;
//   final String tagline;
//   final bool isAvailableNow;
// }

// class LegacyBreathingConfig {
//   const LegacyBreathingConfig({
//     required this.cycleOptions,
//     required this.tip,
//   });

//   factory LegacyBreathingConfig.fromJson(Map<String, dynamic> json) {
//     final options = (json['cycle_options'] as List<dynamic>? ?? [])
//         .whereType<int>()
//         .toList(growable: false);
//     return LegacyBreathingConfig(
//       cycleOptions: options,
//       tip: (json['tip'] as String?)?.trim() ?? '',
//     );
//   }

//   final List<int> cycleOptions;
//   final String tip;
// }

// class LegacyAssessmentQuestion {
//   const LegacyAssessmentQuestion({
//     required this.question,
//     required this.options,
//   });

//   factory LegacyAssessmentQuestion.fromJson(Map<String, dynamic> json) {
//     final options = (json['options'] as List<dynamic>? ?? [])
//         .whereType<String>()
//         .toList(growable: false);
//     return LegacyAssessmentQuestion(
//       question: (json['question'] as String?)?.trim() ?? '',
//       options: options,
//     );
//   }

//   final String question;
//   final List<String> options;
// }

// class LegacyAdvancedCareService {
//   const LegacyAdvancedCareService({
//     required this.title,
//     required this.description,
//     required this.benefits,
//   });

//   factory LegacyAdvancedCareService.fromJson(Map<String, dynamic> json) {
//     final benefits = (json['benefits'] as List<dynamic>? ?? [])
//         .whereType<String>()
//         .toList(growable: false);
//     return LegacyAdvancedCareService(
//       title: (json['title'] as String?)?.trim() ?? '',
//       description: (json['description'] as String?)?.trim() ?? '',
//       benefits: benefits,
//     );
//   }

//   final String title;
//   final String description;
//   final List<String> benefits;
// }

// class LegacyAdvancedCareSpecialist {
//   const LegacyAdvancedCareSpecialist({
//     required this.name,
//     required this.specialization,
//     required this.experienceYears,
//   });

//   factory LegacyAdvancedCareSpecialist.fromJson(Map<String, dynamic> json) {
//     return LegacyAdvancedCareSpecialist(
//       name: (json['name'] as String?)?.trim() ?? '',
//       specialization: (json['specialization'] as String?)?.trim() ?? '',
//       experienceYears: json['experience_years'] as int? ?? 0,
//     );
//   }

//   final String name;
//   final String specialization;
//   final int experienceYears;
// }

// class LegacyAdvancedCareResponse {
//   const LegacyAdvancedCareResponse({
//     required this.services,
//     required this.specialists,
//   });

//   factory LegacyAdvancedCareResponse.fromJson(Map<String, dynamic> json) {
//     final services = (json['services'] as List<dynamic>? ?? [])
//         .whereType<Map<String, dynamic>>()
//         .map(LegacyAdvancedCareService.fromJson)
//         .toList(growable: false);
//     final specialists = (json['specialists'] as List<dynamic>? ?? [])
//         .whereType<Map<String, dynamic>>()
//         .map(LegacyAdvancedCareSpecialist.fromJson)
//         .toList(growable: false);
//     return LegacyAdvancedCareResponse(
//       services: services,
//       specialists: specialists,
//     );
//   }

//   final List<LegacyAdvancedCareService> services;
//   final List<LegacyAdvancedCareSpecialist> specialists;
// }

// class LegacyFeatureSection {
//   const LegacyFeatureSection({
//     required this.heading,
//     required this.bullets,
//   });

//   factory LegacyFeatureSection.fromJson(Map<String, dynamic> json) {
//     final bullets = (json['bullets'] as List<dynamic>? ?? [])
//         .whereType<String>()
//         .toList(growable: false);
//     return LegacyFeatureSection(
//       heading: (json['heading'] as String?)?.trim() ?? '',
//       bullets: bullets,
//     );
//   }

//   final String heading;
//   final List<String> bullets;
// }

// class LegacyFeatureDetail {
//   const LegacyFeatureDetail({required this.title, required this.sections});

//   factory LegacyFeatureDetail.fromJson(Map<String, dynamic> json) {
//     final sections = (json['sections'] as List<dynamic>? ?? [])
//         .whereType<Map<String, dynamic>>()
//         .map(LegacyFeatureSection.fromJson)
//         .toList(growable: false);
//     return LegacyFeatureDetail(
//       title: (json['title'] as String?)?.trim() ?? '',
//       sections: sections,
//     );
//   }

//   final String title;
//   final List<LegacyFeatureSection> sections;
// }

// class ApiClient {
//   static const String _defaultBase = 'http://127.0.0.1:8000/api';
//   static const String base =
//       String.fromEnvironment('BACKEND_BASE_URL', defaultValue: _defaultBase);

//   final FlutterSecureStorage _storage = const FlutterSecureStorage(
//     aOptions: AndroidOptions(
//       encryptedSharedPreferences: true,
//     ),
//     iOptions: IOSOptions(
//       accessibility: KeychainAccessibility.first_unlock_this_device,
//     ),
//     webOptions: WebOptions(),
//   );

//   Future<void> _saveTokens(String access, String refresh) async {
//     await _storage.write(key: 'access', value: access);
//     await _storage.write(key: 'refresh', value: refresh);
//   }

//   Future<String?> get _accessToken async => _storage.read(key: 'access');

//   Future<String?> get _refreshToken async => _storage.read(key: 'refresh');

//   Future<void> logout() async {
//     await _storage.deleteAll();
//   }

//   String _errorFromResponse(http.Response response, {String? fallback}) {
//     try {
//       final decoded = jsonDecode(response.body);
//       if (decoded is Map<String, dynamic>) {
//         if (decoded['detail'] != null) {
//           return decoded['detail'].toString();
//         }
//         final buffer = StringBuffer();
//         decoded.forEach((key, value) {
//           if (value == null) return;
//           if (value is List) {
//             buffer.writeAll(value.map((e) => e.toString()), ' ');
//           } else {
//             buffer.write(value.toString());
//           }
//           buffer.write(' ');
//         });
//         final result = buffer.toString().trim();
//         if (result.isNotEmpty) {
//           return result;
//         }
//       } else if (decoded is List) {
//         final result = decoded.map((e) => e.toString()).join(' ').trim();
//         if (result.isNotEmpty) {
//           return result;
//         }
//       } else if (decoded != null) {
//         final result = decoded.toString().trim();
//         if (result.isNotEmpty) {
//           return result;
//         }
//       }
//     } catch (_) {
//       // ignore json errors
//     }
//     return fallback ?? 'Request failed with status ${response.statusCode}';
//   }

//   Future<(bool, String?)> sendRegistrationOtp(String email) async {
//     final response = await http.post(
//       Uri.parse('$base/auth/send-otp/'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email}),
//     );

//     if (response.statusCode == 200) {
//       return (true, null);
//     }

//     return (
//       false,
//       _errorFromResponse(response, fallback: 'Failed to send OTP')
//     );
//   }

//   Future<(bool, String?, String?)> verifyRegistrationOtp({
//     required String email,
//     required String code,
//   }) async {
//     final response = await http.post(
//       Uri.parse('$base/auth/verify-otp/'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'email': email, 'code': code}),
//     );

//     if (response.statusCode == 200) {
//       try {
//         final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//         final token = decoded['token'] as String?;
//         return (true, null, token);
//       } catch (_) {
//         return (true, null, null);
//       }
//     }

//     return (
//       false,
//       _errorFromResponse(response, fallback: 'OTP verification failed'),
//       null
//     );
//   }

//   Future<(bool, String?)> register({
//     required String username,
//     String? email,
//     required String password,
//     String? fullName,
//     String? nickname,
//     String? phone,
//     int? age,
//     String? gender,
//     required String otpToken,
//   }) async {
//     final payload = <String, dynamic>{
//       'username': username,
//       'password': password,
//       'otp_token': otpToken,
//     };

//     void addIfPresent(String key, dynamic value) {
//       if (value == null) return;
//       if (value is String && value.trim().isEmpty) return;
//       payload[key] = value;
//     }

//     addIfPresent('email', email);
//     addIfPresent('full_name', fullName);
//     addIfPresent('nickname', nickname);
//     addIfPresent('phone', phone);
//     if (age != null) {
//       payload['age'] = age;
//     }
//     addIfPresent('gender', gender);

//     final response = await http.post(
//       Uri.parse('$base/auth/register/'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode(payload),
//     );

//     if (response.statusCode == 201) {
//       return (true, null);
//     }

//     return (
//       false,
//       _errorFromResponse(response, fallback: 'Registration failed')
//     );
//   }

//   Future<(bool, String?)> login(String username, String password) async {
//     final response = await http.post(
//       Uri.parse('$base/auth/token/'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'username': username,
//         'password': password,
//       }),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       await _saveTokens(
//           decoded['access'] as String, decoded['refresh'] as String);
//       return (true, null);
//     }

//     return (
//       false,
//       _errorFromResponse(response, fallback: 'Invalid credentials')
//     );
//   }

//   Future<bool> _refreshTokenIfNeeded() async {
//     final refresh = await _refreshToken;
//     if (refresh == null) {
//       return false;
//     }

//     final response = await http.post(
//       Uri.parse('$base/auth/token/refresh/'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'refresh': refresh}),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       if (decoded['access'] != null) {
//         await _storage.write(key: 'access', value: decoded['access'] as String);
//         return true;
//       }
//     }

//     return false;
//   }

//   Map<String, String> _headers(String? access,
//       [Map<String, String>? overrides]) {
//     return {
//       'Accept': 'application/json',
//           if (access != null) 'Authorization': 'Bearer $access',
//       if (overrides != null) ...overrides,
//     };
//   }

//   String _formatDate(DateTime value) {
//     final local = value.toLocal();
//     String two(int n) => n.toString().padLeft(2, '0');
//     return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-${two(local.day)}';
//   }

//   String _formatTime(DateTime value) {
//     final local = value.toLocal();
//     String two(int n) => n.toString().padLeft(2, '0');
//     return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
//   }

//   Future<http.Response> _sendAuthorized(
//     Future<http.Response> Function(String? accessToken) makeRequest,
//   ) async {
//     Future<http.Response> attempt() async {
//       final access = await _accessToken;
//       if (access == null) {
//         return http.Response('', 401);
//       }
//       return makeRequest(access);
//     }

//     var response = await attempt();
//     if (response.statusCode == 401 && await _refreshTokenIfNeeded()) {
//       response = await attempt();
//     }
//     return response;
//   }

//   String _extractErrorMessage(http.Response response) {
//     if (response.body.isEmpty) {
//       return 'Request failed with status ${response.statusCode}';
//     }
//     try {
//       final Object? decoded = jsonDecode(response.body);
//       if (decoded is Map<String, dynamic>) {
//         final detail = decoded['detail'];
//         if (detail is String && detail.isNotEmpty) {
//           return detail;
//         }
//         final message = decoded['message'];
//         if (message is String && message.isNotEmpty) {
//           return message;
//         }
//         if (decoded.values.isNotEmpty) {
//           final dynamic firstValue = decoded.values.first;
//           if (firstValue is List && firstValue.isNotEmpty) {
//             final first = firstValue.first;
//             if (first is String) {
//               return first;
//             }
//           } else if (firstValue is String) {
//             return firstValue;
//           }
//         }
//       } else if (decoded is List && decoded.isNotEmpty) {
//         final first = decoded.first;
//         if (first is String) {
//           return first;
//         }
//       }
//     } catch (_) {
//       // ignore decode errors and fall through to raw body
//     }
//     return response.body;
//   }

//   Future<Map<String, dynamic>?> getProfile() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/profile/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body) as Map<String, dynamic>;
//     }
//     return null;
//   }

//   Future<UserSettings> fetchUserSettings() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/settings/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return UserSettings.fromJson(decoded);
//     }

//     throw ApiClientException(
//       'Unable to load settings: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<UserSettings> updateUserSettings({
//     String? fullName,
//     String? nickname,
//     String? phone,
//     int? age,
//     String? gender,
//     bool? notificationsEnabled,
//     bool? prefersDarkMode,
//     String? language,
//   }) async {
//     final payload = <String, dynamic>{};
//     if (fullName != null) payload['full_name'] = fullName;
//     if (nickname != null) payload['nickname'] = nickname;
//     if (phone != null) payload['phone'] = phone;
//     if (age != null) payload['age'] = age;
//     if (gender != null) payload['gender'] = gender;
//     if (notificationsEnabled != null) {
//       payload['notifications_enabled'] = notificationsEnabled;
//     }
//     if (prefersDarkMode != null) {
//       payload['prefers_dark_mode'] = prefersDarkMode;
//     }
//     if (language != null) payload['language'] = language;

//     final response = await _sendAuthorized(
//       (access) => http.put(
//         Uri.parse('$base/settings/'),
//         headers: _headers(access, {'Content-Type': 'application/json'}),
//         body: jsonEncode(payload),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return UserSettings.fromJson(decoded);
//     }

//     throw ApiClientException(
//       'Unable to update settings: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<MoodUpdateResult> updateMood({
//     required int value,
//     String? timezone,
//   }) async {
//     final payload = <String, dynamic>{
//       'value': value.clamp(1, 5),
//     };
//     if (timezone != null && timezone.trim().isNotEmpty) {
//       payload['timezone'] = timezone.trim();
//     }

//     final response = await _sendAuthorized(
//       (access) => http.post(
//         Uri.parse('$base/mood/'),
//         headers: _headers(access, {'Content-Type': 'application/json'}),
//         body: jsonEncode(payload),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return MoodUpdateResult.success(decoded);
//     }

//     if (response.statusCode == 429) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return MoodUpdateResult.limit(decoded);
//     }

//     throw ApiClientException(
//       'Unable to update mood: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<WellnessTasksResponse> fetchWellnessTasks() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/wellness/tasks/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       final tasksJson = (decoded['tasks'] as List<dynamic>? ?? [])
//           .whereType<Map<String, dynamic>>()
//           .toList(growable: false);
//       final tasks =
//           tasksJson.map(WellnessTaskItem.fromJson).toList(growable: false);

//       final summaryJson = decoded['summary'] as Map<String, dynamic>? ?? {};
//       final summary = WellnessTaskSummary(
//         total: summaryJson['total'] as int? ?? tasks.length,
//         completed: summaryJson['completed'] as int? ??
//             tasks.where((t) => t.isCompleted).length,
//       );

//       final daily = tasks
//           .where((task) => task.category == WellnessTaskCategory.daily)
//           .toList();
//       final evening = tasks
//           .where((task) => task.category == WellnessTaskCategory.evening)
//           .toList();

//       return WellnessTasksResponse(
//         daily: daily,
//         evening: evening,
//         summary: summary,
//       );
//     }

//     if (response.statusCode == 401) {
//       throw ApiClientException(
//           'You need to log in to view your wellness plan.');
//     }

//     throw ApiClientException(
//       'Unable to fetch wellness tasks: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<WellnessTaskItem> toggleWellnessTaskCompletion(
//     int taskId,
//     bool isCompleted,
//   ) async {
//     final response = await _sendAuthorized(
//       (access) => http.patch(
//         Uri.parse('$base/wellness/tasks/$taskId/'),
//         headers: _headers(access, {'Content-Type': 'application/json'}),
//         body: jsonEncode({'is_completed': isCompleted}),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return WellnessTaskItem.fromJson(decoded);
//     }

//     if (response.statusCode == 404) {
//       throw ApiClientException('Task not found');
//     }

//     throw ApiClientException(
//       'Unable to update task: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<WellnessTaskItem> createWellnessTask({
//     required String title,
//     required WellnessTaskCategory category,
//   }) async {
//     final response = await _sendAuthorized(
//       (access) => http.post(
//         Uri.parse('$base/wellness/tasks/'),
//         headers: _headers(access, {'Content-Type': 'application/json'}),
//         body: jsonEncode({
//           'title': title,
//           'category': category.apiValue,
//         }),
//       ),
//     );

//     if (response.statusCode == 201) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return WellnessTaskItem.fromJson(decoded);
//     }

//     throw ApiClientException(
//       'Unable to add task: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<void> deleteWellnessTask(int taskId) async {
//     final response = await _sendAuthorized(
//       (access) => http.delete(
//         Uri.parse('$base/wellness/tasks/$taskId/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 204) {
//       return;
//     }

//     if (response.statusCode == 404) {
//       throw ApiClientException('Task already removed');
//     }

//     throw ApiClientException(
//       'Unable to delete task: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<List<WellnessJournalEntry>> fetchWellnessJournalEntries() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/wellness/journals/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       final entriesJson = (decoded['entries'] as List<dynamic>? ?? [])
//           .whereType<Map<String, dynamic>>()
//           .toList(growable: false);
//       return entriesJson.map(WellnessJournalEntry.fromJson).toList();
//     }

//     if (response.statusCode == 401) {
//       throw ApiClientException('You need to log in to view journal entries.');
//     }

//     throw ApiClientException(
//       'Unable to fetch journal entries: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<WellnessJournalEntry> createWellnessJournalEntry({
//     required String title,
//     required String note,
//     required String mood,
//     required String entryType,
//   }) async {
//     final response = await _sendAuthorized(
//       (access) => http.post(
//         Uri.parse('$base/wellness/journals/'),
//         headers: _headers(access, {'Content-Type': 'application/json'}),
//         body: jsonEncode({
//           'title': title,
//           'note': note,
//           'mood': mood,
//           'entry_type': entryType,
//         }),
//       ),
//     );

//     if (response.statusCode == 201) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return WellnessJournalEntry.fromJson(decoded);
//     }

//     throw ApiClientException(
//       'Unable to save journal entry: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<void> deleteWellnessJournalEntry(int entryId) async {
//     final response = await _sendAuthorized(
//       (access) => http.delete(
//         Uri.parse('$base/wellness/journals/$entryId/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 204) {
//       return;
//     }

//     if (response.statusCode == 404) {
//       throw ApiClientException('Entry already removed');
//     }

//     throw ApiClientException(
//       'Unable to delete journal entry: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<WalletInfo> getWallet() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/wallet/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return WalletInfo.fromJson(decoded);
//     }

//     throw ApiClientException(
//       'Unable to fetch wallet details: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<int> rechargeWallet(int amount) async {
//     final response = await _sendAuthorized(
//       (access) => http.post(
//         Uri.parse('$base/wallet/recharge/'),
//         headers: _headers(access, {'Content-Type': 'application/json'}),
//         body: jsonEncode({'amount': amount}),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return decoded['wallet_minutes'] as int? ?? amount;
//     }

//     throw ApiClientException(
//       'Unable to recharge wallet: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<List<SupportGroupItem>> fetchSupportGroups() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/support-groups/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       final groupsJson = (decoded['groups'] as List<dynamic>? ?? [])
//           .whereType<Map<String, dynamic>>()
//           .toList(growable: false);
//       return groupsJson.map(SupportGroupItem.fromJson).toList(growable: false);
//     }

//     throw ApiClientException(
//       'Unable to load support groups: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<SupportGroupItem> updateSupportGroupMembership({
//     required String slug,
//     required SupportGroupAction action,
//   }) async {
//     final response = await _sendAuthorized(
//       (access) => http.post(
//         Uri.parse('$base/support-groups/'),
//         headers: _headers(access, {'Content-Type': 'application/json'}),
//         body: jsonEncode({
//           'slug': slug,
//           'action': action == SupportGroupAction.join ? 'join' : 'leave',
//         }),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       final groupJson = decoded['group'] as Map<String, dynamic>? ?? {};
//       return SupportGroupItem.fromJson(groupJson);
//     }

//     throw ApiClientException(
//       'Unable to update group membership: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<List<UpcomingSessionItem>> fetchUpcomingSessions() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/sessions/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as List<dynamic>? ?? [];
//       return decoded
//           .whereType<Map<String, dynamic>>()
//           .map(UpcomingSessionItem.fromJson)
//           .toList(growable: false);
//     }

//     throw ApiClientException(
//       'Unable to load sessions: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<UpcomingSessionItem> createUpcomingSession({
//     required String title,
//     required SessionType sessionType,
//     required DateTime startTime,
//     required String counsellorName,
//     String? notes,
//     bool isConfirmed = true,
//   }) async {
//     final response = await _sendAuthorized(
//       (access) => http.post(
//         Uri.parse('$base/sessions/'),
//         headers: _headers(access, {'Content-Type': 'application/json'}),
//         body: jsonEncode({
//           'title': title,
//           'session_type': sessionType.apiValue,
//           'start_time': startTime.toUtc().toIso8601String(),
//           'counsellor_name': counsellorName,
//           'notes': notes,
//           'is_confirmed': isConfirmed,
//         }),
//       ),
//     );

//     if (response.statusCode == 201) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return UpcomingSessionItem.fromJson(decoded);
//     }

//     throw ApiClientException(
//       'Unable to create session: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<UpcomingSessionItem> updateUpcomingSession({
//     required int sessionId,
//     String? title,
//     SessionType? sessionType,
//     DateTime? startTime,
//     String? counsellorName,
//     String? notes,
//     bool? isConfirmed,
//   }) async {
//     final payload = <String, dynamic>{};
//     if (title != null) payload['title'] = title;
//     if (sessionType != null) payload['session_type'] = sessionType.apiValue;
//     if (startTime != null)
//       payload['start_time'] = startTime.toUtc().toIso8601String();
//     if (counsellorName != null) payload['counsellor_name'] = counsellorName;
//     if (notes != null) payload['notes'] = notes;
//     if (isConfirmed != null) payload['is_confirmed'] = isConfirmed;

//     final response = await _sendAuthorized(
//       (access) => http.patch(
//         Uri.parse('$base/sessions/$sessionId/'),
//         headers: _headers(access, {'Content-Type': 'application/json'}),
//         body: jsonEncode(payload),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return UpcomingSessionItem.fromJson(decoded);
//     }

//     throw ApiClientException(
//       'Unable to update session: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<void> deleteUpcomingSession(int sessionId) async {
//     final response = await _sendAuthorized(
//       (access) => http.delete(
//         Uri.parse('$base/sessions/$sessionId/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 204) {
//       return;
//     }

//     if (response.statusCode == 404) {
//       throw ApiClientException('Session already removed');
//     }

//     throw ApiClientException(
//       'Unable to delete session: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<UpcomingSessionItem> scheduleQuickSession(
//     DateTime startTime, {
//     String? title,
//     String? notes,
//   }) async {
//     final payload = <String, dynamic>{
//       'date': _formatDate(startTime),
//       'time': _formatTime(startTime),
//     };
//     if (title != null && title.trim().isNotEmpty) {
//       payload['title'] = title.trim();
//     }
//     if (notes != null && notes.trim().isNotEmpty) {
//       payload['notes'] = notes.trim();
//     }

//     final response = await _sendAuthorized(
//       (access) => http.post(
//         Uri.parse('$base/sessions/quick/'),
//         headers: _headers(access, {'Content-Type': 'application/json'}),
//         body: jsonEncode(payload),
//       ),
//     );

//     if (response.statusCode == 201) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       final sessionJson = decoded['session'] as Map<String, dynamic>? ?? {};
//       return UpcomingSessionItem.fromJson(sessionJson);
//     }

//     throw ApiClientException(
//       'Unable to schedule session: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<AnalyticsReport> fetchAnalyticsReport() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/reports/analytics/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return AnalyticsReport.fromJson(decoded);
//     }

//     throw ApiClientException(
//       'Unable to load analytics: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<GuidanceResponse> fetchGuidanceResources({
//     String? type,
//     String? category,
//     bool featured = false,
//   }) async {
//     final params = <String, String>{};
//     if (type != null && type.trim().isNotEmpty) {
//       params['type'] = type.trim();
//     }
//     if (category != null && category.trim().isNotEmpty) {
//       params['category'] = category.trim();
//     }
//     if (featured) {
//       params['featured'] = 'true';
//     }

//     final uri = params.isEmpty
//         ? Uri.parse('$base/guidance/resources/')
//         : Uri.parse('$base/guidance/resources/').replace(queryParameters: params);

//     final response = await _sendAuthorized(
//       (access) => http.get(
//         uri,
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return GuidanceResponse.fromJson(decoded);
//     }

//     throw ApiClientException(
//       'Unable to load resources: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<MusicTracksResponse> fetchMusicTracks({String? mood}) async {
//     final params = <String, String>{};
//     if (mood != null && mood.trim().isNotEmpty) {
//       params['mood'] = mood.trim();
//     }
//     final uri = params.isEmpty
//         ? Uri.parse('$base/content/music/')
//         : Uri.parse('$base/content/music/').replace(queryParameters: params);

//     final response = await _sendAuthorized(
//       (access) => http.get(uri, headers: _headers(access)),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       final tracksJson = (decoded['tracks'] as List<dynamic>? ?? [])
//           .whereType<Map<String, dynamic>>()
//           .toList(growable: false);
//       final moods = (decoded['moods'] as List<dynamic>? ?? [])
//           .whereType<String>()
//           .toList(growable: false);
//       final count = decoded['count'] as int? ?? tracksJson.length;

//       final tracks =
//           tracksJson.map(MusicTrackItem.fromJson).toList(growable: false);
//       return MusicTracksResponse(tracks: tracks, moods: moods, count: count);
//     }

//     throw ApiClientException(
//       'Unable to load music tracks: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<MindCareBoostersResponse> fetchMindCareBoosters(
//       {String? category}) async {
//     final params = <String, String>{};
//     if (category != null && category.trim().isNotEmpty) {
//       params['category'] = category.trim();
//     }
//     final uri = params.isEmpty
//         ? Uri.parse('$base/content/boosters/')
//         : Uri.parse('$base/content/boosters/')
//             .replace(queryParameters: params);

//     final response = await _sendAuthorized(
//       (access) => http.get(uri, headers: _headers(access)),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       final boostersJson = (decoded['boosters'] as List<dynamic>? ?? [])
//           .whereType<Map<String, dynamic>>()
//           .toList(growable: false);
//       final categories = (decoded['categories'] as List<dynamic>? ?? [])
//           .whereType<String>()
//           .toList(growable: false);
//       final groupedRaw = decoded['grouped'] as Map<String, dynamic>? ?? {};
//       final grouped = <String, List<MindCareBoosterItem>>{};
//       groupedRaw.forEach((key, value) {
//         final items = (value as List<dynamic>? ?? [])
//             .whereType<Map<String, dynamic>>()
//             .map(MindCareBoosterItem.fromJson)
//             .toList(growable: false);
//         grouped[key.toString()] = items;
//       });

//       final boosters = boostersJson
//           .map(MindCareBoosterItem.fromJson)
//           .toList(growable: false);
//       return MindCareBoostersResponse(
//         boosters: boosters,
//         categories: categories,
//         groupedByCategory: grouped,
//       );
//     }

//     throw ApiClientException(
//       'Unable to load boosters: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<MeditationSessionsResponse> fetchMeditationSessions({
//     String? category,
//     String? difficulty,
//     bool featured = false,
//   }) async {
//     final params = <String, String>{};
//     if (category != null && category.trim().isNotEmpty) {
//       params['category'] = category.trim();
//     }
//     if (difficulty != null && difficulty.trim().isNotEmpty) {
//       params['difficulty'] = difficulty.trim();
//     }
//     if (featured) {
//       params['featured'] = 'true';
//     }

//     final uri = params.isEmpty
//         ? Uri.parse('$base/content/meditations/')
//         : Uri.parse('$base/content/meditations/')
//             .replace(queryParameters: params);

//     final response = await _sendAuthorized(
//       (access) => http.get(uri, headers: _headers(access)),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       final sessionsJson = (decoded['sessions'] as List<dynamic>? ?? [])
//           .whereType<Map<String, dynamic>>()
//           .toList(growable: false);
//       final categories = (decoded['categories'] as List<dynamic>? ?? [])
//           .whereType<String>()
//           .toList(growable: false);
//       final groupedRaw = decoded['grouped'] as Map<String, dynamic>? ?? {};
//       final grouped = <String, List<MeditationSessionItem>>{};
//       groupedRaw.forEach((key, value) {
//         final items = (value as List<dynamic>? ?? [])
//             .whereType<Map<String, dynamic>>()
//             .map(MeditationSessionItem.fromJson)
//             .toList(growable: false);
//         grouped[key.toString()] = items;
//       });
//       final featuredJson = (decoded['featured'] as List<dynamic>? ?? [])
//           .whereType<Map<String, dynamic>>()
//           .map(MeditationSessionItem.fromJson)
//           .toList(growable: false);

//       final sessions = sessionsJson
//           .map(MeditationSessionItem.fromJson)
//           .toList(growable: false);
//       return MeditationSessionsResponse(
//         sessions: sessions,
//         categories: categories,
//         groupedByCategory: grouped,
//         featured: featuredJson,
//       );
//     }

//     throw ApiClientException(
//       'Unable to load meditations: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<LegacyGuidelinesResponse> fetchLegacyGuidelines() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/legacy/guidelines/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return LegacyGuidelinesResponse.fromJson(decoded);
//     }

//     throw ApiClientException(
//       'Unable to load guidelines: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<List<LegacyCounsellor>> fetchLegacyExperts() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/legacy/expert-connect/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       final counsellors = (decoded['counsellors'] as List<dynamic>? ?? [])
//           .whereType<Map<String, dynamic>>()
//           .map(LegacyCounsellor.fromJson)
//           .toList(growable: false);
//       return counsellors;
//     }

//     throw ApiClientException(
//       'Unable to load experts: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<LegacyBreathingConfig> fetchLegacyBreathingConfig() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/legacy/breathing/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return LegacyBreathingConfig.fromJson(decoded);
//     }

//     throw ApiClientException(
//       'Unable to load breathing config: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<List<LegacyAssessmentQuestion>> fetchLegacyAssessmentQuestions() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/legacy/assessment/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       final questions = (decoded['questions'] as List<dynamic>? ?? [])
//           .whereType<Map<String, dynamic>>()
//           .map(LegacyAssessmentQuestion.fromJson)
//           .toList(growable: false);
//       return questions;
//     }

//     throw ApiClientException(
//       'Unable to load assessment: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<List<String>> fetchLegacyAffirmations() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/legacy/affirmations/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       final affirmations = (decoded['affirmations'] as List<dynamic>? ?? [])
//           .whereType<String>()
//           .toList(growable: false);
//       return affirmations;
//     }

//     throw ApiClientException(
//       'Unable to load affirmations: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<LegacyAdvancedCareResponse> fetchLegacyAdvancedCare() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/legacy/advanced-care/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return LegacyAdvancedCareResponse.fromJson(decoded);
//     }

//     throw ApiClientException(
//       'Unable to load advanced care content: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<LegacyFeatureDetail> fetchLegacyFeatureDetail() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/legacy/feature-detail/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as Map<String, dynamic>;
//       return LegacyFeatureDetail.fromJson(decoded);
//     }

//     throw ApiClientException(
//       'Unable to load feature detail: ${_extractErrorMessage(response)}',
//     );
//   }

//   // Counselor-specific methods
//   Future<Map<String, dynamic>> getCounsellorProfile() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/counselor/profile/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body) as Map<String, dynamic>;
//     }

//     if (response.statusCode == 404) {
//       throw ApiClientException('Counsellor profile not found');
//     }

//     throw ApiClientException(
//       'Unable to load counsellor profile: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<Map<String, dynamic>> updateCounsellorProfile({
//     String? specialization,
//     int? experienceYears,
//     List<String>? languages,
//     bool? isAvailable,
//     String? bio,
//   }) async {
//     final payload = <String, dynamic>{};
//     if (specialization != null) payload['specialization'] = specialization;
//     if (experienceYears != null) payload['experience_years'] = experienceYears;
//     if (languages != null) payload['languages'] = languages;
//     if (isAvailable != null) payload['is_available'] = isAvailable;
//     if (bio != null) payload['bio'] = bio;

//     final response = await _sendAuthorized(
//       (access) => http.patch(
//         Uri.parse('$base/counselor/profile/'),
//         headers: _headers(access, {'Content-Type': 'application/json'}),
//         body: jsonEncode(payload),
//       ),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body) as Map<String, dynamic>;
//     }

//     throw ApiClientException(
//       'Unable to update counsellor profile: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<List<Map<String, dynamic>>> getCounsellorAppointments({String? status}) async {
//     final params = <String, String>{};
//     if (status != null && status.trim().isNotEmpty) {
//       params['status'] = status.trim();
//     }

//     final uri = params.isEmpty
//         ? Uri.parse('$base/counselor/appointments/')
//         : Uri.parse('$base/counselor/appointments/').replace(queryParameters: params);

//     final response = await _sendAuthorized(
//       (access) => http.get(uri, headers: _headers(access)),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as List<dynamic>;
//       return decoded
//           .whereType<Map<String, dynamic>>()
//           .toList(growable: false);
//     }

//     throw ApiClientException(
//       'Unable to load appointments: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<Map<String, dynamic>> getCounsellorStats() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/counselor/stats/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body) as Map<String, dynamic>;
//     }

//     if (response.statusCode == 404) {
//       throw ApiClientException('Counsellor profile not found');
//     }

//     throw ApiClientException(
//       'Unable to load stats: ${_extractErrorMessage(response)}',
//     );
//   }

//   // Chat methods
//   Future<Map<String, dynamic>> createChat({String? initialMessage}) async {
//     final payload = <String, dynamic>{};
//     if (initialMessage != null && initialMessage.trim().isNotEmpty) {
//       payload['initial_message'] = initialMessage.trim();
//     }

//     final response = await _sendAuthorized(
//       (access) => http.post(
//         Uri.parse('$base/chats/'),
//         headers: _headers(access, {'Content-Type': 'application/json'}),
//         body: jsonEncode(payload),
//       ),
//     );

//     if (response.statusCode == 201) {
//       return jsonDecode(response.body) as Map<String, dynamic>;
//     }

//     throw ApiClientException(
//       'Unable to create chat: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<List<Map<String, dynamic>>> getChatList() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/chats/list/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as List<dynamic>;
//       return decoded
//           .whereType<Map<String, dynamic>>()
//           .toList(growable: false);
//     }

//     throw ApiClientException(
//       'Unable to load chat list: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<List<Map<String, dynamic>>> getQueuedChats() async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/counselor/queued-chats/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as List<dynamic>;
//       return decoded
//           .whereType<Map<String, dynamic>>()
//           .toList(growable: false);
//     }

//     throw ApiClientException(
//       'Unable to load queued chats: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<Map<String, dynamic>> acceptChat(int chatId) async {
//     final response = await _sendAuthorized(
//       (access) => http.patch(
//         Uri.parse('$base/chats/$chatId/accept/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body) as Map<String, dynamic>;
//     }

//     throw ApiClientException(
//       'Unable to accept chat: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<Map<String, dynamic>> startSession(int sessionId) async {
//     final response = await _sendAuthorized(
//       (access) => http.post(
//         Uri.parse('$base/sessions/$sessionId/start/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       return jsonDecode(response.body) as Map<String, dynamic>;
//     }

//     throw ApiClientException(
//       'Unable to start session: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<Map<String, dynamic>> endSession(int sessionId) async {
//     final response = await _sendAuthorized(
//       (access) => http.post(
//         Uri.parse('$base/sessions/$sessionId/end/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       return jsonDecode(response.body) as Map<String, dynamic>;
//     }

//     throw ApiClientException(
//       'Unable to end session: ${_extractErrorMessage(response)}',
//     );
//   }

//   /// Get current session duration from backend
//   Future<Map<String, dynamic>> getSessionDuration(int sessionId) async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/sessions/$sessionId/duration/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body) as Map<String, dynamic>;
//     }

//     throw ApiClientException(
//       'Unable to get session duration: ${_extractErrorMessage(response)}',
//     );
//   }

//   /// Update session (risk_level, notes, manual_flag)
//   Future<Map<String, dynamic>> updateSession(
//     int sessionId, {
//     String? riskLevel,
//     String? manualFlag,
//     String? notes,
//   }) async {
//     final payload = <String, dynamic>{};
//     if (riskLevel != null) payload['risk_level'] = riskLevel;
//     if (manualFlag != null) payload['manual_flag'] = manualFlag;
//     if (notes != null) payload['notes'] = notes;

//     final response = await _sendAuthorized(
//       (access) => http.patch(
//         Uri.parse('$base/sessions/$sessionId/update/'),
//         headers: _headers(access, {'Content-Type': 'application/json'}),
//         body: jsonEncode(payload),
//       ),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body) as Map<String, dynamic>;
//     }

//     throw ApiClientException(
//       'Unable to update session: ${_extractErrorMessage(response)}',
//     );
//   }

//   /// Get complete session summary
//   Future<Map<String, dynamic>> getSessionSummary(int sessionId) async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/sessions/$sessionId/summary/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       return jsonDecode(response.body) as Map<String, dynamic>;
//     }

//     throw ApiClientException(
//       'Unable to get session summary: ${_extractErrorMessage(response)}',
//     );
//   }

//   // Chat message methods
//   Future<List<Map<String, dynamic>>> getChatMessages(int chatId) async {
//     final response = await _sendAuthorized(
//       (access) => http.get(
//         Uri.parse('$base/chats/$chatId/messages/'),
//         headers: _headers(access),
//       ),
//     );

//     if (response.statusCode == 200) {
//       final decoded = jsonDecode(response.body) as List<dynamic>;
//       return decoded
//           .whereType<Map<String, dynamic>>()
//           .toList(growable: false);
//     }

//     throw ApiClientException(
//       'Unable to load chat messages: ${_extractErrorMessage(response)}',
//     );
//   }

//   Future<Map<String, dynamic>> sendChatMessage(int chatId, String text) async {
//     final response = await _sendAuthorized(
//       (access) => http.post(
//         Uri.parse('$base/chats/$chatId/messages/'),
//         headers: _headers(access, {'Content-Type': 'application/json'}),
//         body: jsonEncode({'text': text}),
//       ),
//     );

//     if (response.statusCode == 201) {
//       return jsonDecode(response.body) as Map<String, dynamic>;
//     }

//     throw ApiClientException(
//       'Unable to send message: ${_extractErrorMessage(response)}',
//     );
//   }

//   // WebSocket connection for real-time chat
//   Future<WebSocketChannel> connectChatWebSocket(int chatId) async {
//     // Get access token for authentication
//     final accessToken = await _accessToken;
//     if (accessToken == null) {
//       throw ApiClientException('Not authenticated. Please login first.');
//     }

//     // Get WebSocket URL (ws:// for development, wss:// for production)
//     // Note: WebSocket routing is at root level, not under /api/
//     // base is http://127.0.0.1:8000/api, so we need to remove /api for WebSocket
//     String httpBase = base;
//     if (httpBase.endsWith('/api')) {
//       httpBase = httpBase.substring(0, httpBase.length - 4);
//     } else if (httpBase.endsWith('/api/')) {
//       httpBase = httpBase.substring(0, httpBase.length - 5);
//     }
    
//     // Determine WebSocket scheme based on HTTP scheme
//     String wsScheme = 'ws://';
//     if (httpBase.startsWith('https://')) {
//       wsScheme = 'wss://';
//       httpBase = httpBase.substring(8); // Remove 'https://'
//     } else if (httpBase.startsWith('http://')) {
//       httpBase = httpBase.substring(7); // Remove 'http://'
//     }
    
//     // Construct WebSocket URL with proper path (ensure trailing slash matches server route)
//     final wsPath = '/ws/chat/$chatId/'; // Match server route exactly
//     final wsUrl = '$wsScheme$httpBase$wsPath?token=${Uri.encodeComponent(accessToken)}';
    
//     // Log the exact URI for debugging
//     if (kDebugMode) {
//       print('[WebSocket] Connecting to: $wsUrl');
//       print('[WebSocket] Chat ID: $chatId');
//       print('[WebSocket] Scheme: $wsScheme');
//     }
    
//     try {
//       final uri = Uri.parse(wsUrl);
//       final channel = WebSocketChannel.connect(uri);
      
//       if (kDebugMode) {
//         print('[WebSocket] Connection established successfully');
//       }
      
//       return channel;
//     } catch (e, stackTrace) {
//       // Log detailed error information for debugging
//       if (kDebugMode) {
//         print('[WebSocket] Connection failed!');
//         print('[WebSocket] URL attempted: $wsUrl');
//         print('[WebSocket] Error: $e');
//         print('[WebSocket] Stack trace: $stackTrace');
//       }
//       // Re-throw as ApiClientException for consistent error handling
//       throw ApiClientException('WebSocket connection failed: $e');
//     }
//   }
// }





import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

class ApiClientException implements Exception {
  ApiClientException(this.message);

  final String message;

  @override
  String toString() => 'ApiClientException: $message';
}

enum WellnessTaskCategory { daily, evening }

extension WellnessTaskCategoryX on WellnessTaskCategory {
  String get apiValue => switch (this) {
        WellnessTaskCategory.daily => 'daily',
        WellnessTaskCategory.evening => 'evening',
      };

  String get displayLabel => switch (this) {
        WellnessTaskCategory.daily => 'Daily Tasks',
        WellnessTaskCategory.evening => 'Evening Reflection',
      };

  static WellnessTaskCategory fromApi(String value) {
    switch (value) {
      case 'evening':
        return WellnessTaskCategory.evening;
      case 'daily':
      default:
        return WellnessTaskCategory.daily;
    }
  }
}

class WellnessTaskItem {
  const WellnessTaskItem({
    required this.id,
    required this.title,
    required this.category,
    required this.isCompleted,
    required this.order,
  });

  factory WellnessTaskItem.fromJson(Map<String, dynamic> json) {
    return WellnessTaskItem(
      id: json['id'] as int,
      title: (json['title'] as String?)?.trim() ?? '',
      category:
          WellnessTaskCategoryX.fromApi(json['category'] as String? ?? 'daily'),
      isCompleted: json['is_completed'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }

  final int id;
  final String title;
  final WellnessTaskCategory category;
  final bool isCompleted;
  final int order;

  WellnessTaskItem copyWith({
    String? title,
    WellnessTaskCategory? category,
    bool? isCompleted,
    int? order,
  }) {
    return WellnessTaskItem(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
    );
  }
}

class WellnessTaskSummary {
  const WellnessTaskSummary({
    required this.total,
    required this.completed,
  });

  final int total;
  final int completed;

  double get completionRatio => total == 0 ? 0 : completed / total;
}

class WellnessTasksResponse {
  const WellnessTasksResponse({
    required this.daily,
    required this.evening,
    required this.summary,
  });

  final List<WellnessTaskItem> daily;
  final List<WellnessTaskItem> evening;
  final WellnessTaskSummary summary;
}

class WellnessJournalEntry {
  WellnessJournalEntry({
    required this.id,
    required this.title,
    required this.note,
    required this.mood,
    required this.entryType,
    required this.formattedDate,
    this.createdAt,
  });

  factory WellnessJournalEntry.fromJson(Map<String, dynamic> json) {
    return WellnessJournalEntry(
      id: json['id'] as int,
      title: (json['title'] as String?)?.trim() ?? '',
      note: (json['note'] as String?)?.trim() ?? '',
      mood: (json['mood'] as String?)?.trim() ?? '',
      entryType: (json['entry_type'] as String?)?.trim() ?? '',
      formattedDate: (json['formatted_date'] as String?)?.trim() ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  final int id;
  final String title;
  final String note;
  final String mood;
  final String entryType;
  final String formattedDate;
  final DateTime? createdAt;

  WellnessJournalEntry copyWith({
    String? title,
    String? note,
    String? mood,
    String? entryType,
    String? formattedDate,
    DateTime? createdAt,
  }) {
    return WellnessJournalEntry(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      mood: mood ?? this.mood,
      entryType: entryType ?? this.entryType,
      formattedDate: formattedDate ?? this.formattedDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum SupportGroupAction { join, leave }

class SupportGroupItem {
  const SupportGroupItem({
    required this.slug,
    required this.name,
    required this.description,
    required this.icon,
    required this.isJoined,
  });

  factory SupportGroupItem.fromJson(Map<String, dynamic> json) {
    return SupportGroupItem(
      slug: (json['slug'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      icon: (json['icon'] as String?)?.trim() ?? '',
      isJoined: json['is_joined'] as bool? ?? false,
    );
  }

  final String slug;
  final String name;
  final String description;
  final String icon;
  final bool isJoined;

  SupportGroupItem copyWith({
    bool? isJoined,
  }) {
    return SupportGroupItem(
      slug: slug,
      name: name,
      description: description,
      icon: icon,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}

enum SessionType { oneOnOne, group, workshop, webinar }

extension SessionTypeX on SessionType {
  String get apiValue => switch (this) {
        SessionType.oneOnOne => 'one_on_one',
        SessionType.group => 'group',
        SessionType.workshop => 'workshop',
        SessionType.webinar => 'webinar',
      };

  String get displayLabel => switch (this) {
        SessionType.oneOnOne => 'One-on-One',
        SessionType.group => 'Group',
        SessionType.workshop => 'Workshop',
        SessionType.webinar => 'Webinar',
      };

  static SessionType fromApi(String value) {
    switch (value) {
      case 'group':
        return SessionType.group;
      case 'workshop':
        return SessionType.workshop;
      case 'webinar':
        return SessionType.webinar;
      case 'one_on_one':
      default:
        return SessionType.oneOnOne;
    }
  }
}

class UpcomingSessionItem {
  UpcomingSessionItem({
    required this.id,
    required this.title,
    required this.sessionType,
    required this.startTime,
    required this.counsellorName,
    required this.notes,
    required this.isConfirmed,
  });

  factory UpcomingSessionItem.fromJson(Map<String, dynamic> json) {
    return UpcomingSessionItem(
      id: json['id'] as int,
      title: (json['title'] as String?)?.trim() ?? '',
      sessionType:
          SessionTypeX.fromApi(json['session_type'] as String? ?? 'one_on_one'),
      startTime: DateTime.tryParse(json['start_time'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      counsellorName: (json['counsellor_name'] as String?)?.trim() ?? '',
      notes: (json['notes'] as String?)?.trim() ?? '',
      isConfirmed: json['is_confirmed'] as bool? ?? true,
    );
  }

  final int id;
  final String title;
  final SessionType sessionType;
  final DateTime startTime;
  final String counsellorName;
  final String notes;
  final bool isConfirmed;

  UpcomingSessionItem copyWith({
    String? title,
    SessionType? sessionType,
    DateTime? startTime,
    String? counsellorName,
    String? notes,
    bool? isConfirmed,
  }) {
    return UpcomingSessionItem(
      id: id,
      title: title ?? this.title,
      sessionType: sessionType ?? this.sessionType,
      startTime: startTime ?? this.startTime,
      counsellorName: counsellorName ?? this.counsellorName,
      notes: notes ?? this.notes,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}

class WalletInfo {
  const WalletInfo({
    required this.balance,
    required this.rates,
    required this.minimumBalance,
  });

  factory WalletInfo.fromJson(Map<String, dynamic> json) {
    final ratesJson = json['rates'] as Map<String, dynamic>? ?? const {};
    final minimumJson = json['minimum_balance'] as Map<String, dynamic>? ?? const {};
    Map<String, int> _mapToInt(Map<String, dynamic> source) {
      return {
        for (final entry in source.entries) entry.key: (entry.value as num?)?.toInt() ?? 0,
      };
    }

    return WalletInfo(
      balance: json['wallet_minutes'] as int? ?? 0,
      rates: _mapToInt(ratesJson),
      minimumBalance: _mapToInt(minimumJson),
    );
  }

  final int balance;
  final Map<String, int> rates;
  final Map<String, int> minimumBalance;

  int get amount => balance;
  int get minutes => balance;
}

class UserSettings {
  const UserSettings({
    this.fullName,
    this.nickname,
    this.phone,
    this.age,
    this.gender,
    required this.notificationsEnabled,
    required this.prefersDarkMode,
    required this.language,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      fullName: (json['full_name'] as String?)?.trim(),
      nickname: (json['nickname'] as String?)?.trim(),
      phone: (json['phone'] as String?)?.trim(),
      age: json['age'] as int?,
      gender: (json['gender'] as String?)?.trim(),
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      prefersDarkMode: json['prefers_dark_mode'] as bool? ?? false,
      language: (json['language'] as String?)?.trim() ?? 'English',
    );
  }

  final String? fullName;
  final String? nickname;
  final String? phone;
  final int? age;
  final String? gender;
  final bool notificationsEnabled;
  final bool prefersDarkMode;
  final String language;

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'nickname': nickname,
      'phone': phone,
      'age': age,
      'gender': gender,
      'notifications_enabled': notificationsEnabled,
      'prefers_dark_mode': prefersDarkMode,
      'language': language,
    }..removeWhere((key, value) => value == null);
  }

  UserSettings copyWith({
    String? fullName,
    String? nickname,
    String? phone,
    int? age,
    String? gender,
    bool? notificationsEnabled,
    bool? prefersDarkMode,
    String? language,
  }) {
    return UserSettings(
      fullName: fullName ?? this.fullName,
      nickname: nickname ?? this.nickname,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      prefersDarkMode: prefersDarkMode ?? this.prefersDarkMode,
      language: language ?? this.language,
    );
  }
}

enum MoodUpdateStatus { ok, limitReached }

class MoodUpdateResult {
  const MoodUpdateResult({
    required this.status,
    this.updatesUsed,
    this.updatesRemaining,
    this.resetAtLocal,
    this.timezone,
  });

  factory MoodUpdateResult.success(Map<String, dynamic> json) {
    return MoodUpdateResult(
      status: MoodUpdateStatus.ok,
      updatesUsed: json['updates_used'] as int?,
      updatesRemaining: json['updates_remaining'] as int?,
    );
  }

  factory MoodUpdateResult.limit(Map<String, dynamic> json) {
    return MoodUpdateResult(
      status: MoodUpdateStatus.limitReached,
      resetAtLocal: json['reset_at_local'] as String?,
      timezone: json['timezone'] as String?,
      updatesUsed: json['updates_used'] as int?,
      updatesRemaining: json['updates_remaining'] as int?,
    );
  }

  final MoodUpdateStatus status;
  final int? updatesUsed;
  final int? updatesRemaining;
  final String? resetAtLocal;
  final String? timezone;
}

class AnalyticsMoodPoint {
  const AnalyticsMoodPoint({
    required this.date,
    required this.average,
    required this.count,
  });

  factory AnalyticsMoodPoint.fromJson(Map<String, dynamic> json) {
    return AnalyticsMoodPoint(
      date: DateTime.tryParse(json['date'] as String? ?? ''),
      average: (json['average'] as num?)?.toDouble() ?? 0,
      count: json['count'] as int? ?? 0,
    );
  }

  final DateTime? date;
  final double average;
  final int count;
}

class AnalyticsReport {
  const AnalyticsReport({
    required this.weeklyMood,
    required this.monthlyMood,
    required this.tasks,
    required this.sessions,
    required this.walletMinutes,
    required this.insight,
  });

  factory AnalyticsReport.fromJson(Map<String, dynamic> json) {
    final moodJson = json['mood'] as Map<String, dynamic>? ?? {};
    final tasksJson = json['tasks'] as Map<String, dynamic>? ?? {};
    final sessionsJson = json['sessions'] as Map<String, dynamic>? ?? {};
    final walletJson = json['wallet'] as Map<String, dynamic>? ?? {};
    return AnalyticsReport(
      weeklyMood: (moodJson['weekly'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AnalyticsMoodPoint.fromJson)
          .toList(growable: false),
      monthlyMood: (moodJson['monthly'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AnalyticsMoodPoint.fromJson)
          .toList(growable: false),
      tasks: TasksAnalytics.fromJson(tasksJson),
      sessions: SessionsAnalytics.fromJson(sessionsJson),
      walletMinutes: walletJson['minutes'] as int? ?? 0,
      insight: (json['insight'] as String?)?.trim() ?? '',
    );
  }

  final List<AnalyticsMoodPoint> weeklyMood;
  final List<AnalyticsMoodPoint> monthlyMood;
  final TasksAnalytics tasks;
  final SessionsAnalytics sessions;
  final int walletMinutes;
  final String insight;
}

class TasksAnalytics {
  const TasksAnalytics({
    required this.total,
    required this.completed,
    required this.completionRate,
    required this.byCategory,
    required this.topTasks,
  });

  factory TasksAnalytics.fromJson(Map<String, dynamic> json) {
    final categoryJson = json['by_category'] as Map<String, dynamic>? ?? {};
    final topJson = json['top_tasks'] as List<dynamic>? ?? const [];
    return TasksAnalytics(
      total: json['total'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
      byCategory: {
        for (final entry in categoryJson.entries)
          entry.key.toString(): entry.value as int? ?? 0,
      },
      topTasks: topJson
          .whereType<Map<String, dynamic>>()
          .map((item) => TaskSummary(
                title: (item['title'] as String?)?.trim() ?? '',
                total: item['total'] as int? ?? 0,
              ))
          .toList(growable: false),
    );
  }

  final int total;
  final int completed;
  final double completionRate;
  final Map<String, int> byCategory;
  final List<TaskSummary> topTasks;
}

class TaskSummary {
  const TaskSummary({required this.title, required this.total});

  final String title;
  final int total;
}

class SessionsAnalytics {
  const SessionsAnalytics({
    required this.total,
    required this.upcoming,
    required this.completed,
  });

  factory SessionsAnalytics.fromJson(Map<String, dynamic> json) {
    return SessionsAnalytics(
      total: json['total'] as int? ?? 0,
      upcoming: json['upcoming'] as int? ?? 0,
      completed: json['completed'] as int? ?? 0,
    );
  }

  final int total;
  final int upcoming;
  final int completed;
}

class GuidanceResourceItem {
  const GuidanceResourceItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.category,
    required this.duration,
    required this.mediaUrl,
    required this.thumbnail,
    required this.isFeatured,
  });

  factory GuidanceResourceItem.fromJson(Map<String, dynamic> json) {
    return GuidanceResourceItem(
      id: json['id'] as int,
      type: (json['resource_type'] as String?)?.trim() ?? 'article',
      title: (json['title'] as String?)?.trim() ?? '',
      subtitle: (json['subtitle'] as String?)?.trim() ?? '',
      summary: (json['summary'] as String?)?.trim() ?? '',
      category: (json['category'] as String?)?.trim() ?? '',
      duration: (json['duration'] as String?)?.trim() ?? '',
      mediaUrl: (json['media_url'] as String?)?.trim() ?? '',
      thumbnail: (json['thumbnail'] as String?)?.trim() ?? '',
      isFeatured: json['is_featured'] as bool? ?? false,
    );
  }

  final int id;
  final String type;
  final String title;
  final String subtitle;
  final String summary;
  final String category;
  final String duration;
  final String mediaUrl;
  final String thumbnail;
  final bool isFeatured;
}

class GuidanceResponse {
  const GuidanceResponse({required this.resources, required this.categories});

  factory GuidanceResponse.fromJson(Map<String, dynamic> json) {
    final resources = (json['resources'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(GuidanceResourceItem.fromJson)
        .toList(growable: false);
    final categories = (json['categories'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList(growable: false);
    return GuidanceResponse(resources: resources, categories: categories);
  }

  final List<GuidanceResourceItem> resources;
  final List<String> categories;
}

class MusicTrackItem {
  const MusicTrackItem({
    required this.id,
    required this.title,
    required this.description,
    required this.durationSeconds,
    required this.durationFormatted,
    required this.audioUrl,
    required this.mood,
    required this.thumbnail,
  });

  factory MusicTrackItem.fromJson(Map<String, dynamic> json) {
    return MusicTrackItem(
      id: json['id'] as int,
      title: (json['title'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      durationFormatted: (json['duration'] as String?)?.trim() ?? '',
      audioUrl: (json['audio_url'] as String?)?.trim() ?? '',
      mood: (json['mood'] as String?)?.trim() ?? '',
      thumbnail: (json['thumbnail'] as String?)?.trim() ?? '',
    );
  }

  final int id;
  final String title;
  final String description;
  final int durationSeconds;
  final String durationFormatted;
  final String audioUrl;
  final String mood;
  final String thumbnail;
}

class MusicTracksResponse {
  const MusicTracksResponse({
    required this.tracks,
    required this.moods,
    required this.count,
  });

  final List<MusicTrackItem> tracks;
  final List<String> moods;
  final int count;
}

class MindCareBoosterItem {
  const MindCareBoosterItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.icon,
    required this.actionLabel,
    required this.prompt,
    required this.estimatedSeconds,
    required this.resourceUrl,
  });

  factory MindCareBoosterItem.fromJson(Map<String, dynamic> json) {
    return MindCareBoosterItem(
      id: json['id'] as int,
      title: (json['title'] as String?)?.trim() ?? '',
      subtitle: (json['subtitle'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      category: (json['category'] as String?)?.trim() ?? '',
      icon: (json['icon'] as String?)?.trim() ?? '',
      actionLabel: (json['action_label'] as String?)?.trim() ?? 'Start',
      prompt: (json['prompt'] as String?)?.trim() ?? '',
      estimatedSeconds: json['estimated_seconds'] as int? ?? 0,
      resourceUrl: (json['resource_url'] as String?)?.trim() ?? '',
    );
  }

  final int id;
  final String title;
  final String subtitle;
  final String description;
  final String category;
  final String icon;
  final String actionLabel;
  final String prompt;
  final int estimatedSeconds;
  final String resourceUrl;
}

class MindCareBoostersResponse {
  const MindCareBoostersResponse({
    required this.boosters,
    required this.categories,
    required this.groupedByCategory,
  });

  final List<MindCareBoosterItem> boosters;
  final List<String> categories;
  final Map<String, List<MindCareBoosterItem>> groupedByCategory;
}

class MeditationSessionItem {
  const MeditationSessionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.durationMinutes,
    required this.difficulty,
    required this.audioUrl,
    required this.videoUrl,
    required this.isFeatured,
    required this.thumbnail,
  });

  factory MeditationSessionItem.fromJson(Map<String, dynamic> json) {
    return MeditationSessionItem(
      id: json['id'] as int,
      title: (json['title'] as String?)?.trim() ?? '',
      subtitle: (json['subtitle'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      category: (json['category'] as String?)?.trim() ?? '',
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      difficulty: (json['difficulty'] as String?)?.trim() ?? '',
      audioUrl: (json['audio_url'] as String?)?.trim() ?? '',
      videoUrl: (json['video_url'] as String?)?.trim() ?? '',
      isFeatured: json['is_featured'] as bool? ?? false,
      thumbnail: (json['thumbnail'] as String?)?.trim() ?? '',
    );
  }

  final int id;
  final String title;
  final String subtitle;
  final String description;
  final String category;
  final int durationMinutes;
  final String difficulty;
  final String audioUrl;
  final String videoUrl;
  final bool isFeatured;
  final String thumbnail;
}

class MeditationSessionsResponse {
  const MeditationSessionsResponse({
    required this.sessions,
    required this.categories,
    required this.groupedByCategory,
    required this.featured,
  });

  final List<MeditationSessionItem> sessions;
  final List<String> categories;
  final Map<String, List<MeditationSessionItem>> groupedByCategory;
  final List<MeditationSessionItem> featured;
}

class LegacyGuidelineSection {
  const LegacyGuidelineSection({
    required this.title,
    required this.bullets,
  });

  factory LegacyGuidelineSection.fromJson(Map<String, dynamic> json) {
    final bullets = (json['bullets'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList(growable: false);
    return LegacyGuidelineSection(
      title: (json['title'] as String?)?.trim() ?? '',
      bullets: bullets,
    );
  }

  final String title;
  final List<String> bullets;
}

class LegacyGuidelinesResponse {
  const LegacyGuidelinesResponse({required this.sections});

  factory LegacyGuidelinesResponse.fromJson(Map<String, dynamic> json) {
    final sections = (json['sections'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LegacyGuidelineSection.fromJson)
        .toList(growable: false);
    return LegacyGuidelinesResponse(sections: sections);
  }

  final List<LegacyGuidelineSection> sections;
}

class LegacyCounsellor {
  const LegacyCounsellor({
    required this.name,
    required this.expertise,
    required this.rating,
    required this.languages,
    required this.tagline,
    required this.isAvailableNow,
  });

  factory LegacyCounsellor.fromJson(Map<String, dynamic> json) {
    return LegacyCounsellor(
      name: (json['name'] as String?)?.trim() ?? '',
      expertise: (json['expertise'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(growable: false),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      languages: (json['languages'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(growable: false),
      tagline: (json['tagline'] as String?)?.trim() ?? '',
      isAvailableNow: json['is_available_now'] as bool? ?? false,
    );
  }

  final String name;
  final List<String> expertise;
  final double rating;
  final List<String> languages;
  final String tagline;
  final bool isAvailableNow;
}

class LegacyBreathingConfig {
  const LegacyBreathingConfig({
    required this.cycleOptions,
    required this.tip,
  });

  factory LegacyBreathingConfig.fromJson(Map<String, dynamic> json) {
    final options = (json['cycle_options'] as List<dynamic>? ?? [])
        .whereType<int>()
        .toList(growable: false);
    return LegacyBreathingConfig(
      cycleOptions: options,
      tip: (json['tip'] as String?)?.trim() ?? '',
    );
  }

  final List<int> cycleOptions;
  final String tip;
}

class LegacyAssessmentQuestion {
  const LegacyAssessmentQuestion({
    required this.question,
    required this.options,
  });

  factory LegacyAssessmentQuestion.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList(growable: false);
    return LegacyAssessmentQuestion(
      question: (json['question'] as String?)?.trim() ?? '',
      options: options,
    );
  }

  final String question;
  final List<String> options;
}

class LegacyAdvancedCareService {
  const LegacyAdvancedCareService({
    required this.title,
    required this.description,
    required this.benefits,
  });

  factory LegacyAdvancedCareService.fromJson(Map<String, dynamic> json) {
    final benefits = (json['benefits'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList(growable: false);
    return LegacyAdvancedCareService(
      title: (json['title'] as String?)?.trim() ?? '',
      description: (json['description'] as String?)?.trim() ?? '',
      benefits: benefits,
    );
  }

  final String title;
  final String description;
  final List<String> benefits;
}

class LegacyAdvancedCareSpecialist {
  const LegacyAdvancedCareSpecialist({
    required this.name,
    required this.specialization,
    required this.experienceYears,
  });

  factory LegacyAdvancedCareSpecialist.fromJson(Map<String, dynamic> json) {
    return LegacyAdvancedCareSpecialist(
      name: (json['name'] as String?)?.trim() ?? '',
      specialization: (json['specialization'] as String?)?.trim() ?? '',
      experienceYears: json['experience_years'] as int? ?? 0,
    );
  }

  final String name;
  final String specialization;
  final int experienceYears;
}

class LegacyAdvancedCareResponse {
  const LegacyAdvancedCareResponse({
    required this.services,
    required this.specialists,
  });

  factory LegacyAdvancedCareResponse.fromJson(Map<String, dynamic> json) {
    final services = (json['services'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LegacyAdvancedCareService.fromJson)
        .toList(growable: false);
    final specialists = (json['specialists'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LegacyAdvancedCareSpecialist.fromJson)
        .toList(growable: false);
    return LegacyAdvancedCareResponse(
      services: services,
      specialists: specialists,
    );
  }

  final List<LegacyAdvancedCareService> services;
  final List<LegacyAdvancedCareSpecialist> specialists;
}

class LegacyFeatureSection {
  const LegacyFeatureSection({
    required this.heading,
    required this.bullets,
  });

  factory LegacyFeatureSection.fromJson(Map<String, dynamic> json) {
    final bullets = (json['bullets'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toList(growable: false);
    return LegacyFeatureSection(
      heading: (json['heading'] as String?)?.trim() ?? '',
      bullets: bullets,
    );
  }

  final String heading;
  final List<String> bullets;
}

class LegacyFeatureDetail {
  const LegacyFeatureDetail({required this.title, required this.sections});

  factory LegacyFeatureDetail.fromJson(Map<String, dynamic> json) {
    final sections = (json['sections'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(LegacyFeatureSection.fromJson)
        .toList(growable: false);
    return LegacyFeatureDetail(
      title: (json['title'] as String?)?.trim() ?? '',
      sections: sections,
    );
  }

  final String title;
  final List<LegacyFeatureSection> sections;
}

class ApiClient {
  static const String _defaultBase = 'http://127.0.0.1:8000/api';
  static const String base =
      String.fromEnvironment('BACKEND_BASE_URL', defaultValue: _defaultBase);

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    webOptions: WebOptions(),
  );

  Future<void> _saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access', value: access);
    await _storage.write(key: 'refresh', value: refresh);
  }

  Future<String?> get _accessToken async => _storage.read(key: 'access');

  Future<String?> get _refreshToken async => _storage.read(key: 'refresh');

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  String _errorFromResponse(http.Response response, {String? fallback}) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['detail'] != null) {
          return decoded['detail'].toString();
        }
        final buffer = StringBuffer();
        decoded.forEach((key, value) {
          if (value == null) return;
          if (value is List) {
            buffer.writeAll(value.map((e) => e.toString()), ' ');
          } else {
            buffer.write(value.toString());
          }
          buffer.write(' ');
        });
        final result = buffer.toString().trim();
        if (result.isNotEmpty) {
          return result;
        }
      } else if (decoded is List) {
        final result = decoded.map((e) => e.toString()).join(' ').trim();
        if (result.isNotEmpty) {
          return result;
        }
      } else if (decoded != null) {
        final result = decoded.toString().trim();
        if (result.isNotEmpty) {
          return result;
        }
      }
    } catch (_) {
      // ignore json errors
    }
    return fallback ?? 'Request failed with status ${response.statusCode}';
  }

  Future<(bool, String?)> sendRegistrationOtp(String email) async {
    final response = await http.post(
      Uri.parse('$base/auth/send-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return (true, null);
    }

    return (
      false,
      _errorFromResponse(response, fallback: 'Failed to send OTP')
    );
  }

  Future<(bool, String?)> sendPasswordResetOtp(String email) async {
    final response = await http.post(
      Uri.parse('$base/auth/send-password-reset-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return (true, null);
    }

    return (
      false,
      _errorFromResponse(response, fallback: 'Failed to send OTP')
    );
  }

  Future<(bool, String?, String?)> verifyRegistrationOtp({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$base/auth/verify-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final token = decoded['token'] as String?;
        return (true, null, token);
      } catch (_) {
        return (true, null, null);
      }
    }

    return (
      false,
      _errorFromResponse(response, fallback: 'OTP verification failed'),
      null
    );
  }

  Future<(bool, String?, String?)> verifyPasswordResetOtp({
    required String email,
    required String code,
  }) async {
    final response = await http.post(
      Uri.parse('$base/auth/verify-password-reset-otp/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'code': code}),
    );

    if (response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final token = decoded['token'] as String?;
        return (true, null, token);
      } catch (_) {
        return (true, null, null);
      }
    }

    return (
      false,
      _errorFromResponse(response, fallback: 'OTP verification failed'),
      null
    );
  }

  Future<(bool, String?)> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$base/auth/password-reset/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'new_password': newPassword}),
    );

    if (response.statusCode == 200) {
      return (true, null);
    }

    return (
      false,
      _errorFromResponse(response, fallback: 'Password reset failed')
    );
  }

  Future<(bool, String?)> register({
    required String username,
    String? email,
    required String password,
    String? fullName,
    String? nickname,
    String? phone,
    int? age,
    String? gender,
    required String otpToken,
  }) async {
    final payload = <String, dynamic>{
      'username': username,
      'password': password,
      'otp_token': otpToken,
    };

    void addIfPresent(String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      payload[key] = value;
    }

    addIfPresent('email', email);
    addIfPresent('full_name', fullName);
    addIfPresent('nickname', nickname);
    addIfPresent('phone', phone);
    if (age != null) {
      payload['age'] = age;
    }
    addIfPresent('gender', gender);

    final response = await http.post(
      Uri.parse('$base/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      return (true, null);
    }

    return (
      false,
      _errorFromResponse(response, fallback: 'Registration failed')
    );
  }

  Future<(bool, String?)> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$base/auth/token/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      await _saveTokens(
          decoded['access'] as String, decoded['refresh'] as String);
      return (true, null);
    }

    return (
      false,
      _errorFromResponse(response, fallback: 'Invalid credentials')
    );
  }

  Future<bool> _refreshTokenIfNeeded() async {
    final refresh = await _refreshToken;
    if (refresh == null) {
      return false;
    }

    final response = await http.post(
      Uri.parse('$base/auth/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['access'] != null) {
        await _storage.write(key: 'access', value: decoded['access'] as String);
        return true;
      }
    }

    return false;
  }

  Map<String, String> _headers(String? access,
      [Map<String, String>? overrides]) {
    return {
      'Accept': 'application/json',
          if (access != null) 'Authorization': 'Bearer $access',
      if (overrides != null) ...overrides,
    };
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year.toString().padLeft(4, '0')}-${two(local.month)}-${two(local.day)}';
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  Future<http.Response> _sendAuthorized(
    Future<http.Response> Function(String? accessToken) makeRequest,
  ) async {
    Future<http.Response> attempt() async {
      final access = await _accessToken;
      if (access == null) {
        return http.Response('', 401);
      }
      return makeRequest(access);
    }

    var response = await attempt();
    if (response.statusCode == 401 && await _refreshTokenIfNeeded()) {
      response = await attempt();
    }
    return response;
  }

  String _extractErrorMessage(http.Response response) {
    if (response.body.isEmpty) {
      return 'Request failed with status ${response.statusCode}';
    }
    try {
      final Object? decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return detail;
        }
        final message = decoded['message'];
        if (message is String && message.isNotEmpty) {
          return message;
        }
        if (decoded.values.isNotEmpty) {
          final dynamic firstValue = decoded.values.first;
          if (firstValue is List && firstValue.isNotEmpty) {
            final first = firstValue.first;
            if (first is String) {
              return first;
            }
          } else if (firstValue is String) {
            return firstValue;
          }
        }
      } else if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is String) {
          return first;
        }
      }
    } catch (_) {
      // ignore decode errors and fall through to raw body
    }
    return response.body;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/profile/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<UserSettings> fetchUserSettings() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/settings/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return UserSettings.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to load settings: ${_extractErrorMessage(response)}',
    );
  }

  Future<UserSettings> updateUserSettings({
    String? fullName,
    String? nickname,
    String? phone,
    int? age,
    String? gender,
    bool? notificationsEnabled,
    bool? prefersDarkMode,
    String? language,
  }) async {
    final payload = <String, dynamic>{};
    if (fullName != null) payload['full_name'] = fullName;
    if (nickname != null) payload['nickname'] = nickname;
    if (phone != null) payload['phone'] = phone;
    if (age != null) payload['age'] = age;
    if (gender != null) payload['gender'] = gender;
    if (notificationsEnabled != null) {
      payload['notifications_enabled'] = notificationsEnabled;
    }
    if (prefersDarkMode != null) {
      payload['prefers_dark_mode'] = prefersDarkMode;
    }
    if (language != null) payload['language'] = language;

    final response = await _sendAuthorized(
      (access) => http.put(
        Uri.parse('$base/settings/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode(payload),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return UserSettings.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to update settings: ${_extractErrorMessage(response)}',
    );
  }

  Future<MoodUpdateResult> updateMood({
    required int value,
    String? timezone,
  }) async {
    final payload = <String, dynamic>{
      'value': value.clamp(1, 5),
    };
    if (timezone != null && timezone.trim().isNotEmpty) {
      payload['timezone'] = timezone.trim();
    }

    final response = await _sendAuthorized(
      (access) => http.post(
        Uri.parse('$base/mood/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode(payload),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return MoodUpdateResult.success(decoded);
    }

    if (response.statusCode == 429) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return MoodUpdateResult.limit(decoded);
    }

    throw ApiClientException(
      'Unable to update mood: ${_extractErrorMessage(response)}',
    );
  }

  Future<WellnessTasksResponse> fetchWellnessTasks() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/wellness/tasks/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final tasksJson = (decoded['tasks'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final tasks =
          tasksJson.map(WellnessTaskItem.fromJson).toList(growable: false);

      final summaryJson = decoded['summary'] as Map<String, dynamic>? ?? {};
      final summary = WellnessTaskSummary(
        total: summaryJson['total'] as int? ?? tasks.length,
        completed: summaryJson['completed'] as int? ??
            tasks.where((t) => t.isCompleted).length,
      );

      final daily = tasks
          .where((task) => task.category == WellnessTaskCategory.daily)
          .toList();
      final evening = tasks
          .where((task) => task.category == WellnessTaskCategory.evening)
          .toList();

      return WellnessTasksResponse(
        daily: daily,
        evening: evening,
        summary: summary,
      );
    }

    if (response.statusCode == 401) {
      throw ApiClientException(
          'You need to log in to view your wellness plan.');
    }

    throw ApiClientException(
      'Unable to fetch wellness tasks: ${_extractErrorMessage(response)}',
    );
  }

  Future<WellnessTaskItem> toggleWellnessTaskCompletion(
    int taskId,
    bool isCompleted,
  ) async {
    final response = await _sendAuthorized(
      (access) => http.patch(
        Uri.parse('$base/wellness/tasks/$taskId/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode({'is_completed': isCompleted}),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return WellnessTaskItem.fromJson(decoded);
    }

    if (response.statusCode == 404) {
      throw ApiClientException('Task not found');
    }

    throw ApiClientException(
      'Unable to update task: ${_extractErrorMessage(response)}',
    );
  }

  Future<WellnessTaskItem> createWellnessTask({
    required String title,
    required WellnessTaskCategory category,
  }) async {
    final response = await _sendAuthorized(
      (access) => http.post(
        Uri.parse('$base/wellness/tasks/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode({
          'title': title,
          'category': category.apiValue,
        }),
      ),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return WellnessTaskItem.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to add task: ${_extractErrorMessage(response)}',
    );
  }

  Future<void> deleteWellnessTask(int taskId) async {
    final response = await _sendAuthorized(
      (access) => http.delete(
        Uri.parse('$base/wellness/tasks/$taskId/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 404) {
      throw ApiClientException('Task already removed');
    }

    throw ApiClientException(
      'Unable to delete task: ${_extractErrorMessage(response)}',
    );
  }

  Future<List<WellnessJournalEntry>> fetchWellnessJournalEntries() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/wellness/journals/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final entriesJson = (decoded['entries'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      return entriesJson.map(WellnessJournalEntry.fromJson).toList();
    }

    if (response.statusCode == 401) {
      throw ApiClientException('You need to log in to view journal entries.');
    }

    throw ApiClientException(
      'Unable to fetch journal entries: ${_extractErrorMessage(response)}',
    );
  }

  Future<WellnessJournalEntry> createWellnessJournalEntry({
    required String title,
    required String note,
    required String mood,
    required String entryType,
  }) async {
    final response = await _sendAuthorized(
      (access) => http.post(
        Uri.parse('$base/wellness/journals/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode({
          'title': title,
          'note': note,
          'mood': mood,
          'entry_type': entryType,
        }),
      ),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return WellnessJournalEntry.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to save journal entry: ${_extractErrorMessage(response)}',
    );
  }

  Future<void> deleteWellnessJournalEntry(int entryId) async {
    final response = await _sendAuthorized(
      (access) => http.delete(
        Uri.parse('$base/wellness/journals/$entryId/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 404) {
      throw ApiClientException('Entry already removed');
    }

    throw ApiClientException(
      'Unable to delete journal entry: ${_extractErrorMessage(response)}',
    );
  }

  Future<WalletInfo> getWallet() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/wallet/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return WalletInfo.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to fetch wallet details: ${_extractErrorMessage(response)}',
    );
  }

  Future<int> rechargeWallet(int amount) async {
    final response = await _sendAuthorized(
      (access) => http.post(
        Uri.parse('$base/wallet/recharge/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode({'amount': amount}),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded['wallet_minutes'] as int? ?? amount;
    }

    throw ApiClientException(
      'Unable to recharge wallet: ${_extractErrorMessage(response)}',
    );
  }

  Future<List<SupportGroupItem>> fetchSupportGroups() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/support-groups/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final groupsJson = (decoded['groups'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      return groupsJson.map(SupportGroupItem.fromJson).toList(growable: false);
    }

    throw ApiClientException(
      'Unable to load support groups: ${_extractErrorMessage(response)}',
    );
  }

  Future<SupportGroupItem> updateSupportGroupMembership({
    required String slug,
    required SupportGroupAction action,
  }) async {
    final response = await _sendAuthorized(
      (access) => http.post(
        Uri.parse('$base/support-groups/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode({
          'slug': slug,
          'action': action == SupportGroupAction.join ? 'join' : 'leave',
        }),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final groupJson = decoded['group'] as Map<String, dynamic>? ?? {};
      return SupportGroupItem.fromJson(groupJson);
    }

    throw ApiClientException(
      'Unable to update group membership: ${_extractErrorMessage(response)}',
    );
  }

  Future<List<UpcomingSessionItem>> fetchUpcomingSessions() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/sessions/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as List<dynamic>? ?? [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(UpcomingSessionItem.fromJson)
          .toList(growable: false);
    }

    throw ApiClientException(
      'Unable to load sessions: ${_extractErrorMessage(response)}',
    );
  }

  Future<UpcomingSessionItem> createUpcomingSession({
    required String title,
    required SessionType sessionType,
    required DateTime startTime,
    required String counsellorName,
    String? notes,
    bool isConfirmed = true,
  }) async {
    final response = await _sendAuthorized(
      (access) => http.post(
        Uri.parse('$base/sessions/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode({
          'title': title,
          'session_type': sessionType.apiValue,
          'start_time': startTime.toUtc().toIso8601String(),
          'counsellor_name': counsellorName,
          'notes': notes,
          'is_confirmed': isConfirmed,
        }),
      ),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return UpcomingSessionItem.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to create session: ${_extractErrorMessage(response)}',
    );
  }

  Future<UpcomingSessionItem> updateUpcomingSession({
    required int sessionId,
    String? title,
    SessionType? sessionType,
    DateTime? startTime,
    String? counsellorName,
    String? notes,
    bool? isConfirmed,
  }) async {
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title;
    if (sessionType != null) payload['session_type'] = sessionType.apiValue;
    if (startTime != null)
      payload['start_time'] = startTime.toUtc().toIso8601String();
    if (counsellorName != null) payload['counsellor_name'] = counsellorName;
    if (notes != null) payload['notes'] = notes;
    if (isConfirmed != null) payload['is_confirmed'] = isConfirmed;

    final response = await _sendAuthorized(
      (access) => http.patch(
        Uri.parse('$base/sessions/$sessionId/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode(payload),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return UpcomingSessionItem.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to update session: ${_extractErrorMessage(response)}',
    );
  }

  Future<void> deleteUpcomingSession(int sessionId) async {
    final response = await _sendAuthorized(
      (access) => http.delete(
        Uri.parse('$base/sessions/$sessionId/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 404) {
      throw ApiClientException('Session already removed');
    }

    throw ApiClientException(
      'Unable to delete session: ${_extractErrorMessage(response)}',
    );
  }

  Future<UpcomingSessionItem> scheduleQuickSession(
    DateTime startTime, {
    String? title,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'date': _formatDate(startTime),
      'time': _formatTime(startTime),
    };
    if (title != null && title.trim().isNotEmpty) {
      payload['title'] = title.trim();
    }
    if (notes != null && notes.trim().isNotEmpty) {
      payload['notes'] = notes.trim();
    }

    final response = await _sendAuthorized(
      (access) => http.post(
        Uri.parse('$base/sessions/quick/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode(payload),
      ),
    );

    if (response.statusCode == 201) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final sessionJson = decoded['session'] as Map<String, dynamic>? ?? {};
      return UpcomingSessionItem.fromJson(sessionJson);
    }

    throw ApiClientException(
      'Unable to schedule session: ${_extractErrorMessage(response)}',
    );
  }

  Future<AnalyticsReport> fetchAnalyticsReport() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/reports/analytics/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalyticsReport.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to load analytics: ${_extractErrorMessage(response)}',
    );
  }

  Future<GuidanceResponse> fetchGuidanceResources({
    String? type,
    String? category,
    bool featured = false,
  }) async {
    final params = <String, String>{};
    if (type != null && type.trim().isNotEmpty) {
      params['type'] = type.trim();
    }
    if (category != null && category.trim().isNotEmpty) {
      params['category'] = category.trim();
    }
    if (featured) {
      params['featured'] = 'true';
    }

    final uri = params.isEmpty
        ? Uri.parse('$base/guidance/resources/')
        : Uri.parse('$base/guidance/resources/').replace(queryParameters: params);

    final response = await _sendAuthorized(
      (access) => http.get(
        uri,
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return GuidanceResponse.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to load resources: ${_extractErrorMessage(response)}',
    );
  }

  Future<MusicTracksResponse> fetchMusicTracks({String? mood}) async {
    final params = <String, String>{};
    if (mood != null && mood.trim().isNotEmpty) {
      params['mood'] = mood.trim();
    }
    final uri = params.isEmpty
        ? Uri.parse('$base/content/music/')
        : Uri.parse('$base/content/music/').replace(queryParameters: params);

    final response = await _sendAuthorized(
      (access) => http.get(uri, headers: _headers(access)),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final tracksJson = (decoded['tracks'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final moods = (decoded['moods'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(growable: false);
      final count = decoded['count'] as int? ?? tracksJson.length;

      final tracks =
          tracksJson.map(MusicTrackItem.fromJson).toList(growable: false);
      return MusicTracksResponse(tracks: tracks, moods: moods, count: count);
    }

    throw ApiClientException(
      'Unable to load music tracks: ${_extractErrorMessage(response)}',
    );
  }

  Future<MindCareBoostersResponse> fetchMindCareBoosters(
      {String? category}) async {
    final params = <String, String>{};
    if (category != null && category.trim().isNotEmpty) {
      params['category'] = category.trim();
    }
    final uri = params.isEmpty
        ? Uri.parse('$base/content/boosters/')
        : Uri.parse('$base/content/boosters/')
            .replace(queryParameters: params);

    final response = await _sendAuthorized(
      (access) => http.get(uri, headers: _headers(access)),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final boostersJson = (decoded['boosters'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final categories = (decoded['categories'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(growable: false);
      final groupedRaw = decoded['grouped'] as Map<String, dynamic>? ?? {};
      final grouped = <String, List<MindCareBoosterItem>>{};
      groupedRaw.forEach((key, value) {
        final items = (value as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(MindCareBoosterItem.fromJson)
            .toList(growable: false);
        grouped[key.toString()] = items;
      });

      final boosters = boostersJson
          .map(MindCareBoosterItem.fromJson)
          .toList(growable: false);
      return MindCareBoostersResponse(
        boosters: boosters,
        categories: categories,
        groupedByCategory: grouped,
      );
    }

    throw ApiClientException(
      'Unable to load boosters: ${_extractErrorMessage(response)}',
    );
  }

  Future<MeditationSessionsResponse> fetchMeditationSessions({
    String? category,
    String? difficulty,
    bool featured = false,
  }) async {
    final params = <String, String>{};
    if (category != null && category.trim().isNotEmpty) {
      params['category'] = category.trim();
    }
    if (difficulty != null && difficulty.trim().isNotEmpty) {
      params['difficulty'] = difficulty.trim();
    }
    if (featured) {
      params['featured'] = 'true';
    }

    final uri = params.isEmpty
        ? Uri.parse('$base/content/meditations/')
        : Uri.parse('$base/content/meditations/')
            .replace(queryParameters: params);

    final response = await _sendAuthorized(
      (access) => http.get(uri, headers: _headers(access)),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final sessionsJson = (decoded['sessions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
      final categories = (decoded['categories'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(growable: false);
      final groupedRaw = decoded['grouped'] as Map<String, dynamic>? ?? {};
      final grouped = <String, List<MeditationSessionItem>>{};
      groupedRaw.forEach((key, value) {
        final items = (value as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(MeditationSessionItem.fromJson)
            .toList(growable: false);
        grouped[key.toString()] = items;
      });
      final featuredJson = (decoded['featured'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MeditationSessionItem.fromJson)
          .toList(growable: false);

      final sessions = sessionsJson
          .map(MeditationSessionItem.fromJson)
          .toList(growable: false);
      return MeditationSessionsResponse(
        sessions: sessions,
        categories: categories,
        groupedByCategory: grouped,
        featured: featuredJson,
      );
    }

    throw ApiClientException(
      'Unable to load meditations: ${_extractErrorMessage(response)}',
    );
  }

  Future<LegacyGuidelinesResponse> fetchLegacyGuidelines() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/legacy/guidelines/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return LegacyGuidelinesResponse.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to load guidelines: ${_extractErrorMessage(response)}',
    );
  }

  Future<List<LegacyCounsellor>> fetchLegacyExperts() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/legacy/expert-connect/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final counsellors = (decoded['counsellors'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(LegacyCounsellor.fromJson)
          .toList(growable: false);
      return counsellors;
    }

    throw ApiClientException(
      'Unable to load experts: ${_extractErrorMessage(response)}',
    );
  }

  Future<LegacyBreathingConfig> fetchLegacyBreathingConfig() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/legacy/breathing/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return LegacyBreathingConfig.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to load breathing config: ${_extractErrorMessage(response)}',
    );
  }

  Future<List<LegacyAssessmentQuestion>> fetchLegacyAssessmentQuestions() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/legacy/assessment/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final questions = (decoded['questions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(LegacyAssessmentQuestion.fromJson)
          .toList(growable: false);
      return questions;
    }

    throw ApiClientException(
      'Unable to load assessment: ${_extractErrorMessage(response)}',
    );
  }

  Future<List<String>> fetchLegacyAffirmations() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/legacy/affirmations/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final affirmations = (decoded['affirmations'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(growable: false);
      return affirmations;
    }

    throw ApiClientException(
      'Unable to load affirmations: ${_extractErrorMessage(response)}',
    );
  }

  Future<LegacyAdvancedCareResponse> fetchLegacyAdvancedCare() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/legacy/advanced-care/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return LegacyAdvancedCareResponse.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to load advanced care content: ${_extractErrorMessage(response)}',
    );
  }

  Future<LegacyFeatureDetail> fetchLegacyFeatureDetail() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/legacy/feature-detail/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return LegacyFeatureDetail.fromJson(decoded);
    }

    throw ApiClientException(
      'Unable to load feature detail: ${_extractErrorMessage(response)}',
    );
  }

  // Counselor-specific methods
  Future<Map<String, dynamic>> getCounsellorProfile() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/counselor/profile/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 404) {
      throw ApiClientException('Counsellor profile not found');
    }

    throw ApiClientException(
      'Unable to load counsellor profile: ${_extractErrorMessage(response)}',
    );
  }

  Future<Map<String, dynamic>> updateCounsellorProfile({
    String? specialization,
    int? experienceYears,
    List<String>? languages,
    bool? isAvailable,
    String? bio,
  }) async {
    final payload = <String, dynamic>{};
    if (specialization != null) payload['specialization'] = specialization;
    if (experienceYears != null) payload['experience_years'] = experienceYears;
    if (languages != null) payload['languages'] = languages;
    if (isAvailable != null) payload['is_available'] = isAvailable;
    if (bio != null) payload['bio'] = bio;

    final response = await _sendAuthorized(
      (access) => http.patch(
        Uri.parse('$base/counselor/profile/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode(payload),
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiClientException(
      'Unable to update counsellor profile: ${_extractErrorMessage(response)}',
    );
  }

  Future<List<Map<String, dynamic>>> getCounsellorAppointments({String? status}) async {
    final params = <String, String>{};
    if (status != null && status.trim().isNotEmpty) {
      params['status'] = status.trim();
    }

    final uri = params.isEmpty
        ? Uri.parse('$base/counselor/appointments/')
        : Uri.parse('$base/counselor/appointments/').replace(queryParameters: params);

    final response = await _sendAuthorized(
      (access) => http.get(uri, headers: _headers(access)),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    }

    throw ApiClientException(
      'Unable to load appointments: ${_extractErrorMessage(response)}',
    );
  }

  Future<Map<String, dynamic>> getCounsellorStats() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/counselor/stats/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 404) {
      throw ApiClientException('Counsellor profile not found');
    }

    throw ApiClientException(
      'Unable to load stats: ${_extractErrorMessage(response)}',
    );
  }

  // Chat methods
  Future<Map<String, dynamic>> createChat({String? initialMessage}) async {
    final payload = <String, dynamic>{};
    if (initialMessage != null && initialMessage.trim().isNotEmpty) {
      payload['initial_message'] = initialMessage.trim();
    }

    final response = await _sendAuthorized(
      (access) => http.post(
        Uri.parse('$base/chats/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode(payload),
      ),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiClientException(
      'Unable to create chat: ${_extractErrorMessage(response)}',
    );
  }

  Future<List<Map<String, dynamic>>> getChatList() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/chats/list/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    }

    throw ApiClientException(
      'Unable to load chat list: ${_extractErrorMessage(response)}',
    );
  }

  Future<List<Map<String, dynamic>>> getQueuedChats() async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/counselor/queued-chats/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    }

    throw ApiClientException(
      'Unable to load queued chats: ${_extractErrorMessage(response)}',
    );
  }

  Future<Map<String, dynamic>> acceptChat(int chatId) async {
    final response = await _sendAuthorized(
      (access) => http.patch(
        Uri.parse('$base/chats/$chatId/accept/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiClientException(
      'Unable to accept chat: ${_extractErrorMessage(response)}',
    );
  }

  Future<Map<String, dynamic>> startSession(int sessionId) async {
    final response = await _sendAuthorized(
      (access) => http.post(
        Uri.parse('$base/sessions/$sessionId/start/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiClientException(
      'Unable to start session: ${_extractErrorMessage(response)}',
    );
  }

  Future<Map<String, dynamic>> endSession(int sessionId) async {
    final response = await _sendAuthorized(
      (access) => http.post(
        Uri.parse('$base/sessions/$sessionId/end/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiClientException(
      'Unable to end session: ${_extractErrorMessage(response)}',
    );
  }

  /// Get current session duration from backend
  Future<Map<String, dynamic>> getSessionDuration(int sessionId) async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/sessions/$sessionId/duration/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiClientException(
      'Unable to get session duration: ${_extractErrorMessage(response)}',
    );
  }

  /// Update session (risk_level, notes, manual_flag)
  Future<Map<String, dynamic>> updateSession(
    int sessionId, {
    String? riskLevel,
    String? manualFlag,
    String? notes,
  }) async {
    final payload = <String, dynamic>{};
    if (riskLevel != null) payload['risk_level'] = riskLevel;
    if (manualFlag != null) payload['manual_flag'] = manualFlag;
    if (notes != null) payload['notes'] = notes;

    final response = await _sendAuthorized(
      (access) => http.patch(
        Uri.parse('$base/sessions/$sessionId/update/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode(payload),
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiClientException(
      'Unable to update session: ${_extractErrorMessage(response)}',
    );
  }

  /// Get complete session summary
  Future<Map<String, dynamic>> getSessionSummary(int sessionId) async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/sessions/$sessionId/summary/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiClientException(
      'Unable to get session summary: ${_extractErrorMessage(response)}',
    );
  }

  // Chat message methods
  Future<List<Map<String, dynamic>>> getChatMessages(int chatId) async {
    final response = await _sendAuthorized(
      (access) => http.get(
        Uri.parse('$base/chats/$chatId/messages/'),
        headers: _headers(access),
      ),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    }

    throw ApiClientException(
      'Unable to load chat messages: ${_extractErrorMessage(response)}',
    );
  }

  Future<Map<String, dynamic>> sendChatMessage(int chatId, String text) async {
    final response = await _sendAuthorized(
      (access) => http.post(
        Uri.parse('$base/chats/$chatId/messages/'),
        headers: _headers(access, {'Content-Type': 'application/json'}),
        body: jsonEncode({'text': text}),
      ),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw ApiClientException(
      'Unable to send message: ${_extractErrorMessage(response)}',
    );
  }

  // WebSocket connection for real-time chat
  Future<WebSocketChannel> connectChatWebSocket(int chatId) async {
    // Get access token for authentication
    final accessToken = await _accessToken;
    if (accessToken == null) {
      throw ApiClientException('Not authenticated. Please login first.');
    }

    // Get WebSocket URL (ws:// for development, wss:// for production)
    // Note: WebSocket routing is at root level, not under /api/
    // base is http://127.0.0.1:8000/api, so we need to remove /api for WebSocket
    String httpBase = base;
    if (httpBase.endsWith('/api')) {
      httpBase = httpBase.substring(0, httpBase.length - 4);
    } else if (httpBase.endsWith('/api/')) {
      httpBase = httpBase.substring(0, httpBase.length - 5);
    }
    
    // Determine WebSocket scheme based on HTTP scheme
    String wsScheme = 'ws://';
    if (httpBase.startsWith('https://')) {
      wsScheme = 'wss://';
      httpBase = httpBase.substring(8); // Remove 'https://'
    } else if (httpBase.startsWith('http://')) {
      httpBase = httpBase.substring(7); // Remove 'http://'
    }
    
    // Construct WebSocket URL with proper path (ensure trailing slash matches server route)
    final wsPath = '/ws/chat/$chatId/'; // Match server route exactly
    final wsUrl = '$wsScheme$httpBase$wsPath?token=${Uri.encodeComponent(accessToken)}';
    
    // Log the exact URI for debugging
    if (kDebugMode) {
      print('[WebSocket] Connecting to: $wsUrl');
      print('[WebSocket] Chat ID: $chatId');
      print('[WebSocket] Scheme: $wsScheme');
    }
    
    try {
      final uri = Uri.parse(wsUrl);
      final channel = WebSocketChannel.connect(uri);
      
      if (kDebugMode) {
        print('[WebSocket] Connection established successfully');
      }
      
      return channel;
    } catch (e, stackTrace) {
      // Log detailed error information for debugging
      if (kDebugMode) {
        print('[WebSocket] Connection failed!');
        print('[WebSocket] URL attempted: $wsUrl');
        print('[WebSocket] Error: $e');
        print('[WebSocket] Stack trace: $stackTrace');
      }
      // Re-throw as ApiClientException for consistent error handling
      throw ApiClientException('WebSocket connection failed: $e');
    }
  }
}