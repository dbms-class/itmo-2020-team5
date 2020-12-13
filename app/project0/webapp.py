# encoding: UTF-8

# Веб сервер
import cherrypy

from app.project0.connect import parse_cmd_line
from app.project0.connect import create_connection
from app.project0.static import index


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
    def planets(self, planet_id=None):
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
    def drugs(self, id=None):
        with create_connection(self.args) as db:
            cur = db.cursor()
            if id is None:
                cur.execute(
                    "SELECT M.id, M.name, A.name FROM Medicine M JOIN ActiveSubstance A ON M.active_substance_id = A.id")
            else:
                cur.execute(
                    "SELECT M.id, M.name, A.name FROM Medicine M JOIN ActiveSubstance A ON M.active_substance_id = A.id WHERE M.id= %s",
                    id)
            result = []
            drugs = cur.fetchall()
            for p in drugs:
                result.append({"id": p[0], "name": p[1], "inn": p[2]})
            return result

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def pharmacies(self, id=None):
        with create_connection(self.args) as db:
            cur = db.cursor()
            if id is None:
                cur.execute("SELECT id, name, address FROM Pharmacy P")
            else:
                cur.execute("SELECT id, name, address FROM Pharmacy WHERE id= %s", id)
            pharmacies = cur.fetchall()
            result = []
            for p in pharmacies:
                result.append({"id": p[0], "name": p[1], "address": p[2]})
            return result

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def status_retail(self, drug_id=None, min_remainder=None, max_price=None):
        with create_connection(self.args) as db:
            cur = db.cursor()
            if min_remainder is None:
                min_remainder = 0
            cur.execute("""WITH MEDICINE_STATS AS (
                                SELECT medicine_id, min(cost) as min, max(cost) as max FROM assortment_pharmacy
                                GROUP BY medicine_id
                                )
                            SELECT M.id, M.name, ACS.name, P.id, P.address, A.release_packaging_count, A.cost, MSTAT.min, MSTAT.max
                            FROM assortment_pharmacy A
                            JOIN medicine M
                                on A.medicine_id = M.id
                            JOIN pharmacy P
                                on P.id = A.pharmacy_id
                            JOIN activesubstance ACS on M.active_substance_id = ACS.id
                            JOIN MEDICINE_STATS MSTAT on MSTAT.medicine_id = M.id
                            WHERE (%s is null or M.id = %s) 
                                and A.release_packaging_count >= %s 
                                and (%s is null or A.cost <= %s::money);
                            """, (drug_id, drug_id, min_remainder, max_price, max_price))
            pharmacies = cur.fetchall()
            result = []
            for p in pharmacies:
                result.append({"drug_id": p[0],
                               "drug_trade_name": p[1],
                               "drug_inn": p[2],
                               "pharmacy_id": p[3],
                               "pharmacy_address": p[4],
                               "remainder": p[5],
                               "price": p[6],
                               "min_price": p[7],
                               "max_price": p[8]})
            return result

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def drug_move(self, drug_id, min_remainder, target_income_increase):
        current_income_increase = 0.0
        min_remainder = int(min_remainder)
        target_income_increase = float(target_income_increase)
        res = []
        with create_connection(self.args) as db:
            cur = db.cursor()

            while current_income_increase <= target_income_increase:
                cur.execute("""
                    (SELECT pharmacy_id, medicine_id, release_packaging_count, cost FROM assortment_pharmacy
                    WHERE release_packaging_count > %s
                        AND medicine_id = %s
                    ORDER BY cost, release_packaging_count DESC
                    LIMIT 1)
                    UNION
                    (SELECT pharmacy_id, medicine_id, release_packaging_count, cost FROM assortment_pharmacy
                    WHERE release_packaging_count < %s
                        AND medicine_id = %s
                    ORDER BY cost DESC, release_packaging_count
                    LIMIT 1)
                """, (min_remainder, drug_id, min_remainder, drug_id))
                rows = cur.fetchall()
                if len(rows) != 2:
                    break
                pharmacy_id1, _, remainder1, cost1 = rows[0]
                pharmacy_id2, _, remainder2, cost2 = rows[1]
                remainder_diff = min(remainder1 - remainder2, remainder1 - min_remainder)
                cost1 = float(cost1.split()[0].replace(',', '.'))
                cost2 = float(cost2.split()[0].replace(',', '.'))
                cost_diff = cost2 - cost1
                if cost_diff < 0:
                    break
                cur.execute("""
                    UPDATE assortment_pharmacy
                    SET release_packaging_count = %s
                    WHERE medicine_id = %s AND pharmacy_id = %s
                """, (remainder1 - remainder_diff, drug_id, pharmacy_id1))

                cur.execute("""
                    UPDATE assortment_pharmacy
                    SET release_packaging_count = %s
                    WHERE medicine_id = %s AND pharmacy_id = %s
                """, (remainder2 + remainder_diff, pharmacy_id2, drug_id))

                current_income_increase += remainder_diff * cost_diff

                res.append({
                    'from_pharmacy_id': pharmacy_id1,
                    'to_pharmacy_id': pharmacy_id2,
                    'price_difference': cost_diff,
                    'count': remainder_diff
                })
            cur.close()
        return res


cherrypy.config.update({
    'server.socket_host': '0.0.0.0',
    'server.socket_port': 8080,
})
cherrypy.quickstart(App(parse_cmd_line()))
