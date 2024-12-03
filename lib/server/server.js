const express = require('express');
const jwt = require('jsonwebtoken');
const bodyParser = require('body-parser');
const firebaseAdmin = require('firebase-admin');
const bcrypt = require('bcrypt');
require('dotenv').config();
const moment = require('moment');
const chalk = require('chalk'); 

const app = express();
const port = 5001;

const serviceAccount = require(process.env.FIREBASE_SERVICE_ACCOUNT_KEY_PATH);
firebaseAdmin.initializeApp({
  credential: firebaseAdmin.credential.cert(serviceAccount),
});
const db = firebaseAdmin.firestore();

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;
const JWT_ACCESS_EXPIRES_IN = process.env.JWT_ACCESS_EXPIRES_IN;
const JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN;

app.use(bodyParser.json());



//generating tokens
const generateTokens = (userEmail) => {
  const accessToken = jwt.sign({ email: userEmail }, JWT_SECRET, {
    expiresIn: JWT_ACCESS_EXPIRES_IN,
  });
  const refreshToken = jwt.sign({ email: userEmail }, JWT_REFRESH_SECRET, {
    expiresIn: JWT_REFRESH_EXPIRES_IN,
  });

  

  return { accessToken, refreshToken };
};


const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ message: 'Access token is missing' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: 'Invalid or expired token' });
    req.user = user;
    next();
  });
};

app.post('/updateTokens', async (req, res) => {  
  const { refresh_token: refreshToken } = req.body;
  if (!refreshToken) {
    console.error('[ERROR] Refresh token is missing in request');
    return res.status(400).json({ message: 'Refresh token is required' });
  }

  jwt.verify(refreshToken, JWT_REFRESH_SECRET, (err, user) => {
    if (err) {
      console.error(`[ERROR] Invalid refresh token: ${err.message}`);
      return res.status(403).json({ message: 'Invalid or expired refresh token' });
    }

    const { email } = user;
    const tokens = generateTokens(email);
    console.log(`[INFO] Tokens refreshed successfully for user: ${email}`);
    console.log('[INFO] New access token:', tokens.accessToken);  // Logging in a new access token
    console.log('[INFO] New refresh token:', tokens.refreshToken);  // Logging in a new refresh token
    res.status(200).json({
      access_token: tokens.accessToken,
      refresh_token: tokens.refreshToken,
    });
  });
});


// User Registration
app.post('/signup', async (req, res) => {
  const { email, password, name } = req.body;
  try {
    const hashedPassword = await bcrypt.hash(password, 10);

    // Creating a user in Firebase
    const userRecord = await firebaseAdmin.auth().createUser({
      email: email,
      password: password,
      displayName: name,
    });

    // Saving user data in the Firestore
    const createdAt = moment().toISOString();
    await db.collection('users').doc(userRecord.uid).set({
      email: email,
      name: name,
      orderCount: 0,
      balance: 0,
      createdAt: createdAt,
      passwordHash: hashedPassword,
    });

    // //generating tokens
    const { accessToken, refreshToken } = generateTokens(email);

    // output information about the new user to the terminal
    const currentTime = moment().format('YYYY-MM-DD HH:mm:ss');
    console.log(chalk.green(`[INFO] ${currentTime}: User "${userRecord.displayName}" has successfully registered.`));
    console.log(chalk.green(`[INFO] Access Token generated: ${accessToken}`));
    console.log(chalk.green(`[INFO] Refresh Token generated: ${refreshToken}`));

    res.json({ userName: userRecord.displayName, access_token: accessToken, refresh_token: refreshToken });
  } catch (error) {
    console.error(chalk.red(`[ERROR] ${error.message}`));
    res.status(400).json({ message: 'Registration failed', error: error.message });
  }
});

app.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const userRecord = await firebaseAdmin.auth().getUserByEmail(email);
    const userDoc = await db.collection('users').doc(userRecord.uid).get();
    const userData = userDoc.data();

    if (!userData) throw new Error('User data not found');

    const isPasswordValid = await bcrypt.compare(password, userData.passwordHash);
    if (!isPasswordValid) throw new Error('Invalid password');

    // //generating tokens
    const { accessToken, refreshToken } = generateTokens(email);

    //display information about the user and the login time
    const loginTime = moment().format('YYYY-MM-DD HH:mm:ss');
    console.log(chalk.green(`[INFO] ${loginTime}: User "${userData.name}" logged in successfully.`));
    console.log(chalk.green(`[INFO] Access Token generated: ${accessToken}`));
    console.log(chalk.green(`[INFO] Refresh Token generated: ${refreshToken}`));

    res.json({ userName: userData.name || email, access_token: accessToken, refresh_token: refreshToken });
  } catch (error) {
    console.error(chalk.red(`[ERROR] ${error.message}`));
    res.status(400).json({ message: 'Invalid email or password', error: error.message });
  }
});

