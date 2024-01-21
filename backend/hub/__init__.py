import os
import time
from threading import Thread

from common import Context, init_db

from .app import app
from .matches import do_matchmaking, manage_matches

def run():
    if os.environ.get('SERVICE') == 'api':
        app.run('0.0.0.0', 3000, debug=True)
    else:
        run_background()

def run_background():
    ctx = Context.create()

    init_db(ctx)

    print('boot background worker')
    while True:
        time.sleep(2.0)

        do_matchmaking(ctx)
        manage_matches(ctx)
