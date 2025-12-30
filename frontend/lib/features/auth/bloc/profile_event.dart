part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserProfile extends ProfileEvent {
  final String userId;

  const LoadUserProfile(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateUserProfile extends ProfileEvent {
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? password;

  const UpdateUserProfile({
    required this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.password,
  });

  @override
  List<Object?> get props => [userId, firstName, lastName, email, password];
}

class DeleteUserAccount extends ProfileEvent {
  final String userId;

  const DeleteUserAccount(this.userId);

  @override
  List<Object?> get props => [userId];
}
