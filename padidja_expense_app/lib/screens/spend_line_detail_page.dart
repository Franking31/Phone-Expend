import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart'; // Alternative pour ouvrir les fichiers
import '../models/spend_line.dart';
import '../models/screen_type.dart';
import '../widgets/notification_button.dart';

class SpendLineDetailPage extends StatelessWidget {
  final SpendLine spendLine;
  final Color primaryColor;
  final String? heroTag;

  const SpendLineDetailPage({
    super.key,
    required this.spendLine,
    this.primaryColor = const Color(0xFF6074F9),
    this.heroTag,
  });

  // Méthode pour déterminer le type d'écran
  ScreenType _getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return ScreenType.mobile;
    if (width < 1200) return ScreenType.tablet;
    return ScreenType.desktop;
  }

  // Méthode pour obtenir les dimensions responsives
  ResponsiveDimensions _getResponsiveDimensions(BuildContext context) {
    final screenType = _getScreenType(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    switch (screenType) {
      case ScreenType.mobile:
        return ResponsiveDimensions(
          headerHeight: screenHeight * 0.35,
          padding: 16.0,
          cardPadding: 16.0,
          fontSize: 16.0,
          titleFontSize: 18.0,
          headerFontSize: 20.0,
          buttonHeight: 45.0,
          buttonWidth: screenWidth * 0.25,
          maxContentWidth: screenWidth,
          crossAxisCount: 1,
        );
      case ScreenType.tablet:
        return ResponsiveDimensions(
          headerHeight: screenHeight * 0.3,
          padding: 24.0,
          cardPadding: 20.0,
          fontSize: 18.0,
          titleFontSize: 20.0,
          headerFontSize: 24.0,
          buttonHeight: 50.0,
          buttonWidth: 140.0,
          maxContentWidth: screenWidth * 0.9,
          crossAxisCount: 2,
        );
      case ScreenType.desktop:
        return ResponsiveDimensions(
          headerHeight: screenHeight * 0.25,
          padding: 32.0,
          cardPadding: 24.0,
          fontSize: 16.0,
          titleFontSize: 20.0,
          headerFontSize: 28.0,
          buttonHeight: 50.0,
          buttonWidth: 150.0,
          maxContentWidth: 1200.0,
          crossAxisCount: 3,
        );
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Non spécifiée';
    
    try {
      DateTime dateTime;
      
      if (date is DateTime) {
        dateTime = date;
      } else if (date is String) {
        if (date.isEmpty) return 'Non spécifiée';
        dateTime = DateTime.parse(date);
      } else {
        return 'Format de date invalide';
      }
      
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return date.toString();
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} FCFA';
  }

  // Vérification et demande des permissions
  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      // Pour Android 13+ (API 33+)
      if (await Permission.manageExternalStorage.isGranted) {
        return true;
      }
      
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      
      if (!status.isGranted) {
        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          photosStatus = await Permission.photos.request();
        }
        return photosStatus.isGranted;
      }
      
      return status.isGranted;
    }
    return true;
  }

  // MÉTHODE CORRIGÉE - Ouverture sécurisée des fichiers avec fallback
  Future<void> _openFile(String filePath, BuildContext context) async {
    if (filePath.isEmpty) {
      _showSnackBar(context, 'Aucun fichier attaché', Colors.orange);
      return;
    }

    try {
      _showLoadingDialog(context, 'Ouverture du fichier...');

      bool hasPermission = await _checkPermissions();
      
      Navigator.of(context, rootNavigator: true).pop(); // Fermer le dialog de chargement
      
      if (!hasPermission) {
        _showPermissionError(context);
        return;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        _showSnackBar(context, 'Fichier introuvable', Colors.red);
        return;
      }

      // Méthode 1: Essayer avec OpenFilex
      try {
        final result = await OpenFilex.open(filePath);
        
        if (result.type == ResultType.done) {
          _showSnackBar(context, 'Fichier ouvert avec succès', Colors.green);
          return;
        } else if (result.type == ResultType.noAppToOpen) {
          await _tryAlternativeMethods(filePath, context);
          return;
        } else {
          throw Exception('OpenFilex failed: ${result.message}');
        }
      } catch (e) {
        debugPrint('OpenFilex error: $e');
        await _tryAlternativeMethods(filePath, context);
      }

    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showSnackBar(context, 'Erreur lors de l\'ouverture du fichier: $e', Colors.red);
    }
  }

  // NOUVELLE MÉTHODE - Méthodes alternatives pour ouvrir le fichier
  Future<void> _tryAlternativeMethods(String originalPath, BuildContext context) async {
    try {
      // Méthode 2: Copier vers un répertoire accessible et utiliser url_launcher
      final directory = await getApplicationDocumentsDirectory();
      final fileName = originalPath.split('/').last;
      final newPath = '${directory.path}/$fileName';
      
      await File(originalPath).copy(newPath);
      
      // Essayer avec url_launcher
      final uri = Uri.file(newPath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        _showSnackBar(context, 'Fichier ouvert avec succès', Colors.green);
        return;
      }
      
      // Méthode 3: Essayer OpenFilex avec le nouveau chemin
      final result = await OpenFilex.open(newPath);
      if (result.type == ResultType.done) {
        _showSnackBar(context, 'Fichier ouvert avec succès', Colors.green);
        return;
      }
      
      // Méthode 4: Proposer de partager le fichier
      _showFileOpenDialog(context, newPath);
      
    } catch (e) {
      _showSnackBar(context, 'Impossible d\'ouvrir le fichier: $e', Colors.red);
    }
  }

  // NOUVELLE MÉTHODE - Dialog pour proposer des options d'ouverture
  void _showFileOpenDialog(BuildContext context, String filePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ouverture du fichier'),
          content: const Text('Impossible d\'ouvrir automatiquement le fichier. Voulez-vous le partager ou le copier?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _shareFile(context, filePath);
              },
              child: const Text('Partager'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackBar(context, 'Fichier sauvegardé dans: $filePath', Colors.blue);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // NOUVELLE MÉTHODE - Partager un fichier spécifique
  Future<void> _shareFile(BuildContext context, String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      _showSnackBar(context, 'Erreur lors du partage du fichier: $e', Colors.red);
    }
  }

  // MÉTHODE UTILITAIRE - Afficher un SnackBar
  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // MÉTHODE UTILITAIRE - Afficher un dialog de chargement
  void _showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  // MÉTHODE UTILITAIRE - Afficher erreur de permission
  void _showPermissionError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permissions de stockage requises pour ouvrir le fichier'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Paramètres',
          textColor: Colors.white,
          onPressed: openAppSettings,
        ),
      ),
    );
  }

  // Partage avec gestion d'erreurs améliorée
  Future<void> _shareSpendLine(BuildContext context) async {
    final spendLineText = '''
Détails de la Ligne Budgétaire:
━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Nom: ${spendLine.name}
💰 Budget: ${_formatCurrency(spendLine.budget)}
📝 Description: ${spendLine.description.isNotEmpty ? spendLine.description : 'Aucune description'}
📅 Date: ${_formatDate(spendLine.date)}
${spendLine.proof.isNotEmpty ? '📎 Justificatif: ${spendLine.proof.split('/').last}' : ''}
━━━━━━━━━━━━━━━━━━━━━━━━━━━
Généré par l'application Budget Manager
''';

    try {
      _showLoadingDialog(context, 'Préparation du partage...');

      if (spendLine.proof.isNotEmpty && await File(spendLine.proof).exists()) {
        await Share.shareXFiles(
          [XFile(spendLine.proof)],
          text: spendLineText,
          subject: 'Ligne Budgétaire: ${spendLine.name}',
        );
      } else {
        await Share.share(
          spendLineText,
          subject: 'Ligne Budgétaire: ${spendLine.name}',
        );
      }
      
      Navigator.of(context, rootNavigator: true).pop();
      
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showSnackBar(context, 'Erreur lors du partage : $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = _getResponsiveDimensions(context);
    final screenType = _getScreenType(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: dimensions.maxContentWidth),
          child: Column(
            children: [
              _buildHeader(dimensions, context),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(dimensions.padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(dimensions),
                      SizedBox(height: dimensions.padding),
                      _buildDetailsCard(dimensions),
                      if (spendLine.proof.isNotEmpty) ...[
                        SizedBox(height: dimensions.padding),
                        _buildAttachmentCard(dimensions, context),
                      ],
                      SizedBox(height: dimensions.padding * 2),
                      _buildActionButtons(dimensions, context, screenType),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ResponsiveDimensions dimensions, BuildContext context) {
    return Container(
      height: dimensions.headerHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(dimensions.padding),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Détails de la Dépense',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: dimensions.headerFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  buildNotificationAction(context),
                ],
              ),
              SizedBox(height: dimensions.padding * 1.5),
              Hero(
                tag: heroTag ?? 'spendline_${spendLine.id ?? 'default'}',
                child: Container(
                  padding: EdgeInsets.all(dimensions.cardPadding),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              spendLine.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: dimensions.titleFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: dimensions.padding * 0.5),
                      Text(
                        _formatCurrency(spendLine.budget),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: dimensions.headerFontSize * 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(ResponsiveDimensions dimensions) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dimensions.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(dimensions.padding * 0.5),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: dimensions.padding),
              Text(
                'Informations Générales',
                style: TextStyle(
                  fontSize: dimensions.titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: dimensions.padding),
          _buildInfoRow('Nom', spendLine.name, dimensions),
          _buildInfoRow('Budget', _formatCurrency(spendLine.budget), dimensions),
          _buildInfoRow('Date', _formatDate(spendLine.date), dimensions),
          if (spendLine.id != null)
            _buildInfoRow('ID', spendLine.id.toString(), dimensions),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(ResponsiveDimensions dimensions) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dimensions.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(dimensions.padding * 0.5),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: dimensions.padding),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: dimensions.titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: dimensions.padding),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(dimensions.padding),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Text(
              spendLine.description.isNotEmpty 
                ? spendLine.description 
                : 'Aucune description disponible',
              style: TextStyle(
                fontSize: dimensions.fontSize,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(ResponsiveDimensions dimensions, BuildContext context) {
    final fileName = spendLine.proof.split('/').last;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(dimensions.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(dimensions.padding * 0.5),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.attach_file,
                  color: primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: dimensions.padding),
              Text(
                'Pièce Jointe',
                style: TextStyle(
                  fontSize: dimensions.titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: dimensions.padding),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openFile(spendLine.proof, context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(dimensions.padding),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: primaryColor,
                      size: 28,
                    ),
                    SizedBox(width: dimensions.padding),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: TextStyle(
                              fontSize: dimensions.fontSize,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Toucher pour ouvrir',
                            style: TextStyle(
                              fontSize: dimensions.fontSize * 0.875,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new,
                      color: primaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ResponsiveDimensions dimensions) {
    return Padding(
      padding: EdgeInsets.only(bottom: dimensions.padding * 0.75),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: dimensions.fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(width: dimensions.padding),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: dimensions.fontSize,
                color: Colors.black87,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ResponsiveDimensions dimensions, BuildContext context, ScreenType screenType) {
    return Column(
      children: [
        if (screenType == ScreenType.desktop) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                'Partager',
                Icons.share,
                primaryColor,
                () => _shareSpendLine(context),
                dimensions,
              ),
              _buildActionButton(
                'Retour',
                Icons.arrow_back,
                Colors.grey[600]!,
                () => Navigator.pop(context),
                dimensions,
              ),
            ],
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            height: dimensions.buttonHeight,
            child: ElevatedButton.icon(
              onPressed: () => _shareSpendLine(context),
              icon: const Icon(Icons.share),
              label: const Text('Partager cette dépense'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 3,
              ),
            ),
          ),
          SizedBox(height: dimensions.padding),
          SizedBox(
            width: double.infinity,
            height: dimensions.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed, ResponsiveDimensions dimensions) {
    return SizedBox(
      width: dimensions.buttonWidth,
      height: dimensions.buttonHeight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 3,
        ),
      ),
    );
  }
}