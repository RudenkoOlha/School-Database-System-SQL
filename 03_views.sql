/* =====================================================================
   03_views.sql
   9 views that join the tables into readable reports.
   ===================================================================== */

USE SchoolDB;
GO
-- Required for the persisted computed columns used in foreign keys
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- Students with their personal data and class
CREATE OR ALTER VIEW dbo.vw_Students AS
SELECT s.StudentID,
       p.FirstName,
       p.LastName,
       p.DateOfBirth,
       c.ClassName,
       s.EnrollmentDate
FROM dbo.Students s
JOIN dbo.People   p ON p.PersonID = s.StudentID
JOIN dbo.Classes  c ON c.ClassID  = s.ClassID;
GO

-- Teachers with the subject they teach and their hire date
CREATE OR ALTER VIEW dbo.vw_Teachers AS
SELECT t.TeacherID,
       p.FirstName,
       p.LastName,
       sub.SubjectName,
       t.HireDate
FROM dbo.Teachers t
JOIN dbo.People   p   ON p.PersonID    = t.TeacherID
JOIN dbo.Subjects sub ON sub.SubjectID = t.SubjectID;
GO

-- All grades with student, class and subject
CREATE OR ALTER VIEW dbo.vw_Grades AS
SELECT g.GradeID,
       g.StudentID,
       p.FirstName,
       p.LastName,
       c.ClassName,
       sub.SubjectName,
       g.GradeValue,
       g.GradeDate
FROM dbo.Grades   g
JOIN dbo.Students s   ON s.StudentID   = g.StudentID
JOIN dbo.People   p   ON p.PersonID    = s.StudentID
JOIN dbo.Classes  c   ON c.ClassID     = s.ClassID
JOIN dbo.Subjects sub ON sub.SubjectID = g.SubjectID;
GO

-- Lessons with class, subject, teacher's full name and status
CREATE OR ALTER VIEW dbo.vw_Lessons AS
SELECT l.LessonID,
       c.ClassName,
       sub.SubjectName,
       p.FirstName + N' ' + p.LastName AS TeacherName,
       l.LessonDateTime,
       CASE WHEN l.IsCancelled = 1 THEN N'Cancelled' ELSE N'Scheduled' END AS LessonStatus
FROM dbo.Lessons  l
JOIN dbo.Classes  c   ON c.ClassID     = l.ClassID
JOIN dbo.Subjects sub ON sub.SubjectID = l.SubjectID
JOIN dbo.People   p   ON p.PersonID    = l.TeacherID;
GO

-- Attendance of students in lessons
CREATE OR ALTER VIEW dbo.vw_Attendance AS
SELECT a.AttendanceID,
       a.StudentID,
       p.FirstName,
       p.LastName,
       c.ClassName,
       sub.SubjectName,
       l.LessonDateTime,
       a.Status
FROM dbo.Attendance a
JOIN dbo.People     p   ON p.PersonID    = a.StudentID
JOIN dbo.Lessons    l   ON l.LessonID    = a.LessonID
JOIN dbo.Classes    c   ON c.ClassID     = l.ClassID
JOIN dbo.Subjects   sub ON sub.SubjectID = l.SubjectID;
GO

-- Homework assigned to classes
CREATE OR ALTER VIEW dbo.vw_Homework AS
SELECT h.HomeworkID,
       c.ClassName,
       sub.SubjectName,
       h.Description,
       h.DueDate
FROM dbo.Homework h
JOIN dbo.Classes  c   ON c.ClassID     = h.ClassID
JOIN dbo.Subjects sub ON sub.SubjectID = h.SubjectID;
GO

-- Submitted homework with student, subject, submission date and grade
CREATE OR ALTER VIEW dbo.vw_SubmittedHomework AS
SELECT sh.SubmissionID,
       p.FirstName,
       p.LastName,
       sub.SubjectName,
       h.Description,
       h.DueDate,
       sh.SubmissionDate,
       CASE WHEN sh.SubmissionDate > h.DueDate THEN 1 ELSE 0 END AS IsLate,
       sh.GradeValue
FROM dbo.SubmittedHomework sh
JOIN dbo.Homework h   ON h.HomeworkID  = sh.HomeworkID
JOIN dbo.People   p   ON p.PersonID    = sh.StudentID
JOIN dbo.Subjects sub ON sub.SubjectID = h.SubjectID;
GO

-- Teachers' comments on grades, with both the student's and the teacher's name
CREATE OR ALTER VIEW dbo.vw_GradeComments AS
SELECT gc.CommentID,
       st.FirstName + N' ' + st.LastName AS StudentName,
       sub.SubjectName,
       g.GradeValue,
       te.FirstName + N' ' + te.LastName AS TeacherName,
       gc.CommentText
FROM dbo.GradeComments gc
JOIN dbo.Grades   g   ON g.GradeID     = gc.GradeID
JOIN dbo.People   st  ON st.PersonID   = g.StudentID
JOIN dbo.Subjects sub ON sub.SubjectID = g.SubjectID
JOIN dbo.People   te  ON te.PersonID   = gc.TeacherID;
GO

-- Teachers' consultations
CREATE OR ALTER VIEW dbo.vw_Consultations AS
SELECT tc.ConsultationID,
       p.FirstName + N' ' + p.LastName AS TeacherName,
       tc.ConsultationDateTime,
       tc.Notes
FROM dbo.TeacherConsultations tc
JOIN dbo.People p ON p.PersonID = tc.TeacherID;
GO
