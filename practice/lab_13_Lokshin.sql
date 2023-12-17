-- 1. Создать две базы данных на одном экземпляре СУБД SQL Server 2012.

-- Первая база данных

CREATE DATABASE lab_13_first
DROP DATABASE IF EXISTS lab_13_first

-- Вторая база данных

CREATE DATABASE lab_13_second
DROP DATABASE IF EXISTS lab_13_second

-- 2. Создать в базах данных п. 1. горизонтально фрагментированные таблицы.

-- Первая база данных
USE lab_13_first
CREATE TABLE Location (
    LocationId INT PRIMARY KEY NOT NULL CHECK (LocationId < 4),
    Address NVARCHAR(256) NOT NULL,
    Name NVARCHAR(256) NOT NULL,
    Description NVARCHAR(1024) NOT NULL,
);

CREATE TRIGGER upd ON Location
AFTER UPDATE AS
    BEGIN
        IF UPDATE(LocationId)
            THROW 50002, 'can not update Location id', 1
    END
;


DROP TRIGGER IF EXISTS upd;

DROP TABLE IF EXISTS Location;

-- Вторая база данных
USE lab_13_second;
CREATE TABLE Location (
    LocationId INT PRIMARY KEY NOT NULL CHECK (LocationId >= 4),
    Address NVARCHAR(256) NOT NULL,
    Name NVARCHAR(256) NOT NULL,
    Description NVARCHAR(1024) NOT NULL,
);

CREATE TRIGGER upd ON Location
AFTER UPDATE AS
    BEGIN
        IF UPDATE(LocationId)
            THROW 50002, 'can not update Location id', 1
    END
;

DROP TRIGGER IF EXISTS upd;

DROP TABLE IF EXISTS Location;

-- 3. Создать секционированные представления,
-- обеспечивающие работу с данными таблиц (выборку, вставку, изменение, удаление).

CREATE VIEW sectionView AS
	SELECT * FROM lab_13_first.dbo.Location
	UNION ALL
	SELECT * FROM lab_13_second.dbo.Location
;

SELECT * FROM lab_13_first.dbo.Location;
SELECT * FROM lab_13_second.dbo.Location;

SELECT * FROM sectionView;

INSERT INTO sectionView(locationid, address, name, description)
VALUES
    (1, 'first 123 Main St', 'first Sample Location', 'first This is a sample location'),
    (2, 'first 456 Oak St', 'first Another Location', 'first This is another location'),
    (3, 'first 789 Pine St', 'first Yet Another Location', 'first This is yet another location'),
    (4, 'second 123 Main St', 'second Sample Location', 'second This is a sample location'),
    (5, 'second 456 Oak St', 'second Another Location', 'second This is another location'),
    (6, 'second 789 Pine St', 'second Yet Another Location', 'second This is yet another location');

UPDATE sectionView SET address = 'update first address' WHERE LocationId = '2';
UPDATE sectionView SET address = 'update second address' WHERE LocationId = '4';

DELETE FROM sectionView WHERE LocationId = '2';
DELETE FROM sectionView WHERE LocationId = '4';
