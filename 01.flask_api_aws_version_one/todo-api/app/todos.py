from flask import Blueprint,request,jsonify
from flask_jwt_extended import jwt_required , get_jwt_identity
from app.db import get_todos,get_todo,create_todo,update_todo,delete_todo


todos_bp = Blueprint("todos",__name__)

@todos_bp.get("/todos")
@jwt_required()
def list_todos():
    return jsonify({"todos":get_todos(get_jwt_identity())}),200

@todos_bp.post("/todos")
@jwt_required()
def create():
    data = request.get_json(silent=True) or {}
    title = data.get("title","").strip()
    if not title:
        return jsonify({"error":"title required"}),400
    return jsonify({
        "todo":create_todo(get_jwt_identity(),title)
    }),201

@todos_bp.put("/todos/<int:tid>")
@jwt_required()
def update(tid):
    data = request.get_json(silent=True) or {}
    updated = update_todo(tid,get_jwt_identity(),data.get("title"),data.get("done"))
    if not updated:
        return jsonify({"error":"not found"}),404
    return jsonify({"todo":updated}),200

@todos_bp.delete("/todos/<int:tid>")
@jwt_required()
def remove(tid):
    if not delete_todo(tid,get_jwt_identity()):
        return jsonify({"error":"Not found"}),404
    return jsonify({"message":f"todo {tid} deleted"}),200