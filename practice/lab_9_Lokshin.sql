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

CREATE TABLE Location (
    LocationId INT PRIMARY KEY,
    Address NVARCHAR(256),
    Name NVARCHAR(256),
    Description NVARCHAR(1024),
);

INSERT INTO Location (LocationId, Address, Name, Description)
VALUES (1, '123 Main St', 'Sample Location', 'This is a sample location');
INSERT INTO Location (LocationId, Address, Name, Description)
VALUES (2, '456 Oak St', 'Another Location', 'This is another location');
INSERT INTO Location (LocationId, Address, Name, Description)
VALUES (3, '789 Pine St', 'Yet Another Location', 'This is yet another location');

DROP TABLE IF EXISTS Location;

CREATE TABLE Meeting (
    MeetingId INT PRIMARY KEY,
    MeetingDate DATE,
    LocationId INT FOREIGN KEY REFERENCES Location(LocationId),
    Agreement BIT,
    FirstRatingStats SMALLINT,
    SecondRatingStats SMALLINT
);

INSERT INTO Meeting (MeetingId, MeetingDate, LocationId, Agreement, FirstRatingStats, SecondRatingStats)
VALUES (1, '2023-11-15', 1, 1, 5, 4);
INSERT INTO Meeting (MeetingId, MeetingDate, LocationId, Agreement, FirstRatingStats, SecondRatingStats)
VALUES (2, '2023-11-16', 2, 0, 3, 5);
INSERT INTO Meeting (MeetingId, MeetingDate, LocationId, Agreement, FirstRatingStats, SecondRatingStats)
VALUES (3, '2023-11-17', 3, 1, 4, 4);
INSERT INTO Meeting (MeetingId, MeetingDate, LocationId, Agreement, FirstRatingStats, SecondRatingStats)
VALUES (4, '2023-11-14', 1, 1, 5, 4);
INSERT INTO Meeting (MeetingId, MeetingDate, LocationId, Agreement, FirstRatingStats, SecondRatingStats)
VALUES (5, '2023-11-19', 2, 0, 2, 5);
INSERT INTO Meeting (MeetingId, MeetingDate, LocationId, Agreement, FirstRatingStats, SecondRatingStats)
VALUES (6, '2024-11-17', 3, 1, 5, 4);


DROP TABLE IF EXISTS Meeting;

-- Создание представления на основе полей связанных таблиц
-- По итогу у меня связь у таблиц один ко многим. Назовем родительской таблицу Location
-- А дочерней Meeting для простоты. Соответсвенно дочерная таблица ссылается на родительскую и
-- таких ссылок может быть от 1 до N.

-- Для этой view нужно ввести ограничения для корректной работы

CREATE VIEW LocationMeeting AS
SELECT
    L.LocationId,
    L.Address,
    L.Name AS LocationName,
    L.Description,
    M.MeetingId,
    M.MeetingDate,
    M.Agreement,
    M.FirstRatingStats,
    M.SecondRatingStats
FROM
    Location L
INNER JOIN
    Meeting M ON L.LocationId = M.LocationId;

SELECT * FROM LocationMeeting;

DROP VIEW IF EXISTS LocationMeeting;

-- Вставка
CREATE TRIGGER trg_LocationMeeting_Insert
ON LocationMeeting
INSTEAD OF INSERT
AS
BEGIN
--  Ограничения вставки - мы не можем вставить в родительскую таблицу те записи, которые
--  Уже есть в этой таблице, в этом нам помогает запрос WHERE NOT EXISTS
    INSERT INTO Location (LocationId, Address, Name, Description)
        SELECT DISTINCT I.LocationId, I.Address, I.LocationName, I.Description
        FROM inserted AS I
        WHERE NOT EXISTS (
            SELECT L.LocationId
            FROM Location AS L
            WHERE I.LocationId = L.LocationId
        );

    INSERT INTO Meeting (MeetingId, MeetingDate, LocationId, Agreement, FirstRatingStats, SecondRatingStats)
        SELECT I.MeetingId, I.MeetingDate, L.LocationId, I.Agreement, I.FirstRatingStats, I.SecondRatingStats
        FROM inserted as I
            JOIN Location AS L
            ON L.LocationId = I.LocationId
END;

DROP TRIGGER IF EXISTS trg_LocationMeeting_Insert;

