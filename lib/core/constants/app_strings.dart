/// All user-facing strings. Kept in one place so they can be moved to
/// ARB files for en / hi / kn localization later.
class AppStrings {
  AppStrings._();

  static const appName = 'CardioGuard';
  static const tagline = 'Your heart, watched over.';
  static const disclaimerFooter = 'Not a medical device. In an emergency, call 112.';
  static const offline = 'Offline - alerts still work';
  static const online = 'Online';

  // Navigation
  static const navDashboard = 'Dashboard';
  static const navEcg = 'ECG';
  static const navHistory = 'History';
  static const navAlerts = 'Alerts';
  static const navProfile = 'Profile';

  // Risk
  static const riskNormal = 'NORMAL';
  static const riskWarning = 'WARNING';
  static const riskEmergency = 'EMERGENCY';
  static const confidence = 'Confidence';
  static const noReasons = 'All readings look steady.';
  static const waitingForData = 'Waiting for data...';

  // Vitals
  static const heartRate = 'Heart rate';
  static const bpm = 'bpm';
  static const spo2 = 'SpO2';
  static const motion = 'Motion';
  static const activity = 'Activity';
  static const posture = 'Posture';
  static const fall = 'Fall';
  static const fallNone = 'No fall detected';
  static const fallDetected = 'FALL DETECTED';
  static const upright = 'Upright';
  static const lying = 'Lying down';
  static const unknown = 'Unknown';
  static const chestBand = 'Chest band';
  static const wristBand = 'Wrist band';
  static const connected = 'Connected';
  static const disconnected = 'Disconnected';
  static const battery = 'Battery';
  static const signal = 'Signal';
  static const leadOff = 'Electrode off';
  static const fingerOff = 'Sensor off skin';
  static const gpsOn = 'GPS ready';
  static const gpsOff = 'GPS unavailable';
  static const demoMode = 'Demo mode';

  // Device
  static const deviceStatus = 'Device status';
  static const connectDevice = 'Connect device';
  static const connectDeviceHelp =
      'Connect to the ESP32 hub worn with your bands, either through its own hotspot or your home Wi-Fi.';
  static const modeHotspot = 'ESP32 hotspot';
  static const modeNetwork = 'Same network';
  static const hostLabel = 'IP address or hostname';
  static const portLabel = 'Port';
  static const connect = 'Connect';
  static const connecting = 'Connecting...';
  static const useDemo = 'Use Demo Mode';
  static const reconnect = 'Reconnect';
  static const leadOffHelp =
      'The chest band electrodes have lost contact. Moisten the pads, tighten the strap and make sure the band sits snugly on bare skin.';
  static const fingerOffHelp =
      'The wrist band sensor is not touching the skin. Tighten the strap so the sensor sits flat against your wrist.';
  static const bandDisconnectedHelp =
      'The band is out of range or switched off. Check its battery and move closer to the hub.';

  // ECG
  static const liveEcg = 'Live ECG';
  static const pause = 'Pause';
  static const resume = 'Resume';
  static const speed = 'Speed';
  static const gain = 'Gain';
  static const rrInterval = 'R-R interval';
  static const leadOffBanner = 'ECG electrode off - reattach the chest band.';
  static const motionArtifact = 'Motion artifact - signal unreliable';

  // History
  static const history = 'History';
  static const trends = 'Trends';
  static const healthLog = 'Health log';
  static const riskTimeline = 'Risk timeline';
  static const exportData = 'Export';
  static const exportForClinical = 'For clinical review';
  static const exportCsv = 'Export as CSV';
  static const exportPdf = 'Export as PDF (coming soon)';
  static const all = 'All';
  static const noData = 'No data yet';

  // Alerts
  static const alerts = 'Alerts';
  static const alertDetail = 'Alert detail';
  static const noAlerts = 'No alerts recorded.';
  static const notified = 'Who was notified';
  static const outcome = 'Outcome';
  static const outcomePending = 'In progress';
  static const outcomeCancelled = 'Cancelled by you';
  static const outcomeDispatched = 'Help dispatched';
  static const outcomeResolved = 'Resolved';

  // Warning check-in
  static const areYouOk = 'Are you OK?';
  static const checkInBody =
      'We noticed something unusual. Please confirm you are fine.';
  static const imOk = "I'm OK";
  static const needHelp = 'I need help';
  static const respondWithin = 'Respond within';

  // Emergency
  static const emergencyTitle = 'EMERGENCY';
  static const sendingAlertIn = 'Alerting your contacts in';
  static const slideToCancel = "Slide: I'm OK";
  static const triggeringReadings = 'What we detected';
  static const emergencyActive = 'Help is on the way';
  static const contactsNotified = 'Emergency contacts notified';
  static const gpsShared = 'GPS location shared';
  static const responderLinkSent = 'Responder link sent';
  static const call112 = 'Call 112';
  static const callAmbulance = 'Call ambulance 108';
  static const openCpr = 'Open CPR guide';
  static const responderView = 'Responder view';
  static const imOkResolve = "I'm OK / Resolve";
  static const resolveTitle = 'Resolve this emergency?';
  static const resolveBody =
      'Only confirm if you are safe. Contacts will be told it is resolved.';
  static const confirm = 'Confirm';
  static const cancel = 'Cancel';

  // CPR
  static const cprTitle = 'CPR guide';
  static const cprSteps = <String>[
    'Check if the person responds: tap their shoulders and shout.',
    'Call for help: dial 112 or ask someone nearby to call.',
    'Push hard and fast in the centre of the chest, about 5-6 cm deep.',
    'Keep pushing to the beat. Do not stop until help arrives.',
    'If an AED is available, switch it on and follow its voice prompts.',
    'AED: stick the pads on the bare chest as shown, stand clear, let it analyse.',
  ];
  static const cprBeat = 'Push to the beat - 110 per minute';
  static const elapsed = 'Elapsed';
  static const mute = 'Mute';
  static const unmute = 'Unmute';
  static const startCpr = 'START';
  static const stopCpr = 'STOP';

