/// Mock ABHA (Ayushman Bharat Health Account) linking. Phase 3 replaces this
/// with the ABDM sandbox / production APIs.
class AbhaService {
  /// OTP the mock accepts, shown as a hint in the UI.
  static const demoOtp = '123456';

  Future<bool> sendOtp(String abhaId) async {
    // TODO(phase3): call ABDM "generate OTP" for the ABHA number.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return abhaId.replaceAll(RegExp(r'\D'), '').length == 14;
  }

  Future<bool> verifyOtp(String otp) async {
    // TODO(phase3): call ABDM "verify OTP" and fetch the ABHA profile.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return otp == demoOtp;
  }
}