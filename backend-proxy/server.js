// Import required packages
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


// --- API Proxy Route ---
// This is the endpoint your frontend will call.
app.get('/api/generate-upload-url', async (req, res) => {
  try {
    // 1. Get the actual, secret AWS API Gateway URL from environment variables
    const awsApiUrl = process.env.API_GATEWAY_URL;

    if (!awsApiUrl) {
      // If the secret URL is not set, return a server error
      return res.status(500).json({ error: 'API endpoint URL is not configured on the server.' });
    }
    
    // 2. Forward the 'contentType' query parameter from the original request
    const contentType = req.query.contentType;
    if (!contentType) {
        return res.status(400).json({ error: 'contentType query parameter is required.' });
    }

    // 3. Make a request from THIS server to the AWS API Gateway.
    // This happens on the server, so the URL is never exposed to the public.
    console.log(`Forwarding request to: ${awsApiUrl}?contentType=${contentType}`);
    const response = await axios.get(`${awsApiUrl}?contentType=${contentType}`);

    // 4. Send the response from AWS back to the frontend
    res.status(200).json(response.data);

  } catch (error) {
    // Basic error handling
    console.error('Error proxying request:', error.message);
    res.status(500).json({ error: 'Failed to fetch data from the upstream service.' });
  }
});


// --- Start the Server ---
app.listen(PORT, () => {
  console.log(`Proxy server is running on http://localhost:${PORT}`);
});