app.get('/getUserProfile', authenticateToken, async (req, res) => {
  const { email } = req.user;

  try {
    const userQuery = await db.collection('users').where('email', '==', email).limit(1).get();

    if (userQuery.empty) {
      return res.status(404).json({ message: 'User not found' });
    }

    const userDoc = userQuery.docs[0];
    const userData = userDoc.data();

    // Checking for a username
    const userName = userData.name && userData.name.trim() !== '' ? userData.name : 'Unknown User';

    res.status(200).json({
      userName: userName,
      orderCount: userData.orderCount || 0,
      balance: userData.balance || 0
    });
  } catch (error) {
    console.error('Error retrieving user profile:', error);
    res.status(500).json({ message: 'Error retrieving user profile', error: error.message });
  }
});


app.post('/updateBalance', authenticateToken, async (req, res) => {
  const { balance } = req.body;
  
  if (typeof balance !== 'number' || balance < 0) {
    return res.status(400).json({ message: 'Invalid amount' });
  }

  const { email } = req.user;
  
  try {
    const userQuery = await db.collection('users').where('email', '==', email).limit(1).get();

    if (userQuery.empty) {
      return res.status(404).json({ message: 'User not found' });
    }

    const userDoc = userQuery.docs[0];
    await userDoc.ref.update({ balance });
    res.status(200).json({ message: 'Balance updated successfully' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Internal server error' });
  }
});



// Получение блюд из базы данных
app.get('/getDishes', async (req, res) => {
  try {
    // Получаем все документы из коллекции 'dishes'
    const dishesCollection = await db.collection('dishes').get();
    
    // Если коллекция пуста, возвращаем ошибку
    if (dishesCollection.empty) {
      return res.status(404).json({ message: 'Dishes collection is empty' });
    }

    // Получаем первый документ из коллекции 'dishes' (с автоматически сгенерированным ID)
    const firstDishesDoc = dishesCollection.docs[0]; // Берём первый документ
    const dishesData = firstDishesDoc.data();

    // Проверка на наличие поля categories
    if (!dishesData || !dishesData.categories) {
      return res.status(400).json({ message: 'Invalid dishes data structure' });
    }

    // Извлекаем категории и готовим их к отправке
    const categories = dishesData.categories;

    // Подготовка списка категорий, которые мы будем отправлять
    const responseCategories = Object.keys(categories).map(categoryName => {
      return {
        category: categoryName,
        dishes: categories[categoryName]
      };
    });

    res.status(200).json({ categories: responseCategories });
  } catch (error) {
    console.error(`[ERROR] Error fetching dishes: ${error.message}`);
    res.status(500).json({ message: 'Error fetching dishes', error: error.message });
  }
});






// Receiving user orders by token
app.get('/getOrdersByUser', authenticateToken, async (req, res) => {
  const { email } = req.user;

  try {
    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    // Search for orders
    const ordersSnapshot = await db.collection('orders').where('email', '==', email).get();

    if (ordersSnapshot.empty) {
      return res.status(404).json({ message: 'No orders found for this user' });
    }

    const orders = ordersSnapshot.docs.map((doc) => {
      const orderData = doc.data();
      return {
        id: doc.id,
        ...orderData,
        orderDate: orderData.orderDate.toDate(), // Firestore Timestamp в Date
        estimatedReadyTime: orderData.estimatedReadyTime.toDate(),
      };
    });
    
    res.status(200).json({ orders });
  } catch (error) {
    console.error('Error retrieving orders:', error.message);
    res.status(500).json({ message: 'Error retrieving orders', error: error.message });
  }
});

app.post('/createOrder', authenticateToken, async (req, res) => {
  const { items, deliveryAddress, selectedTime, totalPrice } = req.body;
  const { email } = req.user;

  try {
    // Checking input data
    if (!Array.isArray(items) || typeof deliveryAddress !== 'string' || typeof selectedTime !== 'string' || typeof totalPrice !== 'number') {
      return res.status(400).json({ message: 'Invalid order data' });
    }

    // get the user by email
    const userRecord = await firebaseAdmin.auth().getUserByEmail(email);
    const userDoc = await db.collection('users').doc(userRecord.uid).get();
    const userData = userDoc.data();

    if (!userData) {
      return res.status(400).json({ message: 'User not found' });
    }

    // Checking the user's balance
    const currentBalance = userData.balance || 0;
    if (currentBalance < totalPrice) {
      return res.status(400).json({ message: 'Insufficient balance' });
    }

    // Subtract the cost from the balance
    const updatedBalance = currentBalance - totalPrice;
    await db.collection('users').doc(userRecord.uid).update({
      balance: updatedBalance,
    });

    // increase the order counter and generate the order number
    let orderCount = userData.orderCount || 0;
    const orderNumber = `ORD${(orderCount + 1).toString().padStart(3, '0')}`;

    // Calculating the order availability time
    const minutesToAdd = selectedTime === 'Через 15 минут' ? 15 : selectedTime === 'Через 30 минут' ? 30 : selectedTime === 'Через 45 минут' ? 45 : 0;
    const estimatedReadyDateTime = moment().add(minutesToAdd, 'minutes').toDate();

    // save order in Firestore
    const orderRef = await db.collection('orders').add({
      email: email,
      orderNumber: orderNumber,
      address: deliveryAddress,
      items: items,
      totalPrice: totalPrice, // save the total cost
      orderDate: firebaseAdmin.firestore.FieldValue.serverTimestamp(),
      estimatedReadyTime: estimatedReadyDateTime,
      status: 'pending',
    });

    //  Updating the order counter for the user
    await db.collection('users').doc(userRecord.uid).update({
      orderCount: orderCount + 1,
    });

    const orderId = orderRef.id;

    // Timer for 10 seconds to update the status to 'progress'
    setTimeout(async () => {
      console.log(`[INFO] Updating order ${orderId} status to 'in_progress'`);
      await db.collection('orders').doc(orderId).update({
        status: 'in_progress',
      });
    }, 10 * 1000);

    // Setting the status to 'completed' automatically
    checkAndUpdateOrderStatus(orderId, estimatedReadyDateTime);

    res.status(200).json({
      message: 'Order created successfully',
      newBalance: updatedBalance, // returning the updated balance
    });
  } catch (error) {
    console.error(chalk.red('Error creating order:', error));
    res.status(500).json({ message: 'Error creating order', error: error.message });
  }
});



const checkAndUpdateOrderStatus = async (orderId, estimatedReadyDateTime) => {
  try {
    const currentTime = moment();

    // receive the order document
    const orderDoc = await db.collection('orders').doc(orderId).get();
    if (!orderDoc.exists) {
      console.log(`[WARNING] Order ${orderId} not found.`);
      return;
    }

    const orderData = orderDoc.data();
    const orderTime = moment(orderData.orderDate.toDate());
    const estimatedReadyTime = moment(estimatedReadyDateTime);

    // Status change to 'completed' if the ready time has passed
    if (currentTime.isSameOrAfter(estimatedReadyTime) && orderData.status === 'in_progress') {
      console.log(`[INFO] Updating order ${orderId} status to 'completed'`);
      await db.collection('orders').doc(orderId).update({
        status: 'completed',
      });
    } else {
      console.log(`[DEBUG] No status update required for order ${orderId}`);
    }
  } catch (error) {
    console.error(`[ERROR] Error updating status for order ${orderId}: ${error.message}`);
  }
};



const startStatusUpdateInterval = () => {
  setInterval(async () => {
    const ordersSnapshot = await db.collection('orders').where('status', '==', 'in_progress').get();
    ordersSnapshot.forEach((orderDoc) => {
      const orderData = orderDoc.data();
      const estimatedReadyTime = orderData.estimatedReadyTime.toDate();
      checkAndUpdateOrderStatus(orderDoc.id, estimatedReadyTime);
    });
  }, 300 * 1000); // check orders every minute
};

// Launching the periodic status check function
startStatusUpdateInterval();

app.listen(port, () => {
  console.log(chalk.blue(`Server is running on http://localhost:${port}`));
});