# encoding: UTF-8

# Веб сервер
import cherrypy

from project.connect import parse_cmd_line
from project.connect import create_connection


@cherrypy.expose
class App(object):
    def __init__(self, args):
        self.args = args

    @cherrypy.expose
    def index(self):
        return "hello"

    @cherrypy.expose
    def update_retail(self, drug_id: int, pharmacy_id: int, remainder: int, price: int):
        with create_connection(self.args) as db:
            cur = db.cursor()
            cur.execute(f"INSERT INTO pharmacy.public.assortment_pharmacy "
                        f"(pharmacy_id, medicine_id, release_packaging_count, cost) "
                        f"VALUES ({pharmacy_id}, {drug_id}, {remainder}, {price}) "
                        f"ON CONFLICT (pharmacy_id, medicine_id) DO UPDATE "
                        f"SET release_packaging_count = {remainder}, cost= {price}")
        return "ok"

    @cherrypy.expose
    @cherrypy.tools.json_out()
    def drugs(self, id=None):
        with create_connection(self.args) as db:
            cur = db.cursor()
            if id is None:
                cur.execute(
                    f"SELECT M.id, M.name, A.name FROM Medicine M "
                    f"JOIN ActiveSubstance A ON M.active_substance_id = A.id")
            else:
                cur.execute(
                    f"SELECT M.id, M.name, A.name FROM Medicine M "
                    f"JOIN ActiveSubstance A ON M.active_substance_id = A.id WHERE M.id= {id}")
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
                cur.execute(f"SELECT id, name, address FROM Pharmacy WHERE id={id}")
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
            if max_price is None:
                max_price = str(10e10)
            if drug_id is None:
                cur.execute(f"""WITH MEDICINE_STATS AS (
                            SELECT medicine_id, min(cost) as min, max(cost) as max FROM assortment_pharmacy
                            GROUP BY medicine_id
                            )
                        SELECT M.id, M.name, ACS.name, P.id, P.address, A.release_packaging_count, A.cost, 
                                  MSTAT.min, MSTAT.max
                        FROM assortment_pharmacy A
                        JOIN medicine M
                            on A.medicine_id = M.id
                        JOIN pharmacy P
                            on P.id = A.pharmacy_id
                        JOIN activesubstance ACS on M.active_substance_id = ACS.id
                        JOIN MEDICINE_STATS MSTAT on MSTAT.medicine_id = M.id
                        WHERE A.release_packaging_count >= {min_remainder} 
                            and A.cost <= {max_price}::money;
                        """)
            else:
                cur.execute(f"""WITH MEDICINE_STATS AS (
                                    SELECT medicine_id, min(cost) as min, max(cost) as max FROM assortment_pharmacy
                                    GROUP BY medicine_id
                                    )
                                SELECT M.id, M.name, ACS.name, P.id, P.address, A.release_packaging_count, A.cost, 
                                          MSTAT.min, MSTAT.max
                                FROM assortment_pharmacy A
                                JOIN medicine M
                                    on A.medicine_id = M.id
                                JOIN pharmacy P
                                    on P.id = A.pharmacy_id
                                JOIN activesubstance ACS on M.active_substance_id = ACS.id
                                JOIN MEDICINE_STATS MSTAT on MSTAT.medicine_id = M.id
                                WHERE (%s is null or M.id = {drug_id}) 
                                    and A.release_packaging_count >= {min_remainder} 
                                    and A.cost <= {max_price}::money;
                                """)
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
                cur.execute(f"""
                        (SELECT pharmacy_id, medicine_id, release_packaging_count, cost FROM assortment_pharmacy
                        WHERE release_packaging_count > {min_remainder}
                        AND medicine_id = {drug_id}
                        ORDER BY cost, release_packaging_count DESC
                        LIMIT 1)
                        UNION
                        (SELECT pharmacy_id, medicine_id, release_packaging_count, cost FROM assortment_pharmacy
                        WHERE release_packaging_count < {min_remainder}
                        AND medicine_id = {drug_id}
                        ORDER BY cost DESC, release_packaging_count
                        LIMIT 1)
                        """)
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
                cur.execute(f"""
                        UPDATE assortment_pharmacy
                        SET release_packaging_count = {remainder1 - remainder_diff}
                        WHERE medicine_id = {drug_id} AND pharmacy_id = {pharmacy_id1}
                        """)

                cur.execute(f"""
                        UPDATE assortment_pharmacy
                        SET release_packaging_count = {remainder2 + remainder_diff}
                        WHERE medicine_id = {pharmacy_id2} AND pharmacy_id = {drug_id}
                        """)

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
