use w
go
DROP TABLE IF EXISTS dbo.DimDate 
GO

CREATE TABLE dbo.DimDate  (
    [dimDateID]				INT				NOT NULL,
    [CalendarDate]			DATE			NOT NULL,
    [Day_of_Month]			TINYINT			NOT NULL,
    [Day_of_Year]			SMALLINT		NOT NULL,
    [Day_of_Week]			TINYINT			NOT NULL,
    [Year]					SMALLINT		NOT NULL,
    [Quarter]				CHAR (2)		NOT NULL,
    [Month]					TINYINT			NOT NULL,
    [Month_Name]			VARCHAR (30)	NOT NULL,
    [Week_of_Year]			TINYINT			NOT NULL,
	[DayOfWeek_Month]		TINYINT			NOT NULL,
    [DayofWeek_Name]		VARCHAR (30)	NOT NULL,
    [ISOWeek_of_Year]		TINYINT			NOT NULL,
	[FirstDay_Month]		DATE			NOT NULL,
	[LastDay_Month]			DATE			NOT NULL,
	[FirstDay_Year]			DATE			NOT NULL,
    [IsWeekend]				CHAR (3)		NOT NULL,
	[IsHoliday]				BIT				NULL,
	[HolidayText]			VARCHAR(64)		NULL,
    CONSTRAINT [PK_WH_DimDate] PRIMARY KEY NONCLUSTERED ([CalendarDate] ASC) WITH (DATA_COMPRESSION = PAGE),
    CONSTRAINT [IDX_NC_DimDate_DimDateID] UNIQUE CLUSTERED ([dimDateID] ASC) WITH (DATA_COMPRESSION = PAGE)
);
go

--Bad
--Antipattern. Takes forever. 
DROP TABLE IF EXISTS #DimDate
CREATE TABLE #DimDate (Seeddate date);

INSERT INTO #DimDate (seeddate)
select seeddate = convert(date, '1/1/2000');

While (Select TOP 1 dateadd(day, 1, seeddate)  from #DimDate) < '1/1/2050'
INSERT INTO #DimDate 	
	select TOP 1 dateadd(day, 1, seeddate) 
	from #DimDate
	ORDER BY seeddate desc;



--Better

TRUNCATE TABLE dbo.DimDate;


SET STATISTICS IO ON
DROP TABLE IF EXISTS #DimDate
CREATE TABLE #DimDate (Seeddate date) 

;with cteDate (seeddate) as 
	(
	select seeddate = convert(date, '1/1/2000') 
	UNION ALL
	select dateadd(day, 1, seeddate) 
	from cteDate
	where seeddate < '1/1/2050'
	)
INSERT INTO #DimDate
SELECT seeddate from cteDate
OPTION (MAXRECURSION 0);

insert into dbo.DimDate (dimDateID, CalendarDate, Day_of_Month, Day_of_Year, Day_of_Week, Year, Quarter, Month, Month_Name, DayOfWeek_Month, Week_of_Year, DayofWeek_Name, ISOWeek_of_Year, FirstDay_Month, LastDay_Month, FirstDay_Year, IsWeekend)
		select 
			dimDateID			=	convert(int,convert(varchar(8),seeddate, 112))
		,	CalendarDate		=	seeddate
		,	Day_of_Month		=	DatePart(d, seeddate)
		,	Day_of_Year			=	DatePart(dy, seeddate)
		,	Day_of_Week			=	DatePart(dw, seeddate)
		,	[Year]				=	DatePart(yyyy, seeddate)
		,	[Quarter]			=	'Q' + Convert(char(1), datepart(quarter , seeddate))
		,	[Month]				=	DatePart(M, seeddate)
		,	[Month_Name]		=	DateName(m, seeddate) 
		,   [DayOfWeek_Month]   =	CONVERT(TINYINT, ROW_NUMBER() OVER 
									(PARTITION BY (CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, seeddate), 0))), DatePart(dw, seeddate) ORDER BY seeddate))
		,	Week_of_Year		=	DatePart(week, seeddate) 
		,	DayofWeek_Name		=	DateName(dw, seeddate) 
		,	ISOWeek_of_Year		=	DatePart(ISO_WEEK, seeddate) 
		,	[FirstDay_Month]	=	CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, seeddate), 0))
		,	[LastDay_Month]		=	MAX(seeddate) OVER (PARTITION BY DatePart(yyyy, seeddate), DatePart(M, seeddate))
		,	[FirstDay_Year]		=	CONVERT(DATE, DATEADD(YEAR,  DATEDIFF(YEAR,  0, seeddate), 0))
		,	IsWeekend			=	CASE WHEN DatePart(dw, seeddate) in (1,7) THEN 'Yes' ELSE 'No' END
from #DimDate
where seeddate < '1/1/2050'
SET STATISTICS IO OFF
GO







	
--Best
--
--Takes 2-3s to create 18263 records

TRUNCATE TABLE dbo.DimDate;
SET STATISTICS IO ON
;with cteDate (seeddate) as
	(
	select seeddate = convert(date, '1/1/2000') 
	UNION ALL
	select dateadd(day, 1, seeddate) 
	from cteDate
	where seeddate < '1/1/2050'
) 

insert into dbo.DimDate (dimDateID, CalendarDate, Day_of_Month, Day_of_Year, Day_of_Week, Year, Quarter, Month, Month_Name, DayOfWeek_Month, Week_of_Year, DayofWeek_Name, ISOWeek_of_Year, FirstDay_Month, LastDay_Month, FirstDay_Year, IsWeekend)
		select 
			dimDateID			=	convert(int,convert(varchar(8),seeddate, 112))
		,	CalendarDate		=	seeddate
		,	Day_of_Month		=	DatePart(d, seeddate)
		,	Day_of_Year			=	DatePart(dy, seeddate)
		,	Day_of_Week			=	DatePart(dw, seeddate)
		,	[Year]				=	DatePart(yyyy, seeddate)
		,	[Quarter]			=	'Q' + Convert(char(1), datepart(quarter , seeddate))
		,	[Month]				=	DatePart(M, seeddate)
		,	[Month_Name]		=	DateName(m, seeddate) 
		,   [DayOfWeek_Month]   =	CONVERT(TINYINT, ROW_NUMBER() OVER 
									(PARTITION BY (CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, seeddate), 0))), DatePart(dw, seeddate) ORDER BY seeddate))
		,	Week_of_Year		=	DatePart(week, seeddate) 
		,	DayofWeek_Name		=	DateName(dw, seeddate) 
		,	ISOWeek_of_Year		=	DatePart(ISO_WEEK, seeddate) 
		,	[FirstDay_Month]	=	CONVERT(DATE, DATEADD(MONTH, DATEDIFF(MONTH, 0, seeddate), 0))
		,	[LastDay_Month]		=	MAX(seeddate) OVER (PARTITION BY DatePart(yyyy, seeddate), DatePart(M, seeddate))
		,	[FirstDay_Year]		=	CONVERT(DATE, DATEADD(YEAR,  DATEDIFF(YEAR,  0, seeddate), 0))
		,	IsWeekend			=	CASE WHEN DatePart(dw, seeddate) in (1,7) THEN 'Yes' ELSE 'No' END
from cteDate
where seeddate < '1/1/2050'
OPTION (MAXRECURSION 0);
SET STATISTICS IO OFF
GO



