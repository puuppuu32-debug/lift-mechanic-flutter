import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/document_model.dart';

class AddDocumentScreen extends StatefulWidget {
  @override
  _AddDocumentScreenState createState() => _AddDocumentScreenState();
}

class _AddDocumentScreenState extends State<AddDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedCategory = 'user';
  bool _isLoading = false;

  final Map<String, String> _categories = {
    'user': 'Мои документы',
    'normative': 'Нормативные документы',
    'instructions': 'Инструкции по эксплуатации',
    'schemes': 'Электромонтажные схемы',
  };

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _addDocument() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      if (user == null) {
        _showSnackBar('Пользователь не авторизован', isError: true);
        return;
      }

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      
      final newDocument = Document(
        id: '', // ID будет присвоен Firestore
        name: _nameController.text,
        url: _urlController.text,
        category: _selectedCategory,
        added: DateTime.now(),
        userId: user.uid,
      );

      await firestoreService.addDocument(newDocument);

      _showSnackBar('Документ "${_nameController.text}" добавлен');
      
      // Очищаем форму
      _nameController.clear();
      _urlController.clear();
      setState(() {
        _selectedCategory = 'user';
      });
    } catch (e) {
      _showSnackBar('Ошибка при добавлении документа: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Добавить новый документ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Название документа',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите название документа';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'Ссылка на документ',
                border: OutlineInputBorder(),
                hintText: 'https://example.com/document.pdf',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите ссылку на документ';
                }
                try {
                  Uri.parse(value);
                } catch (e) {
                  return 'Введите корректную ссылку';
                }
                return null;
              },
            ),
            SizedBox(height: 8),
            Text(
              'Поддерживаются PDF, Word, Excel и другие форматы',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Категория',
                border: OutlineInputBorder(),
              ),
              items: _categories.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addDocument,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF667eea),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Добавить документ',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showClearConfirmationDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Очистить все мои документы'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClearConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Очистить все документы?'),
        content: Text('Вы уверены, что хотите удалить ВСЕ ваши документы? Это действие нельзя отменить.'),
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
      _clearAllDocuments();
    }
  }

  Future<void> _clearAllDocuments() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    if (user == null) return;

    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.clearUserDocuments(user.uid);
      _showSnackBar('Все документы удалены');
    } catch (e) {
      _showSnackBar('Ошибка при удалении документов: $e', isError: true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }
}