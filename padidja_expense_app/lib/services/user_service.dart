import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../models/user_model.dart';
import 'database_service.dart';
import 'supabase_service.dart';

class ErrorDisplayService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static void showError(String message, {String? title, Duration? duration}) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: duration ?? const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Fermer',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
      
      if (title != null) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title, style: const TextStyle(color: Colors.red)),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }
  
  static void showSuccess(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class UserService {
  static Future<int> inscrireUtilisateur({
    required String nom,
    required String email,
    required String motDePasse,
  }) async {
    try {
      developer.log('Début inscription - Email: $email');
      
      if (SupabaseService.client == null) {
        developer.log('Erreur: SupabaseService.client non initialisé');
        ErrorDisplayService.showError('Erreur: Service Supabase non initialisé');
        throw Exception('Supabase non initialisé');
      }

      final response = await SupabaseService.client.auth.signUp(
        email: email,
        password: motDePasse,
        data: {'nom': nom},
      );
      final user = response.user;
      final session = response.session;
      developer.log('Réponse signUp - User: $user, Session: $session');
      
      if (user == null) {
        const errorMsg = 'Échec de l\'inscription: Utilisateur non créé';
        developer.log('Échec inscription: $errorMsg');
        ErrorDisplayService.showError(errorMsg, title: 'Erreur d\'inscription');
        throw Exception(errorMsg);
      }

      await SupabaseService.client.from('utilisateurs').insert({
        'id': user.id,
        'nom': nom,
        'email': email,
        'role': 'user',
        'image_path': null,
      });
      developer.log('Utilisateur inséré dans Supabase - ID: ${user.id}');

      final db = await DatabaseService.database;
      final utilisateur = Utilisateur(
        id: user.id,
        nom: nom,
        email: email,
        motDePasse: '',
        role: 'user',
      );
      
      final localId = await db.insert('utilisateurs', {
        'user_id': utilisateur.id,
        'nom': utilisateur.nom,
        'email': utilisateur.email,
        'mot_de_passe': utilisateur.motDePasse,
        'role': utilisateur.role,
        'image_path': utilisateur.imagePath,
      });
      developer.log('Utilisateur inséré localement - ID: $localId');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_nom', nom);
      await prefs.setString('user_email', email);
      await prefs.setString('user_role', 'user');
      developer.log('Données sauvegardées dans SharedPreferences');

      ErrorDisplayService.showSuccess('Inscription réussie !');
      return localId;
    } catch (e) {
      developer.log('Erreur inscription: $e');
      
      String errorMessage = 'Erreur lors de l\'inscription';
      if (e is DatabaseException) {
        errorMessage = 'Erreur de base de données: ${e.toString()}';
      } else if (e is PostgrestException) {
        errorMessage = 'Erreur Supabase: ${e.message}';
      } else if (e is AuthException) {
        if (e.message.contains('already registered')) {
          errorMessage = 'Cette adresse email est déjà utilisée';
        } else if (e.message.contains('invalid email')) {
          errorMessage = 'Adresse email invalide';
        } else if (e.message.contains('weak password')) {
          errorMessage = 'Mot de passe trop faible (minimum 6 caractères)';
        } else {
          errorMessage = 'Erreur d\'authentification: ${e.message}';
        }
      } else {
        errorMessage = 'Erreur inattendue: ${e.toString()}';
      }
      
      ErrorDisplayService.showError(errorMessage, title: 'Erreur d\'inscription');
      throw Exception(errorMessage);
    }
  }

  static Future<Utilisateur?> connecterUtilisateur(String email, String motDePasse) async {
    try {
      developer.log('Début connexion - Email: $email');
      
      if (SupabaseService.client == null) {
        developer.log('Erreur: SupabaseService.client non initialisé');
        ErrorDisplayService.showError('Erreur: Service Supabase non initialisé');
        throw Exception('Supabase non initialisé');
      }

      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: motDePasse,
      );
      final user = response.user;
      final session = response.session;
      developer.log('Réponse connexion - User: $user, Session: $session');
      
      if (user == null) {
        const errorMsg = 'Échec de la connexion: Identifiants invalides';
        developer.log('Échec connexion: $errorMsg, Réponse: $response');
        ErrorDisplayService.showError(errorMsg, title: 'Erreur de connexion');
        throw Exception(errorMsg);
      }

      final userDataList = await SupabaseService.client
          .from('utilisateurs')
          .select()
          .eq('id', user.id);
      developer.log('Données utilisateur - Résultat: $userDataList');
      if (userDataList.isEmpty) {
        const errorMsg = 'Utilisateur non trouvé dans la base de données';
        developer.log('Échec connexion: $errorMsg, userId: ${user.id}');
        ErrorDisplayService.showError(errorMsg, title: 'Erreur de connexion');
        throw Exception(errorMsg);
      }
      final userData = userDataList.first;

      final utilisateur = Utilisateur(
        id: user.id,
        nom: userData['nom'] ?? '',
        email: user.email ?? '',
        motDePasse: '',
        role: userData['role'] ?? 'user',
        imagePath: userData['image_path'],
      );

      // Section locale avec gestion d'erreur
      try {
        final db = await DatabaseService.database;
        developer.log('Base de données ouverte');
        
        // Vérifier si la table existe avant de nettoyer
        final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='utilisateurs'");
        if (tables.isEmpty) {
          developer.log('Table utilisateurs inexistante, création en cours');
          await db.execute('''
            CREATE TABLE utilisateurs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id TEXT UNIQUE,
              nom TEXT,
              email TEXT UNIQUE,
              mot_de_passe TEXT,
              role TEXT,
              image_path TEXT
            )
          ''');
        }

        await DatabaseService.clearUserData(user.id);
        developer.log('Données locales nettoyées');

        await db.insert('utilisateurs', {
          'user_id': utilisateur.id,
          'nom': utilisateur.nom,
          'email': utilisateur.email,
          'mot_de_passe': utilisateur.motDePasse,
          'role': utilisateur.role,
          'image_path': utilisateur.imagePath,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
        developer.log('Utilisateur inséré localement');

        await synchroniserDonneesUtilisateur(user.id);
        developer.log('Synchronisation terminée');
      } catch (localError) {
        developer.log('Erreur locale: $localError');
        ErrorDisplayService.showError('Erreur lors de la gestion locale: ${localError.toString()}');
        // Continuer malgré l'erreur locale pour permettre la connexion
      }

      final prefs = await SharedPreferences.getInstance();
      developer.log('SharedPreferences initialisé');
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_nom', utilisateur.nom);
      await prefs.setString('user_email', utilisateur.email);
      await prefs.setString('user_role', utilisateur.role);
      developer.log('Données sauvegardées dans SharedPreferences');

      ErrorDisplayService.showSuccess('Connexion réussie !');
      return utilisateur;
    } catch (e) {
      developer.log('Erreur connexion: $e');
      
      String errorMessage = 'Erreur lors de la connexion';
      if (e is AuthException) {
        if (e.message.contains('Invalid login credentials')) {
          errorMessage = 'Email ou mot de passe incorrect';
        } else if (e.message.contains('Email not confirmed')) {
          errorMessage = 'Veuillez confirmer votre email avant de vous connecter';
        } else if (e.message.contains('Too many requests')) {
          errorMessage = 'Trop de tentatives de connexion. Veuillez réessayer plus tard';
        } else {
          errorMessage = 'Erreur d\'authentification: ${e.message}';
        }
      } else if (e is PostgrestException) {
        errorMessage = 'Erreur de base de données: ${e.message}';
      } else if (e is SocketException) {
        errorMessage = 'Erreur de connexion réseau. Vérifiez votre connexion internet';
      } else {
        errorMessage = 'Erreur inattendue: ${e.toString()}';
      }
      
      ErrorDisplayService.showError(errorMessage, title: 'Erreur de connexion');
      throw Exception(errorMessage);
    }
  }

  static Future<Utilisateur?> getUtilisateurLocal() async {
    try {
      developer.log('Début récupération utilisateur local');
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      developer.log('UserId récupéré: $userId');
      if (userId == null) {
        developer.log('Aucun utilisateur local trouvé');
        return null;
      }

      final db = await DatabaseService.database;
      final result = await db.query(
        'utilisateurs',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      developer.log('Résultat requête locale: $result');

      return result.isNotEmpty ? Utilisateur.fromMap(result.first) : null;
    } catch (e) {
      developer.log('Erreur récupération utilisateur local: $e');
      ErrorDisplayService.showError('Erreur lors de la récupération des données utilisateur');
      return null;
    }
  }

  static Future<void> deconnexion() async {
    try {
      developer.log('Début déconnexion');
      await SupabaseService.client.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      developer.log('Déconnexion réussie');
      ErrorDisplayService.showSuccess('Déconnexion réussie');
    } catch (e) {
      developer.log('Erreur déconnexion: $e');
      ErrorDisplayService.showError('Erreur lors de la déconnexion');
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  static Future<bool> emailExiste(String email) async {
    try {
      developer.log('Vérification existence email: $email');
      final response = await SupabaseService.client
          .from('utilisateurs')
          .select()
          .eq('email', email);
      developer.log('Résultat vérification email: $response');
      return response.isNotEmpty;
    } catch (e) {
      developer.log('Erreur vérification email: $e');
      ErrorDisplayService.showError('Erreur lors de la vérification de l\'email');
      throw Exception('Erreur lors de la vérification de l\'email: $e');
    }
  }

  static Future<void> modifierUtilisateur(Utilisateur utilisateur) async {
    try {
      developer.log('Début modification utilisateur - ID: ${utilisateur.id}');
      final db = await DatabaseService.database;

      if (utilisateur.id.isEmpty) {
        const errorMsg = 'ID utilisateur ne peut pas être vide';
        developer.log('Échec modification: $errorMsg');
        ErrorDisplayService.showError(errorMsg, title: 'Erreur de modification');
        throw Exception(errorMsg);
      }

      await db.update(
        'utilisateurs',
        {
          'user_id': utilisateur.id,
          'nom': utilisateur.nom,
          'email': utilisateur.email,
          'mot_de_passe': utilisateur.motDePasse,
          'role': utilisateur.role,
          'image_path': utilisateur.imagePath,
        },
        where: 'user_id = ?',
        whereArgs: [utilisateur.id],
      );
      developer.log('Utilisateur mis à jour localement');

      final data = {
        'nom': utilisateur.nom,
        'email': utilisateur.email,
      };

      if (utilisateur.imagePath != null && utilisateur.imagePath!.isNotEmpty) {
        final file = File(utilisateur.imagePath!);
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.png';
        await SupabaseService.client.storage
            .from('avatars')
            .upload(
              fileName,
              file,
              fileOptions: const FileOptions(upsert: true),
            );
        final imageUrl = SupabaseService.client.storage
            .from('avatars')
            .getPublicUrl(fileName);
        data['image_path'] = imageUrl;
        developer.log('Image uploadée - URL: $imageUrl');
      }

      await SupabaseService.client
          .from('utilisateurs')
          .update(data)
          .eq('id', utilisateur.id);
      developer.log('Utilisateur mis à jour dans Supabase');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_nom', utilisateur.nom);
      await prefs.setString('user_email', utilisateur.email);
      developer.log('Données mises à jour dans SharedPreferences');

      ErrorDisplayService.showSuccess('Profil modifié avec succès !');
    } catch (e) {
      developer.log('Erreur modification utilisateur: $e');
      
      String errorMessage = 'Erreur lors de la modification du profil';
      if (e is PostgrestException) {
        errorMessage = 'Erreur de base de données: ${e.message}';
      } else if (e is StorageException) {
        errorMessage = 'Erreur lors de l\'upload de l\'image: ${e.message}';
      } else if (e is FileSystemException) {
        errorMessage = 'Erreur d\'accès au fichier image';
      } else {
        errorMessage = 'Erreur inattendue: ${e.toString()}';
      }
      
      ErrorDisplayService.showError(errorMessage, title: 'Erreur de modification');
      throw Exception(errorMessage);
    }
  }

  static Future<void> synchroniserDonneesUtilisateur(String userId) async {
    try {
      developer.log('Début synchronisation - UserId: $userId');
      final db = await DatabaseService.database;

      final budgets = await SupabaseService.client
          .from('budgets')
          .select()
          .eq('user_id', userId);
      for (var budget in budgets) {
        await db.insert('budgets', {
          ...budget,
          'id': budget['id'] as int,
          'date': budget['date'] as String,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      developer.log('Budgets synchronisés: $budgets');

      final transactions = await SupabaseService.client
          .from('transactions')
          .select()
          .eq('user_id', userId);
      for (var transaction in transactions) {
        await db.insert('transactions', {
          ...transaction,
          'id': transaction['id'] as int,
          'date': transaction['date'] as String,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      developer.log('Transactions synchronisées: $transactions');

      final historique = await SupabaseService.client
          .from('historique')
          .select()
          .eq('user_id', userId);
      for (var entry in historique) {
        await db.insert('historique', {
          ...entry,
          'id': entry['id'] as int,
          'date_action': entry['date_action'] as String,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      developer.log('Historique synchronisé: $historique');

      developer.log('✅ Synchronisation terminée pour $userId');
    } catch (e) {
      developer.log('❌ Erreur synchronisation: $e');
      
      String errorMessage = 'Erreur lors de la synchronisation des données';
      if (e is PostgrestException) {
        errorMessage = 'Erreur de base de données: ${e.message}';
      } else if (e is SocketException) {
        errorMessage = 'Erreur de connexion réseau lors de la synchronisation';
      } else {
        errorMessage = 'Erreur inattendue lors de la synchronisation: ${e.toString()}';
      }
      
      ErrorDisplayService.showError(errorMessage, title: 'Erreur de synchronisation');
      throw Exception(errorMessage);
    }
  }

  static Future<List<Utilisateur>> getTousLesUtilisateurs() async {
    try {
      developer.log('Début récupération tous les utilisateurs');
      final response = await SupabaseService.client
          .from('utilisateurs')
          .select();
      developer.log('Résultat récupération: $response');
      
      return response.map<Utilisateur>((data) => Utilisateur(
        id: data['id'],
        nom: data['nom'] ?? '',
        email: data['email'] ?? '',
        motDePasse: '',
        role: data['role'] ?? 'user',
        imagePath: data['image_path'],
      )).toList();
    } catch (e) {
      developer.log('Erreur récupération utilisateurs: $e');
      
      String errorMessage = 'Erreur lors de la récupération des utilisateurs';
      if (e is PostgrestException) {
        errorMessage = 'Erreur de base de données: ${e.message}';
      } else if (e is SocketException) {
        errorMessage = 'Erreur de connexion réseau';
      } else {
        errorMessage = 'Erreur inattendue: ${e.toString()}';
      }
      
      ErrorDisplayService.showError(errorMessage, title: 'Erreur de récupération');
      throw Exception(errorMessage);
    }
  }
}