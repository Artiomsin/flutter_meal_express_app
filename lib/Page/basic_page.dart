
/*
import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'cart_page.dart';
import 'history_page.dart';
import 'messages_page.dart';
import 'promotions_page.dart';
import '../services/order_service.dart';// Добавьте этот импорт

class BasicPage extends StatefulWidget {
  final String userName;
  final int orderCount;

  BasicPage({required this.userName, required this.orderCount});

  @override
  _BasicPageState createState() => _BasicPageState();
}

class _BasicPageState extends State<BasicPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> categories = ['Пицца', 'Суши', 'Десерты', 'Напитки','Салаты','Бургеры','Паста','Супы'];
  String selectedCategory = 'Пицца';

  // Стартовый список элементов, пока данные не загружены
  List<Map<String, dynamic>> elements = [];

  int cartItemCount = 0;
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> orderHistory = []; // Инициализация истории заказов

  // Флаг загрузки данных
  bool isLoading = true;

  // Обновление количества товаров в корзине
  void updateCartCount(List<Map<String, dynamic>> updatedCart) {
    setState(() {
      cartItems = updatedCart;
      cartItemCount = cartItems.length;
    });
  }

  // Добавление заказа в историю
  void addOrderToHistory(Map<String, dynamic> order) {
    setState(() {
      orderHistory.add(order);
    });
  }

  @override
  void initState() {
    super.initState();
    fetchDishes();
  }

  // Метод для получения списка блюд с сервера
  void fetchDishes() async {
    setState(() {
      isLoading = true;
    });

    final orderService = OrderService();
    final dishes = await orderService.getDishes();

    setState(() {
      if (dishes != null) {
        elements = []; // Очищаем список
        // Преобразуем данные в формат элементов
        dishes['categories'].forEach((categoryName, items) {
          // Добавляем категорию
          elements.add({'type': 'category', 'title': categoryName});

          // Добавляем блюда
          items.forEach((item) {
            elements.add({
              'type': 'item',
              'name': item['name'],
              'price': item['price'],
              'category': categoryName,
              'image': item['image'], // Убедитесь, что URL правильный
            });
          });
        });
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Basic Page'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          iconSize: 35.0,
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                iconSize: 35.0,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(
                        cartItems: cartItems,
                        onCartUpdated: updateCartCount,
                        onOrderPlaced: addOrderToHistory, // Передаем функцию для добавления заказа в историю
                      ),
                    ),
                  );
                  if (result != null && result is List<Map<String, dynamic>>) {
                    setState(() {
                      cartItems = result;
                      cartItemCount = cartItems.length;
                    });
                  }
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$cartItemCount',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(height: 70),
            buildListTileWithIconAndNavigation('Profile', Icons.person, ProfilePage()),
            buildListTileWithIconAndNavigation('History', Icons.history, HistoryPage()),
            buildListTileWithIconAndNavigation('Promotions', Icons.local_offer, PromotionsPage()),
            buildListTileWithIconAndNavigation('Messages', Icons.message, MessagesPage()),
            buildListTileWithIconAndNavigation(
              'Cart',
              Icons.shopping_cart,
              CartPage(
                cartItems: cartItems,
                onCartUpdated: updateCartCount,
                onOrderPlaced: addOrderToHistory,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(
                      children: categories.map((category) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                selectedCategory = category;
                                scrollToCategory(category);
                              });
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all(
                                selectedCategory == category
                                    ? const Color.fromARGB(255, 94, 55, 248)
                                    : const Color.fromARGB(255, 8, 237, 237),
                              ),
                              foregroundColor: MaterialStateProperty.all(Colors.black),
                            ),
                            child: Text(category),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: elements.length,
                      itemBuilder: (BuildContext context, int index) {
                        final element = elements[index];
                        if (element['type'] == 'category') {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text(
                              element['title'],
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          );
                        } else if (element['type'] == 'item') {
                          return Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            margin: EdgeInsets.only(bottom: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (element['image'] != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15.0),
                                    child: Image.network(
                                      element['image'], // используем Image.network для загрузки изображения по URL
                                      width: double.infinity,
                                      height: 290,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                SizedBox(height: 10),
                                Text(
                                  element['name'],
                                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Цена: ${element['price']} руб.',
                                  style: TextStyle(fontSize: 16.0),
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      cartItems.add({
                                        'itemName': element['name'],
                                        'price': element['price'],
                                        'category': element['category'],
                                      });
                                      cartItemCount = cartItems.length;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(300, 50),
                                  ),
                                  child: Text('Добавить'),
                                ),
                              ],
                            ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void scrollToCategory(String category) {
    final index = elements.indexWhere(
      (element) => element['type'] == 'category' && element['title'] == category,
    );
    if (index != -1) {
      _scrollController.animateTo(
        index * 400,
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget buildListTileWithIconAndNavigation(String title, IconData icon, Widget destinationPage) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destinationPage),
        );
      },
    );
  }
}
*/

