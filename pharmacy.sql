DROP TYPE IF EXISTS Form;
DROP TABLE IF EXISTS Certificate;
DROP TABLE IF EXISTS Laboratory;
DROP TABLE IF EXISTS SupplyMedicine;
DROP TABLE IF EXISTS Medicine;
DROP TABLE IF EXISTS Supply;
DROP TABLE IF EXISTS Distributor;
DROP TABLE IF EXISTS Pharmacy;


-- форма
CREATE TYPE Form as ENUM (
  'PILL', 'CAPSULE', 'AMPOULE'
);

-- лекарства
CREATE TABLE Medicine(
  id                  SERIAL PRIMARY KEY, 
  name                TEXT NOT NULL,
  international_name  TEXT,
  informal_name       TEXT,
  manufacturer_id     INT REFERENCES Manufacturer,
  laboratory_id       INT REFERENCES Laboratory,
  medicine_form       FORM,
  certificate_id      INT REFERENCES Certificate,
  active_substance_id INT REFERENCES ActiveSubstance
);

-- производитель
CREATE TABLE Manufacturer(
  id                 SERIAL PRIMARY KEY, 
  name               TEXT NOT NULL
);

-- действующее вещество
CREATE TABLE ActiveSubstance(
  id      SERIAL PRIMARY KEY, 
  name    TEXT NOT NULL,
  formula TEXT NOT NULL
);

-- сертификат
-- номер, срок действия и указание на исследователькую лабораторию, проводившую испытания.
CREATE TABLE Certificate(
  id              INT PRIMARY KEY, 
  laboratory_id   INT NOT NULL REFERENCES Laboratory,
  expiration_date DATE NOT NULL
);

-- лаборатории
CREATE TABLE Laboratory(
  id              SERIAL PRIMARY KEY, 
  name            text NOT NULL,
  head_last_name  text NOT NULL
);

-- дистрибьютор
CREATE TABLE Distributor(
  id                  INT SERIAL PRIMARY KEY, 
  address             TEXT NOT NULL, 
  bank_account_number TEXT NOT NULL check ( length(bank_account_number) = 20 and bank_account_number like '4%' ), 
  contact_first_name  TEXT NOT NULL, 
  contact_last_name   TEXT NOT NULL, 
  phone_number        TEXT NOT NULL check ( length(phone_number) = 12 and phone_number like '+7%' )
);

-- Перевозочная упаковка
CREATE TABLE ShippingBox(
  id                      INT SERIAL NOT NULL PRIMARY KEY,
  medicine_id             INT NOT NULL REFERENCES Medicine, 
  package_weight_gr       FLOAT NOT NULL check ( package_weight_gr > 0 ), -- Вес перевозочной
  release_packaging_count INT NOT NULL check ( amount_in_a_package > 0 ), -- Количество отпускных упаковке в одной перевозочной
  price_rub               FLOAT NOT NULL -- закупочная стоимость отпускной
);

-- Склады
CREATE TABLE Warehouse(
  id      INT PRIMARY KEY, 
  address TEXT NOT NULL UNIQUE
);

-- Поставка
CREATE TABLE Supply(
  id                          SERIAL PRIMARY KEY, 
--  pharmacy_id    INT NOT NULL REFERENCES Pharmacy,
  distributor_id              INT REFERENCES Distributor -- склад 
  warehouse_id                INT REFERENCES Warehouse,
  arrival_time                TIME NOT NULL, 
  arrival_date                DATE NOT NULL, 
  arrival_storekeeper_surname TEXT NOT NULL,
);

-- Содержание перевозки
CREATE TABLE SuplyContent(
  id                INT SERIAL PRIMARY KEY,
  supply_id         INT NOT NULL REFERENCES Supply, 
  shippingbox_id    INT NOT NULL REFERENCES ShippingBox,
  shippingBox_count INT NOT NULL 
);

-- Аптека
CREATE TABLE Pharmacy(
  id            SERIAL PRIMARY KEY, 
  address       TEXT UNIQUE NOT NULL, 
  number_people TEXT UNIQUE
);

-- Ассортимент
CREATE TABLE Assortment_pharmacy(
  pharmacy_id             INT REFERENCES  Pharmacy, 
  medicine_id             INT REFERENCES Medicine,
  release_packaging_count INT, 
  cost                    FLOAT NOT NULL check ( length(number_of_medications) >= 0 and length(cost) > 0 )
);

-- Закончили здесь --

-- Автомобили
CREATE TABLE Cars(
  id SERIAL   PRIMARY KEY, 
  maintenance DATE NOT NULL
);


CREATE TABLE Transportation(
  id                    SERIAL REFERENCES Cars, 
  date                  DATE, 
  warehouse_id          INT Warehouse REFERENCES Warehouse,
  number_of_medications INT NOT NULL check ( length(number_of_medications) >= 0 )
);



-- Принятие поставки
CREATE TABLE Acceptance(
  car_id        INT REFERENCES Cars, 
  warehouse_id  INT REFERENCES Warehouse, 
  time          TIME NOT NULL, 
  date          DATE NOT NULL, 
  surname       TEXT NOT NULL, 
  UNIQUE(time, date, surname)
);

-- Поставки





INSERT INTO Laboratory (name, head_last_name) VALUES ('HELIX', 'Иванов');
INSERT INTO Certificate(number, laboratory_id) VALUES('00986-101', 1);
INSERT INTO Distributor(address, bank_account_number, first_name, last_name, phone_number) VALUES ('Улица пушкина, дом колотушкина', '40817810570000123456', 'Иван', 'Иванов', '+79142231602');
INSERT INTO Medicine(name) VALUES ('Парацетамол');
INSERT INTO Medicine(name) VALUES ('Арбидол');
INSERT INTO Pharmacy(name) VALUES('Аптека');
INSERT INTO Supply(pharmacy_id, distributor_id) VALUES (1, 1);
INSERT INTO ShippingBox(supply_id, medicine_id, number_of_packages, package_weight_gr, amount_in_a_package, price_rub) VALUES (1, 1, 10, 1000, 100, 20.5), (1, 2, 5, 5000, 20, 33);
