import bcrypt
from flask import Blueprint,request,jsonify
from flask_jwt_extended import create_access_token
# from app.temp.db import get_user_by_email,create_user
from app import db
from app.models import User

auth_bp = Blueprint("auth",__name__)

@auth_bp.post("/auth/register")
def register():
    data = request.get_json(silent=True) or {}
    email = data.get("email","").strip().lower()
    password= data.get("password","")

    if not email or not password:
        return jsonify({"error":"email and password required"}),400
    if len(password) < 8:
        return jsonify({"error":"Password must be 8+ characters"}),400
    if User.query.filter_by(email=email).first():
        return jsonify({"error":"email already registered"}),409

    pw_hash = bcrypt.hashpw(password.encode(),bcrypt.gensalt(rounds=12)).decode()
    user = User(email=email,password_hash=pw_hash)
    db.session.add(user)
    db.session.commit()

    return jsonify({
        "message":"registered",
        "user":user.to_dict()
    }),201

@auth_bp.post("/auth/login")
def login():
    data = request.get_json(silent=True) or {}
    email = data.get("email","").strip().lower()
    password= data.get("password","")

    if not email or not password:
        return jsonify({"error":"email and password required"}),400
    user = User.query.filter_by(email=email).first()

    if not user or not bcrypt.checkpw(password.encode(),user.password_hash.encode()):
        return jsonify({"error":"invalid email or password"}),401

    # token = create_access_token(identity=str(user["id"])) # <-- FIX: Wrap in str()
    token = create_access_token(identity=str(user.id))
    return jsonify({
        "token":token,
        "user":user.to_dict()
    }),200
