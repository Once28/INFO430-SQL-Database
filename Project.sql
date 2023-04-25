-- Final Project Justin Zeng
USE TravelDB_cje22
GO

-- From Lab 7
CREATE OR ALTER PROCEDURE jzeng_getSeasonID
@Sname1 varchar(75),
@S_ID1 INT OUTPUT
AS

SET @S_ID1 = (SELECT seasonID FROM tblSEASON WHERE seasonName = @Sname1)
GO

CREATE OR ALTER PROCEDURE jzeng_getTravelerID
@Fname1 varchar(75),
@Lname1 varchar(75),
@DOB1 varchar(75),
@Trav_ID1 INT OUTPUT
AS

SET @Trav_ID1 = (SELECT travelerID FROM tblTRAVELER WHERE travelerFname = @Fname1 AND travelerLname = @Lname1 AND travelerDOB = @DOB1)
GO

CREATE OR ALTER PROCEDURE jzeng_getDestID
@Dname1 varchar(75),
@D_ID1 INT OUTPUT
AS

SET @D_ID1 = (SELECT destinationID FROM tblDESTINATION D JOIN tblCOUNTRY C ON D.countryID = C.countryID WHERE destinationName = @Dname1)
GO

CREATE OR ALTER PROCEDURE jzeng_InsertVisit
@Dname varchar(75),
@Sname varchar(75),
@Fname varchar(75),
@Lname varchar(75),
@DOB date,
@BeginDate date,
@EndDate date,
@Descr varchar(255)
AS

DECLARE @D_ID INT, @S_ID INT, @Trav_ID INT

EXEC jzeng_getDestID
	@Dname1 = @Dname,
	@D_ID1 = @D_ID OUTPUT
	IF @D_ID IS NULL
		BEGIN
			PRINT '@D_ID is null'
			RAISERROR('@D_ID cannot be null', 11, 1)
			RETURN
		END

EXEC jzeng_getSeasonID
	@Sname1 = @Sname,
	@S_ID1 = @S_ID OUTPUT
	IF @S_ID IS NULL
		BEGIN
			PRINT '@S_ID is null'
			RAISERROR('@S_ID cannot be null', 11, 1)
			RETURN
		END

EXEC jzeng_getTravelerID
	@Fname1 = @Fname,
	@Lname1 = @Lname,
	@DOB1 = @DOB,
	@Trav_ID1 = @Trav_ID OUTPUT
	IF @Trav_ID IS NULL
		BEGIN
			PRINT '@Trav_ID is null'
			RAISERROR('@Trav_ID cannot be null', 11, 1)
			RETURN
		END

BEGIN TRANSACTION T1
	INSERT INTO tblVISIT(travelerID, seasonID, destinationID, visitBeginDate, visitEndDate, visitDescr)
	VALUES (@Trav_ID, @S_ID, @D_ID, @BeginDate, @EndDate, @Descr)
	IF @@ERROR <>0 OR @@TRANCOUNT <> 1
		BEGIN 
			PRINT 'Something failed at the very end'
			ROLLBACK TRANSACTION T1
		END
	ELSE 
		COMMIT TRANSACTION T1

GO

-- Wrapper
CREATE OR ALTER PROCEDURE jzeng_TestInsertVisit
@RUN INT
AS
DECLARE @TravlerRowCount INT = (SELECT COUNT(*) FROM tblTRAVELER)
DECLARE @DestinationRowCount INT = (SELECT COUNT(*) FROM tblDESTINATION)
DECLARE @CountryRowCount INT = (SELECT COUNT(*) FROM tblCOUNTRY)
DECLARE @SeasonRowCount INT = (SELECT COUNT(*) FROM tblSEASON)

DECLARE @Dname varchar(75), @Cname varchar(75), @Sname varchar(75), 
@Fname varchar(75), @Lname varchar(75), @DOB date, @BeginDate date, @EndDate date, @Descr varchar(75)

-- get a variable to hold PK value for each loop

DECLARE @TravelerPK INT, @DestinationPK INT, @SeasonPK INT

WHILE @RUN > 0
BEGIN
SET @TravelerPK = (SELECT RAND() * @TravlerRowCount + 1)
SET @DestinationPK = (SELECT RAND() * @DestinationRowCount + 1)
SET @SeasonPK = (SELECT RAND() * @SeasonRowCount + 1)

