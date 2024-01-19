from . import profile, matches

from .app import app

def run():
    app.run('0.0.0.0', 80, debug=True)
