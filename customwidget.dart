// Automatic FlutterFlow imports
import '../../backend/backend.dart';
import '../../flutter_flow/flutter_flow_theme.dart';
import '../../flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
// Begin custom widget code
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stream_feed/stream_feed.dart';
import 'package:timeago/timeago.dart' as timeago;

class ClubManagerFirebaseUser {
  ClubManagerFirebaseUser(this.user);
  auth.User user;
  bool get loggedIn => user != null;
}

ClubManagerFirebaseUser currentUser;
bool get loggedIn => currentUser?.loggedIn ?? false;
Stream<ClubManagerFirebaseUser> clubManagerFirebaseUserStream() =>
    auth.FirebaseAuth.instance
        .authStateChanges()
        .debounce((user) => user == null && !loggedIn
            ? TimerStream(true, const Duration(seconds: 1))
            : Stream.value(user))
        .map<ClubManagerFirebaseUser>(
            (user) => currentUser = ClubManagerFirebaseUser(user));

String _currentJwtToken = '';
String get currentUserUid =>
    currentUserDocument?.uid ?? currentUser?.user?.uid ?? '';
String get currentJwtToken => _currentJwtToken ?? '';

DocumentReference get currentUserReference => currentUser?.user != null
    ? UserRecord.collection.doc(currentUser.user.uid)
    : null;

UserRecord currentUserDocument;

class ClubFeed extends StatefulWidget {
  const ClubFeed({
    Key key,
    this.width,
    this.height,
  }) : super(key: key);

  final double width;
  final double height;

  @override
  _ClubFeedState createState() => _ClubFeedState();
}

class _ClubFeedState extends State<ClubFeed> {
  bool _isLoading = true;
  List activities = [];

  final StreamFeedClient client = StreamFeedClient('xxxxxxxxxxxxx');

  Future<void> _loadActivities({bool pullToRefresh = false}) async {
    if (!pullToRefresh) setState(() => _isLoading = true);
    await client.setUser(
        User(id: currentUserUid), Token(currentUserDocument?.streamToken));

    final clubTimeline =
        client.flatFeed('club_timeline', FFAppState().currentClub.toString());
    final data = await clubTimeline.getActivities();
    if (!pullToRefresh) _isLoading = false;
    setState(() => activities = data);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RefreshIndicator(
        onRefresh: () => _loadActivities(pullToRefresh: true),
        child: _isLoading
            ? const CircularProgressIndicator()
            : activities.isEmpty
                ? const Text('No activities yet!')
                : ListView.separated(
                    itemCount: activities.length,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (_, index) {
                      final activity = activities[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  child: Text("Jon White"),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Jon White",
                                        style: TextStyle(
                                          fontSize: 18,
                                        ),
                                      ),
                                      Text(
                                        'Shared an update ${timeago.format(
                                          activity.time,
                                          allowFromNow: true,
                                        )}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              activity.extraData['tweet'] as String,
                              style: const TextStyle(
                                fontSize: 24,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