SET @Fname = (SELECT travelerFname FROM tblTRAVELER WHERE travelerID = @TravelerPK)
SET @Lname = (SELECT travelerLname FROM tblTRAVELER WHERE travelerID = @TravelerPK)
SET @DOB = (SELECT travelerDOB FROM tblTRAVELER WHERE travelerID = @TravelerPK)
SET @Dname = (SELECT destinationName FROM tblDESTINATION WHERE destinationID = @DestinationPK)
SET @Sname = (SELECT seasonName FROM tblSEASON WHERE seasonID = @SeasonPK)
SET @BeginDate = (SELECT DateADD(Day, (SELECT RAND() * 1000), @DOB))
SET @EndDate = (SELECT DateAdd(DAY, (SELECT RAND() * 100), @BeginDate))
SET @Descr = ''

EXEC jzeng_InsertVisit
	@Dname = @Dname,
	@Sname = @Sname,
	@Fname = @Fname,
	@Lname = @Lname,
	@DOB = @DOB,
	@BeginDate = @BeginDate,
	@EndDate = @EndDate,
	@Descr = @Descr


SET @RUN = @RUN -1
END
GO

EXEC jzeng_TestInsertVisit 100000
GO

CREATE OR ALTER PROCEDURE jzeng_getVisitID
@Fname2 varchar(75),
@Lname2 varchar(75),
@DOB2 date,
@Begin2 date,
@End2 date,
@Season varchar(75),
@DestName varchar(75),
@V_ID INT OUTPUT
AS

DECLARE @T_ID1 INT, @S_ID1 INT, @D_ID1 INT
EXEC jzeng_getDestID 
	@Dname1 = @DestName,
	@D_ID1 = @D_ID1 OUTPUT
	IF @D_ID1 IS NULL
		BEGIN
			PRINT 'Going to Hawaii!!!'
			SET @D_ID1 = 1 -- Hawaii
		END

EXEC jzeng_getTravelerID
	@Fname1 = @Fname2,
	@Lname1 = @Lname2,
	@DOB1 = @DOB2,
	@Trav_ID1 = @T_ID1 OUTPUT
	IF @T_ID1 IS NULL
		BEGIN
			PRINT 'There is an error with @T_ID'
			RAISERROR ('@T_ID is empty and will fail', 11, 1)
		END

SET @S_ID1 = (SELECT seasonID FROM tblSEASON WHERE seasonName = @Season)
SET @V_ID = (SELECT visitID FROM tblVISIT WHERE travelerID = @T_ID1 AND seasonID = @S_ID1 AND visitBeginDate = @Begin2 AND visitEndDate = @End2)
GO

CREATE OR ALTER PROCEDURE jzeng_InsertTrip
@transportName VARCHAR(75),
@TFirstName VARCHAR(75),
@TLastName VARCHAR(75),
@TravDOB DATE,
@VBegin DATE,
@VEnd DATE,
@DepartTime DATE,
@ArrivalTime DATE,
@Price DECIMAL(5,2),
@Season varchar(75),
@DestName varchar(75)
AS
 
DECLARE @TR_ID INT, @VI_ID INT
 
EXEC jzeng_getVisitID
@Fname2 = @TFirstName,
@Lname2 = @TLastName,
@Begin2 = @VBegin,
@End2 = @VEnd,
@Season = @Season,
@DOB2 = @TravDOB,
@DestName = @DestName,
@V_ID = @VI_ID OUTPUT
IF @VI_ID IS NULL
   BEGIN
       PRINT 'There is an error with @V_ID'
       RAISERROR ('@VI_ID is empty and will fail', 11, 1)
       RETURN
   END
 
EXEC getTransportationID_nishtha1
@transport = @transportName,
@TR_ID2 = @TR_ID OUTPUT
IF @TR_ID IS NULL 
   BEGIN
       PRINT 'Using Boeing 737'
       SET @TR_ID = 13 -- Boeing 737
   END
 
BEGIN TRANSACTION T1
INSERT INTO tblTRIP (transportationID, visitID, departureTime, arrivalTime, transportationPrice)
VALUES(@TR_ID, @VI_ID, @DepartTime, @ArrivalTime, @Price)
IF @@ERROR <> 0
   BEGIN
       ROLLBACK TRANSACTION T1
   END
ELSE
   COMMIT TRANSACTION T1
 
GO

-- Synthetic Transaction
CREATE OR ALTER PROCEDURE jzeng_testInsertTrip
@RUN INT
AS

DECLARE @TransportRowCount INT = (SELECT COUNT(*) FROM tblTRANSPORTATION)
DECLARE @VisitRowCount INT = (SELECT COUNT(*) FROM tblVISIT)
DECLARE @TravelerCount INT = (SELECT COUNT(*) FROM tblTRAVELER)

