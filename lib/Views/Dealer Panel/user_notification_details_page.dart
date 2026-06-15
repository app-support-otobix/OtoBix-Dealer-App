import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:otobix/Controllers/user_notifications_controller.dart';
import 'package:otobix/Models/user_notifications_model.dart';
import 'package:otobix/Utils/app_colors.dart';

class UserNotificationDetailsPage extends StatefulWidget {
  final String id;
  const UserNotificationDetailsPage({super.key, required this.id});

  @override
  State<UserNotificationDetailsPage> createState() =>
      _UserNotificationDetailsPageState();
}

class _UserNotificationDetailsPageState
    extends State<UserNotificationDetailsPage> {
  UserNotificationsModel? item;
  bool loading = true;

  final UserNotificationsController c = Get.find<UserNotificationsController>();

  @override
  void initState() {
    super.initState();
    () async {
      final res = await c.fetchNotificationDetails(widget.id);
      if (mounted) {
        setState(() {
          item = res;
          loading = false;
        });
      }
    }();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.black),
        title: const Text(
          'Notification Details',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        // actions: [
        //   if (item != null && !item!.isRead)
        //     TextButton(
        //       onPressed: () async {
        //         // Optional: mark read from here if you expose such API
        //         await c.markNotificationAsRead(item!.id ?? '');
        //         if (mounted) {
        //           setState(
        //             () =>
        //                 item = UserNotificationsModel(
        //                   id: item!.id,
        //                   userId: item!.userId,
        //                   type: item!.type,
        //                   title: item!.title,
        //                   body: item!.body,
        //                   data: item!.data,
        //                   isRead: true,
        //                   createdAt: item!.createdAt,
        //                 ),
        //           );
        //         }
        //       },
        //       child: const Text(
        //         'Mark read',
        //         style: TextStyle(color: Colors.white),
        //       ),
        //     ),
        // ],
      ),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : item == null
              ? const Center(child: Text('Not found'))
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.grey.withOpacity(
                                      .2,
                                    ),
                                    child: Icon(
                                      _iconForType(item!.type),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item!.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            _chip(
                                              context,
                                              label: item!.type,
                                              color: theme.colorScheme.primary
                                                  .withOpacity(.12),
                                              textColor:
                                                  theme.colorScheme.primary,
                                            ),
                                            // _chip(
                                            //   context,
                                            //   label:
                                            //       item!.isRead ? 'Read' : 'New',
                                            //   color: (item!.isRead
                                            //           ? Colors.grey
                                            //           : Colors.green)
                                            //       .withOpacity(.12),
                                            //   textColor:
                                            //       (item!.isRead
                                            //           ? Colors.grey[700]
                                            //           : Colors.green[700]) ??
                                            //       Colors.green,
                                            // ),
                                            Text(
                                              _formatTime(item!.createdAt),
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // IconButton(
                                  //   tooltip: 'Copy message',
                                  //   onPressed: () async {
                                  //     await Clipboard.setData(
                                  //       ClipboardData(text: item!.body),
                                  //     );
                                  //     if (!mounted) return;
                                  //     ScaffoldMessenger.of(
                                  //       Get.context!,
                                  //     ).showSnackBar(
                                  //       const SnackBar(
                                  //         content: Text('Message copied'),
                                  //         duration: Duration(milliseconds: 900),
                                  //       ),
                                  //     );
                                  //   },
                                  //   icon: const Icon(Icons.copy_rounded),
                                  // ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Divider(),
                              const SizedBox(height: 5),
                              Text(
                                item!.body,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Data (if any)
                      // if (item!.data.isNotEmpty) ...[
                      //   // const SizedBox(height: 16),
                      //   // Text('Details', style: theme.textTheme.titleMedium),
                      //   // const SizedBox(height: 8),
                      //   Card(
                      //     color: AppColors.white,
                      //     elevation: 0,
                      //     shape: RoundedRectangleBorder(
                      //       borderRadius: BorderRadius.circular(10),
                      //     ),
                      //     child: Padding(
                      //       padding: const EdgeInsets.all(15),
                      //       child: Column(
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: [
                      //           Text(
                      //             'Details',
                      //             style: const TextStyle(
                      //               fontSize: 15,
                      //               fontWeight: FontWeight.bold,
                      //             ),
                      //           ),
                      //           Divider(),

                      //           ...item!.data.entries.map((e) {
                      //             return ListTile(
                      //               dense: true,
                      //               title: Text(e.key),
                      //               subtitle: Text('${e.value}'),
                      //             );
                      //           }),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      // ],

                      // Optional CTA if carId present in data
                      // if ((item!.data['carId'] ?? '').toString().isNotEmpty)
                      //   Padding(
                      //     padding: const EdgeInsets.only(top: 16),
                      //     child: FilledButton.icon(
                      //       onPressed: () {
                      //         final carId = item!.data['carId'].toString();
                      //         // TODO: navigate to your car details screen
                      //         // Get.toNamed('/car/details', parameters: {'id': carId});
                      //       },
                      //       icon: const Icon(
                      //         Icons.directions_car_filled_rounded,
                      //       ),
                      //       label: Text(
                      //         'Open ${item!.data['carName'] ?? 'car'}',
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                ),
              ),
    );
  }

  // --- helpers ---

  Widget _chip(
    BuildContext context, {
    required String label,
    required Color color,
    Color? textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: textColor),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'bid_won':
        return Icons.emoji_events;
      case 'bid_lost':
        return Icons.sentiment_dissatisfied;
      case 'bid_outbid':
        return Icons.trending_up;
      case 'auction_reminder':
        return Icons.alarm;
      case 'message':
        return Icons.chat_bubble;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    final d = dt.toLocal();
    final date =
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final time =
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:otobix/Controllers/user_notifications_controller.dart';
// import 'package:otobix/Models/user_notifications_model.dart';
// import 'package:otobix/Utils/app_colors.dart';

// class UserNotificationDetailsPage extends StatefulWidget {
//   final String id;
//   const UserNotificationDetailsPage({super.key, required this.id});

//   @override
//   State<UserNotificationDetailsPage> createState() =>
//       _UserNotificationDetailsPageState();
// }

// class _UserNotificationDetailsPageState
//     extends State<UserNotificationDetailsPage> {
//   UserNotificationsModel? item;
//   bool loading = true;

//   final UserNotificationsController getxController =
//       Get.find<UserNotificationsController>();

//   @override
//   void initState() {
//     super.initState();
//     () async {
//       final res = await getxController.fetchNotificationDetails(widget.id);
//       if (mounted) {
//         setState(() {
//           item = res;
//           loading = false;
//         });
//       }
//     }();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: AppColors.green,
//         iconTheme: const IconThemeData(color: AppColors.white),
//         title: const Text(
//           'Notification Details',
//           style: TextStyle(
//             color: AppColors.white,
//             fontSize: 15,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//       body:
//           loading
//               ? const Center(child: CircularProgressIndicator())
//               : item == null
//               ? const Center(child: Text('Not found'))
//               : Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(item!.title, style: theme.textTheme.titleLarge),
//                     const SizedBox(height: 8),
//                     Text(item!.body, style: theme.textTheme.bodyLarge),
//                     // const SizedBox(height: 12),
//                     // if (item!.data.isNotEmpty) Text('Data: ${item!.data}'),
//                   ],
//                 ),
//               ),
//     );
//   }
// }
