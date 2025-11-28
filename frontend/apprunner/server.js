import express from "express";
import mysql from "mysql2/promise";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import cors from "cors";

const app = express();
app.use(express.json());
app.use(cors());

// DATABASE CONNECTION
const db = await mysql.createPool({
  host: "inf2006proj.c2recquoobti.us-east-1.rds.amazonaws.com",
  user: "admin",
  password: "INF2006Year2Tri1",
  database: "users"
});

// DROP & CREATE TABLE (DEV ONLY)
await db.execute(`
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL
)
`);

console.log("Database ready: 'users' table verified");

// ============================================
// DEBUG ENDPOINTS (Remove before production!)
// ============================================

// View all users
app.get("/debug/users", async (req, res) => {
  try {
    const [rows] = await db.execute("SELECT id, username FROM users");
    res.json({ 
      count: rows.length, 
      users: rows 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Delete a specific user
app.delete("/debug/delete-user/:username", async (req, res) => {
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
app.post("/debug/clear-all", async (req, res) => {
  try {
    const [result] = await db.execute("DELETE FROM users");
    res.json({ 
      message: "All users deleted", 
      deletedCount: result.affectedRows 
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ============================================
// MAIN ENDPOINTS
// ============================================

// SIGNUP
app.post("/signup", async (req, res) => {
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
app.post("/login", async (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) return res.status(400).json({ message: "Missing username or password" });

  try {
    const [rows] = await db.execute(
      "SELECT * FROM users WHERE username = ?",
      [username]
    );

    if (rows.length === 0) return res.status(400).json({ message: "User not found" });

    const user = rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);

    if (!valid) return res.status(400).json({ message: "Invalid password" });

    const token = jwt.sign(
      { userId: user.id, username },
      "YOUR_SECRET_KEY",
      { expiresIn: "2h" }
    );

    res.json({ token });
  } catch (err) {
    console.error("Login error:", err.code, err.sqlMessage);
    res.status(500).json({ message: "Database error" });
  }
});

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "OK", timestamp: new Date().toISOString() });
});

// START SERVER
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running on port ${PORT}`);
  console.log("Debug endpoints enabled:");
  console.log("  GET  /debug/users");
  console.log("  DELETE /debug/delete-user/:username");
  console.log("  POST /debug/clear-all");
});
