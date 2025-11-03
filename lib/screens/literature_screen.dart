import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ← ДОБАВЬТЕ ЭТОТ ИМПОРТ
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/document_model.dart';
import 'add_document_screen.dart';

class LiteratureScreen extends StatefulWidget {
  @override
  _LiteratureScreenState createState() => _LiteratureScreenState();
}

class _LiteratureScreenState extends State<LiteratureScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Не удалось открыть ссылку'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteDocument(String documentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Удалить документ?'),
        content: Text('Вы уверены, что хотите удалить этот документ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Удалить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        await firestoreService.deleteDocument(documentId);
        _showSnackBar('Документ удален');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllDocuments() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Очистить все документы?'),
        content: Text('Это действие нельзя отменить. Все ваши документы будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Очистить все'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user; // ← ИСПРАВЛЕНО: используем authService.user
      if (user != null) {
        try {
          final firestoreService = Provider.of<FirestoreService>(context, listen: false);
          await firestoreService.clearUserDocuments(user.uid);
          _showSnackBar('Все документы удалены');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка очистки: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getCategoryTitle(String category) {
    switch (category) {
      case 'user': return '📁 Мои документы';
      case 'normative': return '📖 Нормативные документы';
      case 'instructions': return '🔧 Инструкции по эксплуатации';
      case 'schemes': return '⚡ Электромонтажные схемы';
      default: return category;
    }
  }

  List<Document> _filterDocuments(List<Document> documents) {
    if (_searchQuery.isEmpty) return documents;
    
    return documents.where((doc) => 
      doc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      doc.category.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user; // ← ИСПРАВЛЕНО: используем authService.user

    return Scaffold(
      appBar: AppBar(
        title: Text('Техническая литература'),
        backgroundColor: Color(0xFF667eea),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Библиотека'),
            Tab(text: 'Добавить документ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Вкладка библиотеки
          _buildLibraryTab(context, user), // ← ИСПРАВЛЕНО: передаем user из authService
          // Вкладка добавления документа
          AddDocumentScreen(),
        ],
      ),
    );
  }

  Widget _buildLibraryTab(BuildContext context, User? user) { // ← ИСПРАВЛЕНО: тип User? из firebase_auth
    return Column(
      children: [
        // Поиск
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              labelText: 'Поиск документов...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        if (user != null) 
          Expanded(
            child: StreamBuilder<List<Document>>(
              stream: Provider.of<FirestoreService>(context).getUserDocuments(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка загрузки: ${snapshot.error}'));
                }

                final documents = snapshot.data ?? [];
                final filteredDocuments = _filterDocuments(documents);
                final userDocuments = filteredDocuments.where((doc) => doc.category == 'user').toList();

                return ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    // Предустановленные документы
                    _buildDocumentCategory(
                      '📖 Нормативные документы',
                      _getPredefinedNormativeDocuments(),
                    ),
                    SizedBox(height: 20),
                    _buildDocumentCategory(
                      '🔧 Инструкции по эксплуатации',
                      _getPredefinedInstructions(),
                    ),
                    SizedBox(height: 20),

                    // Пользовательские документы
                    if (userDocuments.isNotEmpty)
                      _buildUserDocumentsCategory(userDocuments),
                  ],
                );
              },
            ),
          )
        else
          Expanded(
            child: Center(child: Text('Пользователь не авторизован')),
          ),
      ],
    );
  }

  Widget _buildDocumentCategory(String title, List<Map<String, String>> documents) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            SizedBox(height: 12),
            ...documents.map((doc) => ListTile(
              leading: Icon(Icons.description, color: Colors.blue),
              title: Text(doc['name']!),
              onTap: () => _launchUrl(doc['url']!),
              trailing: Icon(Icons.open_in_new, size: 16),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDocumentsCategory(List<Document> documents) {
    final documentsByCategory = <String, List<Document>>{};
    
    for (final doc in documents) {
      if (!documentsByCategory.containsKey(doc.category)) {
        documentsByCategory[doc.category] = [];
      }
      documentsByCategory[doc.category]!.add(doc);
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '📁 Мои документы',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: _clearAllDocuments,
                  child: Text(
                    'Очистить все',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Загружено документов: ${documents.length}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            ...documentsByCategory.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCategoryTitle(entry.key),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...entry.value.map((doc) => Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.insert_drive_file, color: Colors.blue),
                      title: Text(doc.name),
                      subtitle: Text(
                        'Добавлен: ${_formatDate(doc.added)}',
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: () => _launchUrl(doc.url),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red, size: 20),
                        onPressed: () => _deleteDocument(doc.id),
                      ),
                    ),
                  )).toList(),
                  SizedBox(height: 16),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  List<Map<String, String>> _getPredefinedNormativeDocuments() {
    return [
      {
        'name': 'Технический регламент ТР ТС 011/2011',
        'url': 'http://mos.gosnadzor.ru/about/documents/%D0%A2%D0%A0%20%D0%A2%D0%A1%200112011%20%D0%91%D0%B5%D0%B7%D0%BE%D0%BF%D0%B0%D1%81%D0%BD%D0%BE%D1%81%D1%82%D0%B8%20%D0%BB%D0%B8%D1%84%D1%82%D0%BE%D0%B2.pdf',
      },
      {
        'name': 'ПОСТАНОВЛЕНИЕ от 20 октября 2023 г. N 1744',
        'url': 'http://mos.gosnadzor.ru/activity/control/gruz/%D0%9F%D0%BE%D1%81%D1%82%D0%B0%D0%BD%D0%BE%D0%B2%D0%BB%D0%B5%D0%BD%D0%B8%D0%B5%20%D0%9F%D1%80%D0%B0%D0%B2%D0%B8%D1%82%D0%B5%D0%BB%D1%8C%D1%81%D1%82%D0%B2%D0%B0%20%D0%A0%D0%A4%20%D0%BE%D1%82%2020.10.2023%20N%201744.pdf',
      },
      {
        'name': 'ГОСТ Р 55964-2014 Лифты пассажирские',
        'url': 'https://rosgosts.ru/file/gost/91/140/gost_r_55964-2014.pdf',
      },
    ];
  }

  List<Map<String, String>> _getPredefinedInstructions() {
    return [
      {
        'name': 'Лифт ЛП-0263Б-01 - руководство по эксплуатации',
        'url': 'https://www.liftmach.by/upload/iblock/%D0%9B%D0%9F-0263%D0%91-01.pdf',
      },
      {
        'name': 'OTIS Gen2 - техническое описание',
        'url': 'https://kls.ooo/wp-content/uploads/2023/08/%D0%98%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%86%D0%B8%D1%8F-%D0%BF%D0%BE-%D1%8D%D0%BA%D1%81%D0%BF%D0%BB%D1%83%D0%B0%D1%82%D0%B0%D1%86%D0%B8%D0%B8-Otis-Gen-2.pdf',
      },
      {
        'name': 'Schindler 3300 - монтаж и обслуживание',
        'url': 'https://kls.ooo/wp-content/uploads/2024/01/%D0%98%D0%BD%D1%81%D1%82%D1%80%D1%83%D0%BA%D1%86%D0%B8%D1%8F-%D0%BF%D0%BE-%D0%BE%D0%B1%D1%81%D0%BB%D1%83%D0%B6%D0%B8%D0%B2%D0%B0%D0%BD%D0%B8%D1%8E-Shindler-3300-5300.pdf',
      },
    ];
  }
}