DECLARE
@transportName VARCHAR(75),
@TFirstName VARCHAR(75),
@TLastName VARCHAR(75),
@TravDOB DATE,
@VBegin DATE,
@VEnd DATE,
@DepartTime DATE,
@ArrivalTime DATE,
@Price DECIMAL(5,2),
@TransportPK INT, 
@VisitPK INT, 
@TravelerPK INT,
@Season varchar(75),
@DestName varchar(75)
 
WHILE @RUN > 0
BEGIN
DECLARE @RandNumber INT = (SELECT RAND() * 100)

SET @TransportPK = (SELECT RAND() * @TransportRowCount + 1)
SET @VisitPK = (SELECT RAND() * @VisitRowCount + 1)

SET @transportName = (SELECT transporationName FROM tblTRANSPORTATION WHERE transportationID = @TransportPK) 
SET @TFirstName = (SELECT travelerFname FROM tblTRAVELER T JOIN tblVISIT V ON T.travelerID = V.travelerID WHERE V.visitID = @VisitPK)
SET @TLastName = (SELECT travelerLname FROM tblTRAVELER T JOIN tblVISIT V ON T.travelerID = V.travelerID WHERE V.visitID = @VisitPK)
SET @TravDOB = (SELECT travelerDOB FROM tblTRAVELER T JOIN tblVISIT V ON T.travelerID = V.travelerID WHERE V.visitID = @VisitPK)
SET @VBegin = (SELECT visitBeginDate FROM tblVISIT WHERE visitID = @VisitPK )
SET @VEnd = (SELECT visitEndDate FROM tblVISIT WHERE visitID = @VisitPK )
SET @DepartTime = (SELECT DateAdd(DAY, -@RandNumber, GetDate()))
SET @ArrivalTime = (SELECT DateAdd(DAY, @RandNumber, @DepartTime))
SET @Price = (SELECT CAST( RAND() * 1000 AS DECIMAL(5, 2))) print @price
SET @Season = (SELECT seasonName  FROM tblSEASON S JOIN tblVISIT V ON S.seasonID = V.seasonID WHERE V.visitID = @VisitPK)
SET @DestName = (SELECT destinationName FROM tblDESTINATION D JOIN tblVISIT V ON D.destinationID = V.destinationID WHERE V.visitID = @VisitPK)

EXEC jzeng_InsertTrip
@transportName = @transportName,
@TFirstName = @TFirstName,
@TLastName = @TLastName ,
@TravDOB = @TravDOB,
@VBegin = @VBegin,
@VEnd = @VEnd,
@DepartTime = @DepartTime,
@ArrivalTime = @ArrivalTime,
@Price = @Price,
@Season = @Season,
@DestName = @DestName
 
SET @RUN = @RUN - 1
END
GO

EXEC jzeng_testInsertTrip 10000

-- Project 4
USE TravelDB_cje22
GO

CREATE TABLE tblTRIP (
	tripID INT IDENTITY (1, 1) PRIMARY KEY not null,
	transportationID INT REFERENCES tblTRANSPORTATION(transportationID) not null,
	visitID INT REFERENCES tblVISIT(visitID) not null,
	departureTime date,
	arrivalTime date,
	transportationPrice decimal (5, 2)
)

-- Islands, Beach resorts, Mountain areas, Forests, Countryside areas, Towns and cities, Winter sport areas, Cultural Heritage
INSERT INTO tblDESTINATION_TYPE(destinationTypeName, destinationTypeDescr)
	VALUES('Islands', '​Tourism to islands is a special form of tourism that often requires specific consideration as there are distinctive characteristics of islands such as fragile environments and historical and socio-cultural aspects that can result in unique challenges to developing a successful tourism destination.')

INSERT INTO tblDESTINATION_TYPE(destinationTypeName, destinationTypeDescr)
	VALUES('Beach resorts', 'A seaside resort is a town, village, or hotel that serves as a vacation resort and is located on a coast. Sometimes the concept includes an aspect of official accreditation based on the satisfaction of certain requirements, such as in the German Seebad.')

INSERT INTO tblDESTINATION_TYPE(destinationTypeName, destinationTypeDescr)
	VALUES('Mountain areas', 'Tourism activity which takes place in a defined and limited geographical space such as hills or mountains with distinctive characteristics.')

