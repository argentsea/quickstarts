/*
Run this SQL script on each shard to initialize structures.
Afterward, run the 2nd script to populate the shard-specific data.
*/

-- CREATE USERS
IF NOT EXISTS (SELECT 1 FROM sys.sysusers WHERE name = N'webReader')
BEGIN;
	CREATE USER webReader FROM LOGIN webReader;
END;
GRANT CONNECT TO webReader;
IF NOT EXISTS (SELECT 1 FROM sys.sysusers WHERE name = N'webWriter')
BEGIN;
	CREATE USER webWriter FROM LOGIN webWriter;
END;
GRANT CONNECT TO webWriter;
GO
-- CREATE SCHEMAS
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'ws')
BEGIN;
	EXECUTE sp_executesql N'CREATE SCHEMA ws;';
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'shd')
BEGIN;
	EXECUTE sp_executesql N'CREATE SCHEMA shd;';
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'ref')
BEGIN;
	EXECUTE sp_executesql N'CREATE SCHEMA ref;';
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'rd')
BEGIN;
	EXECUTE sp_executesql N'CREATE SCHEMA rd;';
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'wt')
BEGIN;
	EXECUTE sp_executesql N'CREATE SCHEMA wt;';
END;
GO
GRANT EXECUTE ON SCHEMA :: rd TO webReader;
GRANT EXECUTE ON SCHEMA :: wt TO webWriter;

-- DROP SHARD TABLES, IF THEY EXIST
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'ContactCustomers')
BEGIN;
	DROP TABLE shd.ContactCustomers;
END;
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'CustomerContacts')
BEGIN;
	DROP TABLE shd.CustomerContacts;
END;
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Contacts')
BEGIN;
	DROP TABLE shd.Contacts;
END;
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Locations')
BEGIN;
	DROP TABLE shd.Locations;
END;
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = N'Customers')
BEGIN;
	DROP TABLE shd.Customers;
END;
-- DROP AND RECREATE REFERENCE TABLES
IF EXISTS (SELECT * FROM sys.tables WHERE name = N'CustomerTypes')
BEGIN;
	DROP TABLE ref.CustomerTypes;
END;
CREATE TABLE ref.CustomerTypes (
  CustomerTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  CONSTRAINT PK_RefCustomerTypes PRIMARY KEY (CustomerTypeId),
  CONSTRAINT UC_RefCustomerTypes_Name UNIQUE (Name)
);
INSERT INTO ref.CustomerTypes (CustomerTypeId, Name)
VALUES (1, N'Walk-in'),
	(2, N'Subscriber'),
	(3, N'Franchisee'),
	(4, N'Partner');
GO
IF EXISTS (SELECT * FROM sys.tables WHERE name = N'LocationTypes')
BEGIN;
	DROP TABLE ref.LocationTypes;
END;
CREATE TABLE ref.LocationTypes (
  LocationTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  CONSTRAINT PK_RefLocationTypes PRIMARY KEY (LocationTypeId),
  CONSTRAINT UC_RefLocationTypes_Name UNIQUE (Name)
);
INSERT INTO ref.LocationTypes(LocationTypeId, Name)
VALUES (1, 'Retail store'),
	(2, N'Pickup/dropoff'),
	(3, N'Warehouse'),
	(4, N'Office');
