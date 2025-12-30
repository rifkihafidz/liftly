import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/colors.dart';
import '../../../core/models/user.dart';
import '../../../shared/widgets/app_dialogs.dart';
import '../bloc/profile_bloc.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({
    super.key,
    required this.user,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName ?? '');
    _lastNameController = TextEditingController(text: widget.user.lastName ?? '');
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        elevation: 0,
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdated) {
            Navigator.pop(context);
            AppDialogs.showSuccessDialog(
              context: context,
              title: 'Profil Berhasil Diupdate',
              message: 'Data profil Anda telah berhasil diubah.',
            );
          } else if (state is ProfileError) {
            setState(() => _isLoading = false);
            AppDialogs.showErrorDialog(
              context: context,
              title: 'Terjadi Kesalahan',
              message: state.message,
            );
          } else if (state is ProfileLoading) {
            setState(() => _isLoading = true);
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Avatar
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.accent,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Form Fields
                Text(
                  'Informasi Pribadi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),

                // First Name
                TextField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Depan',
                    hintText: 'Masukkan nama depan Anda',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Last Name
                TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Belakang',
                    hintText: 'Masukkan nama belakang Anda',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Masukkan email Anda',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Simpan Perubahan'),
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();

    // Validation
    if (email.isEmpty) {
      AppDialogs.showErrorDialog(
        context: context,
        title: 'Email Kosong',
        message: 'Email tidak boleh kosong.',
      );
      return;
    }

    if (!_isValidEmail(email)) {
      AppDialogs.showErrorDialog(
        context: context,
        title: 'Format Email Tidak Valid',
        message: 'Masukkan format email yang benar.',
      );
      return;
    }

    // Update profile
    context.read<ProfileBloc>().add(
          UpdateUserProfile(
            userId: widget.user.id,
            firstName: firstName.isEmpty ? null : firstName,
            lastName: lastName.isEmpty ? null : lastName,
            email: email,
          ),
        );
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
