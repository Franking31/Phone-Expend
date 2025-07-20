import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
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

  // Updated method to handle both String and DateTime
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

  Future<void> _openFile(String filePath, BuildContext context) async {
    try {
      if (filePath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun fichier attaché')),
        );
        return;
      }

      final file = File(filePath);
      if (await file.exists()) {
        final uri = Uri.file(filePath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir le fichier')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier introuvable')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ouverture : $e')),
      );
    }
  }

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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du partage : $e')),
      );
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
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 8),
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