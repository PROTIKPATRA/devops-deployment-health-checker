from flask import Flask, jsonify
import os
import time

app = Flask(__name__)
START_TIME = time.time()

# Deliberately toggle this via env var to simulate a broken deployment
HEALTHY = os.getenv("HEALTHY", "true").lower() == "true"


@app.route("/")
def index():
    return jsonify({"service": "deployment-health-checker", "version": "1.0.0"})


@app.route("/health")
def health():
    uptime = round(time.time() - START_TIME, 2)
    if not HEALTHY:
        return jsonify({
            "status": "unhealthy",
            "reason": "simulated failure",
            "uptime_seconds": uptime
        }), 503
    return jsonify({
        "status": "healthy",
        "uptime_seconds": uptime,
        "checks": {"app": "ok", "config": "ok"}
    }), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)