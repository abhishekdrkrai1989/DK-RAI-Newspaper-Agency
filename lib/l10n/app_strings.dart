enum AppLanguage { en, hi }

class AppStrings {
  final AppLanguage language;

  const AppStrings(this.language);

  bool get isHindi => language == AppLanguage.hi;

  String tr(String en, String hi) => isHindi ? hi : en;

  // App Header & General
  String get agencyName => 'D K Rai Newspaper Agency';
  String get appTitle => tr('D K Rai Newspaper Agency', 'डी के राय न्यूजपेपर एजेंसी');
  String get appSubtitle => tr(
        'Offline Distribution & Pause Tracker',
        'ऑफलाइन वितरण और चालू/बंद सूची',
      );
  String get languageToggleLabel => isHindi ? 'English' : 'हिंदी';
  String get savedLocallyBadge => tr(
        'Saved on Mobile Storage',
        'मोबाइल स्टोरेज में सुरक्षित',
      );

  // Dashboard Stats
  String get totalCustomers => tr('Total Homes', 'कुल घर');
  String get startedPapers => tr('Started (Active)', 'चालू पेपर');
  String get pausedPapers => tr('Paused (Stopped)', 'बंद पेपर');
  String get todayCopies => tr("Today's Copies", 'आज के कुल पेपर');
  String get deliveredToday => tr('Delivered', 'वितरित किए');

  // Depot / Bundle Summary
  String get depotPickupTitle => tr(
        'Morning Bundle Count (Active Only)',
        'सुबह उठाने वाले अखबार (केवल चालू)',
      );
  String get depotPickupSubtitle => tr(
        'Paused homes & non-matching day variants are automatically excluded',
        'बंद घर और आज न आने वाले अखबार अपने आप हटा दिए गए हैं',
      );
  String get noActivePapersForDay => tr(
        'No active papers scheduled for this day',
        'इस दिन के लिए कोई चालू अखबार नहीं है',
      );
  String get copiesUnit => tr('copies', 'प्रतियां');

  // Filter Tabs & Block/Society Filters
  String get filterAll => tr('All Homes', 'सभी घर');
  String get filterStarted => tr('Started', 'चालू (Started)');
  String get filterPaused => tr('Paused', 'बंद (Paused)');
  String get filterPendingToday => tr('Pending Today', 'आज बाकी');
  String get allSocieties => tr('All Societies', 'सभी सोसाइटी/कॉलोनी');
  String get allBlocks => tr('All Blocks', 'सभी ब्लॉक');
  String get filterByBlockSociety => tr(
        'Filter by Society / Block',
        'सोसाइटी / ब्लॉक के अनुसार छाँटें',
      );
  String get clearFilters => tr('Reset Filter', 'फ़िल्टर हटाएं');

  // Morning Delivery Sheet
  String get generateMorningListBtn => tr(
        'Morning List (Flat & Paper)',
        'सुबह की पर्ची (फ्लैट और अखबार)',
      );
  String get morningListTitle => tr(
        'Morning Delivery Sheet',
        'सुबह की अखबार वितरण पर्ची',
      );
  String get flatNoColumn => tr('Flat / House No.', 'फ्लैट / मकान नं.');
  String get newspaperColumn => tr('Newspaper Name', 'अखबार का नाम');
  String get copyListBtn => tr('Copy List', 'सूची कॉपी करें');
  String get listCopiedMsg => tr(
        'List copied to clipboard!',
        'सूची क्लिपबोर्ड पर कॉपी हो गई है!',
      );
  String get activeFlatsCount => tr('Active Flats', 'चालू फ्लैट');

  // Monthly Billing & Activity Report
  String get monthlyBillingBtn => tr(
        'Month-End Billing & Activity',
        'मासिक बिलिंग और गतिविधि रिपोर्ट',
      );
  String get monthlyBillingTitle => tr(
        'Month-End Billing & Activity (Society-Wise)',
        'मासिक बिलिंग व गतिविधि सूची (सोसाइटी-वार)',
      );
  String get copyBillingBtn =>
      tr('Copy Billing Report', 'बिलिंग रिपोर्ट कॉपी करें');
  String get totalSocietyBill => tr('Total Est. Bill', 'कुल अनुमानित बिल');
  String get activeDaysLabel => tr('Active Days', 'चालू दिन');
  String get pausedDaysLabel => tr('Paused Days', 'बंद दिन');
  String get monthlyActivitiesLabel => tr(
        'Pause / Add / Remove Activity Log',
        'बंद / चालू / अखबार जोड़ने-हटाने का विवरण',
      );
  String get noActivityRecorded => tr(
        'No pause or paper changes recorded',
        'कोई बदलाव या बंद रिकॉर्ड नहीं',
      );

