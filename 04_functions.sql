/* =====================================================================
   04_functions.sql
   Scalar functions used in reports.
   ===================================================================== */

USE SchoolDB;
GO
-- Required for the persisted computed columns used in foreign keys
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Average grade of a student (NULL if the student has no grades)
CREATE OR ALTER FUNCTION dbo.GetAverageGrade (@StudentID INT)
RETURNS DECIMAL(4,2)
AS
BEGIN
    RETURN (
        SELECT CAST(AVG(GradeValue) AS DECIMAL(4,2))
        FROM dbo.Grades
        WHERE StudentID = @StudentID
    );
END;
GO

-- Number of lessons a student missed (status 'Absent'); 0 if none
CREATE OR ALTER FUNCTION dbo.GetAbsenceCount (@StudentID INT)
RETURNS INT
AS
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM dbo.Attendance
        WHERE StudentID = @StudentID
          AND Status = N'Absent'
    );
END;
GO

-- Highest grade of a student (NULL if the student has no grades)
CREATE OR ALTER FUNCTION dbo.GetHighestGrade (@StudentID INT)
RETURNS DECIMAL(3,1)
AS
BEGIN
    RETURN (
        SELECT MAX(GradeValue)
        FROM dbo.Grades
        WHERE StudentID = @StudentID
    );
END;
GO
