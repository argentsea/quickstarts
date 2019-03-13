/*
WARNING: Run the ShardSetup SQL script first!

This walkthrough creates 4 databases (shards), roughly corresponding to EU (Europe), US (North America), ZH (Asia),  and BR (South America).
After you have executed ServerSetup, and then run ShardSetup on each database, run this script on the US database.
*/
USE CustomerShardUS;
GO
-- CREATE FUNCTIONS
CREATE OR ALTER FUNCTION ws.ShardId()
RETURNS tinyint
AS
BEGIN
	RETURN 1;
END;
GO
DELETE FROM shd.ContactCustomers;
DELETE FROM shd.CustomerContacts;
DELETE FROM shd.Locations;
DELETE FROM shd.Customers;
DELETE FROM shd.Contacts;
GO
SET IDENTITY_INSERT shd.Customers ON;
GO
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
SET IDENTITY_INSERT shd.Customers OFF;
GO
SET IDENTITY_INSERT shd.Contacts ON;
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
SET IDENTITY_INSERT shd.Contacts OFF;
GO
INSERT INTO shd.ContactCustomers (CustomerId, CustomerShardId, ContactId)
VALUES (1, 1, 1),
	(2, 1, 2),
	(2, 1, 3),
	(3, 1, 4),
	(3, 1, 5),
	(3, 1, 6),
	(4, 1, 7),
	(5, 1, 8),
	(6, 1, 9),
	(7, 1, 10),
	(8, 1, 11),
	(9, 1, 12),
	(10, 1, 13),
	(11, 1, 14),
	(11, 1, 15),
	(12, 1, 16),
	(12, 1, 17),
	(12, 1, 18),
	(13, 1, 19),
	(13, 1, 20),
	(13, 4, 7), --foreign
	(14, 1, 21),
	(14, 1, 22),
	(15, 1, 23),
	(15, 1, 24),
	(16, 1, 25);
GO
INSERT INTO shd.CustomerContacts (CustomerId, ContactShardId, ContactId)
VALUES (1, 1, 1),
	(2, 1, 2),
	(2, 1, 3),
	(3, 1, 4),
	(3, 1, 5),
	(3, 1, 6),
	(4, 1, 7),
	(4, 2, 7), --foreign
	(5, 1, 8),
	(6, 1, 9),
	(7, 1, 10),
	(8, 1, 11),
	(9, 1, 12),
	(10, 1, 13),
	(11, 1, 14),
	(11, 1, 15),
	(12, 1, 16),
	(12, 1, 17),
	(12, 1, 18),
	(13, 1, 19),
	(13, 1, 20),
	(14, 1, 21),
	(14, 1, 22),
	(15, 1, 23),
	(15, 1, 24),
	(16, 1, 25);
	
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