  // Block-Wise Daily Newspaper Consumption
  String get blockConsumptionBtn => tr(
        'Block-Wise Paper Count',
        'ब्लॉक-वार अखबार संख्या',
      );
  String get blockConsumptionTitle => tr(
        'Block-Wise Newspaper Consumption',
        'ब्लॉक-वार दैनिक अखबार खपत',
      );
  String get totalForDateLabel => tr('Total Consumption for', 'कुल अखबार खपत —');
  String get blockWiseBreakdownTitle => tr(
        'Block-Wise Breakdown',
        'ब्लॉक के अनुसार अलग-अलग अखबारों की संख्या',
      );

  String get searchHint => tr(
        'Search name, house no, block, society, or paper...',
        'नाम, मकान नं., ब्लॉक, सोसाइटी या अखबार खोजें...',
      );

  // Status Labels
  String get statusStarted => tr('STARTED', 'चालू है');
  String get statusPaused => tr('PAUSED', 'बंद है');
  String get btnPausePaper => tr('Pause Paper', 'पेपर बंद करें');
  String get btnStartPaper => tr('Start Paper', 'पेपर चालू करें');
  String get markDelivered => tr('Mark Delivered', 'डिलीवर हो गया');
  String get deliveredDone => tr('Delivered Today', 'आज डिलीवर हुआ');

  // Delivery Frequencies / Variants
  String get freqDaily => tr('Daily (Mon–Sun)', 'रोज़ाना (सोम–रवि)');
  String get freqWeekdays => tr('Weekdays (Mon–Fri)', 'सोमवार से शुक्रवार');
  String get freqWeekends => tr('Weekends (Sat–Sun)', 'वीकेंड (शनि–रवि)');
  String get freqSundayOnly => tr('Sunday Edition Only', 'केवल रविवार');
  String get freqSaturdayOnly => tr('Saturday Edition Only', 'केवल शनिवार');

  String get freqDailyShort => tr('Daily', 'रोज़ाना');
  String get freqWeekdaysShort => tr('Mon–Fri', 'सोम–शुक्र');
  String get freqWeekendsShort => tr('Sat–Sun', 'शनि–रवि');
  String get freqSundayShort => tr('Sun Only', 'रविवार');
  String get freqSaturdayShort => tr('Sat Only', 'शनिवार');

  // Publication Types
  String get newspaperLabel => tr('Newspaper', 'अखबार');
  String get magazineLabel => tr('Magazine', 'पत्रिका (मैगज़ीन)');
  String get managePublications => tr('Papers & Magazines', 'अखबार सूची');

  // Customer Form & Details
  String get addCustomer => tr('Add New Home', 'नया ग्राहक जोड़ें');
  String get editCustomer => tr('Edit Home Details', 'ग्राहक विवरण बदलें');
  String get customerName => tr('Customer Name', 'ग्राहक का नाम');
  String get houseNumber => tr('House / Flat No.', 'मकान / फ्लैट नंबर');
  String get blockTower => tr(
        'Block / Wing / Tower (e.g., Block A)',
        'ब्लॉक / विंग / टावर (जैसे: Block A)',
      );
  String get areaColony => tr(
        'Society / Colony / Area',
        'सोसाइटी / कॉलोनी / एरिया',
      );
  String get phoneNumber => tr('Mobile Number', 'मोबाइल नंबर');
  String get sequenceNumber => tr('Route Sequence No.', 'वितरण क्रम संख्या');
  String get deliveryNotes => tr(
        'Delivery Notes (e.g., 1st floor balcony)',
        'निर्देश (जैसे: पहली मंजिल की बालकनी में डालें)',
      );
  String get selectSubscriptions => tr(
        'Select Newspapers & Magazines (with Daily/Weekend Variant)',
        'अखबार और पत्रिका चुनें (रोज़ाना / वीकेंड विकल्प के साथ)',
      );
  String get variantLabel => tr('Delivery Variant', 'वितरण के दिन');
  String get quantityLabel => tr('Copies (Qty)', 'संख्या (प्रतियां)');
  String get saveCustomer => tr('Save to Mobile Storage', 'मोबाइल में सेव करें');
  String get deleteCustomer => tr('Delete Customer', 'ग्राहक हटाएं');
  String get cancel => tr('Cancel', 'रद्द करें');
  String get confirm => tr('Confirm', 'पुष्टि करें');

