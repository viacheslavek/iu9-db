-- Из 6 лабораторной
USE master;
-- Создать таблицу с первичным ключом на основе глобального уникального идентификатора.

CREATE TABLE Location (
    LocationId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Address NVARCHAR(256),
    Name NVARCHAR(256),
    Description NVARCHAR(1024),
);

INSERT INTO Location (Address, Name, Description)
VALUES ('123 Main St', 'Sample Location', 'This is a sample location');
INSERT INTO Location (Address, Name, Description)
VALUES ('456 Oak St', 'Another Location', 'This is another location');
INSERT INTO Location (Address, Name, Description)
VALUES ('789 Pine St', 'Yet Another Location', 'This is yet another location');

DROP TABLE IF EXISTS Location;

CREATE TABLE Meeting (
    meetingId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    MeetingDate DATE,
    Location UNIQUEIDENTIFIER FOREIGN KEY REFERENCES Location(LocationId),
    Agreement BIT,
    FirstRatingStats SMALLINT,
    SecondRatingStats SMALLINT
);

INSERT INTO Meeting (MeetingDate, Location, Agreement, FirstRatingStats, SecondRatingStats)
VALUES ('2023-11-15', 'A713596D-F3B0-40A5-A86E-1F4F36877B08', 1, 5, 4);
INSERT INTO Meeting (MeetingDate, Location, Agreement, FirstRatingStats, SecondRatingStats)
VALUES ('2023-11-16', '58DF69F5-AAF8-4559-A475-31E6877F2554', 0, 3, 5);
INSERT INTO Meeting (MeetingDate, Location, Agreement, FirstRatingStats, SecondRatingStats)
VALUES ('2023-11-17', '91891353-57B8-4EF6-BCD9-5D888D541A00', 1, 4, 4);


DROP TABLE IF EXISTS Meeting;

-- Создание представления для одной из таблиц - для Location

CREATE VIEW LocationView AS
SELECT LocationId, Address, Name, Description
FROM Location;

DROP VIEW IF EXISTS LocationView;

-- Создание представления на основе полей связанных таблиц

CREATE VIEW CombinedView AS
SELECT
    L.LocationId,
    L.Address,
    L.Name AS LocationName,
    L.Description AS LocationDescription,
    M.meetingId,
    M.MeetingDate,
    M.Location AS MeetingLocation,
    M.Agreement,
    M.FirstRatingStats,
    M.SecondRatingStats
FROM
    Location L
JOIN
    Meeting M ON L.LocationId = M.Location;

DROP VIEW IF EXISTS CombinedView;

-- Индекс для Location с дополнительными неключевыми полями

CREATE INDEX Location_Address_Index
ON Location (Address)
INCLUDE (Name, Description);

DROP INDEX IF EXISTS Location_Address_Index
ON Location;

-- Посмотреть на индекс

SELECT *
FROM sys.indexes
WHERE object_id IN (
    SELECT object_id
    FROM sys.objects
    WHERE name = 'Location'
);

-- Создание индексированного представления для таблицы Location
CREATE VIEW dbo.IndexedLocationView
WITH SCHEMABINDING
AS
SELECT
    LocationId,
    Address,
    Name,
    Description
FROM dbo.Location;

DROP VIEW IF EXISTS dbo.IndexedLocationView;

-- Создание уникального кластеризованного индекса для индексированного представления
CREATE UNIQUE CLUSTERED INDEX IndexedLocationView_Address
ON dbo.IndexedLocationView(LocationId); -- можно и address, но он у меня пока не уникальный

DROP INDEX IF EXISTS IndexedLocationView_Address
ON  dbo.IndexedLocationView;
