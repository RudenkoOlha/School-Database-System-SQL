/* =====================================================================
   05_procedures.sql
   Stored procedures for the most common operations.
   ===================================================================== */

USE SchoolDB;
GO
-- Required for the persisted computed columns used in foreign keys
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Adds a grade for a student in a subject (the date defaults to today)
CREATE OR ALTER PROCEDURE dbo.AddGrade
    @StudentID  INT,
    @SubjectID  INT,
    @GradeValue DECIMAL(3,1),
    @GradeDate  DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Grades (StudentID, SubjectID, GradeValue, GradeDate)
    VALUES (@StudentID, @SubjectID, @GradeValue, COALESCE(@GradeDate, CAST(GETDATE() AS DATE)));
END;
GO

-- Registers a student's attendance: 'Present', 'Absent' or 'Late'
CREATE OR ALTER PROCEDURE dbo.AddAttendance
    @StudentID INT,
    @LessonID  INT,
    @Status    NVARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Attendance (StudentID, LessonID, Status)
    VALUES (@StudentID, @LessonID, @Status);
END;
GO

-- Adds a homework assignment for a class
CREATE OR ALTER PROCEDURE dbo.AddHomework
    @ClassID     INT,
    @SubjectID   INT,
    @Description NVARCHAR(255),
    @DueDate     DATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Homework (ClassID, SubjectID, Description, DueDate)
    VALUES (@ClassID, @SubjectID, @Description, @DueDate);
END;
GO

-- Adds a lesson (the CheckLessonConflict trigger rejects double bookings)
CREATE OR ALTER PROCEDURE dbo.AddLesson
    @ClassID        INT,
    @SubjectID      INT,
    @TeacherID      INT,
    @LessonDateTime DATETIME2(0)
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.Lessons (ClassID, SubjectID, TeacherID, LessonDateTime)
    VALUES (@ClassID, @SubjectID, @TeacherID, @LessonDateTime);
END;
GO

-- Cancels a lesson (the CancelAttendanceForCancelledLesson trigger updates attendance)
CREATE OR ALTER PROCEDURE dbo.CancelLesson
    @LessonID INT
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM dbo.Lessons WHERE LessonID = @LessonID)
        THROW 50010, 'Lesson not found.', 1;

    UPDATE dbo.Lessons
    SET IsCancelled = 1
    WHERE LessonID = @LessonID;
END;
GO

-- Adds a new student: creates the person and enrols them in a class
-- in one transaction, and returns the new StudentID.
CREATE OR ALTER PROCEDURE dbo.AddStudent
    @FirstName      NVARCHAR(50),
    @LastName       NVARCHAR(50),
    @DateOfBirth    DATE,
    @ClassID        INT,
    @EnrollmentDate DATE = NULL,
    @NewStudentID   INT = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO dbo.People (FirstName, LastName, DateOfBirth, PersonType)
        VALUES (@FirstName, @LastName, @DateOfBirth, N'Student');

        SET @NewStudentID = SCOPE_IDENTITY();

        INSERT INTO dbo.Students (StudentID, ClassID, EnrollmentDate)
        VALUES (@NewStudentID, @ClassID, COALESCE(@EnrollmentDate, CAST(GETDATE() AS DATE)));

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
