# init_db.py
import time
from app import create_app, db
from sqlalchemy.exc import OperationalError

app = create_app()

def wait_for_db():
    retries = 10
    while retries > 0:
        try:
            # Attempt a basic test query execution block
            db.session.execute(db.text('SELECT 1'))
            print("Database is awake and reachable! Proceeding...")
            return
        except OperationalError:
            print("PostgreSQL is still booting up... waiting 2 seconds...")
            time.sleep(2)
            retries -= 1
    raise Exception("Could not connect to the database after multiple retries.")

with app.app_context():
    print("Initializing database schema safely from a single isolated thread...")
    wait_for_db() # Wait for Postgres to accept connections
    db.create_all()
    print("Database tables verified successfully!")