INSERT INTO tblDESTINATION_TYPE(destinationTypeName, destinationTypeDescr)
	VALUES('Forests', 'A forest is an area of land dominated by trees. Hundreds of definitions of forest are used throughout the world, incorporating factors such as tree density, tree height, land use, legal standing, and ecological function.')

INSERT INTO tblDESTINATION_TYPE(destinationTypeName, destinationTypeDescr)
	VALUES('Countryside area', 'Rural tourism is a tourism that focuses on actively participating in a rural lifestyle.')

INSERT INTO tblDESTINATION_TYPE(destinationTypeName, destinationTypeDescr)
	VALUES('Towns and cities', 'Urban tourism or also called City tourism is a form of tourism that takes place in the large human agglomerations, usually in the main cities or urban areas of each country.')

INSERT INTO tblDESTINATION_TYPE(destinationTypeName, destinationTypeDescr)
	VALUES('Winter sport areas', 'Areas where winter sports are played.')

INSERT INTO tblDESTINATION_TYPE(destinationTypeName, destinationTypeDescr)
	VALUES('Cultural Heritage', 'Cultural heritage is the heritage of tangible and intangible heritage assets of a group or society that is inherited from past generations. Not all heritages of past generations are "heritage"; rather, heritage is a product of selection by society.')
	
-- Transportation Type
INSERT INTO tblTRANSPORTATION_TYPE (transportationTypeName, transportationTypeDescr)
	VALUES('Walk', 'The easiest (and cheapest) form of transportation is to just walk. A lot of cities are super easy to explore on foot.'), 
	('Bike', 'It’s a bit faster than walking and super fun.'), 
	('Car', 'Whether you rent a car, drive your own, use a ride share app, or take a taxi, driving is another simple way to travel around.'), 
	('Train', 'Trains are roomy, convenient, and give you some time to relax. Remember to bring something to do such as a book to read, music, or a movie if you have a long trip ahead of you.'), 
	('Bus', 'Whether you’re taking a public bus, a charter bus across a country or a hop-on-hop-off tourist bus, there are a few things to remember. For public transportation, always have cash or coins to pay for a ticket when you board (it’s rare they take credit cards) and hit the stop button before your stop to indicate to the driver you need to get off.'), 
	('Boat', 'From huge ferries to small boat tours, this mode of transportation provides a unique view of the city and is definitely worth checking out.'), 
	('Subway', 'The metro/subway can be a quick way to avoid some walking. Just make sure to take a look at the map and figure out which direction you need to go to before jumping aboard.'), 
	('Tram', 'Aerial Tramways come in all different sizes, from fitting a few people to upwards of a hundred people. They are an enjoyable and thrilling way to soar up to a mountain.'), 
	('Aircraft', 'Flying is a great way to get yourself to a major city and start your adventure. Airplanes get you places fast and are the most versatile mode of transportation, taking you across states, across countries, and across waters.'), 
	('Funicular', 'A great alternative to aerial tramways is funiculars. These railways use cable traction to move on steeply inclined slopes, moving cars up and down hills and mountains.')

-- Seasons
INSERT INTO tblSEASON (seasonName)
	VALUES ('Spring'), ('Summer'), ('Autumn'), ('Winter')

