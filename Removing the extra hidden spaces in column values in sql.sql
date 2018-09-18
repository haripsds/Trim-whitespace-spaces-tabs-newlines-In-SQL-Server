/***TO Remove the Hidden space from the column values in SQL Server ***/

/***You might want to consider using a TVF (table-valued-function) to remove the offending characters from the start and end of your data.***/

-----------------------------------------------------
---Create a table to hold test data:
-----------------------------------------------------

IF COALESCE(OBJECT_ID('dbo.TrimTest'), 0) <> 0
BEGIN
    DROP TABLE dbo.TrimTest;
END
CREATE TABLE dbo.TrimTest
(
    SampleData VARCHAR(50) NOT NULL
);

INSERT INTO dbo.TrimTest (SampleData)
SELECT CHAR(13) + CHAR(10) + CHAR(9) + 'this is ' + CHAR(13) + CHAR(10) + ' a test' + CHAR(13) + CHAR(10);
GO
-----------------------------------------------------------
--Create the TVF:
-----------------------------------------------------------

IF COALESCE(OBJECT_ID('dbo.StripCrLfTab'), 0) <> 0
BEGIN
    DROP FUNCTION dbo.StripCrLfTab;
END
GO
CREATE FUNCTION dbo.StripCrLfTab
(
    @val NVARCHAR(1000)
)
RETURNS @Results TABLE
(
    TrimmedVal NVARCHAR(1000) NULL
)
AS
BEGIN
    DECLARE @TrimmedVal NVARCHAR(1000);
    SET @TrimmedVal = CASE WHEN RIGHT(@val, 1) = CHAR(13) OR RIGHT(@val, 1) = CHAR(10) OR RIGHT(@val, 1) = CHAR(9)
            THEN LEFT(
                CASE WHEN LEFT(@val, 1) = CHAR(13) OR LEFT(@val, 1) = CHAR(10) OR LEFT(@val, 1) = CHAR(9)
                THEN RIGHT(@val, LEN(@val) - 1)
                ELSE @val
                END
                , LEN(@val) -1 )
            ELSE
                CASE WHEN LEFT(@val, 1) = CHAR(13) OR LEFT(@val, 1) = CHAR(10) OR LEFT(@val, 1) = CHAR(9)
                THEN RIGHT(@val, LEN(@val) - 1)
                ELSE @val
                END
            END;
    IF @TrimmedVal LIKE (CHAR(13) + '%')
        OR @TrimmedVal LIKE (CHAR(10) + '%')
        OR @TrimmedVal LIKE (CHAR(9) + '%')
        OR @TrimmedVal LIKE ('%' + CHAR(13))
        OR @TrimmedVal LIKE ('%' + CHAR(10))
        OR @TrimmedVal LIKE ('%' + CHAR(9))
        SELECT @TrimmedVal = tv.TrimmedVal
        FROM dbo.StripCrLfTab(@TrimmedVal) tv;
    INSERT INTO @Results (TrimmedVal)
    VALUES (@TrimmedVal);
    RETURN;
END;
GO
--------------------------------------------------------
--Run the TVF to show the results:
--------------------------------------------------------

SELECT tt.SampleData
    , stt.TrimmedVal
FROM dbo.TrimTest tt
CROSS APPLY dbo.StripCrLfTab(tt.SampleData) stt;