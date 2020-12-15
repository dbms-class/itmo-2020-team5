# encoding: UTF-8

import argparse

# Драйвер PostgreSQL
# Находится в модуле psycopg2-binary, который можно установить командой
# pip install psycopg2-binary или её аналогом.
import psycopg2 as pg_driver


# Разбирает аргументы командной строки.
# Выплевывает структуру с полями, соответствующими каждому аргументу.
def parse_cmd_line():
    parser = argparse.ArgumentParser(description='Эта программа вычисляет 2+2 при помощи реляционной СУБД')
    parser.add_argument('--pg-host', help='PostgreSQL host name', default='localhost')
    parser.add_argument('--pg-port', help='PostgreSQL port', default=5432)
    parser.add_argument('--pg-user', help='PostgreSQL user', default='postgres')
    parser.add_argument('--pg-password', help='PostgreSQL password', default='iziparol')
    parser.add_argument('--pg-database', help='PostgreSQL database', default='pharmacy')
    return parser.parse_args()


# Создаёт подключение к постгресу в соответствии с аргументами командной строки.
def create_connection_pg(args):
    return pg_driver.connect(user=args.pg_user, password=args.pg_password, host=args.pg_host, port=args.pg_port, database=args.pg_database)


# Создаёт подключение в соответствии с аргументами командной строки.
# Если указан аргумент --sqlite-file то создается подключение к SQLite,
# в противном случае создаётся подключение к PostgreSQL
def create_connection(args) -> pg_driver._psycopg.connection:
    return create_connection_pg(args)



