import express from "express";
import mysql from "mysql2/promise";
import bcrypt from "bcrypt";
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
await db.execute(`DROP TABLE IF EXISTS users`);

await db.execute(`
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL
)
`);

console.log("Database ready: 'users' table created");

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

// START SERVER
app.listen(3000, () => console.log("Server running on port 3000"));
