CREATE SCHEMA qs1;

CREATE TABLE IF NOT EXISTS qs1.Subscribers (
  SubId integer NOT NULL,
  SubName varchar(255) NOT NULL,
  EndDate timestamp,
  CONSTRAINT PK_Subscribers PRIMARY KEY (SubId)
);

INSERT INTO  qs1.Subscribers (SubId, SubName, EndDate)
VALUES (1, 'Otakar Patton', '2018-Jan-6'),
  (2, 'Fulbert Sorenson', '2018-Jul-15'),
  (3, 'Fortunato Paredes', Null),
  (4, 'Elenora Willoughby', Null),
  (5, 'Aditya Jerome', '2019-Dec-22'),
  (6, 'Ivan Dreesen', '2015-Aug-1');

CREATE USER webuser WITH PASSWORD 'Pwd123456';

GRANT USAGE ON SCHEMA qs1 TO webuser;
GRANT SELECT ON qs1.Subscribers TO webuser;

