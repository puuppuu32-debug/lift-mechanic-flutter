import '../models/task_model.dart';
import '../models/document_model.dart';

class TestData {
  static List<Task> getSampleTasks(String userId) {
    return [
      Task(
        id: '1',
        title: '#001 - Плановый осмотр лифта',
        address: 'ул. Советская, 45',
        elevator: 'Schindler 3300',
        deadline: 'до 20.12.2024',
        status: 'new',
        userId: userId,
        createdAt: DateTime.now().subtract(Duration(days: 1)),
      ),
      Task(
        id: '2',
        title: '#002 - Ремонт дверей кабины',
        address: 'пр. Ленина, 128',
        elevator: 'OTIS Gen2',
        deadline: 'до 15.12.2024',
        status: 'in-progress',
        userId: userId,
        createdAt: DateTime.now().subtract(Duration(hours: 12)),
      ),
      Task(
        id: '3',
        title: '#003 - Замена тросов',
        address: 'ул. Мира, 67',
        elevator: 'KONE MonoSpace',
        deadline: 'до 25.12.2024',
        status: 'completed',
        userId: userId,
        createdAt: DateTime.now().subtract(Duration(days: 3)),
      ),
    ];
  }

  static List<Document> getSampleDocuments(String userId) {
    return [
      Document(
        id: '1',
        name: 'Инструкция по ТО лифтов KONE (PDF)',
        url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        category: 'instructions',
        added: DateTime.now().subtract(Duration(days: 5)),
        userId: userId,
      ),
      Document(
        id: '2',
        name: 'Схема электропитания OTIS Gen2',
        url: 'https://www.africau.edu/images/default/sample.pdf',
        category: 'schemes',
        added: DateTime.now().subtract(Duration(days: 2)),
        userId: userId,
      ),
    ];
  }
}