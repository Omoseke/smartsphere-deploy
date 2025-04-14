const express = require('express');
const router = express.Router();
const { User, Inventory, sequelize } = require('../models');

// Get all users
router.get('/users', async (req, res) => {
  try {
    const users = await User.findAll({
      attributes: { exclude: ['password'] } // Don't send passwords
    });
    res.json(users);
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Get user by ID
router.get('/users/:id', async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id, {
      attributes: { exclude: ['password'] },
      include: [Inventory]
    });
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json(user);
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Create a new user
router.post('/users', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    
    // Simple validation
    if (!username || !email || !password) {
      return res.status(400).json({ message: 'Please include username, email, and password' });
    }
    
    // Check if user already exists
    const existingUser = await User.findOne({ 
      where: {
        [sequelize.Op.or]: [
          { username },
          { email }
        ]
      }
    });
    
    if (existingUser) {
      return res.status(400).json({ message: 'User already exists' });
    }
    
    // Hash password in production (skipped for demo)
    
    // Create user
    const user = await User.create({
      username,
      email,
      password, // In production: hashedPassword
    });
    
    res.status(201).json({
      id: user.id,
      username: user.username,
      email: user.email,
      isVerified: user.isVerified
    });
  } catch (error) {
    console.error('Error creating user:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

// Inventory routes
router.get('/inventory', async (req, res) => {
  try {
    const inventoryItems = await Inventory.findAll({
      include: [
        {
          model: User,
          attributes: ['id', 'username']
        }
      ]
    });
    res.json(inventoryItems);
  } catch (error) {
    console.error('Error fetching inventory:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

router.post('/inventory', async (req, res) => {
  try {
    const { userId, itemName, quantity, category, description, price } = req.body;
    
    // Simple validation
    if (!userId || !itemName) {
      return res.status(400).json({ message: 'User ID and item name are required' });
    }
    
    // Check if user exists
    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    // Create inventory item
    const item = await Inventory.create({
      userId,
      itemName,
      quantity: quantity || 0,
      category,
      description,
      price
    });
    
    res.status(201).json(item);
  } catch (error) {
    console.error('Error creating inventory item:', error);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;