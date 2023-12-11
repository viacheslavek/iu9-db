-- Хорошо написанную теорию нашел на https://backendinterview.ru/db/dBTheory/transactions.html
-- Из предыдущих лаб любимая таблица Location

CREATE TABLE Location (
    LocationId INT PRIMARY KEY,
    Address NVARCHAR(256),
    Name NVARCHAR(256),
    Description NVARCHAR(1024),
);

DROP TABLE IF EXISTS Location;

INSERT INTO Location (LocationId, Address, Name, Description)
VALUES (1, '123 Main St', 'Sample Location', 'This is a sample location');
INSERT INTO Location (LocationId, Address, Name, Description)
VALUES (2, '456 Oak St', 'Another Location', 'This is another location');
INSERT INTO Location (LocationId, Address, Name, Description)
VALUES (3, '789 Pine St', 'Yet Another Location', 'This is yet another location');

-- Исследовать и проиллюстрировать на примерах различные уровни изоляции транзакций MS SQL Server,
-- устанавливаемые с использованием инструкций SET TRANSACTION ISOLATION LEVEL

-- Read uncommitted (чтение незафиксированных данных)
-- Низший (первый) уровень изоляции. Он гарантирует только отсутствие потерянных обновлений.
-- Если несколько параллельных транзакций пытаются изменять одну и ту же строку таблицы,
-- то в окончательном варианте строка будет иметь значение, определенное всем набором успешно выполненных транзакций.
-- При этом возможно считывание не только логически несогласованных данных, но и данных,
-- изменения которых ещё не зафиксированы.
--
-- Типичный способ реализации данного уровня изоляции — блокировка данных на время выполнения команды изменения,
-- что гарантирует, что команды изменения одних и тех же строк, запущенные параллельно,
-- фактически выполнятся последовательно, и ни одно из изменений не потеряется.
-- Транзакции, выполняющие только чтение, при данном уровне изоляции никогда не блокируются.

-- Потерянное обновление (англ. lost update) — при одновременном изменении одного блока данных разными транзакциями
-- одно из изменений теряется;


-- Как защищает:


-- В новом терминале
-- Транзакция 1
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRANSACTION

UPDATE Location SET Description = 'Updated by Transaction 1' WHERE LocationId = 1;

COMMIT TRANSACTION;

-- В новом терминале
-- Транзакция 2
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRANSACTION

UPDATE Location SET Description = 'Updated by Transaction 2' WHERE LocationId = 1;

COMMIT TRANSACTION;

-- Как не работает:

-- В новом терминале
-- Транзакция 1
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRANSACTION

UPDATE Location SET Description = 'Updated by Transaction 1' WHERE LocationId = 1;

ROLLBACK WORK;

-- В новом терминале
-- Транзакция 2
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRANSACTION

SELECT Description FROM Location WHERE LocationId = 1;

ROLLBACK WORK;

-- Read committed (чтение фиксированных данных)
-- На этом уровне обеспечивается защита от чернового, «грязного» чтения, тем не менее,
-- в процессе работы одной транзакции другая может быть успешно завершена и сделанные ею изменения зафиксированы.
-- В итоге первая транзакция будет работать с другим набором данных.
--
-- Реализация завершённого чтения может основываться на одном из двух подходов: блокировании или версионности

-- «Грязное» чтение (англ. dirty read) — чтение данных, добавленных или изменённых транзакцией,
-- которая впоследствии не подтвердится (откатится);

-- Как защищает:

-- В новом терминале
-- Транзакция 1
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION

UPDATE Location SET Description = 'Updated by Transaction 1' WHERE LocationId = 1;

ROLLBACK WORK;

-- В новом терминале
-- Транзакция 2
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION

SELECT Description FROM Location WHERE LocationId = 1;

ROLLBACK WORK;

-- Как не работает?

-- В новом терминале
-- Транзакция 1
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION

UPDATE Location SET Description = 'Updated by Transaction 1' WHERE LocationId = 1;

COMMIT;

-- В новом терминале
-- Транзакция 2
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION

SELECT Description FROM Location WHERE LocationId = 1;

-- Транзакция 1 начинается и завершается

SELECT Description FROM Location WHERE LocationId = 1;

COMMIT;

-- Repeatable read (повторяемость чтения)
-- Уровень, при котором читающая транзакция «не видит» изменения данных, которые были ею ранее прочитаны.
-- При этом никакая другая транзакция не может изменять данные, читаемые текущей транзакцией, пока та не окончена.
--
-- Блокировки в разделяющем режиме применяются ко всем данным, считываемым любой инструкцией транзакции,
-- и сохраняются до её завершения. Это запрещает другим транзакциям изменять строки,
-- которые были считаны незавершённой транзакцией. Однако другие транзакции могут вставлять новые строки,
-- соответствующие условиям поиска инструкций, содержащихся в текущей транзакции.
-- При повторном запуске инструкции текущей транзакцией будут извлечены новые строки,
-- что приведёт к фантомному чтению. Учитывая то, что разделяющие блокировки сохраняются до завершения транзакции,
-- а не снимаются в конце каждой инструкции, степень параллелизма ниже, чем при уровне изоляции READ COMMITTED.
-- Поэтому пользоваться данным и более высокими уровнями транзакций без необходимости обычно не рекомендуется.

-- Неповторяющееся чтение (англ. non-repeatable read) —
-- при повторном чтении в рамках одной транзакции ранее прочитанные данные оказываются изменёнными;

-- Как защищает:

-- В новом терминале
-- Транзакция 1
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION

UPDATE Location SET Description = 'Updated by Transaction 1' WHERE LocationId = 1;

COMMIT;

-- В новом терминале
-- Транзакция 2
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION

SELECT Description FROM Location WHERE LocationId = 1;

-- Транзакция 1 начинается и завершается

SELECT Description FROM Location WHERE LocationId = 1;

COMMIT;

-- Как не работает?

-- В новом терминале
-- Транзакция 1
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION

INSERT INTO Location (LocationId, Address, Name, Description)
VALUES (4, 'New Address', 'New Location', 'New Description');

COMMIT;

-- В новом терминале
-- Транзакция 2
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION

SELECT COUNT(*) FROM Location;

-- Транзакция 1 начинается и завершается

SELECT COUNT(*) FROM Location;

COMMIT;

-- Serializable (упорядочиваемость)
-- Самый высокий уровень изолированности; транзакции полностью изолируются друг от друга,
-- каждая выполняется так, как будто параллельных транзакций не существует.
-- Только на этом уровне параллельные транзакции не подвержены эффекту «фантомного чтения».

-- фантомное чтение (англ. phantom reads) — одна транзакция в ходе своего выполнения несколько раз выбирает
-- множество строк по одним и тем же критериям.
-- Другая транзакция в интервалах между этими выборками добавляет или удаляет строки,
-- или изменяет столбцы некоторых строк, используемых в критериях выборки первой транзакции,
-- и успешно заканчивается. В результате получится,
-- что одни и те же выборки в первой транзакции дают разные множества строк.

-- Как защищает:

-- В новом терминале
-- Транзакция 1
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION

INSERT INTO Location (LocationId, Address, Name, Description)
VALUES (4, 'New Address', 'New Location', 'New Description');

COMMIT;

-- В новом терминале
-- Транзакция 2
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION

SELECT COUNT(*) FROM Location;

-- Транзакция 1 начинается и завершается

SELECT COUNT(*) FROM Location;

COMMIT;

-- Как не работает?
-- Никак

-- 2. Накладываемые блокировки исследовать с использованием sys.dm_tran_locks

-- Внутри транзакции прописываем
SELECT * FROM sys.dm_tran_locks;