GO
-- CREATE SHARD TABLES
CREATE TABLE shd.Customers (
  CustomerId int NOT NULL IDENTITY,
  CustomerTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  --LocationId int NOT NULL,
  CONSTRAINT PK_ShdCustomers PRIMARY KEY (CustomerId),
  CONSTRAINT FK_ShdCustomers_CustomerTypeId FOREIGN KEY (CustomerTypeId) REFERENCES ref.CustomerTypes (CustomerTypeId)
);
CREATE TABLE shd.Contacts (
	ContactId int NOT NULL IDENTITY,
	FullName nvarchar(255) NOT NULL,
	CONSTRAINT PK_ShdContacts PRIMARY KEY (ContactId)
);
CREATE TABLE shd.CustomerContacts (
	CustomerId int NOT NULL,
	ContactShardId tinyint NOT NULL,
	ContactId int NOT NULL,
	CONSTRAINT PK_ShdCustomerContacts PRIMARY KEY (CustomerId, ContactId, ContactShardId),
	CONSTRAINT FK_ShdCustomerContacts_CustomerId FOREIGN KEY (CustomerId) REFERENCES shd.Customers (CustomerId)
);
CREATE TABLE shd.ContactCustomers (
	ContactId int NOT NULL,
	CustomerShardId tinyint NOT NULL,
	CustomerId int NOT NULL,
	CONSTRAINT PK_ShdContactCustomers PRIMARY KEY (ContactId, CustomerId, CustomerShardId),
	CONSTRAINT FK_ShdContactCustomers_ContactId FOREIGN KEY (ContactId) REFERENCES shd.Contacts (ContactId)
);
CREATE TABLE shd.Locations (
	CustomerId int NOT NULL,
	LocationId smallint NOT NULL,
	LocationTypeId tinyint NOT NULL,
	StreetAddress nvarchar(255) NOT NULL,
	Locality nvarchar(100) NOT NULL,
	Region nvarchar(100) NOT NULL,
	PostalCode nvarchar(25) NOT NULL,
	Iso3166 nchar(2) NOT NULL,
	Latitude float NULL,
	Longitude float NULL,
	CONSTRAINT PK_ShdLocations PRIMARY KEY (CustomerId, LocationId),
	CONSTRAINT FK_ShdLocations_LocationTypes FOREIGN KEY (LocationTypeId) REFERENCES ref.LocationTypes (LocationTypeId),
	CONSTRAINT FK_ShdLocations_Customers FOREIGN KEY (CustomerId) REFERENCES shd.Customers (CustomerId)
);
GO
--CREATE TYPES
IF NOT EXISTS(SELECT * FROM sys.types WHERE name = N'RecordKeys')
BEGIN;
	CREATE TYPE ws.RecordKeys AS TABLE (
		ShardId tinyint NOT NULL,
		RecordId int NOT NULL,
		PRIMARY KEY (ShardId, RecordId)
	);
END;
GO
GRANT EXECUTE ON TYPE :: ws.RecordKeys TO webWriter;
GO
IF NOT EXISTS(SELECT * FROM sys.types WHERE name = N'CustomerLocations')
BEGIN;
	CREATE TYPE ws.CustomerLocations AS TABLE (
		LocationId smallint NOT NULL PRIMARY KEY,
		LocationTypeId tinyint NOT NULL,
		StreetAddress nvarchar(255) NOT NULL,
		Locality nvarchar(100) NOT NULL,
		Region nvarchar(100) NOT NULL,
		PostalCode nvarchar(25) NOT NULL,
		Iso3166 nchar(2) NOT NULL,
		Latitude float NULL,
		Longitude float NULL
		);
END;
GO
GRANT EXECUTE ON TYPE :: ws.CustomerLocations TO webWriter;
GO
-- CREATE STUB FUNCTION (to manage procedure dependencies)
CREATE OR ALTER FUNCTION ws.ShardId()
RETURNS tinyint
AS
BEGIN
	RETURN NULL;
END;
GO
CREATE OR ALTER PROCEDURE rd.CustomerList
AS
BEGIN;
	SELECT Customers.CustomerId, Customers.Name
	FROM shd.Customers;
END;
GO
CREATE OR ALTER PROCEDURE rd.CustomerGet (
	@CustomerId int, 
	@CustomerTypeId tinyint OUTPUT, 
	@Name nvarchar(255) OUTPUT
	)
AS
BEGIN;
	SET NOCOUNT ON;

	SELECT @CustomerTypeId = Customers.CustomerTypeId, @Name = Customers.Name
	FROM shd.Customers
	WHERE Customers.CustomerId = @CustomerId;

	SELECT @CustomerId As CustomerId,
		Locations.LocationId, 
		Locations.LocationTypeId, 
		Locations.StreetAddress, 
		Locations.Locality, 
		Locations.Region,
		Locations.PostalCode,
		Locations.Iso3166,
		Locations.Latitude, 
		Locations.Longitude
	FROM shd.Locations
	WHERE Locations.CustomerId = @CustomerId

	SELECT CustomerContacts.ContactShardId, CustomerContacts.ContactId, Contacts.FullName 
	FROM shd.CustomerContacts
		LEFT OUTER JOIN shd.Contacts
		ON CustomerContacts.ContactId = Contacts.ContactId
			AND CustomerContacts.ContactShardId = ws.ShardId()
	WHERE CustomerContacts.CustomerId = @CustomerId;
END;
GO
CREATE OR ALTER PROCEDURE rd.ContactsGet (
	@CustomerShardId tinyint,
	@CustomerId int
)
AS
BEGIN;
SET NOCOUNT ON;
	SELECT ws.ShardId() As ContactShardId, Contacts.ContactId, Contacts.FullName
	FROM shd.Contacts
		INNER JOIN shd.ContactCustomers
		ON ContactCustomers.ContactId = Contacts.Contactid
	WHERE ContactCustomers.CustomerShardId = @CustomerShardId
		AND ContactCustomers.CustomerId = @CustomerId;
