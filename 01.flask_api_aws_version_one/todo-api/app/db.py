import sqlite3
import os

DB_PATH = os.environ.get("DB_PATH","/home/ec2-user/todo-api/todos.db")

def get_conn():
    conn = sqlite3.connect(DB_PATH,check_same_thread=False)
    conn.row_factory=sqlite3.Row
    return conn

def init_db():
    conn = get_conn()
    conn.executescript(
        """
        CREATE TABLE IF NOT EXISTS users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT(datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS todos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            title TEXT NOT NULL,
            done INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL DEFAULT (datetime('now')),
            updated_at TEXT NOT NULL DEFAULT (datetime('now'))
        );
        """
    )
    conn.commit()
    conn.close()


def get_user_by_email(email:str):
    conn = get_conn()
    try:
        row = conn.execute(
            "SELECT id,email,password_hash FROM users WHERE email = ?;",(email,)
        ).fetchone()
        return dict(row) if row else None
    finally:
        conn.close()


def create_user(email,password_hash):
    conn = get_conn()
    try:
        conn.execute("INSERT INTO users (email,password_hash) VALUES (?,?);",(email,password_hash))
        conn.commit()
        return get_user_by_email(email)
    finally:
        conn.close()

def get_todos(user_id):
    conn = get_conn()
    try:
        rows = conn.execute(
            """
            SELECT id,title,done,created_at,updated_at FROM todos WHERE 
            user_id = ? ORDER BY id DESC;
            """,(user_id,)
        ).fetchall()
        return [dict(r) for r in rows]
    finally:
        conn.close()


def get_todo(todo_id,user_id):
    conn = get_conn()
    try:
        row = conn.execute(
            """
            SELECT id,title,done,created_at,updated_at FROM todos
            WHERE id = ? AND user_id = ?;
            """,(todo_id,user_id)
        ).fetchone()
        return dict(row) if row else None
    finally:
        conn.close()

def create_todo(user_id,title):
    conn = get_conn()
    try:
        cur = conn.execute(
            """
            INSERT INTO todos (user_id,title) VALUES (?,?);
            """,(user_id,title)
        )
        conn.commit()
        return get_todo(cur.lastrowid,user_id)
    finally:
        conn.close()

def update_todo(todo_id,user_id,title=None,done=None):
    todo = get_todo(todo_id,user_id)
    if not todo:
        return None
    fields,values=[],[]
    if title is not None:
        fields.append("title = ?"); values.append(title)
    if done is not None:
        fields.append("done = ?"); values.append(1 if done else 0)
    if not fields:
        return todo
    fields.append("updated_at = datetime('now')")
    values.append([todo_id,user_id])
    conn = get_conn()
    try:
        conn.execute(
            f"UPDATE todos SET {', '.join(fields)} WHERE id = ? AND user_id = ?;",
            values
        )
        conn.commit()
        return get_todo(todo_id,user_id)
    finally:
        conn.close()


def delete_todo(todo_id,user_id):
    conn = get_conn()
    try:
        cur = conn.execute(
            "DELETE FROM todos WHERE id = ? AND user_id = ?;",(todo_id,user_id)
        )
        conn.commit()
        return cur.rowcount > 0
    finally:
        conn.close()