-- Добавляем c новыми Location
INSERT INTO LocationMeeting
    (LocationId, Address, LocationName, Description,
     MeetingId,  MeetingDate, Agreement, FirstRatingStats, SecondRatingStats)
VALUES
    (4, '11 Main St', 'Conference Room A', 'first new',
     7, '2023-02-16', 1, 4, 5),
    (5, '50 Oaks St', 'Board Room B', 'second new',
     8, '2023-02-18', 1, 5, 4);

-- Добавляем c существующим Location - таблица Location не изменилась, ребенок добавился
INSERT INTO LocationMeeting
    (LocationId, Address, LocationName, Description,
     MeetingId,  MeetingDate, Agreement, FirstRatingStats, SecondRatingStats)
VALUES
    (1, '123 Main St', 'Sample Location', 'This is a sample location',
     9, '2023-02-11', 1, 3, 4);

-- Обновление
CREATE TRIGGER trg_LocationMeeting_Update
ON LocationMeeting
INSTEAD OF UPDATE
AS
BEGIN

    IF UPDATE(MeetingId)
    BEGIN
        THROW 50005, 'Can not update meeting id', 11;
    END;

    IF (UPDATE(LocationId)) OR (UPDATE(Address)) OR (UPDATE(LocationName)) OR (UPDATE(Description))
    BEGIN
        THROW 50004, 'Can not update location entity', 11;
    END;

    WITH InsertedLocation AS (
        SELECT L.LocationId, I.MeetingId, I.MeetingDate, I.Agreement, I.FirstRatingStats, I.SecondRatingStats
        FROM inserted AS I
            INNER JOIN Location AS L
            ON I.LocationId = L.LocationId
    )
    UPDATE M
    SET MeetingDate = IL.MeetingDate,
        Agreement = IL.Agreement,
        FirstRatingStats = IL.FirstRatingStats,
        SecondRatingStats = IL.SecondRatingStats
    FROM Meeting AS M
        INNER JOIN InsertedLocation AS IL
        ON M.LocationId = IL.LocationId AND M.MeetingId = IL.MeetingId;
END;

DROP TRIGGER IF EXISTS trg_LocationMeeting_Update;

UPDATE LocationMeeting
SET MeetingDate = '2025-11-15', Agreement = 0, FirstRatingStats = 1, SecondRatingStats = 1
WHERE LocationId = 1;

-- тест на просто обновление значений встреч по LocationId
UPDATE LocationMeeting
SET MeetingDate = '2025-11-15', Agreement = 0, FirstRatingStats = 1, SecondRatingStats = 1
WHERE LocationId = 1;

-- тест на просто обновление значений встреч по атрибуту из meeting
UPDATE LocationMeeting
SET FirstRatingStats = 1
WHERE SecondRatingStats = 5;

-- тест на обновление meetingID - ошибка
UPDATE LocationMeeting
SET MeetingId = 1
WHERE MeetingId = 2;

-- тест на обновление чего-либо из Location - ошибка
UPDATE LocationMeeting
SET Address = 'fake address'
WHERE LocationId = 1;

-- Удаление - удаляю только детей
CREATE TRIGGER trg_LocationMeeting_Delete
ON LocationMeeting
INSTEAD OF DELETE
AS
BEGIN
    WITH DeletedLocation AS (
        SELECT L.LocationId, D.MeetingId, D.Address, D.LocationName, D.Description
        FROM deleted AS D
            INNER JOIN Location AS L
            ON D.LocationId = L.LocationId
    )
    DELETE FROM Meeting
    WHERE EXISTS (
        SELECT LocationId, Address, LocationName, Description FROM DeletedLocation AS DL
        WHERE Meeting.LocationId = DL.LocationId AND Meeting.MeetingId = DL.MeetingId
    );
END;

DROP TRIGGER IF EXISTS trg_LocationMeeting_Delete;

-- тест на удаление по MeetingId
DELETE FROM LocationMeeting
WHERE MeetingId = 1;

-- тест на удаление по LocationId
DELETE FROM LocationMeeting
WHERE LocationId = 1;

-- тест на удаление по атрибуту Meeting
DELETE FROM LocationMeeting
WHERE Agreement = 0;

-- тест на удаление по атрибуту Location
DELETE FROM LocationMeeting
WHERE Address = '789 Pine St';

-- Итого: встречи удаляются, локации нет