END;
GO
CREATE OR ALTER PROCEDURE wt.CustomerDelete (
	@CustomerShardId tinyint,
	@CustomerId int
)
AS
BEGIN;
	SET NOCOUNT ON;
	BEGIN TRY;
		BEGIN TRANSACTION;

		SELECT DISTINCT CustomerContacts.ContactShardId
		FROM shd.CustomerContacts
		WHERE CustomerContacts.CustomerId = @CustomerId
			AND CustomerContacts.ContactShardId <> @CustomerShardId;

		DELETE FROM shd.ContactCustomers
		WHERE ContactCustomers.CustomerShardId = @CustomerShardId
			AND ContactCustomers.CustomerId = @CustomerId;

		DELETE FROM shd.CustomerContacts
		WHERE CustomerContacts.CustomerId = @CustomerId;

		DELETE FROM shd.Locations
		WHERE Locations.CustomerId = @CustomerId;

		DELETE FROM shd.Customers
		WHERE Customers.CustomerId = @CustomerId;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH;
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW; 
	END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE wt.CustomerSave (
	@CustomerId int,
	@CustomerTypeId tinyint,
	@Name nvarchar(255),
	@Contacts ws.RecordKeys READONLY,
	@Locations ws.CustomerLocations READONLY
	)
As
BEGIN;
	SET NOCOUNT ON;

	SELECT DISTINCT CustomerContacts.ContactShardId
	FROM shd.CustomerContacts
	WHERE CustomerContacts.CustomerId = @CustomerId
		AND CustomerContacts.ContactShardId <> ws.ShardId()
	UNION SELECT tmpContacts.ShardId
	FROM @Contacts As tmpContacts
	WHERE tmpContacts.ShardId <> ws.ShardId();

	BEGIN TRY;
		BEGIN TRANSACTION;

		SELECT DISTINCT CustomerContacts
		FROM shd.CustomerContacts

		UPDATE shd.Customers
		SET Name = @Name,
			CustomerTypeId = @CustomerTypeId
		FROM shd.Customers
		WHERE Customers.CustomerId = @CustomerId;

		MERGE shd.Locations As target
		USING @Locations As source
		ON (target.LocationId = source.LocationId AND target.CustomerId = @CustomerId)
		WHEN MATCHED AND (target.LocationTypeId <> source.LocationTypeId
			OR target.StreetAddress <> source.StreetAddress
			OR target.Locality <> source.Locality
			OR target.Region <> source.Region
			OR target.PostalCode <> source.PostalCode
			OR target.Iso3166 <> source.Iso3166
			OR target.Latitude <> source.Latitude
			OR target.Longitude <> source.Longitude) THEN 
		UPDATE SET LocationTypeId = source.LocationTypeId,
			StreetAddress = source.StreetAddress,
			Locality = source.Locality,
			Region = source.Region,
			PostalCode = source.PostalCode,
			Iso3166 = source.Iso3166,
			Latitude = source.Latitude,
			Longitude = source.Longitude
		WHEN NOT MATCHED BY target THEN 
			INSERT (CustomerId, LocationId, LocationTypeId, StreetAddress, Locality, Region, PostalCode, Iso3166, Latitude, Longitude)
			VALUES (@CustomerId, source.LocationId, source.LocationTypeId, source.StreetAddress, source.Locality, source.Region, source.PostalCode, source.Iso3166, source.Latitude, source.Longitude)
		WHEN NOT MATCHED BY source THEN DELETE;

		INSERT INTO shd.CustomerContacts (CustomerId, ContactShardId, ContactId)
		SELECT @CustomerId, Contacts.ShardId, Contacts.RecordId
		FROM @Contacts As Contacts
			LEFT OUTER JOIN shd.CustomerContacts
			ON CustomerContacts.ContactId = Contacts.RecordId
				AND CustomerContacts.CustomerId = @CustomerId
				AND CustomerContacts.ContactShardId = Contacts.ShardId
		WHERE CustomerContacts.ContactId Is Null;

		DELETE shd.CustomerContacts
		FROM shd.CustomerContacts
			LEFT OUTER JOIN @Contacts As Contacts
			ON CustomerContacts.ContactId = Contacts.RecordId
				AND CustomerContacts.ContactShardId = Contacts.ShardId
				AND CustomerContacts.CustomerId = @CustomerId
		WHERE Contacts.RecordId Is NULL;

		INSERT INTO shd.ContactCustomers (ContactId, CustomerShardId, CustomerId)
		SELECT Contacts.RecordId, ws.ShardId(), @CustomerId
		FROM @Contacts As Contacts
			LEFT OUTER JOIN shd.ContactCustomers
			ON ContactCustomers.ContactId = Contacts.RecordId
				AND ContactCustomers.CustomerId = @CustomerId
				AND ContactCustomers.CustomerShardId = ws.ShardId()
		WHERE Contacts.ShardId = ws.ShardId()
			AND ContactCustomers.ContactId Is NULL;

		DELETE shd.ContactCustomers
		FROM shd.ContactCustomers
			LEFT OUTER JOIN @Contacts As Contacts
			ON ContactCustomers.ContactId = Contacts.RecordId
				AND ContactCustomers.CustomerShardId = Contacts.ShardId
				AND ContactCustomers.CustomerId = @CustomerId
		WHERE Contacts.RecordId Is NULL;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH;
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW; 
	END CATCH;
