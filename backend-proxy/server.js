// backend-proxy/server.js
const express = require('express');
const axios = require('axios');
const cors = require('cors');
require('dotenv').config(); // Loads environment variables from a .env file

// Create an Express application
const app = express();
const PORT = process.env.PORT || 3000; // Use port from .env or default to 3000

// --- Middleware ---
// Enable Cross-Origin Resource Sharing (CORS) so your frontend can call this server
app.use(cors());
// Enable parsing of JSON bodies in requests
app.use(express.json());


// --- ROUTE 1: Generate Upload URL (Existing) ---
app.get('/api/generate-upload-url', async (req, res) => {
  try {
    const awsApiUrl = process.env.API_GATEWAY_URL;

    if (!awsApiUrl) {
      console.error("API_GATEWAY_URL is missing in .env");
      return res.status(500).json({ error: 'API endpoint URL is not configured on the server.' });
    }
    
    const contentType = req.query.contentType;
    if (!contentType) {
        return res.status(400).json({ error: 'contentType query parameter is required.' });
    }

    console.log(`Forwarding upload request to AWS...`);
    const response = await axios.get(`${awsApiUrl}?contentType=${contentType}`);

    res.status(200).json(response.data);

  } catch (error) {
    console.error('Error proxying upload request:', error.message);
    
    // Robust Error Handling: Pass upstream AWS errors back to frontend
    const msg = error.response && error.response.data ? JSON.stringify(error.response.data) : error.message;
    res.status(500).json({ error: `Failed to fetch upload URL: ${msg}` });
  }
});


// --- ROUTE 2: Get Dashboard Embed URL (New) ---
app.get('/api/get-dashboard-url', async (req, res) => {
  try {
    // 1. Get the Dashboard API URL from environment variables
    const dashboardApiUrl = process.env.DASHBOARD_API_URL;

    if (!dashboardApiUrl) {
      console.error("DASHBOARD_API_URL is missing in .env");
      return res.status(500).json({ error: 'Dashboard API URL is not configured on server.' });
    }

    console.log(`Forwarding dashboard request to: ${dashboardApiUrl}`);
    
    // 2. Call the AWS API Gateway (which calls your Lambda)
    const response = await axios.get(dashboardApiUrl);

    // 3. Send the result (Embed URL) back to the frontend
    res.status(200).json(response.data);

  } catch (error) {
    console.error('Error fetching dashboard URL:', error.message);
    
    // Robust Error Handling: Pass upstream AWS errors back to frontend
    const msg = error.response && error.response.data ? JSON.stringify(error.response.data) : error.message;
    res.status(500).json({ error: `Failed to get dashboard URL: ${msg}` });
  }
});


// --- Start the Server ---
app.listen(PORT, () => {
  console.log(`Proxy server is running on http://localhost:${PORT}`);
});