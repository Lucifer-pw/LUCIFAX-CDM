class AppStrings {
  static const String appName = 'Lucifax CDM';
  static const String appVersion = '1.0.0';
  static const String githubRepo = 'Lucifer-pw/LUCIFAX-CDM';
  
  // Mode Selection
  static const String chooseModeTitle = 'Pilih Mode Aplikasi';
  static const String chooseModeSubtitle = 'Tentukan peran perangkat ini dalam sistem keamanan Lucifax';
  static const String deviceModeTitle = 'Lindungi Perangkat Ini';
  static const String deviceModeDesc = 'Jadikan HP ini target yang bisa dikontrol, dilacak, dan diamankan dari jauh.';
  static const String commanderModeTitle = 'Kontrol Perangkat Lain';
  static const String commanderModeDesc = 'Pantau dan kendalikan HP Anda yang hilang atau terhubung dari dashboard.';
  
  // Auth
  static const String loginTitle = 'Masuk Dashboard';
  static const String registerTitle = 'Daftar Akun Baru';
  static const String emailHint = 'Alamat Email';
  static const String passwordHint = 'Kata Sandi';
  static const String confirmPasswordHint = 'Konfirmasi Kata Sandi';
  static const String loginBtn = 'Masuk';
  static const String registerBtn = 'Daftar';
  static const String registerLink = 'Belum punya akun? Daftar di sini';
  static const String loginLink = 'Sudah punya akun? Masuk di sini';
  static const String logoutBtn = 'Keluar';
  static const String errorAuth = 'Gagal autentikasi. Silakan periksa kembali email & password Anda.';
  
  // Pin Settings
  static const String pinTitle = 'PIN Keamanan';
  static const String pinSubtitle = 'Masukkan PIN 4 digit untuk membuka pengaturan sensitif';
  static const String confirmPinSubtitle = 'Konfirmasi PIN Keamanan Anda';
  static const String errorPinMismatch = 'PIN tidak cocok!';
  static const String errorPinIncorrect = 'PIN salah!';
  
  // Commander Dashboard
  static const String dashboardTitle = 'Dashboard Kontrol';
  static const String activeDevices = 'Perangkat Terhubung';
  static const String noDevicesFound = 'Belum ada perangkat yang terdaftar.';
  static const String statusOnline = 'Aktif / Online';
  static const String statusOffline = 'Offline';
  static const String batteryLabel = 'Baterai';
  static const String lastSeenLabel = 'Terakhir Terlihat';
  
  // Command Buttons
  static const String cmdLock = 'Kunci Perangkat';
  static const String cmdTrack = 'Lacak Lokasi';
  static const String cmdAlarm = 'Bunyikan Alarm';
  static const String cmdStopAlarm = 'Matikan Alarm';
  static const String cmdCapture = 'Ambil Foto';
  static const String cmdWipe = 'Wipe Data (Reset)';
  static const String cmdMessage = 'Kirim Pesan';
  static const String cmdGetInfo = 'Info Sistem';
  
  // Confirmations
  static const String confirmWipeTitle = '⚠️ PERINGATAN KERAS!';
  static const String confirmWipeDesc = 'Tindakan ini akan menghapus seluruh data pada perangkat target (Factory Reset). Tindakan ini TIDAK BISA dibatalkan! Apakah Anda yakin?';
  static const String confirmWipePlaceholder = 'Ketik "WIPE" untuk mengonfirmasi';
  static const String executeBtn = 'Eksekusi';
  static const String cancelBtn = 'Batal';
  
  // Updates
  static const String updateAvailableTitle = 'Pembaruan Tersedia!';
  static const String updateAvailableDesc = 'Versi baru ({version}) telah dirilis di GitHub. Apakah Anda ingin mengunduhnya sekarang?';
  static const String updateDownloadBtn = 'Unduh Sekarang';
  static const String updateLaterBtn = 'Nanti';
  
  // Device Mode
  static const String protectionActive = 'Proteksi Aktif';
  static const String protectionDesc = 'Perangkat ini sedang diawasi dan dilindungi oleh Lucifax CDM.';
  static const String permissionsTitle = 'Izin yang Diperlukan';
  static const String permissionAdmin = 'Administrator Perangkat';
  static const String permissionLocation = 'Lokasi Latar Belakang';
  static const String permissionCamera = 'Kamera (Ambil Foto)';
  static const String permissionNotification = 'Notifikasi Sistem';
  static const String permissionState = 'Status Telepon (SIM)';
  static const String enableBtn = 'Aktifkan';
  static const String enabledLabel = 'Aktif';
}
