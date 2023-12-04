-- Из 7 лабораторной
USE master;

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

-- 1. Создать хранимую процедуру,
-- производящую выборку из некоторой таблицы и возвращающую результат выборки в виде курсора.

DROP PROCEDURE IF EXISTS get_locations;
GO

CREATE PROCEDURE get_locations
	@cursor CURSOR VARYING OUTPUT
AS
	SET @cursor = CURSOR FORWARD_ONLY STATIC FOR
		SELECT LocationId, Address, Name, Description
		FROM Location;
	OPEN @cursor;
GO

DECLARE @location_cursor CURSOR;
EXEC get_locations @cursor = @location_cursor OUTPUT;
DECLARE @LocationId UNIQUEIDENTIFIER, @Address NVARCHAR(256), @Name NVARCHAR(256), @Description NVARCHAR(1024);

FETCH NEXT FROM @location_cursor INTO @LocationId, @Address, @Name, @Description;
WHILE (@@FETCH_STATUS = 0)
	BEGIN
		PRINT CAST(@LocationId AS VARCHAR(36)) + ' : '+ @Description + ' with name ' + @Name + ' in address ' + @Address;
		FETCH NEXT FROM @location_cursor INTO @LocationId, @Description, @Name, @Address;
	END;
CLOSE @location_cursor;
DEALLOCATE @location_cursor;

-- 2. Модифицировать хранимую процедуру таким образом,
-- чтобы выборка осуществлялась с формированием столбца,
-- значение которого формируется пользовательской функцией.

-- Первый три буквы места большими
CREATE FUNCTION dbo.GenerateLocationCode(@locationName NVARCHAR(256))
RETURNS NVARCHAR(3)
AS
BEGIN
    DECLARE @code NVARCHAR(3);
    SET @code = UPPER(LEFT(@locationName, 3));
    RETURN @code;
END;

CREATE PROCEDURE get_locations_with_code
    @cursor CURSOR VARYING OUTPUT
AS
    SET @cursor = CURSOR FORWARD_ONLY STATIC FOR
        SELECT
            LocationId,
            Address,
            Name,
            Description,
            dbo.GenerateLocationCode(Name) AS LocationCode
        FROM Location;
    OPEN @cursor;
GO

DECLARE @location_cursor_with_code CURSOR;
EXEC get_locations_with_code @cursor = @location_cursor_with_code OUTPUT;
DECLARE @LocationId UNIQUEIDENTIFIER, @Address NVARCHAR(256), @Name NVARCHAR(256), @Description NVARCHAR(1024),
    @LocationCode NVARCHAR(3);

FETCH NEXT FROM @location_cursor_with_code INTO @LocationId, @Address, @Name, @Description, @LocationCode;
WHILE (@@FETCH_STATUS = 0)
	BEGIN
		PRINT CAST(@LocationId AS VARCHAR(36)) + ' : '+ @Description + ' with name ' + @Name + ' in address '
		          + @Address + ' with code ' + @LocationCode;
		FETCH NEXT FROM @location_cursor_with_code INTO @LocationId, @Description, @Name, @Address, @LocationCode;
	END;
CLOSE @location_cursor_with_code;
DEALLOCATE @location_cursor_with_code;

-- 3. Создать хранимую процедуру, вызывающую процедуру п. 1,
-- осуществляющую прокрутку возвращаемого курсора и выводящую сообщения,
-- сформированные из записей при выполнении условия, заданного еще одной пользовательской функцией.

CREATE FUNCTION dbo.CheckCondition(@Description NVARCHAR(1024))
RETURNS INT
AS
BEGIN
    DECLARE @ret INT;
	SET @ret = 0
	IF (LEN(@Description) < 50)
	SET @ret = 1
	RETURN @ret
END;

CREATE PROCEDURE process_locations
AS
    DECLARE @location_cursor CURSOR;
    EXEC get_locations @cursor = @location_cursor OUTPUT;
    DECLARE @LocationId UNIQUEIDENTIFIER, @Address NVARCHAR(256), @Name NVARCHAR(256), @Description NVARCHAR(1024);

    FETCH NEXT FROM @location_cursor INTO @LocationId, @Address, @Name, @Description;

    WHILE (@@FETCH_STATUS = 0)
    BEGIN
        PRINT 'ret:' + CAST(dbo.CheckCondition(@Description) AS VARCHAR)
        IF (dbo.CheckCondition(@Description) = 1)

        PRINT 'Condition met for location: ' + CAST(@LocationId AS VARCHAR(36)) + ' : '+ @Description +
              ' with name ' + @Name + ' in address ' + @Address;

        FETCH NEXT FROM @location_cursor INTO @LocationId, @Address, @Name, @Description;
    END;

EXEC process_locations;
CLOSE @location_cursor;
DEALLOCATE @location_cursor;

DROP PROCEDURE IF EXISTS process_locations;

-- 4. Модифицировать хранимую процедуру п.2. таким образом, чтобы выборка формировалась с помощью табличной функции.

CREATE FUNCTION dbo.GenerateLocationCodeTable(@locationName NVARCHAR(256))
RETURNS TABLE
AS
RETURN (
    SELECT
        LocationId,
        Address,
        Name,
        Description,
        UPPER(LEFT(@locationName, 3)) AS LocationCode
    FROM Location
);

DROP PROCEDURE IF EXISTS get_locations_with_code_table;

CREATE PROCEDURE get_locations_with_code_table
    @cursor CURSOR VARYING OUTPUT
AS
    SET @cursor = CURSOR FORWARD_ONLY STATIC FOR
        SELECT
            LocationId,
            Address,
            Name,
            Description,
            LocationCode
        FROM dbo.GenerateLocationCodeTable('Osinniki');
    OPEN @cursor;
GO

-- Какой-то баг ide, на самом деле все норм (get_locations_with_code_table @cursor подсвечивается как ошибка)
DECLARE @location_cursor_with_code_table CURSOR;
EXEC get_locations_with_code_table @cursor = @location_cursor_with_code_table OUTPUT;
DECLARE @LocationId UNIQUEIDENTIFIER, @Address NVARCHAR(256), @Name NVARCHAR(256), @Description NVARCHAR(1024),
    @LocationCode NVARCHAR(3);

FETCH NEXT FROM @location_cursor_with_code_table INTO @LocationId, @Address, @Name, @Description, @LocationCode;
WHILE (@@FETCH_STATUS = 0)
	BEGIN
		PRINT CAST(@LocationId AS VARCHAR(36)) + ' : '+ @Description + ' with name ' + @Name + ' in address '
		          + @Address + ' with code ' + @LocationCode;
		FETCH NEXT FROM @location_cursor_with_code_table INTO @LocationId, @Description, @Name, @Address, @LocationCode;
	END;
CLOSE @location_cursor_with_code_table;
DEALLOCATE @location_cursor_with_code_table;
