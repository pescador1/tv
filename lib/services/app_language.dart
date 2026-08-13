import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguage {
  static final ValueNotifier<String> currentLanguage = ValueNotifier<String>('ar');

  static const Map<String, String> languageNames = {
    'system': 'تلقائي من الهاتف (System)',
    'ar': 'العربية',
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'tr': 'Türkçe',
    'de': 'Deutsch',
  };

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedLang = prefs.getString('user_language');
    if (savedLang == null || savedLang == 'system' || !languageNames.containsKey(savedLang)) {
      savedLang = _detectDeviceLanguage();
    }
    currentLanguage.value = savedLang;
  }

  static String _detectDeviceLanguage() {
    try {
      String code = '';
      if (kIsWeb) {
        code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      } else {
        code = Platform.localeName.split('_')[0].toLowerCase();
      }
      if (['ar', 'en', 'fr', 'es', 'tr', 'de'].contains(code)) {
        return code;
      }
    } catch (_) {}
    return 'ar';
  }

  static Future<void> setLanguage(String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_language', langCode);
    if (langCode == 'system') {
      currentLanguage.value = _detectDeviceLanguage();
    } else {
      currentLanguage.value = langCode;
    }
  }

  static bool get isRtl => currentLanguage.value == 'ar';

  static String tr(String key) {
    final lang = currentLanguage.value;
    return _translations[lang]?[key] ?? _translations['en']?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'ar': {
      'app_title': 'HR TV',
      'login_title': 'تسجيل الدخول',
      'login_sub': 'أدخل كود التفعيل للبدء بمشاهدة القنوات',
      'access_code_hint': 'كود التفعيل',
      'connect_btn': 'الاتصال بالشفرة',
      'free_trial_btn': 'احصل على تفعيل مجاني',
      'please_enter_code': 'يرجى إدخال كود التفعيل',
      'invalid_code': 'كود التفعيل غير صالح',
      'network_error': 'خطأ في الاتصال بالشبكة',

      'live_tv': 'بث مباشر',
      'favourites': 'المفضلة',
      'saved_channels': 'قناة محفوظة',
      'total_channels': 'قناة متاحة',
      'expiration': 'تاريخ الانتهاء:',
      'device_id': 'معرف الجهاز / MAC:',
      'user': 'المستخدم:',
      'settings_title': 'الإعدادات ومعلومات الحساب',
      'language': 'لغة التطبيق',
      'close': 'إغلاق',
      'logout': 'تسجيل الخروج',
      'powered_by': 'HR TV - مشغل القنوات الذكي',

      'categories_title': 'الأقسام والبلدان',
      'categories_tab': 'الأصناف',
      'countries_tab': 'الدول',
      'search_hint': 'بحث...',
      'no_items_found': 'لم يتم العثور على عناصر',

      'channels_title': 'القنوات',
      'search_channel_hint': 'بحث عن قناة...',
      'no_channels': 'لا توجد قنوات متاحة',
      'select_channel_play': 'اختر قناة لمشاهدة البث',
      'report_broken_channel': 'إبلاغ عن قناة لا تعمل',
      'report_success': '🤖 تم إرسال التقرير والمعالجة التلقائية بواسطة المساعد الآلي!',
      'report_failed': 'تعذر إرسال التقرير، حاول مرة أخرى',
      'reporting': 'جاري الإبلاغ والإصلاح...',
      'add_fav': 'إضافة للمفضلة',
      'remove_fav': 'إزالة من المفضلة',
    },
    'en': {
      'app_title': 'HR TV',
      'login_title': 'Login',
      'login_sub': 'Enter your access code to start watching',
      'access_code_hint': 'Access Code',
      'connect_btn': 'Connect',
      'free_trial_btn': 'Get Free Activation',
      'please_enter_code': 'Please enter your access code',
      'invalid_code': 'Invalid access code',
      'network_error': 'Network connection error',

      'live_tv': 'LIVE TV',
      'favourites': 'Favourites',
      'saved_channels': 'Saved Channels',
      'total_channels': 'Channels Available',
      'expiration': 'Expiration Date:',
      'device_id': 'Device ID / MAC:',
      'user': 'User:',
      'settings_title': 'Settings & Account Info',
      'language': 'App Language',
      'close': 'Close',
      'logout': 'Logout',
      'powered_by': 'HR TV - Smart Channel Player',

      'categories_title': 'Categories & Countries',
      'categories_tab': 'Categories',
      'countries_tab': 'Countries',
      'search_hint': 'Search...',
      'no_items_found': 'No items found',

      'channels_title': 'Channels',
      'search_channel_hint': 'Search channel...',
      'no_channels': 'No channels available',
      'select_channel_play': 'Select a channel to play stream',
      'report_broken_channel': 'Report Broken Channel',
      'report_success': '🤖 Report submitted! Auto-healing initiated by AI assistant.',
      'report_failed': 'Failed to send report. Please try again.',
      'reporting': 'Reporting & Repairing...',
      'add_fav': 'Add to Favorites',
      'remove_fav': 'Remove from Favorites',
    },
    'fr': {
      'app_title': 'HR TV',
      'login_title': 'Connexion',
      'login_sub': 'Entrez votre code d\'accès pour commencer à regarder',
      'access_code_hint': 'Code d\'accès',
      'connect_btn': 'Se connecter',
      'free_trial_btn': 'Obtenir un essai gratuit',
      'please_enter_code': 'Veuillez saisir votre code d\'accès',
      'invalid_code': 'Code d\'accès invalide',
      'network_error': 'Erreur de connexion réseau',

      'live_tv': 'TV EN DIRECT',
      'favourites': 'Favoris',
      'saved_channels': 'Chaînes sauvegardées',
      'total_channels': 'Chaînes disponibles',
      'expiration': 'Date d\'expiration:',
      'device_id': 'ID Appareil / MAC:',
      'user': 'Utilisateur:',
      'settings_title': 'Paramètres & Compte',
      'language': 'Langue de l\'application',
      'close': 'Fermer',
      'logout': 'Déconnexion',
      'powered_by': 'HR TV - Lecteur de chaînes intelligent',

      'categories_title': 'Catégories & Pays',
      'categories_tab': 'Catégories',
      'countries_tab': 'Pays',
      'search_hint': 'Rechercher...',
      'no_items_found': 'Aucun élément trouvé',

      'channels_title': 'Chaînes',
      'search_channel_hint': 'Rechercher une chaîne...',
      'no_channels': 'Aucune chaîne disponible',
      'select_channel_play': 'Sélectionnez une chaîne pour lire le flux',
      'report_broken_channel': 'Signaler une chaîne en panne',
      'report_success': '🤖 Signalement envoyé! Réparation automatique lancée par l\'assistant IA.',
      'report_failed': 'Échec de l\'envoi du signalement. Réessayez.',
      'reporting': 'Signalement & Réparation...',
      'add_fav': 'Ajouter aux favoris',
      'remove_fav': 'Retirer des favoris',
    },
    'es': {
      'app_title': 'HR TV',
      'login_title': 'Iniciar Sesión',
      'login_sub': 'Ingrese su código de acceso para comenzar a ver',
      'access_code_hint': 'Código de Acceso',
      'connect_btn': 'Conectar',
      'free_trial_btn': 'Obtener Prueba Gratis',
      'please_enter_code': 'Por favor ingrese su código de acceso',
      'invalid_code': 'Código de acceso no válido',
      'network_error': 'Error de conexión de red',

      'live_tv': 'TV EN VIVO',
      'favourites': 'Favoritos',
      'saved_channels': 'Canales guardados',
      'total_channels': 'Canales disponibles',
      'expiration': 'Fecha de vencimiento:',
      'device_id': 'ID Dispositivo / MAC:',
      'user': 'Usuario:',
      'settings_title': 'Ajustes e Información',
      'language': 'Idioma de la App',
      'close': 'Cerrar',
      'logout': 'Cerrar Sesión',
      'powered_by': 'HR TV - Reproductor Inteligente',

      'categories_title': 'Categorías y Países',
      'categories_tab': 'Categorías',
      'countries_tab': 'Países',
      'search_hint': 'Buscar...',
      'no_items_found': 'No se encontraron elementos',

      'channels_title': 'Canales',
      'search_channel_hint': 'Buscar canal...',
      'no_channels': 'No hay canales disponibles',
      'select_channel_play': 'Seleccione un canal para reproducir',
      'report_broken_channel': 'Reportar Canal Caído',
      'report_success': '🤖 ¡Reporte enviado! Reparación automática iniciada por el asistente IA.',
      'report_failed': 'Error al enviar el reporte. Intente de nuevo.',
      'reporting': 'Reportando y Reparando...',
      'add_fav': 'Añadir a Favoritos',
      'remove_fav': 'Quitar de Favoritos',
    },
    'tr': {
      'app_title': 'HR TV',
      'login_title': 'Giriş Yap',
      'login_sub': 'İzlemeye başlamak için erişim kodunuzu girin',
      'access_code_hint': 'Erişim Kodu',
      'connect_btn': 'Bağlan',
      'free_trial_btn': 'Ücretsiz Deneme Al',
      'please_enter_code': 'Lütfen erişim kodunuzu girin',
      'invalid_code': 'Geçersiz erişim kodu',
      'network_error': 'Ağ bağlantısı hatası',

      'live_tv': 'CANLI TV',
      'favourites': 'Favoriler',
      'saved_channels': 'Kayıtlı Kanal',
      'total_channels': 'Mevcut Kanal',
      'expiration': 'Son Kullanma Tarihi:',
      'device_id': 'Cihaz Kimliği / MAC:',
      'user': 'Kullanıcı:',
      'settings_title': 'Ayarlar ve Hesap Bilgileri',
      'language': 'Uygulama Dili',
      'close': 'Kapat',
      'logout': 'Çıkış Yap',
      'powered_by': 'HR TV - Akıllı Kanal Oynatıcı',

      'categories_title': 'Kategoriler ve Ülkeler',
      'categories_tab': 'Kategoriler',
      'countries_tab': 'Ülkeler',
      'search_hint': 'Ara...',
      'no_items_found': 'Öğe bulunamadı',

      'channels_title': 'Kanallar',
      'search_channel_hint': 'Kanal ara...',
      'no_channels': 'Mevcut kanal yok',
      'select_channel_play': 'Oynatmak için bir kanal seçin',
      'report_broken_channel': 'Bozuk Kanalı Bildir',
      'report_success': '🤖 Bildirim gönderildi! Yapay zeka tarafından otomatik onarım başlatıldı.',
      'report_failed': 'Bildirim gönderilemedi. Lütfen tekrar deneyin.',
      'reporting': 'Bildiriliyor ve Onarılıyor...',
      'add_fav': 'Favorilere Ekle',
      'remove_fav': 'Favorilerden Çıkar',
    },
    'de': {
      'app_title': 'HR TV',
      'login_title': 'Anmelden',
      'login_sub': 'Geben Sie Ihren Zugangscode ein, um fernzusehen',
      'access_code_hint': 'Zugangscode',
      'connect_btn': 'Verbinden',
      'free_trial_btn': 'Kostenlosen Test erhalten',
      'please_enter_code': 'Bitte Zugangscode eingeben',
      'invalid_code': 'Ungültiger Zugangscode',
      'network_error': 'Netzwerkverbindungsfehler',

      'live_tv': 'LIVE TV',
      'favourites': 'Favoriten',
      'saved_channels': 'Gespeicherte Kanäle',
      'total_channels': 'Verfügbare Kanäle',
      'expiration': 'Ablaufdatum:',
      'device_id': 'Geräte-ID / MAC:',
      'user': 'Benutzer:',
      'settings_title': 'Einstellungen & Kontoinfo',
      'language': 'App-Sprache',
      'close': 'Schließen',
      'logout': 'Abmelden',
      'powered_by': 'HR TV - Intelligenter Kanal-Player',

      'categories_title': 'Kategorien & Länder',
      'categories_tab': 'Kategorien',
      'countries_tab': 'Länder',
      'search_hint': 'Suchen...',
      'no_items_found': 'Keine Elemente gefunden',

      'channels_title': 'Kanäle',
      'search_channel_hint': 'Kanal suchen...',
      'no_channels': 'Keine Kanäle verfügbar',
      'select_channel_play': 'Wählen Sie einen Kanal zum Abspielen',
      'report_broken_channel': 'Defekten Kanal melden',
      'report_success': '🤖 Gemeldet! Automatische Reparatur durch KI-Assistent gestartet.',
      'report_failed': 'Meldung fehlgeschlagen. Bitte versuchen Sie es erneut.',
      'reporting': 'Wird gemeldet & repariert...',
      'add_fav': 'Zu Favoriten hinzufügen',
      'remove_fav': 'Aus Favoriten entfernen',
    },
  };
}
