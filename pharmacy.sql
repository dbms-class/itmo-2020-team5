DROP TYPE IF EXISTS Form;
DROP TABLE IF EXISTS Certificate;
DROP TABLE IF EXISTS Laboratory;
DROP TABLE IF EXISTS Supply_Medicine;
DROP TABLE IF EXISTS Medicine;
DROP TABLE IF EXISTS Supply;
DROP TABLE IF EXISTS Distributor;
DROP TABLE IF EXISTS Pharmacy;

CREATE TABLE Cars(id SERIAL PRIMARY KEY, name text NOT NULL); --TODO: Это просто заглушка к таблице машины
CREATE TABLE Medicine(id SERIAL PRIMARY KEY, name text NOT NULL); --TODO: Тоже заглушка к таблице лекарства
CREATE TABLE Pharmacy(id SERIAL PRIMARY KEY, address TEXT UNIQUE NOT NULL, number_people TEXT UNIQUE);
CREATE TABLE Warehouse(id INT PRIMARY KEY, address TEXT NOT NULL UNIQUE);
CREATE TABLE Acceptance(id_car INT REFERENCES Cars NOT NULL, id_warehouse INT REFERENCES Warehouse NOT NULL, time TIME NOT NULL, date DATE NOT NULL, surname TEXT NOT NULL, UNIQUE(time, date, surname));



CREATE TYPE Form as ENUM ('PILL', 'CAPSULE', 'AMPOULE');
CREATE TABLE Laboratory(id SERIAL PRIMARY KEY, name text NOT NULL check ( length(name) > 0 ), head_last_name text NOT NULL check ( length(head_last_name) > 0 ));
CREATE TABLE Certificate(id SERIAL PRIMARY KEY, number text NOT NULL check ( length(number) > 0 ), laboratory_id INT NOT NULL REFERENCES Laboratory);
CREATE TABLE Distributor(id SERIAL PRIMARY KEY, address text NOT NULL, bank_account_number text NOT NULL check ( length(bank_account_number) = 20 and bank_account_number like '4%' ), first_name text NOT NULL, last_name text NOT NULL, phone_number text NOT NULL check ( length(phone_number) = 12 and phone_number like '+7%' ));
CREATE TABLE Supply(id SERIAL PRIMARY KEY, pharmacy_id INT NOT NULL REFERENCES Pharmacy, distributor_id INT NOT NULL REFERENCES Distributor);
CREATE TABLE Supply_Medicine(supply_id INT NOT NULL REFERENCES Supply, medicine_id INT NOT NULL REFERENCES Medicine, PRIMARY KEY(supply_id, medicine_id), number_of_packages int NOT NULL check ( number_of_packages > 0 ), package_weight_gr float NOT NULL check ( package_weight_gr > 0 ), amount_in_a_package int NOT NULL check ( amount_in_a_package > 0 ), price_rub float NOT NULL);

INSERT INTO Laboratory (name, head_last_name) VALUES ('HELIX', 'Иванов');
INSERT INTO Certificate(number, laboratory_id) VALUES('00986-101', 1);
INSERT INTO Distributor(address, bank_account_number, first_name, last_name, phone_number) VALUES ('Улица пушкина, дом колотушкина', '40817810570000123456', 'Иван', 'Иванов', '+79142231602');
INSERT INTO Medicine(name) VALUES ('Парацетамол');
INSERT INTO Medicine(name) VALUES ('Арбидол');
INSERT INTO Pharmacy(name) VALUES('Аптека');
INSERT INTO Supply(pharmacy_id, distributor_id) VALUES (1, 1);
INSERT INTO Supply_Medicine(supply_id, medicine_id, number_of_packages, package_weight_gr, amount_in_a_package, price_rub) VALUES (1, 1, 10, 1000, 100, 20.5), (1, 2, 5, 5000, 20, 33);
