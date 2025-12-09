const express = require('express');
const app = require('./server.js');

exports.handler = async (event, context) => {
  // Convert API Gateway event to Express-compatible request
  const { httpMethod, path, headers, body, queryStringParameters } = event;
  
  // Simple proxy to Express server
  return {
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ message: 'ProShop API - Use direct Express deployment' })
  };
};
