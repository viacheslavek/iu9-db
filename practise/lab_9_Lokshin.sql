-- Из 7 лабораторной пункта 2 таблица

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

-- 1. Для одной из таблиц пункта 2 задания 7 создать триггеры на вставку, удаление и обновления,
-- при выполнении заданных условий один из триггеров должен инициировать возникновение ошибки (RAISERROR / THROW).

-- RAISEERROR является более общей командой.
-- message_string: Текст сообщения об ошибке.
-- severity: Уровень серьезности ошибки (0-25).
-- state: Состояние ошибки (в диапазоне от 0 до 255).
-- RAISEERROR может быть использована в триггерах, хранимых процедурах и других частях T-SQL кода.

-- THROW является более новой командой, введенной в SQL Server 2012.
-- THROW поддерживает только уровень серьезности 0-18. В отличие от RAISEERROR, у THROW нет состояний.
-- В контексте THROW, числовой код может быть любым числом от -2147483648 до 2147483647
-- и используется для идентификации конкретного вида ошибки.
-- THROW обычно используется для простых случаев, где не требуется дополнительной конфигурации.

-- Вставка
CREATE TRIGGER trg_Location_Insert
ON Location
AFTER INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE LEN(Address) > 25
    )
    BEGIN
        RAISERROR('Address length should not exceed 25 characters.', 16, 1);
    END;
END;

INSERT INTO Location (Address, Name, Description)
VALUES ('very very very very long address name', 'Yet Another Location', 'This is yet another location');

DROP TRIGGER IF EXISTS trg_Location_Insert;

-- Обновление
CREATE TRIGGER trg_Location_Update
ON Location
AFTER UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE LEN(Name) > 30
    )
    BEGIN
        THROW 50001, 'Name length should not exceed 30 characters.', 11;
    END;
END;

DROP TRIGGER IF EXISTS trg_Location_Update;

UPDATE Location
SET Name = 'very very very very long name location'
WHERE Address = '123 Main St'

-- Удаление

CREATE TABLE DeletedLocationAudit(
    LocationID UNIQUEIDENTIFIER,
    DeletedDate DATE,
    Address NVARCHAR(256),
);

DROP TABLE IF EXISTS DeletedLocationAudit;

CREATE TRIGGER trg_Location_Delete
ON Location
AFTER DELETE
AS
BEGIN
    INSERT INTO DeletedLocationAudit(LocationId, DeletedDate, Address)
    SELECT LocationId, GETDATE(), Address
    FROM deleted;
END;

DROP TRIGGER IF EXISTS trg_Location_Delete;

DELETE FROM Location
WHERE Address = '456 Oak St';

-- 2. Для представления пункта 2 задания 7 создать триггеры на вставку, удаление и обновление,
-- обеспечивающие возможность выполнения операций с данными непосредственно через представление.

CREATE TABLE Meeting (
    meetingId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    MeetingDate DATE,
    Location UNIQUEIDENTIFIER FOREIGN KEY REFERENCES Location(LocationId),
    Agreement BIT,
    FirstRatingStats SMALLINT,
    SecondRatingStats SMALLINT
);

INSERT INTO Meeting (MeetingDate, Location, Agreement, FirstRatingStats, SecondRatingStats)
VALUES ('2023-11-15', '1B831EC9-C3C2-4DF9-A0B1-3A9085CC9366', 1, 5, 4);
INSERT INTO Meeting (MeetingDate, Location, Agreement, FirstRatingStats, SecondRatingStats)
VALUES ('2023-11-16', 'AD73AD01-17F6-4A88-ADAC-7005DC1419FC', 0, 3, 5);
INSERT INTO Meeting (MeetingDate, Location, Agreement, FirstRatingStats, SecondRatingStats)
VALUES ('2023-11-17', '1AA3E0E1-B7A7-4BB8-A578-7D7B16E5D2E8', 1, 4, 4);


DROP TABLE IF EXISTS Meeting;

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

-- Вставка
CREATE TRIGGER trg_CombinedView_Insert
ON CombinedView
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO Location (Address, Name, Description)
    SELECT Address, LocationName, LocationDescription FROM inserted;

    INSERT INTO Meeting (MeetingDate, Location, Agreement, FirstRatingStats, SecondRatingStats)
    SELECT MeetingDate, LocationId, Agreement, FirstRatingStats, SecondRatingStats FROM inserted;
END;

-- Обновление
CREATE TRIGGER trg_CombinedView_Update
ON CombinedView
INSTEAD OF UPDATE
AS
BEGIN
    UPDATE L
    SET Address = i.Address,
        Name = i.LocationName,
        Description = i.LocationDescription
    FROM Location L
    INNER JOIN inserted i ON L.LocationId = i.LocationId;

    UPDATE M
    SET MeetingDate = i.MeetingDate,
        Location = i.LocationId,
        Agreement = i.Agreement,
        FirstRatingStats = i.FirstRatingStats,
        SecondRatingStats = i.SecondRatingStats
    FROM Meeting M
    INNER JOIN inserted i ON M.MeetingId = i.MeetingId;
END;

-- Удаление
CREATE TRIGGER trg_CombinedView_Delete
ON CombinedView
INSTEAD OF DELETE
AS
BEGIN
    DELETE FROM Location WHERE LocationId IN (SELECT LocationId FROM deleted);
    DELETE FROM Meeting WHERE Location IN (SELECT LocationId FROM deleted);
END;