-- Transportation
INSERT INTO tblTRANSPORTATION(transporationName, transportationDescr, transportationTypeID)
	VALUES ('Walk', 'The easiest (and cheapest) form of transportation is to just walk. A lot of cities are super easy to explore on foot.', 1),
	('Mountain Bike', 'A mountain bike (MTB) or mountain bicycle is a bicycle designed for off-road cycling. Mountain bikes share some similarities with other bicycles, but incorporate features designed to enhance durability and performance in rough terrain, which makes them heavier, more complex and less efficient on smooth surfaces.', 2),
	('Tesla Model 3', 'The Tesla Model 3 is a compact executive sedan that is battery powered and produced by Tesla.', 3),
	('Toyota Sienna', 'The Toyota Sienna is a minivan manufactured and marketed by Toyota primarily for the North American and select East Asian markets.', 3),
	('Honda Civic', 'The Honda Civic (Japanese: ホンダ・シビック, Hepburn: Honda Shibikku) is a series of automobiles manufactured by Honda since 1972. Since 2000, the Civic has been categorized as a compact car, while previously it occupied the subcompact class. As of 2021, the Civic is positioned between the Honda Fit/City and Honda Accord in Hondas global car line-up.', 3),
	('Mercedes-Benz GLS-Class', 'The Mercedes-Benz GLS, formerly Mercedes-Benz GL-Class, is a full-size luxury crossover SUV produced by Mercedes-Benz since 2006. In each of its generations it is a three-row, seven-passenger vehicle positioned above the GLE (formerly Mercedes-Benz M-Class before 2016).', 3),
	('Amtrak', 'The best way to experience the great Pacific Northwest is on the Amtrak Cascades. From Vancouver, British Columbia to Seattle, Portland and Eugene, Oregon, past Mount St. Helens and across the Columbia River Gorge, youll witness some of our continents most distinctive cities and most spectacular natural attractions.', 4),
	('Charter Bus', 'We want you to feel at home when you travel with us. So our buses have plenty of features to help you relax, like comfy leather seats and lots of legroom (plus free Wi-Fi, onboard entertainment and power outlets so you can still be an armchair surfer).', 5),
	('Double-decker Bus', 'A double-decker bus or double-deck bus is a bus that has two storeys or decks. They are used for mass transport in the United Kingdom, the United States, New Zealand, Europe, Asia and also in cities such as Sydney; the best-known example is the red London bus, namely the AEC Routemaster.', 5),
	('Emerald Princess', 'Emerald Princess is a Crown-class cruise ship for Princess Cruises that entered service in April 2007. Her sister ships include Ruby Princess and Crown Princess. Emerald Princess launched from the Italian shipyard of Fincantieri Monfalcone on 1 June 2006. She was then handed over to Princess Cruises on 24 March 2007.', 6),
	('Carnival Vista', 'Carnival Vista is a cruise ship operated by Carnival Cruise Line. She is the lead ship of her namesake class, which includes two additional Carnival ships, Carnival Horizon and Carnival Panorama, as well as two Costa ships, Costa Venezia and Costa Firenze.', 6),
	('1 Line', 'Sound Transit, officially the Central Puget Sound Regional Transit Authority, is a public transit agency serving the Seattle metropolitan area in the U.S. state of Washington. It operates the Link light rail system in Seattle and Tacoma, regional Sounder commuter rail, and Sound Transit Express bus service.', 7),
	('Boeing 737', 'The Boeing 737 is a narrow-body aircraft produced by Boeing at its Renton Factory in Washington. Developed to supplement the Boeing 727 on short and thin routes, the twinjet retains the 707 fuselage width and six abreast seating with two underwing turbofans.', 9),
	('Airbus A320', 'The Airbus A320 family is a series of narrow-body airliners developed and produced by Airbus. The A320 was launched in March 1984, first flew on 22 February 1987, and was introduced in April 1988 by Air France. The first member of the family was followed by the longer A321, the shorter A319, and the even shorter A318', 9),
	('Boeing 747', 'The Boeing 747 is a large, long-range wide-body airliner designed and manufactured by Boeing Commercial Airplanes in the United States. After introducing the 707 in October 1958, Pan Am wanted a jet 2+1⁄2 times its size, to reduce its seat cost by 30% to democratize air travel. ', 9)

GO

-- SYNTHETIC TRANSACTIONS
CREATE OR ALTER PROCEDURE jzeng_PopulateTraveler
AS

DECLARE @RUN INT = 100000
DECLARE @PeopleCount INT, @CustID INT, @FirstName varchar(75),
		@LastName varchar(75), @City varchar(75), @travAddress varchar(75), 
		@RandNumber INT, @DOB2 DATE,
		@TravTypeNum INT, @TravTypeID INT, @TravType varchar(75), 
		@CountryNumbers INT, @CountryID INT, @Country varchar(75)
SET @RandNumber = (SELECT RAND() * 10000)
SET @PeopleCount = (SELECT COUNT(*) FROM PEEPS.dbo.tblCUSTOMER)
SET @TravTypeNum = (SELECT COUNT(*) FROM tblTRAVELER_TYPE)
SET @CountryNumbers = (SELECT COUNT(*) FROM tblCOUNTRY)

