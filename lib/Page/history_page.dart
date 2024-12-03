import 'package:flutter/material.dart';
import '../services/order_service.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late List<Map<String, dynamic>> orders = [];
  late OrderService orderService;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeOrderService();
    _fetchOrderHistory();
  }

  // Инициализация OrderService
  void _initializeOrderService() {
    orderService = OrderService();
  }

  // Загрузка истории заказов
  Future<void> _fetchOrderHistory() async {
    try {
      final fetchedOrders = await orderService.getOrdersByUser();
      setState(() {
        // Сортировка заказов по номеру заказа (по возрастанию)
        fetchedOrders.sort((a, b) => a['orderNumber'].compareTo(b['orderNumber']));
        orders = fetchedOrders;
      });
    } catch (e) {
      print('Ошибка при загрузке заказов: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Метод для вычисления прогресса готовности заказа
  double _getOrderProgress(DateTime orderDate, DateTime estimatedReadyTime) {
    final currentTime = DateTime.now();
    if (currentTime.isAfter(estimatedReadyTime)) return 1.0;
    if (currentTime.isBefore(orderDate)) return 0.0;

    final totalDuration = estimatedReadyTime.difference(orderDate);
    final elapsedDuration = currentTime.difference(orderDate);
    return elapsedDuration.inSeconds / totalDuration.inSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('История заказов')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('Нет заказов'))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final items = order['items'] as List<dynamic>;
                    final estimatedReadyTime = DateTime.parse(order['estimatedReadyTime']);
                    final orderDate = DateTime.parse(order['orderDate']);
                    final progress = _getOrderProgress(orderDate, estimatedReadyTime);

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Номер заказа: ${order['orderNumber']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Адрес: ${order['address']}'),
                            Text('Email: ${order['email']}'),
                            Text('Статус: ${order['status']}'),
                            const SizedBox(height: 10),
                            Text('Прогресс готовности: ${(progress * 100).toStringAsFixed(2)}%'),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 10),
                            const Text('Список товаров:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...items.map<Widget>((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Товар: ${item['itemName']}', style: const TextStyle(fontSize: 16)),
                                    Text('Категория: ${item['category']}'),
                                    Text('Цена: ${item['price']} руб.'),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
