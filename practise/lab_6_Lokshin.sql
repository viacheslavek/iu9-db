--  Создание таблицы с автоинкриментным первичным ключом
USE master;
CREATE TABLE Location (
    LocationId INT IDENTITY(1,1) PRIMARY KEY,
    Address NVARCHAR(256),
    Name NVARCHAR(256),
    Description NVARCHAR(1024)
);

-- Изучаю функции для получения IDENTITY
-- SCOPE_IDENTITY() - Возвращает последний автоинкрементный ID, созданный в текущей сессии и текущей области видимости.
INSERT INTO Location (Address, Name, Description)
VALUES ('123 Main St', 'Sample Location', 'This is a sample location');

DECLARE @GeneratedID INT;
SET @GeneratedID = SCOPE_IDENTITY();
PRINT 'Generated ID: ' + CAST(@GeneratedID AS NVARCHAR);

-- @@IDENTITY Возвращает последний автоинкрементный ID для любой таблицы в текущей сессии,
-- но следует использовать осторожно, так как может быть изменен триггерами или другими операциями.
INSERT INTO Location (Address, Name, Description)
VALUES ('456 Oak St', 'Another Location', 'This is another location');

DECLARE @GeneratedID INT;
SET @GeneratedID = @@IDENTITY;
PRINT 'Generated ID: ' + CAST(@GeneratedID AS NVARCHAR);

-- IDENT_CURRENT('table') - Возвращает последний автоинкрементный ID для указанной таблицы,
-- даже если были внесены изменения в другие таблицы после вставки.
INSERT INTO Location (Address, Name, Description)
VALUES ('789 Pine St', 'Yet Another Location', 'This is yet another location');

DECLARE @GeneratedID INT;
SET @GeneratedID = IDENT_CURRENT('Location');
PRINT 'Generated ID: ' + CAST(@GeneratedID AS NVARCHAR);

-- Используются ограничения (СНЕСК), значения по умолчанию (DEFAULT),
-- также использовать встроенные функции для вычисления значений.

DROP TABLE Location;

CREATE TABLE Location (
    LocationId INT IDENTITY(1,1) PRIMARY KEY,
    Address NVARCHAR(256) CONSTRAINT CK_Address CHECK (LEN(Address) <= 256),
    Name NVARCHAR(256) DEFAULT 'Unknown',
    Description NVARCHAR(1024),
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Создать таблицу с первичным ключом на основе глобального уникального идентификатора.

CREATE TABLE Location (
    LocationId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    Address NVARCHAR(256),
    Name NVARCHAR(256),
    Description NVARCHAR(1024),
);

-- Создать таблицу с первичным ключом на основе последовательности.

-- Создание последовательности
CREATE SEQUENCE LocationSequence
    START WITH 1
    INCREMENT BY 1
    NO CYCLE
    NO CACHE;

-- Создание таблицы с первичным ключом на основе последовательности
CREATE TABLE Location (
    LocationId INT PRIMARY KEY DEFAULT NEXT VALUE FOR LocationSequence,
    Address NVARCHAR(256),
    Name NVARCHAR(256),
    Description NVARCHAR(1024)
);

-- Очистка последовательности после использования
ALTER SEQUENCE LocationSequence
    RESTART WITH 1;

DROP TABLE Location;

DROP SEQUENCE LocationSequence;

-- Создать две связанные таблицы, и протестировать на них различные варианты действий для ограничений
-- ссылочной целостности (NO ACTION | CASCADE | SET NULL | SET DEFAULT)

CREATE TABLE Meeting (
    meetingId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    MeetingDate DATE,
    Location UNIQUEIDENTIFIER FOREIGN KEY REFERENCES Location(LocationId),
    Agreement BIT,
    FirstRatingStats SMALLINT,
    SecondRatingStats SMALLINT
);

ALTER TABLE Meeting
DROP CONSTRAINT FK_Meeting_Location;

-- NO ACTION
-- ON UPDATE NO ACTION: Никаких действий не предпринимается при обновлении значения в родительской таблице.
-- Если существуют дочерние записи, которые ссылаются на обновляемое значение, операция обновления будет отклонена.
-- ON DELETE NO ACTION: Никаких действий не предпринимается при удалении значения из родительской таблицы.
-- Если существуют дочерние записи, которые ссылаются на удаляемое значение, операция удаления будет отклонена.

ALTER TABLE Meeting
ADD CONSTRAINT FK_Meeting_Location
FOREIGN KEY (Location)
REFERENCES Location(LocationId)
ON UPDATE NO ACTION
ON DELETE NO ACTION;

-- CASCADE
-- ON UPDATE CASCADE: При обновлении значения в родительской таблице,
-- все связанные дочерние записи в таблице-потомке также обновятся, чтобы соответствовать новому значению.
-- ON DELETE CASCADE: При удалении значения из родительской таблицы,
-- все связанные дочерние записи в таблице-потомке также будут удалены.

ALTER TABLE Meeting
ADD CONSTRAINT FK_Meeting_Location
FOREIGN KEY (Location)
REFERENCES Location(LocationId)
ON UPDATE CASCADE
ON DELETE CASCADE;

-- SET NULL
-- ON UPDATE SET NULL: При обновлении значения в родительской таблице,
-- значения в соответствующем столбце дочерней таблицы будут установлены в NULL.
-- ON DELETE SET NULL: При удалении значения из родительской таблицы,
-- значения в соответствующем столбце дочерней таблицы будут установлены в NULL.

ALTER TABLE Meeting
ADD CONSTRAINT FK_Meeting_Location
FOREIGN KEY (Location)
REFERENCES Location(LocationId)
ON UPDATE SET NULL
ON DELETE SET NULL;

-- SET DEFAULT
-- ON UPDATE SET DEFAULT: При обновлении значения в родительской таблице,
-- значения в соответствующем столбце дочерней таблицы будут установлены в значение по умолчанию (если оно определено).
-- ON DELETE SET DEFAULT: При удалении значения из родительской таблицы,
-- значения в соответствующем столбце дочерней таблицы будут установлены в значение по умолчанию (если оно определено).

ALTER TABLE Meeting
ADD CONSTRAINT FK_Meeting_Location
FOREIGN KEY (Location)
REFERENCES Location(LocationId)
ON UPDATE SET DEFAULT
ON DELETE SET DEFAULT;

-- Для тестов LocationId, MeetingId -> подставить нужное
DELETE FROM Location
WHERE LocationId = 'LocationId';

UPDATE Location
SET Address = 'NewAddress', Name = 'NewName', Description = 'NewDescription'
WHERE LocationId = 'LocationId';

DELETE FROM Meeting
WHERE MeetingId = 'MeetingId';

UPDATE Meeting
SET Location = 'NewLocationId', Agreement = 1
WHERE MeetingId = 'MeetingId';