WHILE @RUN > 0
	BEGIN
		
		SET @RandNumber = (SELECT RAND() * 1000 + 1)
		SET @DOB2 = (SELECT DateAdd(DAY, -@RandNumber, GetDate()))

		SET @CustID = (SELECT RAND() * @PeopleCount + 1)
		SET @FirstName = (SELECT CustomerFname FROM PEEPS.dbo.tblCUSTOMER WHERE CustomerID = @CustID)
		SET @LastName = (SELECT CustomerLname FROM PEEPS.dbo.tblCUSTOMER WHERE CustomerID = @CustID)
		SET @travAddress = (SELECT CustomerAddress FROM PEEPS.dbo.tblCUSTOMER WHERE CustomerID = @CustID)
		SET @City = (SELECT CustomerCity FROM PEEPS.dbo.tblCUSTOMER WHERE CustomerID = @CustID)

		SET @TravTypeID = (SELECT RAND() * @TravTypeNum + 1)
		SET @TravType = (SELECT travelerTypeName FROM tblTRAVELER_TYPE WHERE travelerTypeID = @TravTypeID)
		PRINT(@TravType)
		PRINT(@TravTypeID)

		SET @CountryID = (SELECT RAND() * @CountryNumbers + 13)
		SET @Country = (SELECT countryName FROM tblCOUNTRY WHERE countryID = @CountryID)
		
		EXEC cje22_InsertTraveler
		@travelerTypeName = @TravType,
		@countryName = @Country,
		@Fname = @FirstName,
		@Lname = @LastName,
		@DOB = @DOB2,
		@travelerCity = @City,
		@address = @travAddress
		

		SET @RUN = @RUN - 1
	END



EXEC jzeng_PopulateTraveler
GO

CREATE OR ALTER PROCEDURE jzeng_getActivityID
@actName1 varchar(75),
@AID1 INT OUTPUT
AS

SET @AID1 = (SELECT activityID FROM tblACTIVITY WHERE activityName = @actName1)
GO

CREATE OR ALTER PROCEDURE jzeng_InsertActivityDest
@actName varchar(75),
@destName1 varchar(75),
@actDate date,
@actPrice numeric(8, 2)
AS

DECLARE @AID INT, @DID INT
EXEC jzeng_getActivityID
    @actName1 = @actName,
    @AID1 = @AID OUTPUT
IF @AID IS NULL
    BEGIN
        PRINT '@AID CANNOT BE NULL'
        RAISERROR(55441, 11, 1)
    END

EXEC cje_getDestinationID 
    @destName2 = @destName1,
    @destID = @DID OUTPUT
IF @DID IS NULL
    BEGIN
        PRINT '@DID CANNOT BE NULL'
        RAISERROR(55441, 11, 1)
    END

BEGIN TRANSACTION T1

    IF @@ERROR <> 0
        BEGIN
            PRINT 'ERROR'
            ROLLBACK TRANSACTION T1
        END
    ELSE
        COMMIT TRANSACTION T1
GO
		
CREATE OR ALTER PROCEDURE jzeng_getActivityID
@actName1 varchar(75),
@AID1 INT OUTPUT
AS

SET @AID1 = (SELECT activityID FROM tblACTIVITY WHERE activityName = @actName1)
GO

CREATE OR ALTER PROCEDURE jzeng_InsertActivityDest
@actName varchar(75),
@destName1 varchar(75),
@actDate date,
@actPrice numeric(8, 2)
AS

DECLARE @AID INT, @DID INT
EXEC jzeng_getActivityID
    @actName1 = @actName,
    @AID1 = @AID OUTPUT
	IF @AID IS NULL
		BEGIN
			PRINT '@AID CANNOT BE NULL'
			RAISERROR(55441, 11, 1)
		END

EXEC cje_getDestinationID 
    @destName2 = @destName1,
    @destID = @DID OUTPUT
	IF @DID IS NULL
		BEGIN
			PRINT '@DID CANNOT BE NULL'
			RAISERROR(55441, 11, 1)
		END

BEGIN TRANSACTION T1
	INSERT INTO tblACTIVITY_DEST(activityID, destinationID, activityDate, activityPrice)
		VALUES (@AID, @DID, @actDate, @actPrice)
    IF @@ERROR <> 0
        BEGIN
            PRINT 'ERROR'
            ROLLBACK TRANSACTION T1
        END
    ELSE
        COMMIT TRANSACTION T1
GO

CREATE OR ALTER PROCEDURE jzeng_populateActDest
@RUN INT
AS

DECLARE @actName varchar(75), @destName1 varchar(75), @actDate date, @actPrice numeric(8, 2),
		@ActivityRowcount INT, @ActivityPK INT, @DestRowcount INT, @DestPK INT

SET @ActivityRowcount = (SELECT COUNT(*) FROM tblACTIVITY)
SET @DestRowcount = (SELECT COUNT(*) FROM tblDESTINATION)


