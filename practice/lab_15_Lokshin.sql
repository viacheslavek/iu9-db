-- 1. Создать в базах данных пункта 1 задания 13 связанные таблицы.
-- Первая база данных

USE lab_13_first

CREATE TABLE LocationDistributed(
    LocationId INT PRIMARY KEY,
    Address NVARCHAR(256) NOT NULL,
    Name NVARCHAR(256) NOT NULL,
    Description NVARCHAR(1024) NOT NULL,
);

INSERT INTO LocationDistributed(LocationId, Address, Name, Description)
VALUES (1, '123 Main St', 'Sample Location', 'This is a sample location');
INSERT INTO LocationDistributed(LocationId, Address, Name, Description)
VALUES (2, '456 Oak St', 'Another Location', 'This is another location');
INSERT INTO LocationDistributed(LocationId, Address, Name, Description)
VALUES (3, '789 Pine St', 'Yet Another Location', 'This is yet another location');

DROP TABLE IF EXISTS LocationDistributed;

-- Вторая база данных

USE lab_13_second

CREATE TABLE MeetingDistributed(
    MeetingId INT PRIMARY KEY,
    MeetingDate DATE NOT NULL,
    Location INT NOT NULL,
    Agreement BIT NOT NULL,
    FirstRatingStats SMALLINT,
    SecondRatingStats SMALLINT,
);

INSERT INTO MeetingDistributed(MeetingId, MeetingDate, Location, Agreement, FirstRatingStats, SecondRatingStats)
VALUES (1, '2023-11-15', 1, 1, 5, 4);
INSERT INTO MeetingDistributed(MeetingId, MeetingDate, Location, Agreement, FirstRatingStats, SecondRatingStats)
VALUES (2, '2023-11-16', 2, 0, 3, 5);
INSERT INTO MeetingDistributed(MeetingId, MeetingDate, Location, Agreement, FirstRatingStats, SecondRatingStats)
VALUES (3, '2023-11-17', 3, 1, 4, 4);

DROP TABLE IF EXISTS MeetingDistributed;

-- 2. Создать необходимые элементы базы данных (представления, триггеры),
-- обеспечивающие работу с данными связанных таблиц (выборку, вставку, изменение, удаление).
USE lab_13_first

CREATE VIEW MeetingView AS
	SELECT ld.LocationId, ld.Address, ld.Name AS LocationName, ld.Description AS LocationDescription,
    md.meetingId, md.MeetingDate, md.Location AS MeetingLocation,
    md.Agreement, md.FirstRatingStats, md.SecondRatingStats
	FROM lab_13_first.dbo.LocationDistributed as ld
	    INNER JOIN lab_13_second.dbo.MeetingDistributed as md
	    ON ld.LocationId = md.Location
;

DROP VIEW IF EXISTS MeetingView;

SELECT * FROM MeetingView;

-- Ограничиваем вставку на несуществующего родителя
CREATE TRIGGER InsertMeeting on MeetingDistributed
AFTER INSERT
AS
    IF EXISTS(SELECT * FROM lab_13_first.dbo.LocationDistributed, inserted
				WHERE lab_13_first.dbo.LocationDistributed.LocationId <> inserted.Location)
		BEGIN
			RAISERROR('ERROR - Parent LocationId DOES NOT EXIST', 16, 1, 'InsertMeeting')
		END
;

DROP TRIGGER IF EXISTS InsertMeeting;

-- триггер пропустит
INSERT INTO MeetingDistributed(MeetingId, MeetingDate, Location, Agreement, FirstRatingStats, SecondRatingStats)
VALUES
    (4, '2024.12.10', 1, 1, 3, 3)

-- триггер сработает
INSERT INTO MeetingDistributed(MeetingId, MeetingDate, Location, Agreement, FirstRatingStats, SecondRatingStats)
VALUES
    (5, '2024.12.10', 100, 1, 3, 3)

-- ограничиваем обновление id родителя
CREATE TRIGGER UpdateMeeting on MeetingDistributed
AFTER UPDATE
AS
    IF UPDATE(Location)
    BEGIN
        RAISERROR('ERROR - Parent LocationId CAN NOT UPDATE', 16, 1, 'UpdateMeeting')
    END
;

DROP TRIGGER IF EXISTS UpdateMeeting;

-- триггер пропустит
UPDATE MeetingDistributed SET
Agreement = 1
WHERE MeetingId = 4;

-- триггер сработает
UPDATE MeetingDistributed SET
Location = 1
WHERE MeetingId = 4;

-- нельзя удалять родителя при сущетсвующих детях
CREATE TRIGGER DeleteLocation on Location
AFTER DELETE
AS
    IF EXISTS(SELECT * FROM lab_13_second.dbo.MeetingDistributed, deleted
				WHERE lab_13_second.dbo.MeetingDistributed.Location <> deleted.LocationId)
		BEGIN
			RAISERROR('ERROR - CHILD EXIST', 16, 1, 'DeleteMeeting')
		END
;

DROP TRIGGER IF EXISTS DeleteLocation;

-- обновление родителя при сущетсвующих детях
CREATE TRIGGER LocationUpdate ON LocationDistributed
FOR UPDATE
AS
	IF UPDATE(LocationId) AND EXISTS (SELECT 1 FROM lab_13_second.dbo.MeetingDistributed RIGHT JOIN inserted
				ON lab_13_second.dbo.MeetingDistributed.Location = inserted.LocationId
				WHERE lab_13_second.dbo.MeetingDistributed.Location IS NULL)
		BEGIN
			RAISERROR('ERROR - Meetings already exist, can not update', 16, 2, 'LocationUpdate')
		END
GO

DROP TRIGGER IF EXISTS LocationUpdate;