  // Pause Dialog
  String get pauseDialogTitle =>
      tr('Pause Newspaper Delivery', 'अखबार वितरण बंद (Pause) करें');
  String get pauseIndefinitely => tr(
        'Pause Until Manually Started',
        'अगले आदेश तक बंद रखें (जब तक खुद चालू न करें)',
      );
  String get pauseForDateRange => tr(
        'Pause for Selected Dates (Auto-Start)',
        'तारीखों के लिए बंद करें (तय तारीख को अपने आप चालू)',
      );
  String get pauseReasonLabel => tr(
        'Reason / Note (e.g., Out of station)',
        'कारण / नोट (जैसे: बाहर गए हैं)',
      );
  String get pauseFromDate => tr('From Date', 'कब से बंद');
  String get resumeAfterDate => tr('Paused Until (Inclusive)', 'कब तक बंद');
  String get statusHistoryTitle => tr(
        'Pause / Start & Newspaper Activity Log',
        'चालू / बंद व अखबार बदलाव का इतिहास',
      );
  String get individualPaperPaused => tr('Item Paused', 'यह पेपर बंद है');

  // Days of week
  String weekdayName(int weekday) {
    const enDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const hiDays = [
      'सोमवार',
      'मंगलवार',
      'बुधवार',
      'गुरुवार',
      'शुक्रवार',
      'शनिवार',
      'रविवार'
    ];
    final index = (weekday - 1).clamp(0, 6);
    return isHindi ? hiDays[index] : enDays[index];
  }

  String monthYearName(int year, int month) {
    const enMonths = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    const hiMonths = [
      'जनवरी',
      'फ़रवरी',
      'मार्च',
      'अप्रैल',
      'मई',
      'जून',
      'जुलाई',
      'अगस्त',
      'सितंबर',
      'अक्टूबर',
      'नवंबर',
      'दिसंबर'
    ];
    final idx = (month - 1).clamp(0, 11);
    final mName = isHindi ? hiMonths[idx] : enMonths[idx];
    return '$mName $year';
  }