WHILE @RUN > 0
	BEGIN
		DECLARE @RAND INT = (SELECT RAND() * 100 + 1) 
		SET @ActivityPK = (SELECT RAND() * @ActivityRowcount + 1) print @activityPK
		SET @DestPK = (SELECT RAND() * @DestRowcount + 1) print @destPK

		SET @actName = (SELECT activityName FROM tblACTIVITY WHERE activityID = @ActivityPK) print @actName
		SET @actDate = (SELECT DATEADD(DAY, -@RAND, GETDATE()))
		SET @actPrice = (SELECT RAND() * 1000)
		SET @destName1 = (SELECT destinationName FROM tblDESTINATION WHERE destinationID = @DestPK) PRINT @destName1

		EXEC jzeng_InsertActivityDest
			@actName = @actName,
			@destName1 = @destName1,
			@actDate = @actDate,
			@actPrice = @actPrice

		SET @RUN = @RUN - 1
	END
GO

EXEC jzeng_populateActDest 1000
SELECT * FROM tblACTIVITY_DEST AD JOIN tblACTIVITY A ON A.activityID = AD.activityID JOIN tblDESTINATION D ON D.destinationID = AD.destinationID
--INSERT INTO tblCURRENCY (currName)
--	VALUES ('Chinese RMB'), ('British Pount'), ('Hong Kong Dollar'), ('Swiss Franc'), ('Australian Dollar'), ('Bitcoin')

INSERT INTO tblDESTINATION (destinationName, destinationDescr, destinationTypeID, countryID)
	VALUES ('Foribidden City', 'The Forbidden City (Chinese: 紫禁城; pinyin: Zǐjìnchéng) is a palace complex in Dongcheng District, Beijing, China, at the center of the Imperial City of Beijing.', 3, 55),
	('Oxford University', 'The oldest university in the English-speaking world (and, thus, of Merry Ol’ England), instruction has been taking place at Oxford University since c. 1096 AD.', 3, 243),
	('Mount Vesuvius', 'Perhaps most infamous for burying the city of Pompeii under approximately 15 feet of volcanic ash and debris in the year 79 AD, Mount Vesuvius is one of the worlds most dangerous volcanoes.', 6, 117),
	('Terracotta Army', 'Since his efforts at immortality didn’t bear fruit, when it came time for Qin Shi Huang, first emperor of Qin, to be interred, he made sure that it was done with style as befitted his greatness.', 3, 55),
	('Hạ Long Bay', 'According the Vietnamese legend, its here that the gods sent jade and jewel-spewing dragons who created the rocky islands dotting the bay and creating a defense against early Chinese invaders.', 4, 250),
	('Broadway', 'Broadway is best known for the middle section between 42nd and 53rd Streets dubbed the “Great White Way” – the Theater District.', 9, 244),
	('Golden Gate Bridge', 'Nestled in the San Francisco fog is the iconic Golden Gate Bridge, a 1.7 mile long suspension bridge that defied everything believed to be true about engineering when it was completed in 1937.', 9, 244),
	('Statue of Liberty', 'Perhaps nothing is more iconic to America than the giant green woman standing in New York Harbor.', 9, 244)
GO

--Business Rules:
--	no travelers under 12 may go to the poles region
CREATE OR ALTER FUNCTION jzeng_noMinorInPoles()
RETURNS INT
AS
BEGIN

DECLARE @RET INT = 0
IF EXISTS (SELECT * 
				FROM tblTRAVELER T
					JOIN tblVISIT V ON T.travelerID = V.travelerID
					JOIN tblDESTINATION D ON V.destinationID = D.destinationID
					JOIN tblCOUNTRY C ON D.countryID = C.countryID
					JOIN tblREGION R ON C.regionID = R.regionID
				WHERE R.regionName LIKE 'Polar' AND DATEADD(YEAR, -18, GETDATE()) < YEAR(T.travelerDOB))
SET @RET = 1

RETURN @RET
END
GO

ALTER TABLE tblTRAVELER
ADD CONSTRAINT ck_noMinorInPoles
CHECK (dbo.jzeng_noMinorInPoles() = 0)
GO

--	no instance of Euro can be used in United Kingdom
CREATE OR ALTER FUNCTION jzeng_noEurosInUK()
RETURNS INT
AS
BEGIN

DECLARE @RET INT = 0
IF EXISTS (SELECT * 
				FROM tblCURRENCY C
					JOIN tblCURRENCY_DEST CD ON C.currID = CD.currID
					JOIN tblDESTINATION D ON CD.destinationID = D.destinationID
					JOIN tblCOUNTRY CY ON D.countryID = CY.countryID
				WHERE CY.countryName = 'United Kingdom' AND C.currName = 'Euro'
				)
