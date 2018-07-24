CREATE DATABASE "MyDb"
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1;

USE MyDb;
GO
CREATE TABLE IF NOT EXISTS Subscribers (
  SubId integer NOT NULL,
  SubName varchar(255) NOT NULL,
  EndDate timestamp,
  CONSTRAINT PK_Subscribers PRIMARY KEY (SubId)
);
GO
INSERT INTO  Subscribers (SubId, SubName, EndDate)
VALUES (1, 'Otakar Patton', '2018-Jan-6'),
  (2, 'Fulbert Sorenson', '2018-Jul-15'),
  (3, 'Fortunato Paredes', Null),
  (4, 'Elenora Willoughby', Null),
  (5, 'Aditya Jerome', '2019-Dec-22'),
  (6, 'Ivan Dreesen', '2015-Aug-1');
GO
CREATE FUNCTION ws.GetSubscriber (
  _subid integer,
  OUT _subname varchar(255),
  OUT _enddate timestamp 
)
AS $$
  SELECT Subscribers.SubName,
    Subscribers.EndDate
  FROM Subscribers
  WHERE Subscribers.SubId = _subid;
$$ LANGUAGE sql;
GO
CREATE SCHEMA ws;
GO
CREATE USER webUser WITH PASSWORD 'Pwd123456';
GO
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA ws TO webUser;
GO
