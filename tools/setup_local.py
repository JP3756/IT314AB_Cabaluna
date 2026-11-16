"""Create the local dev database and app user, and save LOCAL_DATABASE_URL to .env.
Safe to run twice. Never prints passwords."""
import re
import secrets
import psycopg
from psycopg import sql

DB, USER = "enrollment_local", "enrollment_dev"


def env():
    d = {}
    for l in open(".env", encoding="utf-8-sig"):
        if "=" in l and not l.startswith("#"):
            k, v = l.rstrip("\r\n").split("=", 1)
            d[k] = v
    return d


cfg = env()
admin_pw = cfg["LOCAL_ADMIN_PASSWORD"]
try:
    admin = psycopg.connect(host="localhost", port=5432, user="postgres", password=admin_pw,
                            dbname="postgres", autocommit=True, connect_timeout=8)
except psycopg.Error as e:
    raise SystemExit("ADMIN LOGIN FAILED: " + str(e).strip().splitlines()[0])

cur = admin.cursor()
dev_pw = None
cur.execute("select 1 from pg_roles where rolname=%s", (USER,))
if cur.fetchone():
    print("role exists")
else:
    dev_pw = secrets.token_urlsafe(18)
    cur.execute(sql.SQL("create role {} login password {}").format(sql.Identifier(USER), sql.Literal(dev_pw)))
    print("role created")
cur.execute("select 1 from pg_database where datname=%s", (DB,))
if cur.fetchone():
    print("database exists")
else:
    cur.execute(sql.SQL("create database {} owner {}").format(sql.Identifier(DB), sql.Identifier(USER)))
    print("database created")
admin.close()

if dev_pw and "LOCAL_DATABASE_URL" not in cfg:
    with open(".env", "a", encoding="ascii") as f:
        f.write("\nLOCAL_DATABASE_URL=postgresql://%s:%s@localhost:5432/%s\n" % (USER, dev_pw, DB))
    print("LOCAL_DATABASE_URL saved to .env")
elif "LOCAL_DATABASE_URL" in cfg:
    print("LOCAL_DATABASE_URL already in .env")
else:
    print("WARNING: role existed but no LOCAL_DATABASE_URL in .env; reset the role password manually")
