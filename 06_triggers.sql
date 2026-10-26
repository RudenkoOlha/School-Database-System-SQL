/* =====================================================================
   06_triggers.sql
   Triggers for data validation, conflict detection, audit history and
   clean-up of related data. All triggers are set-based, so they also
   work when many rows are inserted or updated at once.
   ===================================================================== */

USE SchoolDB;
GO
-- Required for the persisted computed columns used in foreign keys
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   Grades
   --------------------------------------------------------------------- */

-- CheckGrade: a grade must be between 1 and 6
CREATE OR ALTER TRIGGER dbo.CheckGrade
ON dbo.Grades
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE GradeValue < 1 OR GradeValue > 6)
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001, 'Grade must be between 1 and 6.', 1;
    END;
END;
GO

-- LogGradeChanges: stores the old and new value whenever a grade is changed
CREATE OR ALTER TRIGGER dbo.LogGradeChanges
ON dbo.Grades
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.GradeHistory (GradeID, OldGradeValue, NewGradeValue)
    SELECT i.GradeID, d.GradeValue, i.GradeValue
    FROM inserted i
    JOIN deleted  d ON d.GradeID = i.GradeID
    WHERE i.GradeValue <> d.GradeValue;
END;
GO

/* ---------------------------------------------------------------------
   Homework
   --------------------------------------------------------------------- */

-- CheckHomeworkDueDate: the due date cannot be in the past.
-- Checked only for new homework or when the due date itself is changed,
-- so old homework can still be edited (e.g. its description).
CREATE OR ALTER TRIGGER dbo.CheckHomeworkDueDate
ON dbo.Homework
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted i
        LEFT JOIN deleted d ON d.HomeworkID = i.HomeworkID
        WHERE i.DueDate < CAST(GETDATE() AS DATE)
          AND (d.HomeworkID IS NULL OR d.DueDate <> i.DueDate)
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50002, 'Homework due date cannot be in the past.', 1;
    END;
END;
GO

/* ---------------------------------------------------------------------
   Lessons
   --------------------------------------------------------------------- */

-- CheckLessonConflict: a class or a teacher cannot have two lessons at
-- the same time. The new row is excluded from the comparison
-- (l.LessonID <> i.LessonID), and cancelled lessons are ignored.
CREATE OR ALTER TRIGGER dbo.CheckLessonConflict
ON dbo.Lessons
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN dbo.Lessons l
          ON  l.LessonID       <> i.LessonID
          AND l.LessonDateTime =  i.LessonDateTime
          AND (l.ClassID = i.ClassID OR l.TeacherID = i.TeacherID)
        WHERE i.IsCancelled = 0
          AND l.IsCancelled = 0
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50003, 'Schedule conflict: the class or the teacher already has a lesson at this time.', 1;
    END;
END;
GO

-- CancelAttendanceForCancelledLesson: when a lesson is cancelled
-- (IsCancelled changes from 0 to 1), the attendance of all students
-- registered for it is set to 'Cancelled'.
CREATE OR ALTER TRIGGER dbo.CancelAttendanceForCancelledLesson
ON dbo.Lessons
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(IsCancelled)
    BEGIN
        UPDATE a
        SET Status = N'Cancelled'
        FROM dbo.Attendance a
        JOIN inserted i ON i.LessonID = a.LessonID
        JOIN deleted  d ON d.LessonID = i.LessonID
        WHERE i.IsCancelled = 1
          AND d.IsCancelled = 0;
    END;
END;
GO

/* ---------------------------------------------------------------------
   Schedules
   --------------------------------------------------------------------- */

-- LogScheduleChanges: stores the old and new day/time when a timetable slot is moved
CREATE OR ALTER TRIGGER dbo.LogScheduleChanges
ON dbo.Schedules
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.ScheduleHistory (ScheduleID, OldDayOfWeek, NewDayOfWeek, OldStartTime, NewStartTime)
    SELECT i.ScheduleID, d.DayOfWeek, i.DayOfWeek, d.StartTime, i.StartTime
    FROM inserted i
    JOIN deleted  d ON d.ScheduleID = i.ScheduleID
    WHERE i.DayOfWeek <> d.DayOfWeek
       OR i.StartTime <> d.StartTime;
END;
GO

/* ---------------------------------------------------------------------
   Students
   --------------------------------------------------------------------- */

-- DeleteStudentWithRelatedData: deleting a student first removes the
-- rows that reference them (grade comments, grade history, grades,
-- attendance, submitted homework), so the foreign keys do not block
-- the delete. The person's row in People is kept.
CREATE OR ALTER TRIGGER dbo.DeleteStudentWithRelatedData
ON dbo.Students
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DELETE gc
    FROM dbo.GradeComments gc
    JOIN dbo.Grades g ON g.GradeID   = gc.GradeID
    JOIN deleted    d ON d.StudentID = g.StudentID;

    DELETE gh
    FROM dbo.GradeHistory gh
    JOIN dbo.Grades g ON g.GradeID   = gh.GradeID
    JOIN deleted    d ON d.StudentID = g.StudentID;

    DELETE g
    FROM dbo.Grades g
    JOIN deleted d ON d.StudentID = g.StudentID;

    DELETE a
    FROM dbo.Attendance a
    JOIN deleted d ON d.StudentID = a.StudentID;

    DELETE sh
    FROM dbo.SubmittedHomework sh
    JOIN deleted d ON d.StudentID = sh.StudentID;

    DELETE s
    FROM dbo.Students s
    JOIN deleted d ON d.StudentID = s.StudentID;
END;
GO