SET @RET = 1

RETURN @RET
END
GO

ALTER TABLE tblCURRENCY_DEST
ADD CONSTRAINT ck_noEurosInUK
CHECK (dbo.jzeng_noEurosInUK() = 0)
GO

-- There can only be 4 Seasons
CREATE OR ALTER FUNCTION jzeng_OnlyFourSeasons()
RETURNS INT
AS
BEGIN

DECLARE @RET INT = 0
IF EXISTS (SELECT * FROM tblSEASON
				WHERE seasonName NOT IN ('Spring', 'Summer', 'Autumn', 'Winter'))
SET @RET = 1

RETURN @RET
END
GO

ALTER TABLE tblSEASON with nocheck
ADD CONSTRAINT ck_OnlyFourSeasons
CHECK (dbo.jzeng_OnlyFourSeasons() = 0)
GO

-- 2 comp col:
-- Number of travelers who shopped in each country
CREATE OR ALTER FUNCTION jzeng_numShoppers(@PK INT)
RETURNS INT
AS
BEGIN

DECLARE @RET INT = (SELECT COUNT(T.travelerID)
					FROM tblCOUNTRY C
						JOIN tblTRAVELER T ON T.countryID = C.countryID
						JOIN tblVISIT V ON T.travelerID = V.travelerID
						JOIN tblDESTINATION D ON V.destinationID = D.destinationID
						JOIN tblACTIVITY_DEST AD ON D.destinationID = AD.destinationID
						JOIN tblACTIVITY A ON AD.activityID = A.activityID
					WHERE A.activityName = 'Shopping'
					AND C.countryID = @PK)
RETURN @RET
END
GO

ALTER TABLE tblCOUNTRY
ADD numShoppers AS dbo.jzeng_numShoppers(countryID)
GO

-- Number of winter sport areas per country
CREATE OR ALTER FUNCTION jzeng_numSkiResorts(@PK INT)
RETURNS INT
AS
BEGIN

DECLARE @RET INT = (SELECT COUNT(T.travelerID)
					FROM tblCOUNTRY C
						JOIN tblTRAVELER T ON T.countryID = C.countryID
						JOIN tblVISIT V ON T.travelerID = V.travelerID
						JOIN tblDESTINATION D ON V.destinationID = D.destinationID
						JOIN tblDESTINATION_TYPE DT ON D.destinationTypeID = DT.destinationTypeID
					WHERE DT.destinationTypeName = 'Winter sports areas'
					AND C.countryID = @PK)
RETURN @RET
END
GO

ALTER TABLE tblCOUNTRY
ADD numSkiResorts AS dbo.jzeng_numSkiResorts(countryID)
GO

-- Views
-- What are the top 5 most popular countries to visit in the winter?
CREATE OR ALTER VIEW topFiveVisitedCountries
AS 
	SELECT C.countryName, COUNT(T.travelerID) AS numTravelers, RANK() OVER (ORDER BY COUNT(T.travelerID) DESC) as ranky
	FROM tblCOUNTRY C
		JOIN tblDESTINATION D on D.countryID = C.countryID
		JOIN tblVISIT V ON D.destinationID = V.destinationID
		JOIN tblTRAVELER T ON V.travelerID = T.travelerID
		JOIN tblSEASON S ON V.seasonID = S.seasonID
	WHERE S.seasonName = 'Winter'
	GROUP BY C.countryName
	
	SELECT * FROM topFiveVisitedCountries
	WHERE ranky <= 5

DROP VIEW topFiveVisitedCountries
GO

-- What is the 3rd most common activity in any destination in the US?
CREATE OR ALTER VIEW thirdMostCommonActivityInUS
AS 
	SELECT A.activityName, COUNT(AD.activityDestinationID) AS numTravelers, RANK() OVER (ORDER BY COUNT(AD.activityDestinationID) DESC) as ranky
	FROM tblCOUNTRY C
		JOIN tblDESTINATION D on D.countryID = C.countryID
		JOIN tblVISIT V ON D.destinationID = V.destinationID
		JOIN tblTRAVELER T ON V.travelerID = T.travelerID
		JOIN tblACTIVITY_DEST AD ON AD.destinationID = D.destinationID
		JOIN tblACTIVITY A ON AD.activityID = A.activityID
	WHERE C.countryName = 'United States'
	GROUP BY A.activityName
	
	SELECT * FROM thirdMostCommonActivityInUS
	WHERE ranky = 3

DROP VIEW thirdMostCommonActivityInUS
GO