import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'cart_page.dart';
import 'history_page.dart';
import 'messages_page.dart';
import 'promotions_page.dart';

class BasicPage extends StatefulWidget {
  final String userName;
  final int orderCount;
  BasicPage({required this.userName,required this.orderCount});

  @override
  _BasicPageState createState() => _BasicPageState();
}

class _BasicPageState extends State<BasicPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<String> categories = ['Пицца', 'Суши', 'Десерты', 'Напитки','Салаты','Бургеры','Паста','Супы'];
  String selectedCategory = 'Пицца';

  final List<Map<String, dynamic>> elements = [
  // Категория Пицца
  {'type': 'category', 'title': 'Пицца'},
  {'type': 'item', 'name': 'Пицца Маргарита', 'price': 15, 'category': 'Пицца', 'image': 'assets/pasted image 0.png'},
  {'type': 'item', 'name': 'Пицца Пепперони', 'price': 20, 'category': 'Пицца','image': 'assets/istockphoto-521403691-612x612.jpg'},
  {'type': 'item', 'name': 'Пицца Гавайи', 'price': 18, 'category': 'Пицца','image':'assets/istockphoto-537640710-612x612.jpg'},
  {'type': 'item', 'name': 'Пицца Вегетарианская', 'price': 17, 'category': 'Пицца','image':'assets/Vegan-classic-pizza.jpg'},
  {'type': 'item', 'name': 'Пицца 4 Сыра', 'price': 22, 'category': 'Пицца','image':'assets/2ee97a2b-05b7-47c1-ab43-cbdbaa3477c9.webp'},

  // Категория Суши
  {'type': 'category', 'title': 'Суши'},
  {'type': 'item', 'name': 'Сет роллов', 'price': 30, 'category': 'Суши','image':'assets/0001-set-mamita.avif'},
  {'type': 'item', 'name': 'Суши Нигири', 'price': 40, 'category': 'Суши','image':'assets/u-6c84c6c696e15a6530698d13d6bcf004.jpg'},
  {'type': 'item', 'name': 'Калифорния Ролл', 'price': 25, 'category': 'Суши','image':'assets/rolly-kaliforniya-1.jpg'},
  {'type': 'item', 'name': 'Суши Филадельфия', 'price': 35, 'category': 'Суши','image':'assets/c7b2bb283346ef24401014e3e2e13c3d-0x0.webp'},
  {'type': 'item', 'name': 'Ролл с угрем', 'price': 45, 'category': 'Суши','image':'assets/unagi.jpg'},
  
  // Категория Десерты
  {'type': 'category', 'title': 'Десерты'},
  {'type': 'item', 'name': 'Макаронцы', 'price': 3, 'category': 'Десерты','image':'assets/00672227.n_4.png'},
  {'type': 'item', 'name': 'Тирамису', 'price': 5, 'category': 'Десерты','image':'assets/classic_tiramisu_an_italian_dessert_with_a_hint_o_653656ee-0bef-4698-afd7-f74f78e63082.webp'},
  {'type': 'item', 'name': 'Медовик', 'price': 6, 'category': 'Десерты','image':'assets/u-b5a44090328835a7f391d2cb9c1702f7.jpeg'},
  {'type': 'item', 'name': 'Чизкейк', 'price': 7, 'category': 'Десерты','image':'assets/748a58f3156f74631a6d9f09c05b601d.jpg'},
  {'type': 'item', 'name': 'Шоколадный торт', 'price': 8, 'category': 'Десерты','image':'assets/super-vlazhnyy-shokoladnyy-tort-.jpg'},

  // Категория Напитки
  {'type': 'category', 'title': 'Напитки'},
  {'type': 'item', 'name': 'Кока-Кола', 'price': 2, 'category': 'Напитки','image':'assets/CC-1000-01-scaled.jpg'},
  {'type': 'item', 'name': 'Сок Апельсиновый', 'price': 3, 'category': 'Напитки','image':'assets/4uw9qfa8w8cgnvdh3dixs36s9y1bmucw.jpg'},
  {'type': 'item', 'name': 'Спрайт', 'price': 3, 'category': 'Напитки','image':'assets/Спрайт-01.png'},
  {'type': 'item', 'name': 'Фанта', 'price': 2, 'category': 'Напитки','image':'assets/2184813195548903.jpg'},
  {'type': 'item', 'name': 'Минеральная вода', 'price': 1, 'category': 'Напитки','image':'assets/n-u4ng-54n-65nn-ey-tytry-500x500.jpg'},
  
  // Категория Салаты
  {'type': 'category', 'title': 'Салаты'},
  {'type': 'item', 'name': 'Цезарь с курицей', 'price': 12, 'category': 'Салаты','image':'assets/2_1634551409-scaled-e1634551464449-1280x640.jpg'},
  {'type': 'item', 'name': 'Греческий салат', 'price': 10, 'category': 'Салаты','image':'assets/Greek_salad.jpg.webp'},
  {'type': 'item', 'name': 'Салат с тунцом', 'price': 14, 'category': 'Салаты','image':'assets/141621-ed4_wide.jpg'},
  {'type': 'item', 'name': 'Салат оливье', 'price': 10, 'category': 'Салаты','image':'assets/salat_moskovskiy_s_kopchenoy_kolbasoy.jpg'},

  // Категория Бургеры
  {'type': 'category', 'title': 'Бургеры'},
  {'type': 'item', 'name': 'Бургер с курицей', 'price': 10, 'category': 'Бургеры','image':'assets/35_20211112113450_8780.png'},
  {'type': 'item', 'name': 'Бургер с говядиной', 'price': 12, 'category': 'Бургеры','image':'assets/0306202206_Burger_Sochniy-1600x1600.png'},
  {'type': 'item', 'name': 'Бургер с рыбой', 'price': 13, 'category': 'Бургеры','image':'assets/burger-s-rybnoi-kotletoi-1.webp'},
  {'type': 'item', 'name': 'Веганский бургер', 'price': 11, 'category': 'Бургеры','image':'assets/burger-feat.jpg'},
  
  // Категория Паста
  {'type': 'category', 'title': 'Паста'},
  {'type': 'item', 'name': 'Паста Карбонара', 'price': 13, 'category': 'Паста','image':'assets/Pasta-Karbonara-500х350.jpg'},
  {'type': 'item', 'name': 'Паста Болоньезе', 'price': 14, 'category': 'Паста','image':'assets/pasta-boloneze-s-timyanom_126627_photo_151171.jpg'},
  {'type': 'item', 'name': 'Паста с морепродуктами', 'price': 16, 'category': 'Паста','image':'assets/pasta-s-moreproduktami-zelenyu-i-chesnokom-v-tomatnom-souse_49226_photo_52154.jpg'},
  {'type': 'item', 'name': 'Вегетарианская паста', 'price': 12, 'category': 'Паста','image':'assets/shutterstock_1055117249-600x600.jpg'},

  // Категория Супы
  {'type': 'category', 'title': 'Супы'},
  {'type': 'item', 'name': 'Борщ', 'price': 8, 'category': 'Супы','image':'assets/50fad4a0-19c9-4d10-be24-09e942969953.webp'},
  {'type': 'item', 'name': 'Том ям', 'price': 10, 'category': 'Супы','image':'assets/0bbe736b07322095d3e61a8bf4e3e0f8.jpg'},
  {'type': 'item', 'name': 'Куриный бульон', 'price': 6, 'category': 'Супы','image':'assets/zzbijh---c1905x884x50px50p-up--5f1740e8811006828cb58bddc1174e2b.jpg'},
];


  int cartItemCount = 0;
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> orderHistory = []; // Инициализация истории заказов

  // Обновление количества товаров в корзине
  void updateCartCount(List<Map<String, dynamic>> updatedCart) {
    setState(() {
      cartItems = updatedCart;
      cartItemCount = cartItems.length;
    });
  }

  // Добавление заказа в историю
  void addOrderToHistory(Map<String, dynamic> order) {
    setState(() {
      orderHistory.add(order);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Basic Page'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          iconSize: 35.0,
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                iconSize: 35.0,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(
                        cartItems: cartItems,
                        onCartUpdated: updateCartCount,
                        onOrderPlaced: addOrderToHistory, // Передаем функцию для добавления заказа в историю
                      ),
                    ),
                  );
                  if (result != null && result is List<Map<String, dynamic>>) {
                    setState(() {
                      cartItems = result;
                      cartItemCount = cartItems.length;
                    });
                  }
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$cartItemCount',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(height: 70),
            buildListTileWithIconAndNavigation('Profile', Icons.person, ProfilePage()),
            buildListTileWithIconAndNavigation(
              'History',
              Icons.history,
               HistoryPage(), 
            ),
            buildListTileWithIconAndNavigation('Promotions', Icons.local_offer, PromotionsPage()),
            buildListTileWithIconAndNavigation('Messages', Icons.message, MessagesPage()),
            buildListTileWithIconAndNavigation(
              'Cart',
              Icons.shopping_cart,
              CartPage(
                cartItems: cartItems,
                onCartUpdated: updateCartCount,
                onOrderPlaced: addOrderToHistory,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                children: categories.map((category) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedCategory = category;
                          scrollToCategory(category);
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          selectedCategory == category
                              ? const Color.fromARGB(255, 94, 55, 248)
                              : const Color.fromARGB(255, 8, 237, 237),
                        ),
                        foregroundColor: MaterialStateProperty.all(Colors.black),
                      ),
                      child: Text(category),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: ListView.builder(
  controller: _scrollController,
  itemCount: elements.length,
  itemBuilder: (BuildContext context, int index) {
    final element = elements[index];
    if (element['type'] == 'category') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          element['title'],
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      );
    } else if (element['type'] == 'item') {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10.0),
        ),
        margin: EdgeInsets.only(bottom: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (element['image'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15.0), 
                child: Image.asset(
                element['image'],
                width: double.infinity,
                height: 290,
                fit: BoxFit.cover,
                ),
                        ),
            SizedBox(height: 10),
            Text(element['name'],
            style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            ),
            ),
            SizedBox(height: 10),
            Text('Цена: ${element['price']} руб.',
            style: TextStyle(
            fontSize: 16.0,
            ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  cartItems.add({
                    'itemName': element['name'],
                    'price': element['price'],
                    'category': element['category'],
                  });
                  cartItemCount = cartItems.length;
                });
              },
              style: ElevatedButton.styleFrom(
                      minimumSize: Size(300, 50), 
              ),
              child: Text('Добавить'),
            ),
          ],
        ),
      );
    }
    return SizedBox.shrink();
  },
)
            ),
          ],
        ),
      ),
    );
  }

  void scrollToCategory(String category) {
    final index = elements.indexWhere(
      (element) => element['type'] == 'category' && element['title'] == category,
    );
    if (index != -1) {
      _scrollController.animateTo(
        index * 400,
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget buildListTileWithIconAndNavigation(String title, IconData icon, Widget destinationPage) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destinationPage),
        );
      },
    );
  }
}
 