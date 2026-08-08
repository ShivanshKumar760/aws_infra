from datetime import datetime , timezone
from app import db 

class User(db.Model):
    __tablename__ = "users"
    id = db.Column(db.Integer,primary_key=True,autoincrement=True)
    email = db.Column(db.String(255),unique=True,nullable=False,index=True)
    password_hash = db.Column(db.String(255),nullable=False)
    created_at = db.Column(db.DateTime(timezone=True),default=lambda:datetime.now(timezone.utc),nullable=False)

    todos = db.relationship('Todo',backref='owner',lazy=True,cascade='all, delete-orphan')

    def to_dict(self):
        return {'id':self.id,'email':self.email}

class Todo(db.Model):
    __tablename__ = 'todos'
    id = db.Column(db.Integer,primary_key=True,autoincrement=True)
    user_id = db.Column(db.Integer,db.ForeignKey('users.id',ondelete='CASCADE'),nullable=False,index=True)
    title = db.Column(db.Text,nullable=False)
    done = db.Column(db.Boolean,nullable=False,default=False)
    created_at = db.Column(db.DateTime(timezone=True),default=lambda:datetime.now(timezone.utc),nullable=False)

    updated_at = db.Column(db.DateTime(timezone=True),default=lambda:datetime.now(timezone.utc),onupdate=lambda:datetime.now(timezone.utc),nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id':self.user_id,
            'title':self.title,
            'done':self.done,
            'created_at':self.created_at.isoformat() if self.created_at else None,
            'updated_at':self.updated_at.isoformat() if self.updated_at else None,
        }
