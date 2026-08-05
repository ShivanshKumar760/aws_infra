from app import create_app

app = create_app()

if __name__ == "__main__":
    # Specify the port and allow external network connections (optional)
    app.run(host="0.0.0.0", port=5001, debug=True)