  String formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year;
    return '$dd/$mm/$yyyy';
  }

  String formatDateDash(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year;
    return '$dd-$mm-$yyyy';
  }

  // Cloud Sync & Supabase Database
  String get cloudSyncTitle =>
      tr('Free Cloud Database (Supabase)', 'मुफ़्त क्लाउड डेटाबेस (Supabase)');
  String get cloudSyncTooltip =>
      tr('Cloud Sync & Backup', 'क्लाउड सिंक और बैकअप');
  String get cloudStatusConnected =>
      tr('Connected to Cloud DB', 'क्लाउड डेटाबेस से जुड़ा है');
  String get cloudStatusOffline =>
      tr('Offline / Local Storage Only', 'ऑफलाइन / केवल मोबाइल स्टोरेज');
  String get cloudStatusSyncing =>
      tr('Syncing with Cloud...', 'क्लाउड के साथ सिंक हो रहा है...');
  String get supabaseProjectUrl =>
      tr('Supabase Project URL', 'Supabase प्रोजेक्ट URL');
  String get supabaseProjectUrlHint =>
      'https://xyzcompany.supabase.co';
  String get supabaseAnonKey =>
      tr('Supabase Anon API Key', 'Supabase Anon API कुंजी');
  String get supabaseAnonKeyHint =>
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  String get autoSyncLabel =>
      tr('Auto-sync when changes are made', 'बदलाव होने पर अपने आप सिंक करें');
  String get syncNowBtn =>
      tr('Sync Now (Two-Way)', 'अभी सिंक करें (दोनों तरफ)');
  String get uploadToCloudBtn =>
      tr('Upload to Cloud (Backup)', 'क्लाउड पर अपलोड करें (बैकअप)');
  String get downloadFromCloudBtn =>
      tr('Download from Cloud (Restore)', 'क्लाउड से डाउनलोड करें (रिस्टोर)');
  String get testConnectionBtn =>
      tr('Test Connection', 'कनेक्शन जांचें');
  String get saveConfigBtn =>
      tr('Save Cloud Settings', 'क्लाउड सेटिंग्स सहेजें');
  String get sqlSetupTitle =>
      tr('Free Supabase Setup (1-Minute Guide)', 'मुफ़्त Supabase सेटअप (1 मिनट गाइड)');
  String get copySqlSchemaBtn =>
      tr('Copy SQL Tables Schema', 'SQL टेबल स्क्रिप्ट कॉपी करें');
  String get sqlCopiedMsg =>
      tr('SQL script copied! Paste it in Supabase SQL Editor and click Run.',
          'SQL स्क्रिप्ट कॉपी हो गई! Supabase SQL एडिटर में पेस्ट करके Run दबाएं।');
  String get connectionSuccess =>
      tr('Successfully connected to Supabase!', 'Supabase से सफलतापूर्वक जुड़ गया!');
  String get connectionFailed =>
      tr('Connection failed. Please check URL & Anon Key.',
          'कनेक्शन विफल रहा। कृपया URL और Anon कुंजी जांचें।');
  String get syncSuccess =>
      tr('Cloud sync completed successfully!', 'क्लाउड सिंक सफलतापूर्वक पूरा हुआ!');
  String get lastSyncedLabel => tr('Last synced', 'अंतिम सिंक');
  String get neverSynced => tr('Never synced', 'कभी सिंक नहीं हुआ');

  // Role Authentication & Approvals
  String get loginTitle =>
      tr('D K Rai Newspaper Agency Login', 'डी के राय न्यूजपेपर एजेंसी लॉगिन');
  String get loginSubtitle =>
      tr('Select role to access register', 'रजिस्टर खोलने के लिए पद चुनें');
  String get roleOwner => tr('Owner (Admin)', 'मालिक (एडमिन)');
  String get roleOwnerDesc => tr(
        'Full agency control, all delivery actions & approve boy activities',
        'पूर्ण एजेंसी नियंत्रण, सभी वितरण कार्य और हॉकर के कार्यों को मंज़ूरी दें',
      );
  String get roleDeliveryBoy => tr('Delivery Boy', 'हॉकर (डिलीवरी बॉय)');
  String get roleDeliveryBoyDesc => tr(
        'Can add, delete customer & paper, stop/start paper delivery',
        'ग्राहक व अखबार जोड़ें/हटाएं, पेपर चालू या बंद करें',
      );
  String get enterPinLabel => tr('Enter 4-Digit PIN', '4 अंकों का पिन दर्ज करें');
  String get pinHintOwner => tr('••••', '••••');
  String get pinHintDelivery => tr('••••', '••••');
  String get loginBtn => tr('Login', 'लॉगिन करें');
  String get quickDemoLogin => tr('Instant Login (No PIN)', 'त्वरित लॉगिन (बिना पिन)');
  String get logoutBtn => tr('Logout / Switch Role', 'लॉगआउट / पद बदलें');
  String get invalidPin =>
      tr('Incorrect PIN. Please try again.', 'गलत पिन। कृपया पुन: प्रयास करें।');
  String get approvalsTitle =>
      tr('Owner Approval Center', 'मालिक मंज़ूरी केंद्र');
  String get pendingApprovalsTab =>
      tr('Pending Review', 'मंज़ूरी बाकी');
  String get approvedTab => tr('Approved History', 'मंज़ूर इतिहास');
  String get rejectedTab => tr('Rejected History', 'अस्वीकृत इतिहास');
  String get btnApprove => tr('Approve Action', 'मंज़ूर करें');
  String get btnReject => tr('Reject / Revert', 'अस्वीकार / वापस लें');
  String get btnApproveAll =>
      tr('Approve All Pending', 'सभी को मंज़ूर करें');
  String get noPendingApprovals => tr(
        'No pending actions from Delivery Boy.',
        'डिलीवरी बॉय का कोई कार्य मंज़ूरी के लिए बाकी नहीं है।',
      );
  String get approvedSuccessMsg =>
      tr('Action approved successfully!', 'कार्य सफलतापूर्वक मंज़ूर हो गया!');
  String get rejectedSuccessMsg =>
      tr('Action rejected and reverted.', 'कार्य अस्वीकार व वापस कर दिया गया।');
  String get deliveryBoyBanner => tr(
        'Logged in as Delivery Boy. All start/stop & customer changes are submitted for Owner approval.',
        'डिलीवरी बॉय के रूप में लॉगिन। सभी बदलाव मालिक की मंज़ूरी के लिए दर्ज होते हैं।',
      );

  // Delivery Boys Management
  String get manageDeliveryBoysTitle =>
      tr('Delivery Boys Management', 'हॉकर (डिलीवरी बॉय) प्रबंधन');
  String get addDeliveryBoy =>
      tr('Add New Delivery Boy', 'नया डिलीवरी बॉय जोड़ें');
  String get editDeliveryBoy =>
      tr('Edit Delivery Boy Details', 'डिलीवरी बॉय विवरण बदलें');
  String get deliveryBoyName =>
      tr('Delivery Boy Name', 'हॉकर (डिलीवरी बॉय) का नाम');
  String get deliveryBoyNameHint =>
      tr('e.g., Ramesh Kumar', 'उदा. रमेश कुमार');
  String get deliveryBoyPhone =>
      tr('Mobile / Phone Number', 'मोबाइल नंबर');
  String get deliveryBoyPhoneHint =>
      tr('e.g., 9876543210', 'उदा. 9876543210');
  String get deliveryBoyPin =>
      tr('Login PIN (4-Digits)', 'लॉगिन पिन (4 अंक)');
  String get deliveryBoyPinHint =>
      tr('e.g., 0000', 'उदा. 0000');
  String get assignedAreaRoute =>
      tr('Assigned Area / Society / Block', 'निर्धारित क्षेत्र / सोसाइटी / ब्लॉक');
  String get assignedAreaHint =>
      tr('e.g., Block A, Shanti Nagar', 'उदा. ब्लॉक A, शांति नगर सोसाइटी');
  String get vehicleNumber =>
      tr('Vehicle / Bicycle Details', 'वाहन / साइकिल का नंबर');
  String get vehicleNumberHint =>
      tr('e.g., Hero Splendor (UP 65 AB 1234)', 'उदा. हीरो स्प्लेंडर (UP 65 AB 1234)');
  String get deliveryBoyNotes =>
      tr('Shift / Route Notes', 'शिफ्ट या रूट नोट्स');
  String get deliveryBoyNotesHint =>
      tr('e.g., Morning Shift: 5:30 AM - 7:00 AM', 'उदा. सुबह 5:30 से 7:00 बजे तक');
  String get statusActive => tr('Active', 'सक्रिय');
  String get statusInactive => tr('Inactive', 'निष्क्रिय (ब्लॉक)');
  String get activeStatusToggle =>
      tr('Allow App Login (Active)', 'ऐप लॉगिन की अनुमति दें (सक्रिय)');
  String get deleteDeliveryBoyConfirm =>
      tr('Are you sure you want to remove this delivery boy?', 'क्या आप वाकई इस डिलीवरी बॉय को हटाना चाहते हैं?');
  String get deliveryBoySavedSuccess =>
      tr('Delivery boy details saved successfully!', 'डिलीवरी बॉय की जानकारी सफलतापूर्वक सहेज ली गई!');
  String get deliveryBoyDeletedSuccess =>
      tr('Delivery boy removed successfully!', 'डिलीवरी बॉय सफलतापूर्वक हटा दिया गया!');
  String get cannotDeleteOwner =>
      tr('Owner account cannot be deleted.', 'मालिक (एडमिन) का खाता हटाया नहीं जा सकता।');
  String get noDeliveryBoysFound =>
      tr('No delivery boys added yet. Tap + to add.', 'अभी तक कोई डिलीवरी बॉय नहीं जोड़ा गया है। नया जोड़ने के लिए + दबाएं।');
  String get deliveryBoyInactiveMsg =>
      tr('This account is inactive. Please contact the Owner.', 'यह खाता निष्क्रिय है। कृपया मालिक से संपर्क करें।');
  String get totalDeliveryBoys => tr('Total Hawkers', 'कुल हॉकर');
  String get activeHawkers => tr('Active', 'सक्रिय');
  String get inactiveHawkers => tr('Inactive', 'निष्क्रिय');
  String get generatePinBtn => tr('Generate PIN', 'पिन बनाएं');
  String get ownerOnlyAccess =>
      tr('Only Owner (Admin) can manage delivery boys.', 'केवल मालिक (एडमिन) ही डिलीवरी बॉय का प्रबंधन कर सकते हैं।');
  String get editAdminProfile =>
      tr('Edit Admin Profile & PIN', 'एडमिन प्रोफ़ाइल व पिन बदलें');
  String get changeAdminPinSubtitle =>
      tr('Update owner name, phone, and 4-digit login PIN', 'मालिक का नाम, मोबाइल और 4 अंकों का लॉगिन पिन बदलें');
  String get ownerProfileSavedSuccess =>
      tr('Admin profile and PIN updated successfully!', 'एडमिन प्रोफ़ाइल और लॉगिन पिन सफलतापूर्वक बदल दिया गया!');
  String get ownerCardTitle =>
      tr('Agency Owner / Admin (You)', 'एजेंसी मालिक (एडमिन)');

  // Block Management & Assignment
  String get manageBlocksTitle =>
      tr('Manage Blocks & Hawkers', 'ब्लॉक एवं हॉकर प्रबंधन');
  String get manageBlocksBtn =>
      tr('Manage Blocks', 'ब्लॉक प्रबंधन');
  String get manageBlocksSubtitle => tr(
        'Assign fixed blocks to delivery boys & add new blocks',
        'हॉकरों को निर्धारित ब्लॉक आवंटित करें और नए ब्लॉक जोड़ें',
      );
  String get assignedBlocksLabel =>
      tr('Assigned Blocks', 'आवंटित ब्लॉक');
  String get totalBlocksCount =>
      tr('Total Blocks', 'कुल ब्लॉक');
  String get assignedBlocksCount =>
      tr('Assigned Blocks', 'आवंटित ब्लॉक');
  String get unassignedBlocksCount =>
      tr('Unassigned Blocks', 'अनावंटित ब्लॉक');
  String get addNewBlockBtn =>
      tr('Add New Block', 'नया ब्लॉक जोड़ें');
  String get blockNameLabel =>
      tr('Block / Tower Name', 'ब्लॉक / टॉवर का नाम');
  String get blockNameHint =>
      tr('e.g., Block C, Tower 2, Wing B', 'उदा. ब्लॉक C, टॉवर 2, विंग B');
  String get assignDeliveryBoyLabel =>
      tr('Assign Delivery Boy (Hawker)', 'हॉकर (डिलीवरी बॉय) चुनें');
  String get unassignedOption =>
      tr('Unassigned (No Hawker)', 'कोई हॉकर नहीं (अनावंटित)');
  String get blockSavedSuccess =>
      tr('Block saved and assigned successfully!', 'ब्लॉक सफलतापूर्वक सहेजा व आवंटित किया गया!');
  String get blockAssignmentUpdated =>
      tr('Hawker assignment updated!', 'हॉकर आवंटन सफलतापूर्वक बदल दिया गया!');
  String get blockAccessDenied => tr(
        'Access Restricted: You can only view and manage your assigned block(s).',
        'प्रतिबंधित: आप केवल अपने आवंटित ब्लॉक को ही देख और प्रबंधित कर सकते हैं।',
      );
  String get cannotModifyOtherBlock => tr(
        'You cannot add, edit, delete, start, or stop paper for other blocks.',
        'आप अन्य ब्लॉक के ग्राहकों या पेपर को जोड़, बदल, हटा, चालू या बंद नहीं कर सकते।',
      );
  String get noAssignedBlocksWarning => tr(
        'No blocks have been assigned to you. Contact Admin.',
        'आपको कोई ब्लॉक आवंटित नहीं किया गया है। कृपया एडमिन से संपर्क करें।',
      );
  String get deliveryBoyRequiredTitle =>
      tr('Delivery Boy Required', 'हॉकर का होना आवश्यक है');
  String get createDeliveryBoyFirstPrompt => tr(
        'Please create at least one delivery boy first before adding blocks. Every block must be assigned to an existing delivery boy.',
        'ब्लॉक बनाने से पहले कृपया कम से कम एक हॉकर बनाएं। प्रत्येक ब्लॉक के लिए हॉकर का चयन अनिवार्य है।',
      );
  String get blockNameRequired =>
      tr('Block name is required', 'ब्लॉक का नाम अनिवार्य है');
  String get selectDeliveryBoyMandatory =>
      tr('Assigning a delivery boy is mandatory', 'हॉकर का चयन अनिवार्य है');
  String get selectDeliveryBoyPrompt =>
      tr('Select Delivery Boy', 'हॉकर चुनें');
  String get pendingForApprovalFlag =>
      tr('Pending for Approval', 'मंज़ूरी के लिए लंबित');
  String get confirmLogoutTitle =>
      tr('Confirm Logout', 'लॉगआउट की पुष्टि करें');
  String get confirmLogoutPrompt =>
      tr('Are you sure you want to log out?', 'क्या आप लॉगआउट करना चाहते हैं?');
  String get deletionPendingAdminApproval => tr(
        'Deletion requested. Pending Admin/Owner approval.',
        'हटाने का अनुरोध दर्ज किया गया। एडमिन/मालिक की मंज़ूरी लंबित है।',
      );
  String get filterPendingApproval =>
      tr('Pending Approval', 'मंज़ूरी लंबित');
  String get reviewApprovalBtn =>
      tr('Review', 'देखें');
}
