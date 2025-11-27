import express from "express";
import mysql from "mysql2/promise";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";
import cors from "cors";

const app = express();
app.use(express.json());
app.use(cors());

// =========================
// DB CONNECTION POOL
// =========================
const db = await mysql.createPool({
  host: "inf2006proj.c2recquoobti.us-east-1.rds.amazonaws.com",
  user: "admin",
  password: "INF2006Year2Tri1",
  database: "inf2006proj"
});

// =========================
// SIGNUP
// =========================
app.post("/signup", async (req, res) => {
  const { username, password } = req.body;

  const hash = await bcrypt.hash(password, 12);

  try {
    await db.execute("INSERT INTO users (username, password_hash) VALUES (?, ?)", [
      username,
      hash
    ]);
    res.json({ message: "User created successfully" });
  } catch (err) {
    res.status(400).json({ message: "User already exists" });
  }
});

// =========================
// LOGIN
// =========================
app.post("/login", async (req, res) => {
  const { username, password } = req.body;

  const [rows] = await db.execute("SELECT * FROM users WHERE username = ?", [username]);
  if (rows.length === 0) return res.status(400).json({ message: "User not found" });

  const user = rows[0];
  const valid = await bcrypt.compare(password, user.password_hash);

  if (!valid) return res.status(400).json({ message: "Invalid password" });

  // JWT
  const token = jwt.sign(
    { userId: user.id, username },
    "YOUR_SECRET_KEY",
    { expiresIn: "2h" }
  );

  res.json({ token });
});

// =========================
// PROTECTED ROUTE (example)
// =========================
app.get("/verify", (req, res) => {
  const token = req.headers.authorization?.split(" ")[1];

  try {
    const payload = jwt.verify(token, "YOUR_SECRET_KEY");
    res.json({ valid: true, payload });
  } catch {
    res.status(401).json({ valid: false });
  }
});

app.listen(3000, () => console.log("Server running on 3000"));
