DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-- форма
CREATE TYPE Form as ENUM (
    'PILL', 'CAPSULE', 'AMPOULE'
    );

-- производитель
CREATE TABLE Manufacturer
(
    id   SERIAL PRIMARY KEY,
    name TEXT NOT NULL
);

-- лаборатории
CREATE TABLE Laboratory
(
    id             SERIAL PRIMARY KEY,
    name           text NOT NULL,
    head_last_name text NOT NULL
);

-- сертификат
-- номер, срок действия и указание на исследователькую лабораторию, проводившую испытания.
CREATE TABLE Certificate
(
    id              SERIAL PRIMARY KEY,
    laboratory_id   INT  NOT NULL REFERENCES Laboratory,
    expiration_date DATE NOT NULL
);

-- действующее вещество
CREATE TABLE ActiveSubstance
(
    id      SERIAL PRIMARY KEY,
    name    TEXT NOT NULL UNIQUE,
    formula TEXT NOT NULL
);

-- лекарства
CREATE TABLE Medicine
(
    id                  SERIAL PRIMARY KEY,
    name                TEXT NOT NULL,
    international_name  TEXT,
    informal_name       TEXT,
    manufacturer_id     INT REFERENCES Manufacturer,
    laboratory_id       INT REFERENCES Laboratory,
    medicine_form       FORM,
    certificate_id      INT REFERENCES Certificate,
    active_substance_id INT REFERENCES ActiveSubstance NOT NULL
);


-- дистрибьютор
CREATE TABLE Distributor
(
    id                  SERIAL PRIMARY KEY,
    address             TEXT NOT NULL,
    bank_account_number TEXT NOT NULL UNIQUE check ( length(bank_account_number) = 20 and bank_account_number like '4%'
) ,
  contact_first_name  TEXT NOT NULL,
  contact_last_name   TEXT NOT NULL,
  phone_number        TEXT NOT NULL UNIQUE check ( length(phone_number) = 12 and phone_number like '+7%' )
);


-- Склады
CREATE TABLE Warehouse
(
    id      SERIAL PRIMARY KEY,
    address TEXT NOT NULL UNIQUE
);

-- Поставка от дистрибьютора в склад
CREATE TABLE Supply
(
    id                          SERIAL PRIMARY KEY,
    distributor_id              INT REFERENCES Distributor, -- поставщик
    warehouse_id                INT REFERENCES Warehouse,   -- склад
    arrival_datetime            TIMESTAMP NOT NULL,
    arrival_storekeeper_surname TEXT NOT NULL
);

-- Перевозочная упаковка
CREATE TABLE ShippingBox
(
    id                      SERIAL NOT NULL PRIMARY KEY,
    medicine_id             INT    NOT NULL REFERENCES Medicine,
    package_weight_gr       FLOAT  NOT NULL check ( package_weight_gr > 0 ),       -- Вес перевозочной
    release_packaging_count INT    NOT NULL check ( release_packaging_count > 0 ), -- Количество отпускных упаковке в одной перевозочной
    price_rub               MONEY  NOT NULL                                        -- закупочная стоимость отпускной
);

-- Содержание перевозки
CREATE TABLE SuplyContent
(
    id                SERIAL PRIMARY KEY,
    supply_id         INT NOT NULL REFERENCES Supply,
    shipping_box_id    INT NOT NULL REFERENCES ShippingBox,
    shipping_box_count INT NOT NULL,
    UNIQUE(supply_id, shipping_box_id)
);


-- Аптека
CREATE TABLE Pharmacy
(
    id            SERIAL PRIMARY KEY,
    address       TEXT UNIQUE NOT NULL,
    name          TEXT UNIQUE
);

-- Ассортимент
CREATE TABLE Assortment_pharmacy
(
    pharmacy_id             INT REFERENCES Pharmacy,
    medicine_id             INT REFERENCES Medicine,
    release_packaging_count INT,                        -- остаток
    cost                    money NOT NULL,             -- check ( length(number_of_medications) >= 0 and length(cost) > 0 ),
    PRIMARY KEY (pharmacy_id, medicine_id)
);

-- Автомобили
CREATE TABLE Cars
(
    id          SERIAL PRIMARY KEY,
    maintenance DATE NOT NULL
);

-- Поставка в аптеку из склада
CREATE TABLE Transportation
(
    car_id                INT REFERENCES Cars,
    date                  DATE NOT NULL,
    warehouse_id          INT REFERENCES Warehouse,
    shipping_box_id       INT REFERENCES ShippingBox,
    medicine_id           INT REFERENCES Medicine,
    pharmacy_id           INT REFERENCES Pharmacy,
    number_of_medications INT NOT NULL check ( number_of_medications >= 0 )
);

-- Принятие поставки
CREATE TABLE Acceptance
(
    car_id       INT REFERENCES Cars,
    warehouse_id INT REFERENCES Warehouse,
    datetime     TIMESTAMP NOT NULL,
    storekeeper_last_name      TEXT NOT NULL
);

INSERT INTO ActiveSubstance(name, formula) VALUES ('Аденин', 'АААААЫФВЦ'),
                                                  ('АПРЕПИТАНТ', 'УУАУА') ,
                                                  ('ИБОПРОФЕН', 'АСС'),
                                                  ('ПЛАЦЕБО', '32'),
                                                  ('АСПАРАГИНАЗА', '123');
INSERT INTO Laboratory (name, head_last_name) VALUES ('HELIX', 'Иванов');
INSERT INTO Certificate(laboratory_id, expiration_date) VALUES(1, '20-12-2022');
INSERT INTO Distributor(address, bank_account_number, contact_first_name, contact_last_name, phone_number) VALUES ('Улица пушкина, дом колотушкина', '40817810570000123456', 'Иван', 'Иванов', '+79142231602');
INSERT INTO Medicine(name, active_substance_id) VALUES ('Парацетамол', 1),
                                                        ('Арбидол', 2);
INSERT INTO Pharmacy(address, name) VALUES('Аптека', 'Аптека за углом №7');
INSERT INTO Pharmacy(address, name) VALUES('Аптека2', 'Аптека за углом №14');
INSERT INTO Warehouse(address) VALUES ('Улица пушкина 1');
INSERT INTO Supply(distributor_id, warehouse_id, arrival_datetime, arrival_storekeeper_surname) VALUES (1, 1, '20-11-2020 20:30', 'Иванов');

INSERT INTO Assortment_pharmacy(pharmacy_id, medicine_id, release_packaging_count, cost) VALUES (1, 1, 100, 10),
                                                                                                (1, 2, 22, 66),
                                                                                                (2, 1, 25, 50);