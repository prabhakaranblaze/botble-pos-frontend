// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  // Auth
  @override
  String get appTitle => 'StampSmart POS';
  @override
  String get login => 'Connexion';
  @override
  String get logout => 'Déconnexion';
  @override
  String get email => 'E-mail';
  @override
  String get password => 'Mot de passe';
  @override
  String get username => 'Nom d\'utilisateur';
  @override
  String get loginButton => 'Se connecter';
  @override
  String get loggingIn => 'Connexion en cours...';
  @override
  String get loginFailed => 'Échec de la connexion';
  @override
  String get invalidCredentials => 'E-mail ou mot de passe invalide';
  @override
  String get deviceName => 'Nom de l\'appareil';
  @override
  String get deviceNameHint => 'Terminal POS 1';
  @override
  String get enterPassword => 'Entrez votre mot de passe';
  @override
  String get unlockScreen => 'Déverrouiller';
  @override
  String get locked => 'Verrouillé';
  @override
  String get logoutConfirm => 'Êtes-vous sûr de vouloir vous déconnecter?';

  // Navigation
  @override
  String get sales => 'Ventes';
  @override
  String get products => 'Produits';
  @override
  String get categories => 'Catégories';
  @override
  String get customers => 'Clients';
  @override
  String get orders => 'Commandes';
  @override
  String get reports => 'Rapports';
  @override
  String get settings => 'Paramètres';

  // Cart
  @override
  String get cart => 'Panier';
  @override
  String get emptyCart => 'Le panier est vide';
  @override
  String get addToCart => 'Ajouter au panier';
  @override
  String get removeFromCart => 'Supprimer';
  @override
  String get clearCart => 'Vider le panier';
  @override
  String get clearCartConfirm => 'Vider le panier?';
  @override
  String get clearCartMessage => 'Cela supprimera tous les articles du panier.';
  @override
  String get saveCart => 'Enregistrer le panier';
  @override
  String get savedCarts => 'Paniers enregistrés';
  @override
  String get loadCart => 'Charger le panier';
  @override
  String get deleteCart => 'Supprimer le panier';
  @override
  String get cartName => 'Nom du panier';
  @override
  String get enterCartName => 'Entrez le nom du panier...';
  @override
  String get cartHeldSuccess => 'Panier mis en attente!';
  @override
  String get cartLoadedSuccess => 'Panier chargé!';
  @override
  String get userNotLoggedIn => 'Utilisateur non connecté';
  @override
  String get clear => 'Effacer';

  // Checkout/Payment
  @override
  String get checkout => 'Paiement';
  @override
  String get payment => 'Paiement';
  @override
  String get cash => 'Espèces';
  @override
  String get card => 'Carte';
  @override
  String get cashReceived => 'Espèces reçues';
  @override
  String get change => 'Monnaie';
  @override
  String get cardLastDigits => '4 derniers chiffres de la carte';
  @override
  String get cardLastDigitsHint => '1234';
  @override
  String get completePayment => 'Finaliser le paiement';
  @override
  String get insufficientCash => 'Espèces insuffisantes';
  @override
  String get enterCardDigits => 'Veuillez entrer les 4 derniers chiffres';
  @override
  String get payNow => 'Payer';
  @override
  String get processing => 'Traitement...';

  // Amounts
  @override
  String get subtotal => 'Sous-total';
  @override
  String get tax => 'Taxe';
  @override
  String get discount => 'Remise';
  @override
  String get total => 'Total';
  @override
  String get quantity => 'Quantité';
  @override
  String get price => 'Prix';
  @override
  String get amount => 'Montant';
  @override
  String get shipping => 'Livraison';
  @override
  String get shippingAmount => 'Frais de livraison';
  @override
  String get enterShippingAmount => 'Entrez le montant de livraison';
  @override
  String get shippingUpdated => 'Livraison mise à jour!';

  // Coupon
  @override
  String get coupon => 'Coupon';
  @override
  String get couponCode => 'Code coupon';
  @override
  String get enterCouponCode => 'Entrez le code coupon';
  @override
  String get applyCoupon => 'Appliquer le coupon';
  @override
  String get removeCoupon => 'Supprimer le coupon';
  @override
  String get couponApplied => 'Coupon appliqué avec succès!';
  @override
  String get apply => 'Appliquer';
  @override
  String get applying => 'Application...';

  // Discount
  @override
  String get discountDescription => 'Description (Optionnel)';
  @override
  String get discountDescriptionHint => 'Ex: Remise employé, Fidélité';
  @override
  String get discountApplied => 'Remise appliquée avec succès!';

  // Order
  @override
  String get orderComplete => 'Commande terminée';
  @override
  String get orderCode => 'Code de commande';
  @override
  String get orderNumber => 'Commande #';
  @override
  String get orderDate => 'Date';
  @override
  String get dateTime => 'Date/Heure';
  @override
  String get paymentMethod => 'Mode de paiement';
  @override
  String get printReceipt => 'Imprimer le reçu';
  @override
  String get newSale => 'Nouvelle vente';
  @override
  String get orderCompleted => 'Commande terminée!';
  @override
  String get printing => 'Impression...';
  @override
  String get receiptPrinted => 'Reçu imprimé';
  @override
  String get items => 'Articles';
  @override
  String get status => 'Statut';
  @override
  String get mode => 'Mode';

  // Session
  @override
  String get session => 'Session';
  @override
  String get openRegister => 'Ouvrir la caisse';
  @override
  String get closeRegister => 'Fermer la caisse';
  @override
  String get openingCash => 'Fond de caisse';
  @override
  String get openingCashAmount => 'Montant d\'ouverture';
  @override
  String get closingCash => 'Caisse de fermeture';
  @override
  String get closingCashAmount => 'Montant de fermeture';
  @override
  String get expectedCash => 'Espèces attendues';
  @override
  String get actualCash => 'Espèces réelles';
  @override
  String get difference => 'Différence';
  @override
  String get cashSales => 'Ventes en espèces';
  @override
  String get cardSales => 'Ventes par carte';
  @override
  String get totalSales => 'Ventes totales';
  @override
  String get sessionNotes => 'Notes de session';
  @override
  String get notesOptional => 'Notes (Optionnel)';
  @override
  String get addNotes => 'Ajouter des notes...';
  @override
  String get closeSession => 'Fermer la session';
  @override
  String get closingSession => 'Fermeture de la session...';
  @override
  String get sessionClosed => 'Session fermée';
  @override
  String get noActiveSession => 'Aucune session active';
  @override
  String get noSession => 'Pas de session';
  @override
  String get viewActiveSession => 'Voir la session active';
  @override
  String get openSessionFirst => 'Veuillez ouvrir une caisse pour commencer à vendre';
  @override
  String get closeSessionFirst => 'Fermer la session d\'abord';
  @override
  String get closeSessionFirstMessage => 'Vous avez une session active. Veuillez fermer votre session avant de vous déconnecter.';
  @override
  String get viewSession => 'Voir la session';
  @override
  String get continueSession => 'Continuer la session';
  @override
  String get startFresh => 'Recommencer';
  @override
  String get existingSession => 'Session existante';
  @override
  String get sessionOpen => 'OUVERTE';
  @override
  String get openedAt => 'Ouvert à';
  @override
  String get openedBy => 'Ouvert par';
  @override
  String get duration => 'Durée';
  @override
  String get countDenominations => 'Compter les coupures (Optionnel)';
  @override
  String get checkingSession => 'Vérification de la session...';

  // Search & General
  @override
  String get search => 'Rechercher';
  @override
  String get searchProducts => 'Rechercher des produits...';
  @override
  String get scanBarcode => 'Scanner le code-barres, SKU ou rechercher...';
  @override
  String get searchCustomers => 'Rechercher des clients...';
  @override
  String get searchCustomer => 'Rechercher un client...';
  @override
  String get searchByOrderCode => 'Rechercher par code de commande...';
  @override
  String get noResults => 'Aucun résultat trouvé';
  @override
  String get loading => 'Chargement...';
  @override
  String get error => 'Erreur';
  @override
  String get retry => 'Réessayer';
  @override
  String get cancel => 'Annuler';
  @override
  String get confirm => 'Confirmer';
  @override
  String get save => 'Enregistrer';
  @override
  String get delete => 'Supprimer';
  @override
  String get edit => 'Modifier';
  @override
  String get close => 'Fermer';
  @override
  String get back => 'Retour';
  @override
  String get next => 'Suivant';
  @override
  String get done => 'Terminé';
  @override
  String get yes => 'Oui';
  @override
  String get no => 'Non';
  @override
  String get ok => 'OK';
  @override
  String get update => 'Mettre à jour';
  @override
  String get refresh => 'Actualiser';
  @override
  String get all => 'Tout';
  @override
  String get filter => 'Filtrer';
  @override
  String get sortBy => 'Trier par';
  @override
  String get current => 'Actuel';
  @override
  String get useArrowKeys => 'Utilisez les flèches pour sélectionner';

  // Customer
  @override
  String get customer => 'Client';
  @override
  String get walkIn => 'Sur place';
  @override
  String get walkInCustomer => 'Client de passage';
  @override
  String get selectCustomer => 'Sélectionner un client';
  @override
  String get noCustomer => 'Aucun client sélectionné';
  @override
  String get addCustomer => 'Ajouter un client';
  @override
  String get customerName => 'Nom du client';
  @override
  String get enterName => 'Entrez le nom';
  @override
  String get enterEmail => 'Entrez l\'e-mail';
  @override
  String get enterEmailOptional => 'Entrez l\'e-mail (optionnel)';
  @override
  String get enterPhone => 'Entrez le téléphone';
  @override
  String get deliver => 'Livrer';
  @override
  String get deliveryAddress => 'Adresse de livraison';
  @override
  String get addAddress => 'Ajouter une adresse';
  @override
  String get streetAddress => 'Adresse';
  @override
  String get enterStreetAddress => 'Entrez l\'adresse';
  @override
  String get city => 'Ville';
  @override
  String get enterCity => 'Entrez la ville';
  @override
  String get zipCode => 'Code postal';
  @override
  String get enterZipCode => 'Entrez le code postal';
  @override
  String get phone => 'Téléphone';
  @override
  String get name => 'Nom';

  // Product
  @override
  String get productNotFound => 'Produit non trouvé';
  @override
  String get outOfStock => 'Rupture de stock';
  @override
  String get inStock => 'En stock';
  @override
  String get lowStock => 'Stock faible';
  @override
  String get sku => 'SKU';
  @override
  String get variation => 'Variation';
  @override
  String get qtySold => 'Qté vendue';
  @override
  String get revenue => 'Revenu';
  @override
  String get product => 'Produit';

  // Language
  @override
  String get language => 'Langue';
  @override
  String get english => 'Anglais';
  @override
  String get french => 'Français';
  @override
  String get currency => 'Devise';

  // Receipt
  @override
  String get receipt => 'Reçu';
  @override
  String get posReceipt => 'Reçu POS';
  @override
  String get thankYou => 'Merci pour votre achat!';
  @override
  String get pleaseReturn => 'À bientôt';

  // Denominations
  @override
  String get enterDenominations => 'Entrer les coupures';
  @override
  String get quickCash => 'Montant rapide';

  // Dashboard
  @override
  String get recentBills => 'Factures récentes';
  @override
  String get calculator => 'Calculatrice';
  @override
  String get fullScreen => 'Plein écran';
  @override
  String get exitFullScreen => 'Quitter le plein écran';

  // Connectivity
  @override
  String get workingOffline => 'Mode hors ligne - Synchronisation automatique';
  @override
  String get online => 'En ligne';
  @override
  String get offline => 'Hors ligne';

  // Export
  @override
  String get exportCsv => 'Exporter CSV';
  @override
  String get exportSuccess => 'Exporté avec succès';
  @override
  String get exportFailed => 'Échec de l\'exportation';
  @override
  String get noOrdersToExport => 'Aucune commande à exporter';
  @override
  String get noProductsToExport => 'Aucun produit à exporter';

  // Resync
  @override
  String get resync => 'Resynchroniser';
  @override
  String get resyncProducts => 'Resynchroniser les produits';
  @override
  String get clearAndResyncProducts => 'Effacer et resynchroniser les produits';
  @override
  String get resyncNow => 'Resynchroniser maintenant';
  @override
  String get resyncing => 'Resynchronisation des produits...';
  @override
  String get resyncSuccess => 'Produits resynchronisés avec succès!';
  @override
  String get resyncFailed => 'Échec de la resynchronisation';

  // Clear Data
  @override
  String get clearAllData => 'Effacer toutes les données';
  @override
  String get clearAll => 'Tout effacer';
  @override
  String get clearingData => 'Effacement des données...';
  @override
  String get dataCleared => 'Toutes les données locales effacées et resynchronisées!';
  @override
  String get clearFailed => 'Échec de l\'effacement';

  // Printer
  @override
  String get printerSettings => 'Paramètres d\'imprimante';
  @override
  String get selectPrinter => 'Sélectionner l\'imprimante';
  @override
  String get defaultPrinter => 'Imprimante par défaut';
  @override
  String get defaultPrinterSet => 'Imprimante par défaut définie';
  @override
  String get defaultPrinterCleared => 'Imprimante par défaut effacée';
  @override
  String get selectPrinterFirst => 'Veuillez d\'abord sélectionner une imprimante';
  @override
  String get testPrint => 'Test d\'impression';
  @override
  String get testPrintSuccess => 'Test d\'impression envoyé!';
  @override
  String get printFailed => 'Échec d\'impression';
  @override
  String get autoPrintOnPayment => 'Impression auto au paiement';
  @override
  String get autoPrintDescription => 'Imprimer automatiquement le reçu après le paiement';
  @override
  String get usb => 'USB';
  @override
  String get bluetooth => 'BT';
  @override
  String get wifi => 'WiFi';
  @override
  String get demoPayment => 'Paiement démo';

  // Updates
  @override
  String get checkForUpdates => 'Vérifier les mises à jour';
  @override
  String get installUpdate => 'Installer la mise à jour';
  @override
  String get updateNow => 'Mettre à jour';
  @override
  String get updateAvailable => 'Mise à jour disponible';
  @override
  String get noUpdatesAvailable => 'Aucune mise à jour disponible';
  @override
  String get check => 'Vérifier';
}
