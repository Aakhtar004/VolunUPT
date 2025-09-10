class RegisterCredentials {
  final String email;
  final String password;
  final String confirmPassword;
  final String fullName;
  final String role;

  RegisterCredentials({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.fullName,
    required this.role,
  });

  // Validación básica
  bool get isPasswordValid => password.length >= 6;
  bool get doPasswordsMatch => password == confirmPassword;
  bool get isEmailValid => email.contains('@') && email.isNotEmpty;
  bool get isFullNameValid => fullName.trim().isNotEmpty;
  bool get isValid =>
      isPasswordValid && doPasswordsMatch && isEmailValid && isFullNameValid;
}
