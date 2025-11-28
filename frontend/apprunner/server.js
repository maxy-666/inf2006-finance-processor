import express from "express";
import mysql from "mysql2/promise";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import cors from "cors";

const app = express();
app.use(express.json());
app.use(cors());

// Global variable to hold the database connection
let db;

// ============================================
// DATABASE INITIALIZATION
// ============================================
async function initDB() {
  try {
    const pool = mysql.createPool({
      host: "inf2006proj.c2recquoobti.us-east-1.rds.amazonaws.com",
      user: "admin",
      password: "INF2006Year2Tri1",
      database: "users",
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0
    });

    // Test the connection
    await pool.query("SELECT 1");
    console.log("Database connected successfully");

    // Initialize Table
    await pool.execute(`
      CREATE TABLE IF NOT EXISTS users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        username VARCHAR(50) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL
      )
    `);
    console.log("'users' table verified");

    return pool;
  } catch (err) {
    console.error("----------------------------------------");
    console.error("DATABASE CONNECTION FAILED");
    console.error("Error Message:", err.message);
    console.error("Make sure your RDS Security Group allows traffic from 0.0.0.0/0");
    console.error("----------------------------------------");
    // Return null so the app knows DB is down, but doesn't crash
    return null;
  }
}

// ============================================
// MIDDLEWARE TO CHECK DB STATUS
// ============================================
const checkDb = (req, res, next) => {
  if (!db) {
    return res.status(503).json({ 
      message: "Service Unavailable: Database not connected yet.", 
      hint: "Check server logs for connection errors." 
    });
  }
  next();
};

// ============================================
// DEBUG ENDPOINTS
// ============================================

// View all users
app.get("/debug/users", checkDb, async (req, res) => {
  try {
    const [rows] = await db.execute("SELECT id, username FROM users");
    res.json({ count: rows.length, users: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete a specific user
app.delete("/debug/delete-user/:username", checkDb, async (req, res) => {
  try {
    const [result] = await db.execute(
      "DELETE FROM users WHERE username = ?",
      [req.params.username]
    );
    res.json({ 
      message: result.affectedRows > 0 ? "User deleted" : "User not found",
      deletedCount: result.affectedRows 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Clear all users
app.post("/debug/clear-all", checkDb, async (req, res) => {
  try {
    const [result] = await db.execute("DELETE FROM users");
    res.json({ message: "All users deleted", deletedCount: result.affectedRows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// MAIN ENDPOINTS
// ============================================

// SIGNUP
app.post("/signup", checkDb, async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ message: "Missing username or password" });

  try {
    const hash = await bcrypt.hash(password, 12);
    await db.execute(
      "INSERT INTO users (username, password_hash) VALUES (?, ?)",
      [username, hash]
    );
    res.json({ message: "User created successfully" });
  } catch (err) {
    console.error("Signup error:", err.code, err.sqlMessage);
    if (err.code === "ER_DUP_ENTRY") {
      res.status(400).json({ message: "User already exists" });
    } else {
      res.status(500).json({ message: "Database error" });
    }
  }
});

// LOGIN
app.post("/login", checkDb, async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ message: "Missing username or password" });

  try {
    const [rows] = await db.execute("SELECT * FROM users WHERE username = ?", [username]);

    if (rows.length === 0) return res.status(400).json({ message: "User not found" });

    const user = rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);

    if (!valid) return res.status(400).json({ message: "Invalid password" });

    const token = jwt.sign(
      { userId: user.id, username },
      "YOUR_SECRET_KEY", // Note: In production, use process.env.JWT_SECRET
      { expiresIn: "2h" }
    );

    res.json({ token });
  } catch (err) {
    console.error("Login error:", err.code, err.sqlMessage);
    res.status(500).json({ message: "Database error" });
  }
});

// HEALTH CHECK (Crucial for App Runner)
// This will work even if DB is down, preventing "Container exit code 1"
app.get("/health", (req, res) => {
  res.json({ 
    status: "OK", 
    dbStatus: db ? "Connected" : "Disconnected", 
    timestamp: new Date().toISOString() 
  });
});

// ============================================
// SERVER STARTUP
// ============================================
const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', async () => {
  console.log(`Server running on port ${PORT}`);
  
  // Try to connect to DB after server starts
  db = await initDB();
});
