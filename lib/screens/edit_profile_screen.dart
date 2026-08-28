import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_screen.dart';
import '../theme/app_colors.dart';
import '../services/profile_service.dart';


// ================================================================
// EDIT PROFILE SCREEN
// ================================================================
//
// Form untuk mengubah data profil: Nama Lengkap, Username, Tanggal
// Lahir, Nomor Telepon, Email, dan foto profil. Foto diambil lewat
// kamera/galeri (pola pengambilan foto sama seperti di
// review_screen.dart -- _showPhotoSourceSheet), lalu semuanya
// disimpan ke ProfileService supaya langsung sinkron dengan
// ProfileScreen dan ulasan-ulasan berikutnya.
//
// ================================================================

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  DateTime? _birthDate;

  // null di awal berarti "belum diganti", jadi masih pakai foto
  // lama dari ProfileService (lihat _displayPhotoPath).
  String? _newPhotoPath;

  // Nama-nama bulan Indonesia untuk format "07 Oktober 2006" --
  // tidak pakai package intl supaya tidak menambah dependency baru
  // (lihat pubspec.yaml, package intl memang belum ada di sana).
  static const List<String> _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    final ProfileData current = ProfileService.instance.profile.value;
    _nameController = TextEditingController(text: current.name);
    _usernameController = TextEditingController(text: current.username);
    _phoneController = TextEditingController(text: current.phone);
    _emailController = TextEditingController(text: current.email);
    _birthDate = current.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? get _displayPhotoPath =>
      _newPhotoPath ?? ProfileService.instance.profile.value.photoPath;

  // Foto profil untuk pratinjau di form ini menggunakan helper
  // bersama buildAvatarImage() dari profile_screen.dart, yang
  // otomatis membedakan URL network dan path file lokal.

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_monthNames[date.month - 1]} '
        '${date.year}';
  }

  // ============================================================
  // AMBIL FOTO (KAMERA / GALERI)
  // ============================================================

  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (photo == null) return;

      setState(() {
        _newPhotoPath = photo.path;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka kamera.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (photo == null) return;

      setState(() {
        _newPhotoPath = photo.path;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka galeri.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.primaryBlue),
                title: const Text('Ambil Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryBlue),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // PILIH TANGGAL LAHIR
  // ============================================================

  Future<void> _pickBirthDate() async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() {
      _birthDate = picked;
    });
  }

  // ============================================================
  // SIMPAN
  // ============================================================

  Future<void> _handleSave() async {
    final String name = _nameController.text.trim();
    final String username = _usernameController.text.trim();
    final String phone = _phoneController.text.trim();
    final String email = _emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama tidak boleh kosong.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Memperbarui profil...'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await ProfileService.instance.updateProfile(
      name: name,
      username: username,
      birthDate: _birthDate,
      phone: phone,
      email: email,
      photoPath: _newPhotoPath ?? _displayPhotoPath,
    );

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil berhasil diperbarui'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
                children: [
                  const SizedBox(height: 10),

                  // ==============================================
                  // AVATAR + GANTI FOTO
                  // ==============================================

                  Center(
                    child: GestureDetector(
                      onTap: _showPhotoSourceSheet,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: buildAvatarImage(
                              _displayPhotoPath,
                              size: 90,
                            ),

                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Center(
                    child: TextButton(
                      onPressed: _showPhotoSourceSheet,
                      child: const Text(
                        'Ganti Foto Profil',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ==============================================
                  // NAMA LENGKAP
                  // ==============================================

                  _buildFieldLabel('Nama Lengkap'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Nama lengkap kamu',
                  ),

                  const SizedBox(height: 20),

                  // ==============================================
                  // USERNAME
                  // ==============================================

                  _buildFieldLabel('Username'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _usernameController,
                    hintText: 'Username kamu',
                  ),

                  const SizedBox(height: 20),

                  // ==============================================
                  // TANGGAL LAHIR
                  // ==============================================

                  _buildFieldLabel('Tanggal Lahir'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickBirthDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.fieldBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _birthDate == null
                                  ? 'Pilih tanggal lahir'
                                  : _formatDate(_birthDate!),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: _birthDate == null
                                    ? const Color(0xFF9A9A9A)
                                    : AppColors.darkText,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.greyText,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==============================================
                  // NOMOR TELEPON
                  // ==============================================

                  _buildFieldLabel('Nomor Telepon'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _phoneController,
                    hintText: 'Nomor telepon kamu',
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 20),

                  // ==============================================
                  // EMAIL
                  // ==============================================

                  _buildFieldLabel('Email'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Email kamu',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 28),

                  // ==============================================
                  // SIMPAN
                  // ==============================================

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.darkBlue,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
  // LABEL FIELD
  // ============================================================

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.darkText,
      ),
    );
  }

  // ============================================================
  // TEXT FIELD -- kotak putih bergaris tipis (border), BUKAN lagi
  // filled abu-abu seperti sebelumnya, disamakan dengan tampilan
  // referensi (Nama Lengkap/Username/Nomor Telepon/Email).
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13.5, color: AppColors.darkText),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF9A9A9A)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
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
                    border: Border.all(color:  AppColors.borderColorLight),
                  ),
                  child: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF555555),
                    size: 27,
                  ),
                ),
              ),
            ),
            const Text(
              'Edit Profil',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}