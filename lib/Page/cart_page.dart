import 'package:flutter/material.dart';
import '../services/order_service.dart'; // Импортируем сервис OrderService

class CartPage extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function(List<Map<String, dynamic>>) onCartUpdated;
  final Function(Map<String, dynamic>)
      onOrderPlaced; // Функция для добавления заказа в историю

  CartPage({
    Key? key,
    this.cartItems = const [],
    required this.onCartUpdated,
    required this.onOrderPlaced, // Обязательная функция для передачи заказа в историю
  }) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late List<Map<String, dynamic>> currentCartItems;
  String deliveryAddress = '';
  String selectedTime = 'Выберите время';

  // Переменная для хранения общей стоимости
  double totalPrice = 0.0;

  // Добавляем счетчик номеров заказов
  int orderCounter = 1;
  final OrderService _orderService =
      OrderService(); // Создаем экземпляр OrderService

  @override
  void initState() {
    super.initState();
    currentCartItems = List.from(widget.cartItems);
    totalPrice = _calculateTotalPrice(); // Инициализируем totalPrice при старте
  }

  // Метод для вычисления общей стоимости
  double _calculateTotalPrice() {
    double total = 0.0;
    for (var item in currentCartItems) {
      total += item['price']; // Суммируем цены всех товаров
    }
    return total;
  }

  // Метод для обновления общей стоимости, когда корзина изменяется
  void _updateTotalPrice() {
    setState(() {
      totalPrice = _calculateTotalPrice();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cart', style: TextStyle(fontSize: 25)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            widget.onCartUpdated(currentCartItems);
            Navigator.pop(context, currentCartItems);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            iconSize: 30.0,
            onPressed: () {
              _clearCart();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7.0),
                    child: ElevatedButton(
                      onPressed: () {
                        _showTimeSelectionDialog();
                      },
                      child: Text(
                        selectedTime,
                        style: TextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                            vertical: 20.0, horizontal: 80.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Улица для доставки:'),
                        SizedBox(height: 5),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color.fromARGB(255, 40, 33, 243)),
                          ),
                          child: TextField(
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                              hintText: 'Введите улицу',
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 20),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              setState(() {
                                deliveryAddress = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentCartItems.length,
                      itemBuilder: (context, index) {
                        final item = currentCartItems[index];
                        return Dismissible(
                          key: UniqueKey(),
                          onDismissed: (direction) {
                            setState(() {
                              currentCartItems.removeAt(index);
                            });
                            widget.onCartUpdated(currentCartItems);
                            _updateTotalPrice(); // Обновляем общую стоимость
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            color: const Color.fromARGB(255, 0, 26, 255),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          child: ListTile(
                            title: Text(item['itemName']),
                            subtitle: Text('Категория: ${item['category']}'),
                            trailing: Text('Цена: ${item['price']} \$'),
                          ),
                        );
                      },
                    ),
                  ),
                  // Отображение общей стоимости
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 15.0),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 56, 12, 235),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(255, 103, 9, 255).withOpacity(0.3),
                            spreadRadius: 3,
                            blurRadius: 7,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Итого:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 9, 219, 230),
                            ),
                          ),
                          Text(
                            '${totalPrice.toStringAsFixed(2)} руб.',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 9, 219, 230),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      
                      onPressed: () {
                        _placeOrder();
                      },
                      child: Text('Оплатить'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _clearCart() {
    setState(() {
      currentCartItems.clear();
      widget.onCartUpdated([]); // Уведомляем об изменении корзины
      _updateTotalPrice(); // Обновляем общую стоимость
    });
    _showSnackBar('Корзина очищена');
  }

  void _placeOrder() {
    if (currentCartItems.isEmpty) {
      _showSnackBar('Корзина пуста!');
      return;
    }
    if (deliveryAddress.isEmpty) {
      _showSnackBar('Введите адрес доставки');
      return;
    }
    if (selectedTime == 'Выберите время') {
      _showSnackBar('Выберите время доставки');
      return;
    }

    // Используем сервис для записи заказа в базу данных
    _orderService
        .createOrder(
      items: currentCartItems,
      deliveryAddress: deliveryAddress,
      selectedTime: selectedTime,
      totalPrice: totalPrice,
    )
        .then((_) {
      // После успешного создания заказа, обновляем историю и очищаем корзину
      final order = {
        'orderNumber': 'ORD${orderCounter.toString().padLeft(3, '0')}',
        'address': deliveryAddress,
        'time': selectedTime,
        'items': List<Map<String, dynamic>>.from(currentCartItems),
        'totalPrice': totalPrice, // Используем переменную totalPrice
      };

      widget.onOrderPlaced(order); // Передаем заказ в историю
      widget.onCartUpdated([]); // Очистка корзины

      setState(() {
        orderCounter++; // Инкрементируем номер заказа для следующего
      });

      Navigator.pop(context, []); // Закрытие корзины
    }).catchError((e) {
      _showSnackBar('Ошибка при создании заказа: $e');
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
        message,
        textAlign: TextAlign.center,
      )),
    );
  }

  void _showTimeSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выберите время для выполнения заказа'),
          content: Container(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: Text('15 минут'),
                  onTap: () {
                    setState(() {
                      selectedTime = 'Через 15 минут';
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('30 минут'),
                  onTap: () {
                    setState(() {
                      selectedTime = 'Через 30 минут';
                    });
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text('45 минут'),
                  onTap: () {
                    setState(() {
                      selectedTime = 'Через 45 минут';
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
