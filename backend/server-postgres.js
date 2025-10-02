const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');
const bcrypt = require('bcrypt');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// PostgreSQL connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
});

async function initializeDatabase() {
  try {
    // Test connection
    await pool.query('SELECT NOW()');
    
    // Create tables if they don't exist
    await createTables();
    
    console.log('✅ PostgreSQL database connected and initialized');
  } catch (error) {
    console.error('❌ Database connection failed:', error);
  }
}

async function createTables() {
  try {
    // Users table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS users (
        user_id VARCHAR(255) PRIMARY KEY,
        username VARCHAR(100) UNIQUE NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        full_name VARCHAR(255) NOT NULL,
        role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'operator', 'viewer')),
        assigned_constituencies JSONB DEFAULT '[]',
        is_active BOOLEAN DEFAULT true,
        phone_number VARCHAR(20),
        department VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_login_at TIMESTAMP NULL
      )
    `);

    // Constituencies table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS constituencies (
        constituency_no INT PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        electoral_population INT NOT NULL,
        ethnic_majority VARCHAR(100) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    // Attendance events table
    await pool.query(`
      CREATE TABLE IF NOT EXISTS attendance_events (
        id VARCHAR(255) PRIMARY KEY,
        person_id VARCHAR(255),
        card_uid VARCHAR(255),
        zone_id VARCHAR(255),
        reader_id VARCHAR(255),
        decision VARCHAR(10) NOT NULL CHECK (decision IN ('allow', 'deny')),
        reason_code VARCHAR(50),
        timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        constituency_no INT,
        user_id VARCHAR(255),
        offline_flag BOOLEAN DEFAULT false,
        synced BOOLEAN DEFAULT true
      )
    `);

    console.log('✅ Database tables created/verified');
  } catch (error) {
    console.error('❌ Error creating tables:', error);
  }
}

// Routes

// Health check
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'Mauritius Attendance API is running' });
});

// Users endpoints
app.get('/api/users', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM users ORDER BY full_name');
    res.json({ users: result.rows });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/users/search', async (req, res) => {
  try {
    const { query } = req.query;
    const result = await pool.query(
      'SELECT * FROM users WHERE username = $1 OR email = $1 LIMIT 1',
      [query]
    );
    res.json({ user: result.rows[0] || null });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/users', async (req, res) => {
  try {
    const user = req.body;
    const hashedPassword = await bcrypt.hash(user.passwordHash, 10);
    
    await pool.query(`
      INSERT INTO users (user_id, username, email, password_hash, full_name, role, 
                        assigned_constituencies, is_active, phone_number, department)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
    `, [
      user.userId, user.username, user.email, hashedPassword, user.fullName,
      user.role, JSON.stringify(user.assignedConstituencies), user.isActive,
      user.phoneNumber, user.department
    ]);
    
    res.status(201).json({ message: 'User created successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Constituencies endpoints
app.get('/api/constituencies', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM constituencies ORDER BY constituency_no');
    res.json({ constituencies: result.rows });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/constituencies', async (req, res) => {
  try {
    const constituency = req.body;
    await pool.query(`
      INSERT INTO constituencies (constituency_no, name, electoral_population, ethnic_majority)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (constituency_no) DO UPDATE SET 
        name = EXCLUDED.name,
        electoral_population = EXCLUDED.electoral_population,
        ethnic_majority = EXCLUDED.ethnic_majority
    `, [
      constituency.constituencyNo, constituency.name, 
      constituency.electoralPopulation, constituency.ethnicMajority
    ]);
    
    res.status(201).json({ message: 'Constituency saved successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Attendance endpoints
app.post('/api/attendance', async (req, res) => {
  try {
    const event = req.body;
    await pool.query(`
      INSERT INTO attendance_events (id, person_id, card_uid, zone_id, reader_id, 
                                   decision, reason_code, constituency_no, user_id, 
                                   offline_flag, synced)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
    `, [
      event.id, event.personId, event.cardUid, event.zoneId, event.readerId,
      event.decision, event.reasonCode, event.constituencyNo, event.userId,
      event.offlineFlag, event.synced
    ]);
    
    res.status(201).json({ message: 'Attendance event saved successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.get('/api/attendance', async (req, res) => {
  try {
    const { constituency, start_date, end_date } = req.query;
    let query = 'SELECT * FROM attendance_events WHERE 1=1';
    const params = [];
    let paramCount = 0;
    
    if (constituency) {
      paramCount++;
      query += ` AND constituency_no = $${paramCount}`;
      params.push(constituency);
    }
    
    if (start_date) {
      paramCount++;
      query += ` AND timestamp >= $${paramCount}`;
      params.push(start_date);
    }
    
    if (end_date) {
      paramCount++;
      query += ` AND timestamp <= $${paramCount}`;
      params.push(end_date);
    }
    
    query += ' ORDER BY timestamp DESC';
    
    const result = await pool.query(query, params);
    res.json({ events: result.rows });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Initialize database and start server
initializeDatabase().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 Mauritius Attendance API running on port ${PORT}`);
  });
});
