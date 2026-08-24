import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            // ==================================================
            // HEADER
            // ==================================================

            _buildHeader(context),

            // ==================================================
            // NOTIFICATION CONTENT
            // ==================================================

            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),

                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 10,
                  bottom: 30,
                ),

                children: [
                  // ==================================================
                  // TODAY
                  // ==================================================

                  const Padding(
                    padding: EdgeInsets.only(
                      left: 5,
                      bottom: 12,
                    ),

                    child: Text(
                      'Hari ini',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),

                  // ==================================================
                  // NOTIFICATION 1
                  // ==================================================

                  _buildNotificationCard(
                    icon: Icons.groups,
                    iconColor: Colors.red,
                    backgroundColor:
                         AppColors.errorBg,
                    title:
                        'Prediksi kepadatan diperbarui',
                    description:
                        'Pulau Pahawang diprediksi ramai hari ini pada pukul 09.00 - 15.00.',
                    time: '10 menit yang lalu',
                    unread: true,
                  ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // NOTIFICATION 2
                  // ==================================================

                  _buildNotificationCard(
                    icon: Icons.explore_outlined,
                    iconColor: AppColors.primaryBlue,
                    backgroundColor:
                         AppColors.lightBlue,
                    title:
                        'Rekomendasi baru untukmu',
                    description:
                        'Ada beberapa destinasi di Lampung yang mungkin sesuai dengan minat perjalananmu.',
                    time: '1 jam yang lalu',
                    unread: true,
                  ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // NOTIFICATION 3
                  // ==================================================

                  _buildNotificationCard(
                    icon: Icons.route_outlined,
                    iconColor: Colors.green,
                    backgroundColor:
                         AppColors.successBg,
                    title:
                        'Itinerary berhasil dibuat',
                    description:
                        'Rencana perjalananmu untuk menjelajahi Lampung telah berhasil dibuat.',
                    time: '2 jam yang lalu',
                    unread: false,
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // PREVIOUS
                  // ==================================================

                  const Padding(
                    padding: EdgeInsets.only(
                      left: 5,
                      bottom: 12,
                    ),

                    child: Text(
                      'Sebelumnya',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),

                  // ==================================================
                  // NOTIFICATION 4
                  // ==================================================

                  _buildNotificationCard(
                    icon: Icons.location_on_outlined,
                    iconColor: AppColors.primaryBlue,
                    backgroundColor:
                         AppColors.lightBlue,
                    title:
                        'Destinasi yang kamu simpan',
                    description:
                        'Pulau Wayang masih tersedia di daftar destinasi tersimpanmu.',
                    time: 'Kemarin',
                    unread: false,
                  ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // NOTIFICATION 5
                  // ==================================================

                  _buildNotificationCard(
                    icon: Icons.calendar_today_outlined,
                    iconColor: Colors.orange,
                    backgroundColor:
                        const Color(0xFFFFF5E6),
                    title:
                        'Perjalananmu semakin dekat',
                    description:
                        'Jangan lupa cek kembali rencana perjalanan dan destinasi yang akan kamu kunjungi.',
                    time: '2 hari yang lalu',
                    unread: false,
                  ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // NOTIFICATION 6
                  // ==================================================

                  _buildNotificationCard(
                    icon: Icons.info_outline,
                    iconColor: const Color(0xFF7B61FF),
                    backgroundColor:
                        const Color(0xFFF1EEFF),
                    title:
                        'Informasi perjalanan',
                    description:
                        'Pastikan kamu memeriksa informasi destinasi sebelum memulai perjalanan.',
                    time: '3 hari yang lalu',
                    unread: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        10,
      ),

      child: SizedBox(
        height: 48,

        child: Stack(
          alignment: Alignment.center,

          children: [
            // ==================================================
            // BACK BUTTON
            // ==================================================

            Align(
              alignment: Alignment.centerLeft,

              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },

                child: Container(
                  width: 38,
                  height: 38,

                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,

                    border: Border.all(
                      color:  AppColors.borderColorLight,
                    ),
                  ),

                  child: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF555555),
                    size: 27,
                  ),
                ),
              ),
            ),

            // ==================================================
            // TITLE
            // ==================================================

            const Text(
              'Notifikasi',

              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),

            // ==================================================
            // MARK AS READ
            // ==================================================

            Align(
              alignment: Alignment.centerRight,

              child: GestureDetector(
                onTap: () {
                  // Aksi tandai semua sudah dibaca
                },

                child: const Text(
                  'Tandai semua',

                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION CARD
  // ============================================================

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String description,
    required String time,
    required bool unread,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(17),

        border: Border.all(
          color: const Color(0xFFEAEAEA),
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ==================================================
          // ICON
          // ==================================================

          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),

            child: Icon(
              icon,
              color: iconColor,
              size: 21,
            ),
          ),

          const SizedBox(width: 11),

          // ==================================================
          // CONTENT
          // ==================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ==============================================
                // TITLE + UNREAD DOT
                // ==============================================

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Expanded(
                      child: Text(
                        title,

                        maxLines: 2,

                        overflow:
                            TextOverflow.ellipsis,

                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: unread
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                    ),

                    if (unread) ...[
                      const SizedBox(width: 7),

                      Container(
                        width: 7,
                        height: 7,

                        margin:
                            const EdgeInsets.only(
                          top: 4,
                        ),

                        decoration:
                            const BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 5),

                // ==============================================
                // DESCRIPTION
                // ==============================================

                Text(
                  description,

                  maxLines: 2,

                  overflow:
                      TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 10.5,
                    height: 1.4,
                    color: AppColors.greyText,
                  ),
                ),

                const SizedBox(height: 7),

                // ==============================================
                // TIME
                // ==============================================

                Text(
                  time,

                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}