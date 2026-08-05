import bcrypt
from flask import Blueprint,request,jsonify
from flask_jwt_extended import create_access_token
from app.db import get_user_by_email,create_user

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
    if get_user_by_email(email):
        return jsonify({"error":"email already registered"}),409

    pw_hash = bcrypt.hashpw(password.encode(),bcrypt.gensalt(rounds=12)).decode()
    user = create_user(email,pw_hash)

    return jsonify({
        "message":"registered",
        "user":{"id":user["id"] , "email":user["email"]}
    }),201

@auth_bp.post("/auth/login")
def login():
    data = request.get_json(silent=True) or {}
    email = data.get("email","").strip().lower()
    password= data.get("password","")

    if not email or not password:
        return jsonify({"error":"email and password required"}),400
    user = get_user_by_email(email)

    if not user or not bcrypt.checkpw(password.encode(),user["password_hash"].encode()):
        return jsonify({"error":"invalid email or password"}),401

    token = create_access_token(identity=str(user["id"])) # <-- FIX: Wrap in str()
    return jsonify({
        "token":token,
        "user":{
            "id":user["id"],
            "email":user["email"]
        }
    }),200
