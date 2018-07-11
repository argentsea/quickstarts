CREATE DATABASE MyDb;
GO
USE MyDb;
GO
CREATE TABLE dbo.Subscribers (
  SubscriberId int NOT NULL,
  SubscriberName nvarchar(255) NOT NULL,
  EndDate datetime2,
  CONSTRAINT PK_Subscribers PRIMARY KEY (SubscriberId)
);
GO
INSERT INTO  dbo.Subscribers (SubId, SubName, EndDate)
VALUES (1, N'Otakar Patton', N'2018-Jan-6'),
  (2, N'Fulbert Sorenson', N'2018-Jul-15'),
  (3, N'Fortunato Paredes', Null),
  (4, N'Elenora Willoughby', Null),
  (5, N'Aditya Jerome', N'2019-Dec-22'),
  (6, N'Ivan Dreesen', N'2015-Aug-1');
GO
CREATE SCHEMA ws;
GO
CREATE LOGIN webUser WITH PASSWORD = N'Pwd123456';
GO
CREATE USER webUser FROM LOGIN webUser;
GO
GRANT EXECUTE ON SCHEMA :: ws TO webUser;
GO
CREATE PROCEDURE ws.GetSubscriber
  @SubscriberId int,
  @SubscriberName nvarchar(255) OUTPUT,
  @EndDate datetime2 OUTPUT
AS
BEGIN
  SELECT TOP 1 @SubscriberName = Subscribers.SubscriberName, 
    @EndDate = Subscribers.EndDate
  FROM dbo.Subscribers
  WHERE Subscribers.SubscriberId = @SubscriberId;
END;

