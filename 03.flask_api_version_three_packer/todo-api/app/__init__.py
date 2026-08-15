import os 
import socket
from flask import Flask,jsonify
from flask_jwt_extended import JWTManager
from datetime import timedelta
# from app.temp.db import init_db
from flask_sqlalchemy import SQLAlchemy
jwt = JWTManager()
db = SQLAlchemy()

def create_app():
    app = Flask(__name__)
    app.config["JWT_SECRET_KEY"] = os.environ.get("JWT_SECRET_KEY","change-me-in-production")
    app.config["JWT_ACCESS_TOKEN_EXPIRES"] = timedelta(hours=24)
    app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL','postgresql://postgres:password@localhost:5432/tododb')

    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['SQLALCHEMY_ECHO'] = os.environ.get('SQLALCHEMY_ECHO','False') == 'True'
    db.init_app(app)
    jwt.init_app(app)

    # with app.app_context():
    #     from app.models import User,Todo
    #     db.create_all()

    #  FIXED LAYOUT
    
    from app.models import User, Todo # Simply import, don't execute create_all() here
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
        db_ok = True
        try:
            db.session.execute(db.text('SELECT 1'))
        except Exception:
            db_ok = False
        return jsonify({
            "status":"ok" if db_ok else 'degraded',
            "database": 'ok' if db_ok else 'unreachable',
            "hostname":socket.gethostname(),
            "instance":os.environ.get("AWS_AZ","unknown")
        })
    return app