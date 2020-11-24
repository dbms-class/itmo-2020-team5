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
    name    TEXT NOT NULL,
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
    active_substance_id INT REFERENCES ActiveSubstance
);


-- дистрибьютор
CREATE TABLE Distributor
(
    id                  SERIAL PRIMARY KEY,
    address             TEXT NOT NULL,
    bank_account_number TEXT NOT NULL check ( length(bank_account_number) = 20 and bank_account_number like '4%'
) ,
  contact_first_name  TEXT NOT NULL,
  contact_last_name   TEXT NOT NULL,
  phone_number        TEXT NOT NULL check ( length(phone_number) = 12 and phone_number like '+7%' )
);


-- Склады
CREATE TABLE Warehouse
(
    id      SERIAL PRIMARY KEY,
    address TEXT NOT NULL UNIQUE
);

-- Поставка
CREATE TABLE Supply
(
    id                          SERIAL PRIMARY KEY,
--  pharmacy_id    INT NOT NULL REFERENCES Pharmacy,
    distributor_id              INT REFERENCES Distributor, -- склад
    warehouse_id                INT REFERENCES Warehouse,
    arrival_time                TIME NOT NULL,
    arrival_date                DATE NOT NULL,
    arrival_storekeeper_surname TEXT NOT NULL
);

-- Перевозочная упаковка
CREATE TABLE ShippingBox
(
    id                      SERIAL NOT NULL PRIMARY KEY,
    medicine_id             INT    NOT NULL REFERENCES Medicine,
    package_weight_gr       FLOAT  NOT NULL check ( package_weight_gr > 0 ),       -- Вес перевозочной
    release_packaging_count INT    NOT NULL check ( release_packaging_count > 0 ), -- Количество отпускных упаковке в одной перевозочной
    price_rub               FLOAT  NOT NULL                                        -- закупочная стоимость отпускной
);

-- Содержание перевозки
CREATE TABLE SuplyContent
(
    id                SERIAL PRIMARY KEY,
    supply_id         INT NOT NULL REFERENCES Supply,
    shippingbox_id    INT NOT NULL REFERENCES ShippingBox,
    shippingBox_count INT NOT NULL
);

-- Аптека
CREATE TABLE Pharmacy
(
    id            SERIAL PRIMARY KEY,
    address       TEXT UNIQUE NOT NULL,
    number_people TEXT UNIQUE
);

-- Ассортимент
CREATE TABLE Assortment_pharmacy
(
    pharmacy_id             INT REFERENCES Pharmacy,
    medicine_id             INT REFERENCES Medicine,
    release_packaging_count INT,
    cost                    money NOT NULL, --check ( length(number_of_medications) >= 0 and length(cost) > 0 ),
    PRIMARY KEY (pharmacy_id, medicine_id)
);

-- Закончили здесь --

-- Автомобили
CREATE TABLE Cars
(
    id          SERIAL PRIMARY KEY,
    maintenance DATE NOT NULL
);


CREATE TABLE Transportation
(
    id                    SERIAL REFERENCES Cars,
    date                  DATE,
    warehouse_id          INT REFERENCES Warehouse,
    number_of_medications INT NOT NULL check ( number_of_medications >= 0 )
);


-- Принятие поставки
CREATE TABLE Acceptance
(
    car_id       INT REFERENCES Cars,
    warehouse_id INT REFERENCES Warehouse,
    time         TIME NOT NULL,
    date         DATE NOT NULL,
    surname      TEXT NOT NULL,
    UNIQUE (time, date, surname)
);

-- Поставки


INSERT INTO Laboratory (name, head_last_name) VALUES ('HELIX', 'Иванов');
INSERT INTO Certificate(laboratory_id, expiration_date) VALUES(1, '20-12-2022');
INSERT INTO Distributor(address, bank_account_number, contact_first_name, contact_last_name, phone_number) VALUES ('Улица пушкина, дом колотушкина', '40817810570000123456', 'Иван', 'Иванов', '+79142231602');
INSERT INTO Medicine(name) VALUES ('Парацетамол');
INSERT INTO Medicine(name) VALUES ('Арбидол');
INSERT INTO Pharmacy(address, number_people) VALUES('Аптека', '?');
INSERT INTO Warehouse(address) VALUES ('Улица пушкина 1');
INSERT INTO Supply(distributor_id, warehouse_id, arrival_date, arrival_time, arrival_storekeeper_surname) VALUES (1, 1, '20-11-2020', '20:30', 'Иванов');