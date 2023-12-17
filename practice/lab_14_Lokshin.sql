-- 1. Создать в базах данных пункта 1 задания 13 таблицы, содержащие вертикально фрагментированные данные.

-- Общий вид таблицы:
-- CREATE TABLE CoffeeUser (
--     UserId INT PRIMARY KEY NOT NULL,
--     Email NVARCHAR(256) UNIQUE NOT NULL,
--     Name NVARCHAR(64) NOT NULL,
--     Lastname NVARCHAR(64) NOT NULL,
--     Password  NVARCHAR(128) NOT NULL,
--     DateOfBirth DATE NOT NULL,
--     RegistrationDate DATE NOT NULL,
--     Gender NVARCHAR(1) NOT NULL,
-- );

-- Первая база данных
USE lab_13_first

CREATE TABLE CoffeeUser (
    UserId INT PRIMARY KEY NOT NULL,
    Email NVARCHAR(256) UNIQUE NOT NULL,
    Name NVARCHAR(64) NOT NULL,
    Lastname NVARCHAR(64) NOT NULL,
    Password  NVARCHAR(128) NOT NULL,
);

DROP TABLE IF EXISTS CoffeeUser;

-- Вторая база данных
USE lab_13_second

CREATE TABLE CoffeeUser (
    UserId INT PRIMARY KEY NOT NULL,
    DateOfBirth DATE NOT NULL,
    RegistrationDate DATE NOT NULL,
    Gender NVARCHAR(1) NOT NULL,
);

DROP TABLE IF EXISTS CoffeeUser;

-- 2. Создать необходимые элементы базы данных (представления, триггеры),
-- обеспечивающие работу с данными вертикально фрагментированных таблиц (выборку, вставку, изменение, удаление).

CREATE VIEW sectionVerticalView AS
	SELECT f.UserId, f.Email, f.Name, f.Lastname, f.Password, s.Gender, s.DateOfBirth, s.RegistrationDate
	FROM lab_13_first.dbo.CoffeeUser f, lab_13_second.dbo.CoffeeUser s
	WHERE f.UserId = s.UserId
;

DROP VIEW IF EXISTS sectionVerticalView;

SELECT * FROM sectionVerticalView;

-- Insert

CREATE TRIGGER VerticalViewInsert ON sectionVerticalView
INSTEAD OF INSERT
AS
	INSERT INTO lab_13_first.dbo.CoffeeUser(UserId, Email, Name, Lastname, Password)
		SELECT i.UserId, i.Email, i.Name, i.Lastname, i.Password FROM inserted AS i
	INSERT INTO lab_13_second.dbo.CoffeeUser(UserId, DateOfBirth, RegistrationDate, Gender)
		SELECT i.UserId, i.DateOfBirth, i.RegistrationDate, i.Gender FROM inserted AS i
;

INSERT INTO sectionVerticalView (UserId, Email, Name, Lastname, Password, Gender, DateOfBirth, RegistrationDate)
VALUES
    (1, 'slava@email.com', 'Slava', 'Lokshin', 'password_slava', 'M', '1990-05-15', '2022-08-20'),
    (2, 'kirill@email.com', 'Kirill', 'Kiselev', 'password_kirill', 'M', '1995-08-23', '2022-10-20'),
    (3, 'denis@email.com', 'Denis', 'Okutin', 'password_denis', 'M', '1988-11-07', '2023-08-20'),
    (4, 'alexey@email.com', 'Aleksey', 'Tinarsky', 'password_alexey', 'M', '1992-02-28', '2022-08-15');

DROP TRIGGER IF EXISTS VerticalViewInsert;

-- Update

CREATE TRIGGER VerticalViewUpdate ON sectionVerticalView
INSTEAD OF UPDATE
AS
	IF UPDATE(UserId)
		BEGIN
			THROW 49555, 'can not update User id', 1
		END
	ELSE
		BEGIN
			UPDATE lab_13_first.dbo.CoffeeUser
				SET Email = i.email, Name = i.Name, Lastname = i.Lastname, Password = i.Password
					FROM inserted AS i, lab_13_first.dbo.CoffeeUser AS cu
					WHERE cu.UserId = i.UserId;
			UPDATE lab_13_second.dbo.CoffeeUser
				SET DateOfBirth = i.DateOfBirth, RegistrationDate = i.RegistrationDate, Gender = i.Gender
					FROM inserted AS i, lab_13_second.dbo.CoffeeUser AS cu
					WHERE cu.UserId = i.UserId;
		END
;

UPDATE sectionVerticalView SET Name = 'Klava' WHERE UserId = 1;
UPDATE sectionVerticalView SET Gender = 'W' WHERE UserId = 1;

DROP TRIGGER IF EXISTS VerticalViewUpdate;

-- Delete

CREATE TRIGGER VerticalViewDelete ON sectionVerticalView
INSTEAD OF DELETE
AS
	DELETE f FROM lab_13_first.dbo.CoffeeUser AS f
		INNER JOIN deleted ON f.UserId = deleted.UserId
	DELETE s FROM lab_13_second.dbo.CoffeeUser AS s
		INNER JOIN deleted ON s.UserId = deleted.UserId
;

DELETE FROM sectionVerticalView WHERE UserId = '2';
