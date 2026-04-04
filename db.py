import os
from pathlib import Path

import mariadb
from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parent
ENV_PATH = BASE_DIR / ".env"

load_dotenv(dotenv_path=ENV_PATH, override=True)


def _config_value(name, default):
    value = os.getenv(name)
    if value is None or value == "":
        return default
    return value


def _db_host():
    host = _config_value("DB_HOST", "localhost")
    if host == "127.0.0.1":
        return "localhost"
    return host


def get_connection():
    return mariadb.connect(
        host=_db_host(),
        port=int(_config_value("DB_PORT", "3306")),
        user=_config_value("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=_config_value("DB_NAME", "helpdesk"),
    )


def fetch_all(query, params=None):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(query, params or ())
        return cursor.fetchall()
    finally:
        cursor.close()
        conn.close()


def fetch_one(query, params=None):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(query, params or ())
        return cursor.fetchone()
    finally:
        cursor.close()
        conn.close()


def execute_query(query, params=None):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(query, params or ())
        conn.commit()
        return cursor.lastrowid
    finally:
        cursor.close()
        conn.close()
