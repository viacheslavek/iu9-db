-- Создать базу данных с настройками
CREATE DATABASE slavaDB
ON
(
    NAME = YourDataFileLogicalName,
    FILENAME = '/labs/lab5DataFile.mdf', -- Путь к файлу данных
    SIZE = 100MB,                        -- Начальный размер файла данных
    MAXSIZE = UNLIMITED,                 -- Максимальный размер (неограниченный)
    FILEGROWTH = 10MB                    -- Рост файла данных
)
LOG ON
(
    NAME = YourLogFileName,
    FILENAME = '/labs/lab5LogFile.ldf',  -- Путь к файлу журнала
    SIZE = 50MB,                         -- Начальный размер файла журнала
    MAXSIZE = 2GB,                       -- Максимальный размер файла журнала
    FILEGROWTH = 10MB                    -- Рост файла журнала
);

-- Долго мучился c root и тем, чтобы это заработало

-- Удалить базу данных
USE master;
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'slavaDB')
BEGIN
    DROP DATABASE slavaDB;
END

-- Создаю таблицу
CREATE TABLE Location (
    LocationId INT PRIMARY KEY,
    Address NVARCHAR(256),
    Name NVARCHAR(256),
    Description NVARCHAR(1024)
);

-- Добавление файловой группы
ALTER DATABASE slavaDB
ADD FILEGROUP TestFileGroup;

-- Добавление файла данных к файловой группе
ALTER DATABASE slavaDB
ADD FILE
(
    NAME = TestFileName,
    FILENAME = '/labs/AlterLab5DataFile.mdf',
    SIZE = 10MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
)
TO FILEGROUP TestFileGroup;

-- Просмотр файловых групп
SELECT name
FROM sys.filegroups;

-- Просмотр файлов данных
SELECT name, physical_name
FROM sys.master_files
WHERE database_id = DB_ID('slavaDB');

-- Созданная файловая группа по умолчанию
ALTER DATABASE slavaDB
MODIFY FILEGROUP TestFileGroup DEFAULT;

CREATE TABLE Interest (
    InterestId INT PRIMARY KEY,
    Name NVARCHAR(256),
    Description NVARCHAR(1024)
);

-- Удаление файловой группы
-- Проверяем, что она пуста

ALTER DATABASE slavaDB
MODIFY FILEGROUP [PRIMARY] DEFAULT;

SELECT *
FROM sys.master_files
WHERE data_space_id = FILEGROUP_ID('TestFileGroup');

SELECT *
FROM sys.allocation_units
WHERE data_space_id = FILEGROUP_ID('TestFileGroup');

-- Удаление файла
ALTER DATABASE slavaDB
REMOVE FILE TestFileName;

-- Удаление таблиц
DROP TABLE Interest;

-- Удаление пустой файловой группы
ALTER DATABASE slavaDB
REMOVE FILEGROUP TestFileGroup;

-- Создаю схему
USE slavaDB;
CREATE SCHEMA fifth_lab;

-- Удаляю схему
USE slavaDB;
DROP SCHEMA fifth_lab;

-- Переместить таблицу в схему
ALTER SCHEMA fifth_lab
TRANSFER dbo.Location;