  // Responder
  static const responderReadOnly = 'Read-only responder view';
  static const bloodGroup = 'Blood group';
  static const allergies = 'Allergies';
  static const conditions = 'Conditions';
  static const medications = 'Medications';
  static const lastVitals = 'Last vitals';
  static const lastEcg = 'Last ECG strip';
  static const liveLocation = 'Live location';
  static const emergencyContacts = 'Emergency contacts';
  static const qrPlaceholder = 'QR share link - available in Phase 3';
  static const sharingOff = 'Wearer has not consented to share medical details.';

  // Profile
  static const profile = 'Profile';
  static const abhaId = 'ABHA ID';
  static const abhaAddress = 'ABHA address';
  static const linkAbha = 'Link ABHA';
  static const abhaLinked = 'ABHA linked';
  static const verifyOtp = 'Verify OTP';
  static const sendOtp = 'Send OTP';
  static const dataConsent = 'Data sharing consent';
  static const consentIntro = 'When you allow sharing, first responders can see:';
  static const consentItems = <String>[
    'Name, age and blood group',
    'Allergies, conditions and medications',
    'Latest vitals and ECG strip',
    'Your live location during an emergency',
    'Emergency contacts',
  ];
  static const shareWithResponders = 'Share with first responders';

  // Contacts
  static const contacts = 'Emergency contacts';
  static const addContact = 'Add contact';
  static const editContact = 'Edit contact';
  static const deleteContact = 'Delete contact';
  static const notifyWarning = 'Notify on warning';
  static const notifyEmergency = 'Notify on emergency';
  static const noContacts = 'Add at least one emergency contact.';

  // Settings
  static const settings = 'Settings';
  static const thresholds = 'Alert thresholds';
  static const hrLow = 'Low heart rate';
  static const hrHigh = 'High heart rate';
  static const spo2Min = 'Minimum SpO2';
  static const countdownLength = 'Emergency countdown';
  static const fallSensitivity = 'Fall sensitivity';
  static const alarmSound = 'Alarm sound';
  static const alarmVibration = 'Vibration';
  static const classifierSource = 'Classifier source';
  static const classifierDevice = 'Device label (ESP32)';
  static const classifierRules = 'Rule based';
  static const classifierTflite = 'TFLite model (coming soon)';
  static const esp32Connection = 'ESP32 connection';
  static const theme = 'Theme';
  static const themeSystem = 'System';
  static const themeLight = 'Light';
  static const themeDark = 'Dark';
  static const dataRetention = 'Data retention';
  static const language = 'Language';
  static const languagePlaceholder = 'English (Hindi and Kannada coming soon)';
  static const simulator = 'Simulator';
  static const scenario = 'Scenario';

  // Onboarding
  static const next = 'Next';
  static const back = 'Back';
  static const skip = 'Skip';
  static const getStarted = 'Get started';
  static const onboardingTitles = <String>[
    'Protect your heart',
    'Two bands and a hub',
    'Allow permissions',
    'Please read',
  ];
  static const onboardingBodies = <String>[
    'CardioGuard watches your heart rhythm, oxygen, movement and falls together, and calls for help when it matters.',
    'A chest band reads your ECG and movement. A wrist band reads heart rate and SpO2. An ESP32 hub combines both and sends them to this app over Wi-Fi.',
    'Location lets us send your position to contacts. Notifications and phone access let us raise alarms and place calls.',
    'CardioGuard is not a medical device and does not diagnose. It cannot replace a doctor. In an emergency always call 112.',
  ];
  static const grantPermissions = 'Allow permissions';
  static const iUnderstand = 'I understand';

  // Setup
  static const setupTitle = 'Set up your profile';
  static const stepPersonal = 'About you';
  static const stepAbha = 'ABHA ID';
  static const stepMedical = 'Medical info';
  static const stepContact = 'Emergency contact';
  static const name = 'Full name';
  static const age = 'Age';
  static const sex = 'Sex';
  static const finish = 'Finish';
  static const optional = 'Optional';

  // Alert stages
  static const stageWarning = 'Check-in prompt';
  static const stageEmergency = 'Emergency countdown';
  static const stageDispatched = 'Help dispatched';
  static const stageResolved = 'Resolved';

  // Dashboard extras
  static const waitingNoDevice = 'No device connected yet.';
  static const openSettings = 'Settings';
  static const showMore = 'Show more';
  static const lastUpdated = 'Updated';
  static const viewEcg = 'Open live ECG';
  static const seconds = 's';
  static const normalHint = 'Everything looks fine';
  // Emergency extras
  static const fallShortened = 'Fall detected - countdown shortened';
  static const secondsShort = 'sec';
  static const callFailed = 'Could not open the phone dialer.';
  static const dispatchPending = 'Sending...';
  static const dispatchDone = 'Done';
  static const checkInSoundNote = 'Tap a button to silence the alarm.';
  static const responderBanner = 'First responder information';
  static const consentOffTitle = 'Medical details hidden';
  static const noContactsYet = 'No contacts saved';
  static const patient = 'Patient';
  static const ageLabel = 'Age';
  static const none = 'None listed';

  // Misc
  static const save = 'Save';
  static const delete = 'Delete';
  static const edit = 'Edit';
  static const close = 'Close';
  static const ok = 'OK';
  static const pdfComingSoon = 'PDF export is coming soon.';
}