import os 
from flask import Flask,jsonify
from flask_jwt_extended import JWTManager
from datetime import timedelta
from app.db import init_db

jwt = JWTManager()

def create_app():
    app = Flask(__name__)
    app.config["JWT_SECRET_KEY"] = os.environ.get("JWT_SECRET_KEY","change-me-in-production")
    app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(hours=24)
    jwt.init_app(app)

    init_db()

    from app.auth import auth_bp
    from app.todos import todos_bp
    app.register_blueprint(auth_bp)
    app.register_blueprint(todos_bp)

    @jwt.unauthorized_loader
    def missing(r): return jsonify({"error":"token requied"}),401
    @jwt.expired_token_loader
    def expired(h,p): return jsonify({"error":"token expired"}),401
    @jwt.invalid_token_loader
    def invalid(r): return jsonify({"error":"invalid token"}),422

    @app.get("/healthz")
    def healthz():
        import socket
        return jsonify({
            "status":"ok",
            "hostname":socket.gethostname(),
            "instance":os.environ.get("AWS_AZ","unknown")
        })
    return app