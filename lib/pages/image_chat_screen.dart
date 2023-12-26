import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ImageChatScreen extends StatefulWidget {
  const ImageChatScreen({super.key});

  @override
  _ImageChatScreenState createState() => _ImageChatScreenState();
}

// Состояние экрана чата с изображениями, где происходит основная логика
class _ImageChatScreenState extends State<ImageChatScreen> {
  final FirebaseStorage storage =
      FirebaseStorage.instance; // Экземпляр Firebase Storage
  List<String> imageUrls = []; // Список URL изображений для отображения
  @override
  void initState() {
    super.initState();
    _loadImages(); // Загрузка изображений при инициализации состояния
  }

// Функция для загрузки изображений из хранилища
  Future<void> _loadImages() async {
// Получаем все файлы в папке 'images/'
    ListResult result = await storage.ref('images/').listAll();
    List<String> urls = []; // Список для URL изображений
    for (var ref in result.items) {
// Для каждого файла
      String downloadURL = await ref.getDownloadURL(); // Получаем URL
      urls.add(downloadURL); // Добавляем URL в список
    }
// Обновляем UI с новым списком URL
    setState(() {
      imageUrls = urls;
    });
  }

// Функция для просмотра изображения в полноэкранном режиме
  void _viewImage(String imageUrl) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Image Viewer'), // Заголовок
        ),
// Тело с изображением
        body: Center(
          child: Image.network(imageUrl),
        ),
      );
    }));
  }

// Переопределяем метод 'build' виджета, который используется для построения UI
  @override
  Widget build(BuildContext context) {
// Возвращаем 'Scaffold' виджет, который обеспечивает базовую структуру приложения
    return Scaffold(
// В 'AppBar' виджета вставляем виджет 'title', который показывает имя текущего
      appBar: AppBar(
        title: const Text('Attachements'), // Заголовок для AppBar
      ),
// В 'body' используем 'RefreshIndicator' виджет, который добавляет

      body: RefreshIndicator(
        onRefresh: _loadImages, // Функция, вызываемая при pull-to-refresh
        child: Column(
// Потомок RefreshIndicator, в данной части виджет 'Column', который

          children: <Widget>[
// Список виджетов, расположенных в Column

            Expanded(
// Expanded виджет используется для растягивания своего потомка на всё
              child: ListView.builder(
// Внутри 'Expanded' используем 'ListView.builder', который создает

                itemCount: imageUrls.length,
                // Количество элементов в списке определяется длиной

                itemBuilder: (BuildContext context, int index) {
// Функция, создающая виджеты для каждого элемента списка
                  String imageUrl = imageUrls[
                      index]; // Получение URL изображения из списка по индексу
                  return ListTile(
// Возвращаем 'ListTile' виджет для каждого элемента списка
                    leading: Icon(Icons.image),
                    // Иконка перед заголовком
                    title: Text('Image $index'),
                    // Заголовок элемента списка, содержит индекс

                    onTap: () {
                      _viewImage(
                          imageUrl); // Функция, которая выполняется при касании
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
