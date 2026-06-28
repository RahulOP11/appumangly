#!/usr/bin/env python3
"""
Minimal Flask test server to verify connectivity
"""
from flask import Flask, jsonify
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@app.route('/')
def health():
    logger.info("Health check request received")
    return jsonify({
        "status": "healthy",
        "message": "Emotion Detection API is running",
        "version": "1.0.0"
    })

@app.route('/test')
def test():
    logger.info("Test endpoint request received")
    return jsonify({
        "message": "Test endpoint working",
        "success": True
    })

if __name__ == '__main__':
    logger.info("Starting minimal test server...")
    logger.info("Endpoints available:")
    logger.info("  GET / - Health check")
    logger.info("  GET /test - Test endpoint")
    
    try:
        app.run(host='127.0.0.1', port=5000, debug=False)
    except Exception as e:
        logger.error(f"Failed to start server: {e}")