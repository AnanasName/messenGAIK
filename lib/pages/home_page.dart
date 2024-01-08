import 'package:cloud_firestore/cloud_firestore.dart'; // Импорт Firestore для работы с базой данных Firebase.
import 'package:firebase_auth/firebase_auth.dart'; // Импорт FirebaseAuth для аутентификации пользователей.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Импорт Provider для управления состоянием приложения.
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../services/auth/auth_service.dart'; // Импорт сервиса аутентификации.
import 'chat_page.dart'; // Импорт страницы чата.

class HomePage extends StatefulWidget {
  // Определение StatefulWidget для домашней страницы.
  const HomePage({super.key}); // Конструктор с ключом для виджета.

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Состояние для HomePage.

  final FirebaseAuth _auth = FirebaseAuth
      .instance; // Экземпляр FirebaseAuth для текущего пользователя.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _getCurrentCity();
  }

  // Функция для выхода пользователя.
  void signOut() {
    // Получение сервиса аутентификации.
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut(); // Вызов функции выхода через сервис аутентификации.
  }

  Future _getCurrentCity() async {
    // получаем разрешения от пользователя, если они не были получены
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // получить текущее местоположение
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy:
        LocationAccuracy.bestForNavigation); // с высокой точностью

    // // преобразование местоположения в список placemark objects
    List<Placemark> placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);

    _saveToFirebase(placemarks[0]);
  }

  Future<void> _saveToFirebase(Placemark placemark) async {

    await _firestore
        .collection('coords') // Обращаемся к коллекции чат-комнат
        .doc(_auth.currentUser!.uid) // Документ для конкретной чат-комнаты
        .collection("lat and longs")
        .add(placemark.toJson());
  }

  @override
  Widget build(BuildContext context) {
    // Функция построения интерфейса.
    return Scaffold(
      // Создание каркаса приложения.
        appBar: AppBar(
          title: const Text('Home Page'), // Заголовок для AppBar.
          backgroundColor: Colors.grey[400], // Цвет фона AppBar.
          actions: [
            // Кнопка для создания новой группы.
            IconButton(
              onPressed: _buildUserList,
              // Обработка нажатия кнопки (переход к списку пользователей).
              icon: const Icon(Icons.group), // Иконка группы.
            ),
            // Кнопка для выхода из учетной записи.
            IconButton(
                onPressed: signOut,
                // Обработка нажатия кнопки (выход из учетной записи).
                icon: const Icon(Icons.logout) // Иконка выхода.
            ),
          ],
        ),
        body: _buildUserList() // Вывод списка пользователей в теле приложения.
    );
  }

  // Функция построения списка пользователей, кроме текущего авторизованного пользователя.
  Widget _buildUserList() {
    // Виджет StreamBuilder для асинхронной работы с потоками данных.
    return StreamBuilder<QuerySnapshot>(
      // Поток данных пользователей из Firestore.
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        // Отображение ошибок.
        if (snapshot.hasError) {
          return const Text('Ошибка');
        }
        // Индикатор загрузки, если подключение находится в ожидании.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Загрузка...');
        }
        // Виджет списка ListView для отображения пользователей.
        return ListView(
          // Преобразование документов в виджеты для их отображения.
          children: snapshot.data!.docs
              .map<Widget>((doc) => _buildUserListItem(doc))
              .toList(),
        );
      },
    );
  }

  // Функция построения элементов списка пользователей.
  Widget _buildUserListItem(DocumentSnapshot document) {
    // Преобразование данных пользователя из документа Firestore.
    Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

    print(data);

    // Отображение всех пользователей, кроме текущего.
    if (_auth.currentUser!.email != data['email']) {
      return ListTile(
        // Показываем адрес электронной почты пользователя.
        title: Text(data['email']),
        onTap: () {
          // Обработка нажатия на элемент списка.
          // При нажатии пользователя отправляют на страницу чата
          // с передачей данных выбранного пользователя.
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ChatPage(
                      receiveuserEmail: data['email'],
                      reciveUserID: data['uid'],
                    ),
              ));
        },
      );
    } else {
      // Если текущий пользователь, возвращаем пустой контейнер.
      return Container();
    }
  }
}
