/* =====================================================================
   09_tests.sql
   Checks that the triggers and procedures work as intended.
   Each test prints PASS or FAIL. Tests that change data run inside a
   transaction that is rolled back at the end, so the sample data stays
   the same.
   ===================================================================== */

USE SchoolDB;
GO
-- Required for the persisted computed columns used in foreign keys
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO
SET NOCOUNT ON;
GO

/* ---------- Validation: these operations must be rejected ---------- */

PRINT 'Test 1 - CheckGrade rejects a grade of 7';
BEGIN TRY
    EXEC dbo.AddGrade @StudentID = 1, @SubjectID = 1, @GradeValue = 7.0;
    PRINT '  FAIL: the grade was accepted';
END TRY
BEGIN CATCH
    PRINT CASE WHEN ERROR_NUMBER() = 50001 THEN '  PASS: ' ELSE '  FAIL: ' END + ERROR_MESSAGE();
END CATCH;
GO

PRINT 'Test 2 - CheckHomeworkDueDate rejects a due date in the past';
BEGIN TRY
    EXEC dbo.AddHomework @ClassID = 1, @SubjectID = 1,
         @Description = N'Old homework', @DueDate = '2020-01-01';
    PRINT '  FAIL: the homework was accepted';
END TRY
BEGIN CATCH
    PRINT CASE WHEN ERROR_NUMBER() = 50002 THEN '  PASS: ' ELSE '  FAIL: ' END + ERROR_MESSAGE();
END CATCH;
GO

PRINT 'Test 3 - CheckLessonConflict rejects a second lesson for the same class at the same time';
BEGIN TRY
    EXEC dbo.AddLesson @ClassID = 1, @SubjectID = 3, @TeacherID = 4,
         @LessonDateTime = '2025-02-17 08:00';
    PRINT '  FAIL: the lesson was accepted';
END TRY
BEGIN CATCH
    PRINT CASE WHEN ERROR_NUMBER() = 50003 THEN '  PASS: ' ELSE '  FAIL: ' END + ERROR_MESSAGE();
END CATCH;
GO

PRINT 'Test 4 - CheckLessonConflict rejects a teacher teaching two classes at the same time';
BEGIN TRY
    EXEC dbo.AddLesson @ClassID = 2, @SubjectID = 1, @TeacherID = 2,
         @LessonDateTime = '2025-02-17 08:00';
    PRINT '  FAIL: the lesson was accepted';
END TRY
BEGIN CATCH
    PRINT CASE WHEN ERROR_NUMBER() = 50003 THEN '  PASS: ' ELSE '  FAIL: ' END + ERROR_MESSAGE();
END CATCH;
GO

PRINT 'Test 5 - A person of type Teacher cannot be enrolled as a student';
BEGIN TRY
    INSERT INTO dbo.Students (StudentID, ClassID, EnrollmentDate) VALUES (2, 1, '2024-09-01');
    PRINT '  FAIL: the teacher was enrolled as a student';
END TRY
BEGIN CATCH
    PRINT CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%FK_Students_People%'
               THEN '  PASS: rejected by the foreign key FK_Students_People'
               ELSE '  FAIL: ' + ERROR_MESSAGE() END;
END CATCH;
GO

/* ---------- Behaviour: changes run in a transaction and are rolled back ---------- */

BEGIN TRANSACTION;

DECLARE @n INT, @before INT;

PRINT 'Test 6 - A free time slot is accepted by AddLesson';
SELECT @before = COUNT(*) FROM dbo.Lessons;
EXEC dbo.AddLesson @ClassID = 1, @SubjectID = 1, @TeacherID = 2, @LessonDateTime = '2025-02-19 10:00';
SELECT @n = COUNT(*) FROM dbo.Lessons;
PRINT CASE WHEN @n = @before + 1 THEN '  PASS' ELSE '  FAIL' END;

PRINT 'Test 7 - LogGradeChanges records a changed grade in GradeHistory';
UPDATE dbo.Grades SET GradeValue = 4.0 WHERE GradeID = 7;   -- was 2.0
SELECT @n = COUNT(*) FROM dbo.GradeHistory
WHERE GradeID = 7 AND OldGradeValue = 2.0 AND NewGradeValue = 4.0;
PRINT CASE WHEN @n = 1 THEN '  PASS' ELSE '  FAIL' END;

PRINT 'Test 8 - LogScheduleChanges records a moved timetable slot';
UPDATE dbo.Schedules SET StartTime = '09:50' WHERE ScheduleID = 1;  -- was 08:00
SELECT @n = COUNT(*) FROM dbo.ScheduleHistory
WHERE ScheduleID = 1 AND OldStartTime = '08:00' AND NewStartTime = '09:50';
PRINT CASE WHEN @n = 1 THEN '  PASS' ELSE '  FAIL' END;

PRINT 'Test 9 - CancelLesson sets the attendance of that lesson to Cancelled';
EXEC dbo.CancelLesson @LessonID = 2;
SELECT @n = COUNT(*) FROM dbo.Attendance WHERE LessonID = 2 AND Status <> N'Cancelled';
PRINT CASE WHEN @n = 0 THEN '  PASS' ELSE '  FAIL' END;

PRINT 'Test 10 - AddStudent creates the person and the enrolment in one step';
DECLARE @NewID INT;
EXEC dbo.AddStudent @FirstName = N'Ewa', @LastName = N'Mazur', @DateOfBirth = '2009-05-05',
     @ClassID = 1, @NewStudentID = @NewID OUTPUT;
SELECT @n = COUNT(*) FROM dbo.vw_Students WHERE StudentID = @NewID AND LastName = N'Mazur';
PRINT CASE WHEN @n = 1 THEN '  PASS (new StudentID = ' + CAST(@NewID AS VARCHAR(10)) + ')' ELSE '  FAIL' END;

PRINT 'Test 11 - Deleting a student also removes their grades, comments, attendance and homework';
DELETE FROM dbo.Students WHERE StudentID = 6;
SELECT @n = (SELECT COUNT(*) FROM dbo.Students          WHERE StudentID = 6)
          + (SELECT COUNT(*) FROM dbo.Grades            WHERE StudentID = 6)
          + (SELECT COUNT(*) FROM dbo.Attendance        WHERE StudentID = 6)
          + (SELECT COUNT(*) FROM dbo.SubmittedHomework WHERE StudentID = 6)
          + (SELECT COUNT(*) FROM dbo.GradeComments     WHERE GradeID = 7);
PRINT CASE WHEN @n = 0 THEN '  PASS' ELSE '  FAIL' END;

ROLLBACK TRANSACTION;
PRINT 'All changes from tests 6-11 were rolled back.';
GO
