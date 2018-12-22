CREATE DATABASE CustomerShardUS;
GO
USE CustomerShardUS;
GO
CREATE SCHEMA ws;
GO
CREATE SCHEMA shd;
GO
CREATE SCHEMA ref;
GO
CREATE FUNCTION ws.ShardId()
RETURNS tinyint
AS
BEGIN
	RETURN 1;
END;
GO
CREATE USER webReader FROM LOGIN webReader;
GO
GRANT EXECUTE ON SCHEMA :: rd TO webReader;
GO
CREATE USER webWriter FROM LOGIN webWriter;
GO
GRANT EXECUTE ON SCHEMA :: wt TO webWriter;
GO
CREATE TABLE ref.CustomerTypes (
  CustomerTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  CONSTRAINT PK_RefCustomerTypes PRIMARY KEY (CustomerTypeId),
  CONSTRAINT UC_RefCustomerTypes_Name UNIQUE (Name)
);
GO
INSERT INTO ref.CustomerTypes (CustomerTypeId, Name)
VALUES (1, N'Walk-in'),
	(2, N'Subscriber'),
	(3, N'Franchisee'),
	(4, N'Partner');
GO
CREATE TABLE ref.LocationTypes (
  LocationTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  CONSTRAINT PK_RefLocationTypes PRIMARY KEY (LocationTypeId),
  CONSTRAINT UC_RefLocationTypes_Name UNIQUE (Name)
);
GO
INSERT INTO ref.LocationTypes(LocationTypeId, Name)
VALUES (1, 'Retail store'),
	(2, N'Pickup/dropoff'),
	(3, N'Warehouse'),
	(4, N'Office');

CREATE TABLE shd.Customers (
  CustomerId int NOT NULL,
  CustomerTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  --LocationId int NOT NULL,
  CONSTRAINT PK_ShdCustomers PRIMARY KEY (CustomerId),
  CONSTRAINT FK_ShdCustomers_CustomerTypeId FOREIGN KEY (CustomerTypeId) REFERENCES ref.CustomerTypes (CustomerTypeId)
);
GO
CREATE TABLE shd.Contacts (
	ContactId int NOT NULL,
	FullName nvarchar(255) NOT NULL,
	CONSTRAINT PK_ShdContacts PRIMARY KEY (ContactId)
);
GO
CREATE TABLE shd.CustomerContacts (
	CustomerId int NOT NULL,
	ContactShardId tinyint NOT NULL,
	ContactId int NOT NULL,
	CONSTRAINT PK_ShdCustomerContacts PRIMARY KEY (CustomerId, ContactId, ContactShardId),
	CONSTRAINT FK_ShdCustomerContacts_CustomerId FOREIGN KEY (CustomerId) REFERENCES shd.Customers (CustomerId)
);
GO
CREATE TABLE shd.ContactCustomers (
	ContactId int NOT NULL,
	CustomerShardId tinyint NOT NULL,
	CustomerId int NOT NULL,
	CONSTRAINT PK_ShdContactCustomers PRIMARY KEY (ContactId, CustomerId, CustomerShardId),
	CONSTRAINT FK_ShdContactCustomers_ContactId FOREIGN KEY (ContactId) REFERENCES shd.Contacts (ContactId)
);
GO
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
CREATE TYPE ws.RecordKeys AS TABLE (
	ShardId tinyint NOT NULL,
	RecordId int NOT NULL,
	PRIMARY KEY (ShardId, RecordId)
);
GO
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
GO
CREATE PROCEDURE rd.CustomerList
AS
BEGIN;
	SELECT Customers.CustomerId, Customers.Name
	FROM shd.Customers;
END;
GO
ALTER PROCEDURE rd.CustomerGet (
	@ShardId tinyint,
	@CustomerId int, 
	@CustomerTypeId tinyint OUTPUT, 
	@Name nvarchar(255) OUTPUT
	)
AS
BEGIN;
	SET NOCOUNT ON;

	IF @ShardId <> ws.ShardId()
	BEGIN;
		THROW 50001, N'The expected shard id is not valid. Data configuration metadata may be corrupted.', 16;
	END;

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
			AND CustomerContacts.ContactShardId = @ShardId
	WHERE CustomerContacts.CustomerId = @CustomerId;
END;
GO
CREATE PROCEDURE rd.ContactsGet(@ContactKeys ws.RecordKeys READONLY)
AS
BEGIN;
	DECLARE @ShardId tinyint = ws.ShardId();
	
	SELECT @ShardId As ContactShardId, Contacts.ContactId, Contacts.FullName 
	FROM shd.Contacts
		INNER JOIN @ContactKeys As ContactKeys
		ON ContactKeys.RecordId = Contacts.ContactId
			AND ContactKeys.ShardId = @ShardId;
END;
GO
CREATE PROCEDURE wt.CustomerDelete (@ShardId tinyint, @CustomerId int)
As
BEGIN;
	SET NOCOUNT ON;
	BEGIN TRY;
		BEGIN TRANSACTION;


		DELETE shd.ContactCustomers
		FROM shd.ContactCustomers
		WHERE ContactCustomers.CustomerShardId = @ShardId
			AND ContactCustomers.CustomerId = @CustomerId;

		IF @ShardId = ws.ShardId()
		BEGIN;
			DELETE shd.CustomerContacts
			FROM shd.CustomerContacts
			WHERE CustomerContacts.CustomerId = @CustomerId;

			DELETE shd.Locations
			FROM shd.Locations
			WHERE Locations.CustomerId = @CustomerId

			DELETE shd.Customers
			FROM shd.Customers
			WHERE Customers.CustomerId = @CustomerId
		END;
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH;
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW; 
	END CATCH;
