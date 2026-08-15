from flask import Blueprint,request,jsonify
from flask_jwt_extended import jwt_required , get_jwt_identity
# from app.temp.db import get_todos,get_todo,create_todo,update_todo,delete_todo
from app import db
from app.models import Todo

todos_bp = Blueprint("todos",__name__)

@todos_bp.get("/todos")
@jwt_required()
def list_todos():
    user_id = get_jwt_identity()
    todos = Todo.query.filter_by(user_id=user_id).order_by(Todo.id.desc()).all()
    return jsonify({"todos":[t.to_dict() for t in todos]}),200

@todos_bp.post("/todos")
@jwt_required()
def create():
    user_id = get_jwt_identity()
    data = request.get_json(silent=True) or {}
    title = data.get("title","").strip()
    if not title:
        return jsonify({"error":"title required"}),400
    todo = Todo(user_id=user_id,title=title)
    db.session.add(todo)
    db.session.commit()
    return jsonify({
        "todo":todo.to_dict()
    }),201

@todos_bp.put("/todos/<int:tid>")
@jwt_required()
def update(tid):
    user_id = get_jwt_identity()
    todo = Todo.query.filter_by(id=tid,user_id=user_id).first()
    if not todo:
        return jsonify({"error":"Not found"}),404

    data = request.get_json(silent=True) or {}
    title = data.get('title')
    done = data.get('done')
    if title is not None: todo.title = title
    if done is not None: todo.done = bool(done)
    db.session.commit()
    return jsonify({"todo":todo.to_dict()}),200

@todos_bp.delete("/todos/<int:tid>")
@jwt_required()
def remove(tid):
    user_id = get_jwt_identity()
    todo = Todo.query.filter_by(id=tid,user_id=user_id).first()
    if not todo:
        return jsonify({"error":"Not found"}),404
    db.session.delete(todo)
    db.session.commit()
    return jsonify({"message":f"todo {tid} deleted"}),200