END;
GO
CREATE OR ALTER PROCEDURE wt.CustomerCreate (
	@ShardId tinyint,
	@CustomerId int OUTPUT,
	@CustomerTypeId tinyint,
	@Name nvarchar(255),
	@Contacts ws.RecordKeys READONLY,
	@Locations ws.CustomerLocations READONLY
	)
As
BEGIN;
	IF @ShardId <> ws.ShardId()
	BEGIN;
		THROW 50001, N'The expected shard id is not valid. Data configuration metadata may be corrupted.', 16;
	END;
	SET NOCOUNT ON;
	BEGIN TRY;
		BEGIN TRANSACTION;

		INSERT INTO shd.Customers (CustomerTypeId, Name)
		VALUES (@CustomerTypeId, @Name);

		SET @CustomerId = SCOPE_IDENTITY();

		INSERT shd.Locations (CustomerId, LocationId, LocationTypeId, StreetAddress, Locality, Region, PostalCode, Iso3166, Latitude, Longitude)
		SELECT @CustomerId, Location.LocationId, Location.LocationTypeId, Location.StreetAddress, Location.Locality, 
			Location.Region, Location.PostalCode, Location.Iso3166, Location.Latitude, Location.Longitude
		FROM @Locations As Location;

		INSERT INTO shd.CustomerContacts (CustomerId, ContactShardId, ContactId)
		SELECT @CustomerId, Contacts.ShardId, Contacts.RecordId
		FROM @Contacts As Contacts;

		INSERT INTO shd.ContactCustomers (ContactId, CustomerShardId, CustomerId)
		SELECT Contacts.RecordId, @ShardId, @CustomerId
		FROM @Contacts As Contacts
		WHERE Contacts.ShardId = @ShardId;

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH;
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW; 
	END CATCH;
END;
GO
CREATE PROCEDURE wt.ContactCustomersCreate (
	@CustomerShardId tinyint,
	@CustomerId int,
	@Contacts ws.RecordKeys READONLY
)
AS
BEGIN;
	SET NOCOUNT ON;

	DELETE shd.ContactCustomers
	FROM shd.ContactCustomers
	WHERE ContactCustomers.Customerid = @CustomerId
		AND ContactCustomers.CustomerShardid = @CustomerShardId
		AND ContactCustomers.Contactid NOT IN (SELECT DISTINCT tmpContacts.RecordId FROM @Contacts As tmpContacts WHERE tmpContacts.ShardId = ws.Shardid());

	INSERT INTO shd.ContactCustomers (Customerid, CustomerShardId, Contactid)
	SELECT @CustomerId, @CustomerShardId, tmpContacts.RecordId
	FROM @Contacts As tmpContacts
		LEFT OUTER JOIN shd.ContactCustomers
		ON ContactCustomers.Customerid = @CustomerId
			AND ContactCustomers.CustomerShardid = @CustomerShardId
			AND ContactCustomers.Contactid = tmpContacts.RecordId
	WHERE tmpContacts.ShardId = ws.Shardid()
		AND ContactCustomers.Customerid Is NULL;
END;
GO
CREATE PROCEDURE wt.ContactCustomersDelete (
	@CustomerShardId tinyint,
	@CustomerId int
)
AS
BEGIN;
	SET NOCOUNT ON;

	DELETE shd.ContactCustomers
	FROM shd.ContactCustomers
	WHERE ContactCustomers.CustomerShardId = @CustomerShardId
		AND ContactCustomers.CustomerId = @CustomerId;
END;
GO