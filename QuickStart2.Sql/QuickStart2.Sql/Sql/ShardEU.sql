/*
WARNING: Run the ShardSetup SQL script first!

This walkthrough creates 4 databases (shards), roughly corresponding to EU (Europe), US (North America), ZH (Asia),  and BR (South America).
After you have executed ServerSetup, and then run ShardSetup on each database, run this script on the EU database.
*/
USE CustomerShardEU;
GO
-- CREATE FUNCTIONS
CREATE OR ALTER FUNCTION ws.ShardId()
RETURNS tinyint
AS
BEGIN
	RETURN 2;
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
SET IDENTITY_INSERT shd.Customers OFF;
GO
SET IDENTITY_INSERT shd.Contacts ON;
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
SET IDENTITY_INSERT shd.Contacts OFF;
GO
INSERT INTO shd.ContactCustomers (CustomerId, CustomerShardId, ContactId)
VALUES (1, 2, 1),
	(2, 2, 2),
	(2, 3, 4), --foreign
	(3, 2, 3),
	(3, 4, 5), --foreign
	(4, 2, 3),
	(4, 4, 6), --foriegn
	(5, 2, 3),
	(6, 2, 4),
	(7, 2, 4),
	(7, 1, 4), --foreign
	(8, 2, 5),
	(9, 2, 6),
	(10, 2, 7),
	(11, 2, 7),
	(12, 2, 8),
	(13, 2, 9),
	(14, 2, 9),
	(15, 2, 10),
	(16, 2, 11),
	(17, 2, 12),
	(18, 2, 12);
GO
INSERT INTO shd.CustomerContacts (ContactId, ContactShardId, CustomerId)
VALUES (1, 2, 1),
	(2, 2, 2),
	(3, 2, 3),
	(4, 2, 3),
	(5, 2, 3),
	(6, 2, 4),
	(7, 2, 4),
	(8, 2, 5),
	(9, 2, 6),
	(9, 3, 6), --foreign
	(10, 2, 7),
	(11, 2, 7),
	(12, 2, 8),
	(13, 2, 9),
	(14, 2, 9),
	(15, 2, 10),
	(16, 2, 11),
	(17, 2, 12),
	(18, 2, 12);
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
