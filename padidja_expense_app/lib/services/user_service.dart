import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import '../models/user_model.dart';

class UserService {
  // Ajouter un utilisateur
  static Future<int> inscrireUtilisateur(Utilisateur user) async {
    final db = await DatabaseService.database;
    return await db.insert('utilisateurs', user.toMap());
  }

  // Connexion (vérifie email et mot de passe)
  static Future<Utilisateur?> connecterUtilisateur(String email, String mdp) async {
    final db = await DatabaseService.database;
    final result = await db.query(
      'utilisateurs',
      where: 'email = ? AND mot_de_passe = ?',
      whereArgs: [email, mdp],
    );

    if (result.isNotEmpty) {
      return Utilisateur.fromMap(result.first);
    } else {
      return null;
    }
  }

  // Vérifie si un email existe déjà
  static Future<bool> emailExiste(String email) async {
    final db = await DatabaseService.database;
    final result = await db.query(
      'utilisateurs',
      where: 'email = ?',
      whereArgs: [email],
    );
    return result.isNotEmpty;
  }
}
