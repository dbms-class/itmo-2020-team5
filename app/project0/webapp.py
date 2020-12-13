# encoding: UTF-8

# Веб сервер
import cherrypy

from connect import parse_cmd_line
from connect import create_connection
from static import index


@cherrypy.expose
class App(object):
    def __init__(self, args):
        self.args = args

    @cherrypy.expose
    def start(self):
        return "Hello web app"

    @cherrypy.expose
    def index(self):
        return index()

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def planets(self, planet_id = None):
        with create_connection(self.args) as db:
            cur = db.cursor()
            if planet_id is None:
                cur.execute("SELECT id, name FROM Planet P")
            else:
                cur.execute("SELECT id, name FROM Planet WHERE id= %s", planet_id)
            result = []
            planets = cur.fetchall()
            for p in planets:
                result.append({"id": p[0], "name": p[1]})
            return result

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def commanders(self):
        with create_connection(self.args) as db:
            cur = db.cursor()
            cur.execute("SELECT id, name FROM Commander")
            result = []
            commanders = cur.fetchall()
            for c in commanders:
                result.append({"id": c[0], "name": c[1]})
            return result

    @cherrypy.expose
    def update_retail(self, drug_id: int, pharmacy_id: int, remainder: int, price: int):
        with create_connection(self.args) as db:
            cur = db.cursor()
            cur.execute("INSERT INTO pharmacy.public.assortment_pharmacy "
                        "(pharmacy_id, medicine_id, release_packaging_count, cost) "
                        "VALUES (%s, %s, %s, %s) ON CONFLICT (pharmacy_id, medicine_id) DO UPDATE "
                        "SET release_packaging_count = %s, cost= %s",
                        (pharmacy_id, drug_id, remainder, price, remainder, price))
            return "ok"

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def drugs(self, id = None):
        with create_connection(self.args) as db:
            cur = db.cursor()
            if id is None:
                cur.execute("SELECT id, name, active_substance_id FROM Medicine M")
            else:
                cur.execute("SELECT id, name, active_substance_id FROM Medicine WHERE id= %s", id)
            result = []
            drugs = cur.fetchall()
            for p in drugs:
                result.append({"id": p[0], "name": p[1], "inn": p[2]})
            return result

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def pharmacies(self, id = None):
        with create_connection(self.args) as db:
            cur = db.cursor()
            if id is None:
                cur.execute("SELECT id, name, address FROM Pharmacy P")
            else:
                cur.execute("SELECT id, name, address FROM Pharmacy WHERE id= %s", id)
            pharmacies = []
            pharmacies = cur.fetchall()
            for p in pharmacies:
                result.append({"id": p[0], "name": p[1], "address": p[2]})
            return result


cherrypy.config.update({
  'server.socket_host': '0.0.0.0',
  'server.socket_port': 8080,
})
cherrypy.quickstart(App(parse_cmd_line()))

