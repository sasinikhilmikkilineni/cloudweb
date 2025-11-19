// backend/controllers/orderController.js
import asyncHandler from '../middleware/asyncHandler.js';
import Order from '../models/orderModel.js';
import Product from '../models/productModel.js';

/**
 * @desc   Create new order
 * @route  POST /api/orders
 * @access Private
 */
export const addOrderItems = asyncHandler(async (req, res) => {
  // ✅ hard guard: make sure auth middleware actually populated req.user
  if (!req.user || !req.user._id) {
    res.status(401);
    throw new Error('Not authorized: user missing or session expired');
  }

  const { orderItems = [], shippingAddress, paymentMethod } = req.body;

  if (!orderItems.length) {
    res.status(400);
    throw new Error('No order items');
  }

  // Normalize item id (accept item.product or item._id) and inject current price
  const itemsWithPrice = await Promise.all(
    orderItems.map(async (x, idx) => {
      const productId = x.product || x._id;
      if (!productId) {
        throw new Error(`Invalid cart item at index ${idx}: missing product id`);
      }

      const product = await Product.findById(productId).select('price name image');
      if (!product) {
        throw new Error(`Product not found: ${productId}`);
      }

      const qty = Number.isFinite(Number(x.qty)) ? Number(x.qty) : 0;

      return {
        product: productId,
        name: x.name || product.name,
        image: x.image || product.image,
        qty,
        price: Number(product.price),
      };
    })
  );

  // Server-side totals
  const itemsPrice = Number(
    itemsWithPrice.reduce((acc, item) => acc + item.qty * item.price, 0).toFixed(2)
  );
  const taxPrice = Number((0.15 * itemsPrice).toFixed(2));
  const shippingPrice = Number((itemsPrice > 100 ? 0 : 10).toFixed(2));
  const totalPrice = Number((itemsPrice + taxPrice + shippingPrice).toFixed(2));

  const order = new Order({
    orderItems: itemsWithPrice,
    shippingAddress,
    paymentMethod,
    itemsPrice,
    taxPrice,
    shippingPrice,
    totalPrice,
    user: req.user._id, // safe because we guarded above
  });

  const createdOrder = await order.save();
  res.status(201).json(createdOrder);
});

/**
 * @desc   Get order by ID
 * @route  GET /api/orders/:id
 * @access Private
 */
export const getOrderById = asyncHandler(async (req, res) => {
  const order = await Order.findById(req.params.id).populate('user', 'name email');
  if (order) {
    res.json(order);
  } else {
    res.status(404);
    throw new Error('Order not found');
  }
});

/**
 * @desc   Update order to paid
 * @route  PUT /api/orders/:id/pay
 * @access Private
 */
export const updateOrderToPaid = asyncHandler(async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) {
    res.status(404);
    throw new Error('Order not found');
  }

  order.isPaid = true;
  order.paidAt = Date.now();
  order.paymentResult = {
    id: req.body.id,
    status: req.body.status,
    update_time: req.body.update_time,
    email_address: req.body.payer?.email_address,
  };

  const updatedOrder = await order.save();
  res.json(updatedOrder);
});

/**
 * @desc   Update order to delivered
 * @route  PUT /api/orders/:id/deliver
 * @access Private/Admin
 */
export const updateOrderToDelivered = asyncHandler(async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order) {
    res.status(404);
    throw new Error('Order not found');
  }

  order.isDelivered = true;
  order.deliveredAt = Date.now();

  const updatedOrder = await order.save();
  res.json(updatedOrder);
});

/**
 * @desc   Get logged-in user's orders
 * @route  GET /api/orders/myorders
 * @access Private
 */
export const getMyOrders = asyncHandler(async (req, res) => {
  if (!req.user || !req.user._id) {
    res.status(401);
    throw new Error('Not authorized: user missing or session expired');
  }
  const orders = await Order.find({ user: req.user._id }).sort({ createdAt: -1 });
  res.json(orders);
});

/**
 * @desc   Get all orders
 * @route  GET /api/orders
 * @access Private/Admin
 */
export const getOrders = asyncHandler(async (_req, res) => {
  const orders = await Order.find({}).populate('user', 'id name').sort({ createdAt: -1 });
  res.json(orders);
});
