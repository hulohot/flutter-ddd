import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_ddd/domain/auth/I_auth_facade.dart';
import 'package:flutter_ddd/domain/auth/auth_failure.dart';
import 'package:flutter_ddd/domain/auth/value_objects.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sign_in_form_event.dart';
part 'sign_in_form_state.dart';
part 'sign_in_form_bloc.freezed.dart';

class SignInFormBloc extends Bloc<SignInFormEvent, SignInFormState> {
  final IAuthFacade _authFacade;

  SignInFormBloc(SignInFormState initialState, this._authFacade)
      : super(initialState);

  @override
  Stream<SignInFormState> mapEventToState(
    SignInFormEvent event,
  ) async* {
    yield* event.map(
      emailChanged: (e) async* {
        yield state.copyWith(
          emailAddress: EmailAddress(e.emailStr),
          authFailureOrSuccessOption: none(),
        );
      },
      passwordChanged: (e) async* {
        yield state.copyWith(
          password: Password(e.passwordStr),
          authFailureOrSuccessOption: none(),
        );
      },
      registerWithEmailAndPasswordPressed: (e) async* {
        yield* _preformActionOnAuthFacadeWithEmailAndPassword(
          _authFacade.registerWithEmailAndPassword,
        );
      },
      signInWithEmailAndPasswordPressed: (e) async* {
        yield* _preformActionOnAuthFacadeWithEmailAndPassword(
          _authFacade.signInWithEmailAndPassword,
        );
      },
      signInWithGooglePressed: (e) async* {
        yield state.copyWith(
          isSubmitting: true,
          authFailureOrSuccessOption: none(),
        );
        final failureOrSuccess = await _authFacade.signInWithGoogle();
        yield state.copyWith(
          isSubmitting: true,
          authFailureOrSuccessOption: some(failureOrSuccess),
        );
      },
    );
  }

  Stream<SignInFormState> _preformActionOnAuthFacadeWithEmailAndPassword(
    Future<Either<AuthFailure, Unit>> Function({
      @required EmailAddress emailAddress,
      @required Password password,
    })
        forwaredCall,
  ) async* {
    Either<AuthFailure, Unit> failureOrSuccess;

    final isEmailValid = state.emailAddress.isValid();
    final isPasswordValid = state.password.isValid();

    if (isEmailValid && isPasswordValid) {
      yield state.copyWith(
        isSubmitting: true,
        authFailureOrSuccessOption: none(),
      );

      failureOrSuccess = await forwaredCall(
        emailAddress: state.emailAddress,
        password: state.password,
      );
    }

    yield state.copyWith(
      showErrorMessages: false,
      // optionOf is equivelent to failureOr == null ? none() : some(failureOrSuccess)
      authFailureOrSuccessOption: optionOf(failureOrSuccess),
    );
  }
}