END;
GO
CREATE PROCEDURE wt.CustomerSave (
	@ShardId tinyint,
	@CustomerId int,
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

		UPDATE shd.Customers
		SET Name = @Name,
			CustomerTypeId = @CustomerTypeId
		FROM shd.Customers
		WHERE Customers.CustomerId = @CustomerId
			AND (Customers.Name <> @Name OR Customers.CustomerTypeId <> @CustomerTypeId)


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
		SELECT Contacts.RecordId, @ShardId, @CustomerId
		FROM @Contacts As Contacts
			LEFT OUTER JOIN shd.ContactCustomers
			ON ContactCustomers.ContactId = Contacts.RecordId
				AND ContactCustomers.CustomerId = @CustomerId
				AND ContactCustomers.CustomerShardId = @ShardId
		WHERE Contacts.ShardId = @ShardId
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
CREATE PROCEDURE wt.CustomerCreate (
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
/* ========== Shard Data ========== */
INSERT INTO shd.Customers (CustomerId, CustomerTypeId, Name)
VALUES (1, 1, N'Labplus'),
	(2, 1, N'Planettom Inc.'),
	(3, 1, N'Matcanlax LLC'),
	(4, 2, N'Newcode Partners'),
	(5, 1, N'Redzim'),
	(6, 4, N'Namsantam'),
	(7, 1, N'Plexgreen Incorporated'),
	(8, 1, N'Trisplex'),
	(9, 3, N'Kayhouse Corp'),
	(10, 3, N'Meding LLC'),
	(11, 3, N'U-techno Inc.'),
	(12, 1, N'Hatcone'),
	(13, 2, N'Zum Planet'),
	(14, 1, N'Pan Tam LLC'),
	(15, 4, N'Zoom Tax'),
	(16, 3, N'MediaLux');
GO
INSERT INTO shd.Contacts (ContactId, FullName)
VALUES (1, N'Alexey Jagoda'),
	(2, N'Lynne Dukes'),
	(3, N'Orval Viteri'),
	(4, N'Mike Saunders'),
	(5, N'Marty Lewin'),
	(6, N'Riley Derrickson'),
	(7, N'Heard Sartor'),
	(8, N'Madalena Vroomen'),
	(9, N'Charleen Ríos'),
	(10, N'Mikey Ojeda'),
	(11, N'Deeann Sánchez'),
	(12, N'Antonia Stone'),
	(13, N'Josué Church'),
	(14, N'Ira Barros'),
	(15, N'Vivian Wyatt'),
	(16, N'Gideon White'),
	(17, N'Isidora Kimberley'),
	(18, N'Karina Molloy'),
	(19, N'Irma Appleby'),
	(20, N'Ophelia Haight'),
	(21, N'Anita Lundgren'),
	(22, N'Raúl Tolbert'),
	(23, N'Isabel Aylmer'),
	(24, N'Marylyn Carman'),
	(25, N'Paulina Viteri');
GO
INSERT INTO shd.CustomerLocalContacts (CustomerId, ContactId)
VALUES (1, 1),
	(2, 2),
	(2, 3),
	(3, 4),
	(3, 5),
	(3, 6),
	(4, 7),
	(5, 8),
	(6, 9),
	(7, 10),
	(8, 11),
	(9, 12),
	(10, 13),
	(11, 14),
	(11, 15),
	(12, 16),
	(12, 17),
	(12, 18),
	(13, 19),
	(13, 20),
	(14, 21),
	(14, 22),
	(15, 23),
	(15, 24),
	(16, 25);
	
INSERT INTO shd.Locations(CustomerId, LocationId, LocationTypeId, StreetAddress, Locality, Region, PostalCode, Iso3166, Latitude, Longitude)
VALUES (1, 1, 4, N'7391 N. Marsh Drive', N'Fremont', N'OH', N'43420', N'US', 41.355909200, -83.122007400),
	(1, 2, 4, N'6 Lafayette Street', N'Wasilla', N'AK', N'99654', N'US', 61.347218000, -150.032669400),
	(2, 1, 4, N'553 Blue Spring Lane', N'Hempstead', N'NY', N'11550', N'US', 40.698625700, -73.624185500),
	(3, 1, 1, N'285 Buttonwood Street', N'Ephrata', N'PA', N'17522', N'US', 40.175941700, -76.166780700),
	(3, 2, 1, N'720 Shore Street', N'Millville', N'NJ', N'08332', N'US', 39.357173800, -75.037750200),
	(3, 3, 4, N'233 Homewood Dr.', N'Hicksville', N'NY', N'11801', N'US', 40.762138800, -73.518183300),
	(4, 1, 1, N'154 Greenrose Drive', N'Fitchburg', N'MA', N'01420', N'US', 42.576869800, -71.833414500),
	(4, 2, 4, N'9498 Brook Lane', N'Chippewa Falls', N'WI', N'54729', N'US', 44.953096600, -91.482148200),
	(5, 1, 1, N'9824 Main Street', N'Indian Trail', N'NC', N'28079', N'US', 35.101964800, -80.599385400),
	(5, 2, 4, N'7664 Ridgeview Street', N'Grand Island', N'NE', N'68801', N'US', 40.962847400, -98.286947800),
	(5, 3, 1, N'7775 Monroe Drive', N'Old Bridge', N'NJ', N'08857', N'US', 40.387988900, -74.335285800),
	(5, 4, 1, N'397 S. Manor Street', N'Nazareth', N'PA', N'18064', N'US', 40.758117500, -75.317895200),
	(6, 1, 1, N'888 Buttonwood Drive', N'West Babylon', N'NY', N'11704', N'US', 40.718141600, -73.353185200),
	(6, 2, 4, N'8119 10th Road', N'West Lafayette', N'IN', N'47906', N'US', 40.493274300, -86.962408600),
	(7, 1, 1, N'2 East Pineknoll Lane', N'Osseo', N'MN', N'55311', N'US', 40.493274300, -86.962408600),
	(8, 1, 1, N'4 Pheasant Lane', N'Glendale Heights', N'IL', N'60139', N'US', 41.928376100, -88.075418800),
	(9, 1, 1, N'8063 Canterbury Avenue', N'Lorton', N'VA', N'22079', N'US', 38.667912300, -77.206024100),
	(9, 2, 4, N'333 Boston Drive', N'Lowell', N'MA', N'01851', N'US', 42.632572700, -71.340870700),
	(10, 1, 1, N'115 Thomas Drive', N'Lynchburg', N'VA', N'24502', N'US', 37.357978100, -79.176016100),
	(10, 2, 4, N'8392 N. Sage Street', N'New York', N'NY', N'10002', N'US', 40.713509700, -73.985941400),
	(10, 3, 3, N'8335 NW. Thorne Drive', N'San Angelo', N'TX', N'76901', N'US', 31.480113400, -100.642179900),
	(10, 4, 2, N'5 Fairway Drive', N'Brunswick', N'GA', N'31525', N'US', 31.326239100, -81.537701300),
	(10, 5, 2, N'9465 North Cedar Swamp Street', N'Sewell', N'NJ', N'08080', N'US', 39.762251600, -75.119510700),
	(10, 6, 1, N'13 Glen Ridge Street', N'Clementon', N'NJ', N'08021', N'US', 39.807376700, -75.002697200),
	(10, 7, 1, N'649 Redwood Street', N'Sebastian', N'FL', N'32958', N'US', 27.795499300, -80.488267200),
	(10, 8, 3, N'9259 Airport Avenue', N'Stuart', N'FL', N'34997', N'US', 27.103896300, -80.243283900),
	(11, 1, 1, N'15 Bellevue Street', N'West Des Moines', N'IA', N'50265', N'US', 41.550735700, -93.733353700),
	(11, 2, 4, N'178 Division Avenue', N'Salisbury', N'MD', N'21801', N'US', 38.400147400, -75.632447000),
	(11, 3, 1, N'7161 Branch Street', N'The Villages', N'FL', N'32162', N'US', 28.912116200, -81.986206000),
	(12, 1, 1, N'9110 Sierra Road', N'Waxhaw', N' NC', N'28173', N'US', 34.927455500, -80.743614100),
	(12, 2, 1, N'47 Court Street', N'Monsey', N'NY', N'10952', N'US', 41.109109100, -74.082883900),
	(12, 3, 4, N'65 West Golden Star Court', N'Brookfield', N'WI', N'53045', N'US', 43.053282500, -88.158412900),
	(12, 4, 3, N'488 E. Heather Road', N'Saugus', N'MA', N'01906', N'US', 42.468164200, -71.014118000),
	(12, 5, 2, N'513 E. Pleasant Drive', N'Elkhart', N'IN', N'46514', N'US', 41.720429900, -85.981533900),
	(13, 1, 3, N'358 Edgewater Drive', N'Naugatuck', N'CT', N'06770', N'US', 41.491015700, -73.052334000),
	(13, 2, 1, N'646 SE Goldfield Street', N'La Porte', N'IN', N'46350', N'US', 41.593919300, -86.701389400),
	(14, 1, 1, N'731 West Westminster Drive.', N'Norcross', N'GA', N'30092', N'US', 33.985186800, -84.238417000),
	(14, 2, 4, N'2 Lawrence Drive', N'Maspeth', N'NY', N'11378', N'US', 40.722409200, -73.909527900),
	(14, 3, 1, N'103 Acacia Drive', N'Milledgeville', N'GA', N'31061', N'US', 33.097556400, -83.229186200),
	(14, 4, 4, N'8095 W. Williams Road', N'Hamburg', N'NY', N'14075', N'US', 42.727983300, -78.860912200),
	(14, 5, 3, N'52 Mammoth Street', N'Southfield', N'MI', N'48076', N'US', 42.498672300, -83.239894300 ),
	(15, 1, 1, N'8173 Old Howard Street', N'Oak Park', N'MI', N'48237', N'US', 42.460965600, -83.180977600 ),
	(15, 2, 2, N'710 Griffin Lane', N'Yakima', N'WA', N'98908', N'US', 46.614284400, -120.732328000),
	(15, 3, 1, N'720 Broad Drive', N'Green Cove Springs', N'FL', N'32043', N'US', 29.945687400, -81.734942000),
	(16, 1, 1, N'3468 Bel Meadow Drive', N'Irvine', N'CA', N'92614', N'US', 33.683249700, -117.834073500);
GO

DECLARE @CustomerTypeId tinyint, @Name nvarchar(255);
EXECUTE ws.GetCustomer 2, @CustomerTypeId OUTPUT, @Name OUTPUT;
SELECT @CustomerTypeId, @Name
/*=============================================================*/
CREATE DATABASE CustomerShardEU;
GO
USE CustomerShardEU;
GO
CREATE SCHEMA rd;
GO
CREATE SCHEMA wt;
GO
CREATE FUNCTION ws.ShardId()
RETURNS tinyint
AS
BEGIN
	RETURN 2;
END;
GO
CREATE SCHEMA shd;
GO
CREATE SCHEMA ref;
GO
CREATE USER webReader FROM LOGIN webReader;
GO
CREATE USER webWriter FROM LOGIN webWriter;
GO
GRANT EXECUTE ON SCHEMA :: rd TO webReader;
GO
GRANT EXECUTE ON SCHEMA :: wt TO webWriter;
GO
CREATE TABLE ref.CustomerTypes (
  CustomerTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  CONSTRAINT PK_RefCustomerTypes PRIMARY KEY (CustomerTypeId),
  CONSTRAINT UC_RefCustomerTypes_Name UNIQUE (Name)
);
GO
INSERT INTO ref.CustomerTypes (CustomerTypeId, Name)
VALUES (1, N'Walk-in'),
	(2, N'Subscriber'),
	(3, N'Franchisee'),
	(4, N'Partner');
GO
CREATE TABLE ref.LocationTypes (
  LocationTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  CONSTRAINT PK_RefLocationTypes PRIMARY KEY (LocationTypeId),
  CONSTRAINT UC_RefLocationTypes_Name UNIQUE (Name)
);
GO
INSERT INTO ref.LocationTypes(LocationTypeId, Name)
VALUES (1, 'Retail store'),
	(2, N'Pickup/dropoff'),
	(3, N'Warehouse'),
	(4, N'Office');

CREATE TABLE shd.Customers (
  CustomerId int NOT NULL,
  CustomerTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  --LocationId int NOT NULL,
  CONSTRAINT PK_ShdCustomers PRIMARY KEY (CustomerId),
  CONSTRAINT FK_ShdCustomers_CustomerTypeId FOREIGN KEY (CustomerTypeId) REFERENCES ref.CustomerTypes (CustomerTypeId)
);
GO
CREATE TABLE shd.Contacts (
	ContactId int NOT NULL,
	FullName nvarchar(255) NOT NULL,
	CONSTRAINT PK_ShdContacts PRIMARY KEY (ContactId)
);
GO
CREATE TABLE shd.CustomerLocalContacts (
	ContactId int NOT NULL,
	CustomerId int NOT NULL,
	CONSTRAINT PK_ShdCustomerContacts PRIMARY KEY (ContactId, CustomerId),
	CONSTRAINT UC_ShdCustomerContacts_Customer UNIQUE (CustomerId, ContactId),
	CONSTRAINT FK_ShdCustomerContacts_ContactId FOREIGN KEY (CustomerId) REFERENCES shd.Customers (CustomerId),
	CONSTRAINT FK_ShdCustomerContacts_CustomerId FOREIGN KEY (ContactId) REFERENCES shd.Contacts (ContactId)
);
GO
CREATE TABLE shd.CustomerForeignContacts (
	CustomerId int NOT NULL,
	ContactShardId tinyint NOT NULL,
	ContactId int NOT NULL,
	CONSTRAINT PK_ShdCustomerForeignContacts PRIMARY KEY (CustomerId, ContactId, ContactShardId),
	CONSTRAINT FK_ShdCustomerForeignContacts_CustomerId FOREIGN KEY (CustomerId) REFERENCES shd.Customers (CustomerId)
);
GO
CREATE TABLE shd.ContactsForeignCustomers (
	ContactId int NOT NULL,
	CustomerShardId tinyint NOT NULL,
	CustomerId int NOT NULL,
	CONSTRAINT PK_ShdContactsForeignCustomers PRIMARY KEY (ContactId, CustomerShardId, CustomerId),
	CONSTRAINT FK_ShdContactsForeignCustomers_ContactId FOREIGN KEY (ContactId) REFERENCES shd.Contacts (ContactId)
);
GO
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
CREATE PROCEDURE rd.GetCustomer(@CustomerId int, @CustomerTypeId tinyint OUTPUT, @Name nvarchar(255) OUTPUT)
AS
BEGIN;
	SET NOCOUNT ON;

	DECLARE @ShardId tinyint;
	SET @ShardId = ws.ShardId();
	
	SELECT @CustomerTypeId = Customers.CustomerTypeId, @Name = Customers.Name
	FROM shd.Customers
	WHERE Customers.CustomerId = @CustomerId;

	SELECT Locations.LocationId, 
		Locations.LocationTypeId, 
		Locations.StreetAddress, 
		Locations.Locality, 
		Locations.Region,
		Locations.PostalCode,
		Locations.Latitude, 
		Locations.Longitude
	FROM shd.Locations
	WHERE Locations.CustomerId = @CustomerId

	SELECT @ShardId As ContactShardId, CustomerLocalContacts.ContactId, Contacts.FullName 
	FROM shd.Contacts
		INNER JOIN shd.CustomerLocalContacts
		ON CustomerLocalContacts.ContactId = Contacts.ContactId
	WHERE CustomerLocalContacts.CustomerId = @CustomerId
	UNION ALL SELECT CustomerForeignContacts.ContactShardId, CustomerForeignContacts.ContactId, Null
	FROM shd.CustomerForeignContacts
	WHERE CustomerForeignContacts.CustomerId = @CustomerId;

END;
GO
CREATE TYPE ws.RecordIds AS TABLE(
	RecordId int NOT NULL PRIMARY KEY
);
GO
CREATE PROCEDURE rd.GetContacts(@ContactIDs RecordIds READONLY)
As
BEGIN;

	DECLARE @ShardId tinyint;
	SET @ShardId = ws.ShardId();
	
	SELECT @ShardId As ContactShardId, Contacts.ContactId, Contacts.FullName 
	FROM shd.Contacts
		INNER JOIN @ContactIds As ContactIds
		ON ContactIds.RecordId = Contacts.ContactId

END;
GO
CREATE PROCEDURE wt.DeleteCustomer(@ShardId tinyint, @CustomerId int)
As
BEGIN;
	SET NOCOUNT ON;
	BEGIN TRY;
		BEGIN TRANSACTION;

		DELETE shd.CustomerForeignContacts
		FROM shd.CustomerForeignContacts
		WHERE CustomerForeignContacts.CustomerShardId = @ShardId
			AND CustomerForeignContacts.CustomerId = @CustomerId;

		IF @ShardId = ShardId()
		BEGIN;
			DELETE shd.Customers
			FROM shd.Customers
			WHERE Customers.CustomerId = @CustomerId

			DELETE shd.CustomerLocalContacts
			FROM shd.CustomerLocalContacts
			WHERE CustomerLocalContacts.CustomerId = @CustomerId

			DELETE shd.Locations
			FROM shd.Locations
			WHERE Locations.CustomerId = @CustomerId
		END;
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH;
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW; 
	END CATCH;
END;
GO
/* ========== Shard Data ========== */
INSERT INTO shd.Customers (CustomerId, CustomerTypeId, Name)
VALUES (1, 1, N'Swan & Son Ltd'),
	(2, 1, N'Dawson & Sanderson Ltd'),
	(3, 1, N'Pembrokeshire District Services'),
	(4, 2, N'Acacia Partnership Ltd'),
	(5, 4, N'Bayerischer Einzelhandel'),
	(6, 1, N'Kunststoffe der nächsten Generation'),
	(7, 3, N'Kapitalverkäufe'),
	(8, 1, N'Anzathix'),
	(9, 3, N'Experts de la Capitale du Nord-Ouest'),
	(10, 2, N'Solutions financières'),
	(11, 4, N'Services d’Investissement Regency'),
	(12, 1, N'Gruppo di Gestione Delle Vendite');
GO
INSERT INTO shd.Contacts (ContactId, FullName)
VALUES (1, N'Dionisia Cory'),
	(2, N'Kira Harland'),
	(3, N'Zach Keen'),
	(4, N'Sonia Busto'),
	(5, N'Tamara Joseph'),
	(6, N'Dorthy Devine'),
	(7, N'Willaiam Elliot'),
	(8, N'Wolfram Meier'),
	(9, N'Gustav Schöttmer'),
	(10, N'Elmo Brotz'),
	(11, N'Gertrud Bachmeier'),
	(12, N'Kilian Schirmer'),
	(13, N'Gabriel Albert'),
	(14, N'Zénaïde Rey'),
	(15, N'Stéphanie Charron'),
	(16, N'Cédric Laurent'),
	(17, N'Dionisia Serpico'),
	(18, N'Stefano Leoni');
GO
INSERT INTO shd.CustomerLocalContacts (ContactId, CustomerId)
VALUES (1, 1),
	(2, 2),
	(3, 3),
	(4, 3),
	(5, 3),
	(6, 4),
	(7, 4),
	(8, 5),
	(9, 6),
	(10, 7),
	(11, 7),
	(12, 8),
	(13, 9),
	(14, 9),
	(15, 10),
	(16, 11),
	(17, 12),
	(18, 12);

GO
INSERT INTO shd.Locations(CustomerId, LocationId, LocationTypeId, StreetAddress, Locality, Region, PostalCode, Iso3166, Latitude, Longitude)
VALUES (1, 1, 4, N'14 Bedford Way', N'North Shields', N'', N'NE29 6RX', N'UK', 55.012936, -1.448773),
	(1, 2, 4, N'95  Circle Way', N'Welney', N'', N'PE14 5UJ', N'UK', 52.528421, 0.278721),
	(2, 1, 1, N'77  Well Lane', N'Pebworth', N'', N'CV37 6UB', N'UK', 52.118293, -1.811528),
	(2, 2, 3, N'143  Sea Road', N'Lambley', N'', N'CA6 8AJ', N'UK', 53.001411, -1.061614),
	(2, 3, 4, N'62  Hart Road', N'Northfield', N'', N'B31 0NB', N'UK', 52.409470, -1.962783),
	(3, 1, 4, N'61  Uxbridge Road', N'Slade', N'', N'EX34 9YS', N'UK', 51.019879, -4.221757),
	(4, 1, 4, N'56  Iffley Road', N'Broadwell', N'', N'GL7 5FR', N'UK', 51.945479, -1.701910),
	(4, 2, 1, N'64  Scrimshire Lane', N'Aston Rogers', N'', N'SY5 5LF', N'UK', 52.652160, -2.973802),
	(4, 3, 2, N'78  Walwyn Rd', N'', N'Charleshill', N'GU10 6PP', N'UK', 51.193520, -0.723270),
	(5, 1, 1, N'Rathausstrasse 18', N'Nürnberg', N'Freistaat Bayern', N'90013', N'DE', 49.477293, 11.066000),
	(5, 2, 4, N'An Der Urania 9', N'Rosdorf', N'Niedersachsen', N'37124', N'DE', 51.505419, 9.900929),
	(6, 1, 1, N'Nuernbergerstrasse 41', N'Bargteheide', N'Schleswig-Holstein', N'22933', N'DE', 53.730731, 10.265551),
	(7, 1, 3, N'Eichendorffstr. 6', N'Rottenburg', N'Baden-Württemberg', N'72108', N'DE', 48.786614, 9.273656),
	(7, 2, 1, N'Storkower Strasse 64', N'Oberhaid', N'Rheinland-Pfalz', N'56237', N'DE', 49.944471, 10.795291),
	(7, 3, 3, N'Bleibtreustrasse 59', N'Gütersloh Isselhorst', N'Nordrhein-Westfalen', N'33334', N'DE', 51.947298, 8.409868),
	(8, 1, 1, N'Hans Schacksvej 39', N'Skovlunde', N'Region Sjælland', N'2740', N'DK', 55.716279, 12.396225),
	(9, 1, 1, N'65 Avenue Millies Lacroix', N'Dzaoudzi', N'Mayotte', N'97610', N'FR', -12.782605, 45.256703),
	(10, 1, 4, N'94 avenue Jean Portalis', N'Tulle', N'Limousin', N'19000', N'FR', 45.265885, 1.771127),
	(10, 2, 1, N'107 avenue de l', N'Bordeaux', N'Aquitaine', N'33000', N'FR', 44.841071, -0.591293),
	(11, 1, 1, N'92 rue de Geneve', N'Alfortville', N'Île-de-France', N'94140', N'FR', 48.801123, 2.421776),
	(11, 2, 3, N'89 avenue Jules Ferry', N'Soissons', N'Picardie', N'02200', N'FR', 49.380018, 3.321288),
	(11, 3, 4, N'38 Rue Frédéric Chopin', N'Tarbes', N'Midi-Pyrénées', N'65000', N'FR', 43.231348, 0.071465),
	(11, 4, 3, N'20 rue des Lacs', N'Hénin-Beaumont', N'Nord-Pas-de-Calais', N'62110', N'FR', 50.413327, 2.954768),
	(12, 1, 1, N'Via Torre di Mezzavia 72', N'Villagrande', N'Chieti', N'66020', N'IT', 42.329558, 14.364362),
	(12, 2, 4, N'Via Lagrange 60', N'Celleno', N'Viterbo', N'01020', N'IT', 42.558882, 12.128616);
GO
/*=============================================================*/
CREATE DATABASE CustomerShardBR;
GO
USE CustomerShardBR;
GO
CREATE SCHEMA rd;
GO
CREATE SCHEMA wt;
GO
CREATE FUNCTION ws.ShardId()
RETURNS tinyint
AS
BEGIN
	RETURN 2;
END;
GO
CREATE SCHEMA shd;
GO
CREATE SCHEMA ref;
GO
CREATE USER webReader FROM LOGIN webReader;
GO
CREATE USER webWriter FROM LOGIN webWriter;
GO
GRANT EXECUTE ON SCHEMA :: rd TO webReader;
GO
GRANT EXECUTE ON SCHEMA :: wt TO webWriter;
GO
CREATE TABLE ref.CustomerTypes (
  CustomerTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  CONSTRAINT PK_RefCustomerTypes PRIMARY KEY (CustomerTypeId),
  CONSTRAINT UC_RefCustomerTypes_Name UNIQUE (Name)
);
GO
INSERT INTO ref.CustomerTypes (CustomerTypeId, Name)
VALUES (1, N'Walk-in'),
	(2, N'Subscriber'),
	(3, N'Franchisee'),
	(4, N'Partner');
GO
CREATE TABLE ref.LocationTypes (
  LocationTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  CONSTRAINT PK_RefLocationTypes PRIMARY KEY (LocationTypeId),
  CONSTRAINT UC_RefLocationTypes_Name UNIQUE (Name)
);
GO
INSERT INTO ref.LocationTypes(LocationTypeId, Name)
VALUES (1, 'Retail store'),
	(2, N'Pickup/dropoff'),
	(3, N'Warehouse'),
	(4, N'Office');

CREATE TABLE shd.Customers (
  CustomerId int NOT NULL,
  CustomerTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  --LocationId int NOT NULL,
  CONSTRAINT PK_ShdCustomers PRIMARY KEY (CustomerId),
  CONSTRAINT FK_ShdCustomers_CustomerTypeId FOREIGN KEY (CustomerTypeId) REFERENCES ref.CustomerTypes (CustomerTypeId)
);
GO
CREATE TABLE shd.Contacts (
	ContactId int NOT NULL,
	FullName nvarchar(255) NOT NULL,
	CONSTRAINT PK_ShdContacts PRIMARY KEY (ContactId)
);
GO
CREATE TABLE shd.CustomerLocalContacts (
	ContactId int NOT NULL,
	CustomerId int NOT NULL,
	CONSTRAINT PK_ShdCustomerContacts PRIMARY KEY (ContactId, CustomerId),
	CONSTRAINT UC_ShdCustomerContacts_Customer UNIQUE (CustomerId, ContactId),
	CONSTRAINT FK_ShdCustomerContacts_ContactId FOREIGN KEY (CustomerId) REFERENCES shd.Customers (CustomerId),
	CONSTRAINT FK_ShdCustomerContacts_CustomerId FOREIGN KEY (ContactId) REFERENCES shd.Contacts (ContactId)
);
GO
CREATE TABLE shd.CustomerForeignContacts (
	CustomerId int NOT NULL,
	ContactShardId tinyint NOT NULL,
	ContactId int NOT NULL,
	CONSTRAINT PK_ShdCustomerForeignContacts PRIMARY KEY (CustomerId, ContactId, ContactShardId),
	CONSTRAINT FK_ShdCustomerForeignContacts_CustomerId FOREIGN KEY (CustomerId) REFERENCES shd.Customers (CustomerId)
);
GO
CREATE TABLE shd.ContactsForeignCustomers (
	ContactId int NOT NULL,
	CustomerShardId tinyint NOT NULL,
	CustomerId int NOT NULL,
	CONSTRAINT PK_ShdContactsForeignCustomers PRIMARY KEY (ContactId, CustomerShardId, CustomerId),
	CONSTRAINT FK_ShdContactsForeignCustomers_ContactId FOREIGN KEY (ContactId) REFERENCES shd.Contacts (ContactId)
);
GO
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
CREATE PROCEDURE rd.GetCustomer(@CustomerId int, @CustomerTypeId tinyint OUTPUT, @Name nvarchar(255) OUTPUT)
AS
BEGIN;
	SET NOCOUNT ON;

	DECLARE @ShardId tinyint;
	SET @ShardId = ws.ShardId();
	
	SELECT @CustomerTypeId = Customers.CustomerTypeId, @Name = Customers.Name
	FROM shd.Customers
	WHERE Customers.CustomerId = @CustomerId;

	SELECT Locations.LocationId, 
		Locations.LocationTypeId, 
		Locations.StreetAddress, 
		Locations.Locality, 
		Locations.Region,
		Locations.PostalCode,
		Locations.Latitude, 
		Locations.Longitude
	FROM shd.Locations
	WHERE Locations.CustomerId = @CustomerId

	SELECT @ShardId As ContactShardId, CustomerLocalContacts.ContactId, Contacts.FullName 
	FROM shd.Contacts
		INNER JOIN shd.CustomerLocalContacts
		ON CustomerLocalContacts.ContactId = Contacts.ContactId
	WHERE CustomerLocalContacts.CustomerId = @CustomerId
	UNION ALL SELECT CustomerForeignContacts.ContactShardId, CustomerForeignContacts.ContactId, Null
	FROM shd.CustomerForeignContacts
	WHERE CustomerForeignContacts.CustomerId = @CustomerId;

END;
GO
CREATE TYPE ws.RecordIds AS TABLE(
	RecordId int NOT NULL PRIMARY KEY
);
GO
CREATE PROCEDURE rd.GetContacts(@ContactIDs RecordIds READONLY)
As
BEGIN;

	DECLARE @ShardId tinyint;
	SET @ShardId = ws.ShardId();
	
	SELECT @ShardId As ContactShardId, Contacts.ContactId, Contacts.FullName 
	FROM shd.Contacts
		INNER JOIN @ContactIds As ContactIds
		ON ContactIds.RecordId = Contacts.ContactId

END;
GO
CREATE PROCEDURE wt.DeleteCustomer(@ShardId tinyint, @CustomerId int)
As
BEGIN;
	SET NOCOUNT ON;
	BEGIN TRY;
		BEGIN TRANSACTION;

		DELETE shd.CustomerForeignContacts
		FROM shd.CustomerForeignContacts
		WHERE CustomerForeignContacts.CustomerShardId = @ShardId
			AND CustomerForeignContacts.CustomerId = @CustomerId;

		IF @ShardId = ShardId()
		BEGIN;
			DELETE shd.Customers
			FROM shd.Customers
			WHERE Customers.CustomerId = @CustomerId

			DELETE shd.CustomerLocalContacts
			FROM shd.CustomerLocalContacts
			WHERE CustomerLocalContacts.CustomerId = @CustomerId

			DELETE shd.Locations
			FROM shd.Locations
			WHERE Locations.CustomerId = @CustomerId
		END;
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH;
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW; 
	END CATCH;
END;
GO
/* ========== Shard Data ========== */
INSERT INTO shd.Customers (CustomerId, CustomerTypeId, Name)
VALUES (1, 1, N'Recursos de Liquidação Financeira'),
	(2, 3, N'Especialistas em Restaurantes'),
	(3, 1, N'Especialistas em Automação'),
	(4, 3, N'Grupo de Consultoria Financeira'),
	(5, 3, N'Junta Internacional de Viajes'),
	(6, 1, N'El Club para el Servicio Juvenil'),
	(7, 2, N'Los Especialistas en Ventas y Marketing.'),
	(8, 2, N'La Tienda de Autopartes'),
	(9, 2, N'El Banco de la Paz');
GO
INSERT INTO shd.Contacts (ContactId, FullName)
VALUES (1, N'Modesto Fernandes'),
	(2, N'Dênis Palmeiro'),
	(3, N'Estefânia Mateus'),
	(4, N'Toni Alves'),
	(5, N'Bernardo David'),
	(6, N'Maristela Mata'),
	(7, N'Serafina Cardoso'),
	(8, N'Octávio Henriques'),
	(9, N'Herminio Santos'),
	(10, N'Eberardo Duarte'),
	(11, N'Raymundo Villanueva'),
	(12, N'Genoveva Cabrera'),
	(13, N'Laura Cruz'),
	(14, N'Basilio Nieves'),
	(15, N'Eric Ortega'),
	(16, N'Basilio Nieves'),
	(17, N'Griselda Giménez'),
	(18, N'Roberta Castellano');
GO
INSERT INTO shd.CustomerLocalContacts (ContactId, CustomerId)
VALUES (1, 1),
	(2, 1),
	(3, 1),
	(4, 2),
	(5, 2),
	(6, 3),
	(7, 3),
	(8, 4),
	(9, 4),
	(10, 5),
	(11, 5),
	(12, 5),
	(13, 6),
	(14, 7),
	(15, 8),
	(16, 8),
	(17, 9),
	(18, 9);
GO
INSERT INTO shd.Locations(LocationId, CustomerId, LocationTypeId, StreetAddress, Locality, Region, PostalCode, Iso3166, Latitude, Longitude)
VALUES (1, 1, 1, N'Rua Palmares 271', N'Teresina', N'Piauí', N'64017-760', N'BR', -5.093374, -42.751256),
	(1, 2, 4, N'Avenida Geraldo Hilário da Silva 1161', N'Araraquara', N'São Paulo', N'14805-290', N'BR', -21.779457, -48.178341),
	(2, 1, 1, N'Alameda A 703', N'Vila Velha', N'Espírito Santo', N'29129-654', N'BR', -20.370124, -40.316256),
	(2, 2, 4, N'Avenida Sebastião Eugênio de Camargo 489', N'São Paulo', N'São Paulo', N'05360-010', N'BR', -23.592837, -46.662626),
	(3, 1, 1, N'Rua Nova Palma 1505', N'Santa Maria', N'Rio Grande do Sul', N'97040-350', N'BR', -29.673561, -53.817593),
	(4, 1, 1, N'Rua José Bandeira 337', N'São Paulo', N'São Paulo', N'03480-110', N'BR', -23.669583, -46.680479),
	(4, 2, 4, N'Rua Ana Miranda Jesus de Souza 679', N'Itapecerica da Serra', N'São Paulo', N'06864-196', N'BR', -23.707634, -46.857147),
	(4, 3, 2, N'Rua João Rocha 219', N'São Paulo', N'São Paulo', N'04437-030', N'BR', -23.475744, -46.702451),
	(4, 4, 2, N'Rua Pedro Furlan 419', N'Indaiatuba', N'São Paulo', N'13345-445', N'BR', -23.081925, -47.210416),
	(5, 1, 4, N'J Morganti 8885', N'Loma Hermosa', N'Buenos Aires', N'', N'AR', -34.568455, -58.605372),
	(5, 2, 1, N'Bme Mitre 150', N'San Carlos de Bariloche', N'Río Negro', N'', N'AR', -41.126716, -71.370820),
	(6, 1, 4, N'Irlanda 172', N'San Pedro', N'Buenos Aires', N'', N'AR', -33.679337, -59.663550),
	(6, 2, 1, N'P Lagrave 828', N'Pilar', N'Buenos Aires', N'', N'AR', -34.478305, -58.923777),
	(6, 3, 2, N'Rioja 82', N'Mendoza', N'Mendoza', N'', N'AR', -32.873815, -68.836375),
	(6, 4, 3, N'15 1136', N'La Plata', N'Buenos Aires', N'', N'AR', -34.913767, -57.962784),
	(7, 1, 4, N'Jr. Torres Paz 1252 - Sta Beatriz', N'Lima', N'', N'Lima', N'PE', -12.058166, -77.052333),
	(7, 2, 1, N'Jirón Petronila Álvarez, 2323', N'El Cercado', N'Lima', N'', N'PE', -12.064880, -77.127864),
	(7, 3, 2, N'Av. Isabel La Católica 103-La Victoria', N'Lima', N'Lima y Callao', N'', N'PE', -12.054137, -77.055767),
	(8, 1, 2, N'Avenida Pablo Neruda, 02461', N'IX Región', N'Temuco', N'', N'CL', -38.738442, -72.618172),
	(9, 1, 3, N'Av. Chacaltaya final # 4', N'', N'La Paz', N'', N'BO', -16.496424, -68.129659);
GO
/*=============================================================*/
CREATE DATABASE CustomerShardZH;
GO
USE CustomerShardZH;
GO
CREATE SCHEMA rd;
GO
CREATE SCHEMA wt;
GO
CREATE FUNCTION ws.ShardId()
RETURNS tinyint
AS
BEGIN
	RETURN 2;
END;
GO
CREATE SCHEMA shd;
GO
CREATE SCHEMA ref;
GO
CREATE USER webReader FROM LOGIN webReader;
GO
CREATE USER webWriter FROM LOGIN webWriter;
GO
GRANT EXECUTE ON SCHEMA :: rd TO webReader;
GO
GRANT EXECUTE ON SCHEMA :: wt TO webWriter;
GO
CREATE TABLE ref.CustomerTypes (
  CustomerTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  CONSTRAINT PK_RefCustomerTypes PRIMARY KEY (CustomerTypeId),
  CONSTRAINT UC_RefCustomerTypes_Name UNIQUE (Name)
);
GO
INSERT INTO ref.CustomerTypes (CustomerTypeId, Name)
VALUES (1, N'Walk-in'),
	(2, N'Subscriber'),
	(3, N'Franchisee'),
	(4, N'Partner');
GO
CREATE TABLE ref.LocationTypes (
  LocationTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  CONSTRAINT PK_RefLocationTypes PRIMARY KEY (LocationTypeId),
  CONSTRAINT UC_RefLocationTypes_Name UNIQUE (Name)
);
GO
INSERT INTO ref.LocationTypes(LocationTypeId, Name)
VALUES (1, 'Retail store'),
	(2, N'Pickup/dropoff'),
	(3, N'Warehouse'),
	(4, N'Office');

CREATE TABLE shd.Customers (
  CustomerId int NOT NULL,
  CustomerTypeId tinyint NOT NULL,
  Name nvarchar(255) NOT NULL,
  --LocationId int NOT NULL,
  CONSTRAINT PK_ShdCustomers PRIMARY KEY (CustomerId),
  CONSTRAINT FK_ShdCustomers_CustomerTypeId FOREIGN KEY (CustomerTypeId) REFERENCES ref.CustomerTypes (CustomerTypeId)
);
GO
CREATE TABLE shd.Contacts (
	ContactId int NOT NULL,
	FullName nvarchar(255) NOT NULL,
	CONSTRAINT PK_ShdContacts PRIMARY KEY (ContactId)
);
GO
CREATE TABLE shd.CustomerLocalContacts (
	ContactId int NOT NULL,
	CustomerId int NOT NULL,
	CONSTRAINT PK_ShdCustomerContacts PRIMARY KEY (ContactId, CustomerId),
	CONSTRAINT UC_ShdCustomerContacts_Customer UNIQUE (CustomerId, ContactId),
	CONSTRAINT FK_ShdCustomerContacts_ContactId FOREIGN KEY (CustomerId) REFERENCES shd.Customers (CustomerId),
	CONSTRAINT FK_ShdCustomerContacts_CustomerId FOREIGN KEY (ContactId) REFERENCES shd.Contacts (ContactId)
);
GO
CREATE TABLE shd.CustomerForeignContacts (
	CustomerId int NOT NULL,
	ContactShardId tinyint NOT NULL,
	ContactId int NOT NULL,
	CONSTRAINT PK_ShdCustomerForeignContacts PRIMARY KEY (CustomerId, ContactId, ContactShardId),
	CONSTRAINT FK_ShdCustomerForeignContacts_CustomerId FOREIGN KEY (CustomerId) REFERENCES shd.Customers (CustomerId)
);
GO
CREATE TABLE shd.ContactsForeignCustomers (
	ContactId int NOT NULL,
	CustomerShardId tinyint NOT NULL,
	CustomerId int NOT NULL,
	CONSTRAINT PK_ShdContactsForeignCustomers PRIMARY KEY (ContactId, CustomerShardId, CustomerId),
	CONSTRAINT FK_ShdContactsForeignCustomers_ContactId FOREIGN KEY (ContactId) REFERENCES shd.Contacts (ContactId)
);
GO
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
CREATE PROCEDURE rd.GetCustomer(@CustomerId int, @CustomerTypeId tinyint OUTPUT, @Name nvarchar(255) OUTPUT)
AS
BEGIN;
	SET NOCOUNT ON;

	DECLARE @ShardId tinyint;
	SET @ShardId = ws.ShardId();
	
	SELECT @CustomerTypeId = Customers.CustomerTypeId, @Name = Customers.Name
	FROM shd.Customers
	WHERE Customers.CustomerId = @CustomerId;

	SELECT Locations.LocationId, 
		Locations.LocationTypeId, 
		Locations.StreetAddress, 
		Locations.Locality, 
		Locations.Region,
		Locations.PostalCode,
		Locations.Latitude, 
		Locations.Longitude
	FROM shd.Locations
	WHERE Locations.CustomerId = @CustomerId

	SELECT @ShardId As ContactShardId, CustomerLocalContacts.ContactId, Contacts.FullName 
	FROM shd.Contacts
		INNER JOIN shd.CustomerLocalContacts
		ON CustomerLocalContacts.ContactId = Contacts.ContactId
	WHERE CustomerLocalContacts.CustomerId = @CustomerId
	UNION ALL SELECT CustomerForeignContacts.ContactShardId, CustomerForeignContacts.ContactId, Null
	FROM shd.CustomerForeignContacts
	WHERE CustomerForeignContacts.CustomerId = @CustomerId;

END;
GO
CREATE TYPE ws.RecordIds AS TABLE(
	RecordId int NOT NULL PRIMARY KEY
);
GO
CREATE PROCEDURE rd.GetContacts(@ContactIDs RecordIds READONLY)
As
BEGIN;

	DECLARE @ShardId tinyint;
	SET @ShardId = ws.ShardId();
	
	SELECT @ShardId As ContactShardId, Contacts.ContactId, Contacts.FullName 
	FROM shd.Contacts
		INNER JOIN @ContactIds As ContactIds
		ON ContactIds.RecordId = Contacts.ContactId

END;
GO
CREATE PROCEDURE wt.DeleteCustomer(@ShardId tinyint, @CustomerId int)
As
BEGIN;
	SET NOCOUNT ON;
	BEGIN TRY;
		BEGIN TRANSACTION;

		DELETE shd.CustomerForeignContacts
		FROM shd.CustomerForeignContacts
		WHERE CustomerForeignContacts.CustomerShardId = @ShardId
			AND CustomerForeignContacts.CustomerId = @CustomerId;

		IF @ShardId = ShardId()
		BEGIN;
			DELETE shd.Customers
			FROM shd.Customers
			WHERE Customers.CustomerId = @CustomerId

			DELETE shd.CustomerLocalContacts
			FROM shd.CustomerLocalContacts
			WHERE CustomerLocalContacts.CustomerId = @CustomerId

			DELETE shd.Locations
			FROM shd.Locations
			WHERE Locations.CustomerId = @CustomerId
		END;
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH;
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		THROW; 
	END CATCH;
END;
GO
/* ========== Shard Data ========== */
INSERT INTO shd.Customers (CustomerId, CustomerTypeId, Name)
VALUES (1, 1, N'段飞机零件'),
	(2, 1, N'杭州汽车打捞'),
	(3, 1, N'最好的早餐咖啡馆'),
	(4, 2, N'美国健身房'),
	(5, 1, N'设计师鲜花'),
	(6, 4, N'금속 가공 회사'),
	(7, 1, N'종이 가게'),
	(8, 1, N'장난감 및 학습 도구'),
	(9, 1, N'庭の供給店'), --jp
	(10, 4, N'ผลิตภัณฑ์กระดาษไทย'); --th
GO
INSERT INTO shd.Contacts (ContactId, FullName)
VALUES (1, N'段留贤'),
	(2, N'王若刚'),
	(3, N'霍海'),
	(4, N'董文'),
	(5, N'秦德'),
	(6, N'宣芬'),
	(7, N'曾泽民'),
	(8, N'高达'),
	(9, N'冯周'),
	(10, N'罗忠'),
	(11, N'학 광혁'),
	(12, N'윤영재'),
	(13, N'화승현'), 
	(14, N'매대정'), --jp
	(15, N'솔상훈'), --jp
	(16, N'เนติบัณฑิตชินวัตร'), --thai
	(17, N'คุณหมั่นไพบูลย์');
GO
INSERT INTO shd.CustomerLocalContacts (ContactId, CustomerId)
VALUES (1, 1),
(2, 1),
(3, 2),
(4, 2),
(5, 3),
(6, 4),
(7, 4),
(8, 4),
(9, 5),
(10, 5),
(11, 6),
(12, 6),
(13, 7),
(14, 8),
(15, 8),
(16, 9),
(17, 10);
GO
INSERT INTO shd.Locations(CustomerId, LocationId, LocationTypeId, StreetAddress, Locality, Region, PostalCode, Iso3166, Latitude, Longitude)
VALUES (1, 1, 4, N'24楼416', N'哈尔滨市-南岗区', N'黑龙江省', N'150080', N'ZH', 0.0, 0.0),
(1, 2, 1, N'', N'', N'', N'', N'ZH', 0.0, 0.0),
(1, 3, 2, N'青年路西里二号院五号楼三单元501室', N'市区-朝阳区', N'北京市', N'100123', N'ZH', 39.932229, 116.323272),
(2, 1, 1, N'万航渡路83号金航大厦22楼', N'市区-静安区', N'上海市', N'200040', N'ZH', 31.233550, 121.449087),
(2, 2, 4, N'4-5-401', N'市区-西城区', N'北京市', N'100055', N'ZH', 39.912480, 116.351133),
(3, 1, 1, N'金沙江路875弄23号602室', N'市区-普陀区', N'上海市', N'200062', N'ZH', 31.267605, 121.399066),
(3, 2, 2, N'湖南路55号A座17层', N'青岛市', N'山东省', N'266041', N'ZH', 36.141706, 120.366180),
(3, 3, 4, N'沙井大道华南城招商中心广西北部湾银行华南城支行', N'南宁市-江南区', N'广西壮族自治区', N'530031', N'ZH', 22.616268, 108.201032),
(3, 4, 2, N'总府路2号时代广场A座20层', N'成都市-锦江区', N'四川省', N'610016', N'ZH', 30.622447, 104.103105),
(4, 1, 4, N'东方路573弄4号907室', N'市辖区', N'上海市', N'200092', N'ZH', 31.203378, 121.401340),
(4, 2, 1, N'五一北路110号海鑫大厦7楼', N'福州市-鼓楼区', N'福建省', N'350001', N'ZH', 26.080195, 119.281127),
(5, 1, 1, N'49 토기로 18 길 남산동 2 (i) -가', N'중구', N'서울', N'', N'KO', 37.551750, 126.978887),
(6, 1, 4, N'신길로41가길 ', N'영등포구', N'서울', N'', N'KO', 37.507870, 126.909282),
(7, 1, 4, N'창동 657-119', N'도봉구', N'서울', N'', N'KO', 37.647579, 127.036123),
(7, 2, 3, N'상도로47마길', N'동학구', N'서울', N'', N'KO', 37.501784, 126.950414),
(8, 1, 1, N'송림길', N'전주', N'강원도', N'', N'KO', 35.836534, 139.468500),
(9, 1, 4, N'1丁目 - 34-17めぐり町', N'東村山市', N'東京都', N'189-0025', N'JP', 35.745289, 139.439890),
(9, 2, 1, N'東洋汽缶工業所', N'大坂市', N'浪和区', N'', N'JP', 34.662983, 135.490868),
(10, 1, 4, N'148 ซอยแจ้งวัฒนะ 29', N'วัดวาอาราม, เขตบางกอกใหญ่', N'กรุงเทพมหานคร', N'10600', N'TH', 13.741124, 100.479173);
GO
