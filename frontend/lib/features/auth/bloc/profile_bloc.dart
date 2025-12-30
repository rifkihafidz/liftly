import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/user.dart';
import '../repositories/user_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserRepository userRepository;

  ProfileBloc({UserRepository? userRepository})
      : userRepository = userRepository ?? UserRepository(),
        super(const ProfileInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<DeleteUserAccount>(_onDeleteUserAccount);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      final user = await userRepository.getUserProfile(userId: event.userId);
      emit(ProfileLoaded(user));
    } catch (e) {
      emit(ProfileError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      final user = await userRepository.updateUserProfile(
        userId: event.userId,
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        password: event.password,
      );
      emit(ProfileUpdated(user));
    } catch (e) {
      emit(ProfileError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onDeleteUserAccount(
    DeleteUserAccount event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      await userRepository.deleteUserAccount(userId: event.userId);
      emit(const ProfileDeleted());
    } catch (e) {
      emit(ProfileError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
