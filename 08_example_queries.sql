/* =====================================================================
   08_example_queries.sql
   Everyday queries and a few reporting queries (aggregates, window
   functions, conditional counts).
   ===================================================================== */

USE SchoolDB;
GO
-- Required for the persisted computed columns used in foreign keys
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

-- 1. All students with their class
SELECT p.FirstName, p.LastName, c.ClassName
FROM dbo.Students s
JOIN dbo.People  p ON p.PersonID = s.StudentID
JOIN dbo.Classes c ON c.ClassID  = s.ClassID
ORDER BY c.ClassName, p.LastName;

-- 2. All grades of one student with subjects and dates
SELECT sub.SubjectName, g.GradeValue, g.GradeDate
FROM dbo.Grades   g
JOIN dbo.Subjects sub ON sub.SubjectID = g.SubjectID
WHERE g.StudentID = 1
ORDER BY g.GradeDate;

-- 3. Lessons of one class with subject, teacher and time
SELECT sub.SubjectName,
       p.FirstName + N' ' + p.LastName AS TeacherName,
       l.LessonDateTime
FROM dbo.Lessons  l
JOIN dbo.Subjects sub ON sub.SubjectID = l.SubjectID
JOIN dbo.People   p   ON p.PersonID    = l.TeacherID
WHERE l.ClassID = 1
  AND l.IsCancelled = 0
ORDER BY l.LessonDateTime;

-- 4. Average grade of every student (uses the GetAverageGrade function)
SELECT p.FirstName, p.LastName, dbo.GetAverageGrade(s.StudentID) AS AverageGrade
FROM dbo.Students s
JOIN dbo.People   p ON p.PersonID = s.StudentID
ORDER BY AverageGrade DESC;

-- 5. Teachers and the subjects they teach
SELECT FirstName, LastName, SubjectName
FROM dbo.vw_Teachers
ORDER BY LastName;

-- 6. Student ranking within each class by average grade (window function)
SELECT ClassName,
       FirstName + N' ' + LastName AS Student,
       CAST(AVG(GradeValue) AS DECIMAL(4,2)) AS AverageGrade,
       RANK() OVER (PARTITION BY ClassName ORDER BY AVG(GradeValue) DESC) AS RankInClass
FROM dbo.vw_Grades
GROUP BY ClassName, StudentID, FirstName, LastName
ORDER BY ClassName, RankInClass;

-- 7. Attendance rate per student (cancelled lessons are not counted)
SELECT p.FirstName + N' ' + p.LastName AS Student,
       COUNT(*) AS Lessons,
       SUM(CASE WHEN a.Status = N'Absent' THEN 1 ELSE 0 END) AS Absences,
       SUM(CASE WHEN a.Status = N'Late'   THEN 1 ELSE 0 END) AS LateArrivals,
       CAST(100.0 * SUM(CASE WHEN a.Status IN (N'Present', N'Late') THEN 1 ELSE 0 END)
            / COUNT(*) AS DECIMAL(5,1)) AS AttendanceRatePct
FROM dbo.Attendance a
JOIN dbo.People     p ON p.PersonID = a.StudentID
WHERE a.Status <> N'Cancelled'
GROUP BY p.FirstName, p.LastName
ORDER BY AttendanceRatePct, Student;

-- 8. Average grade per class and subject
SELECT ClassName, SubjectName,
       CAST(AVG(GradeValue) AS DECIMAL(4,2)) AS AverageGrade,
       COUNT(*) AS NumberOfGrades
FROM dbo.vw_Grades
GROUP BY ClassName, SubjectName
ORDER BY ClassName, SubjectName;

-- 9. Students at risk: any grade below 3.0 or more than one absence
SELECT p.FirstName + N' ' + p.LastName AS Student,
       dbo.GetAverageGrade(s.StudentID) AS AverageGrade,
       dbo.GetAbsenceCount(s.StudentID) AS Absences
FROM dbo.Students s
JOIN dbo.People   p ON p.PersonID = s.StudentID
WHERE EXISTS (SELECT 1 FROM dbo.Grades g WHERE g.StudentID = s.StudentID AND g.GradeValue < 3.0)
   OR dbo.GetAbsenceCount(s.StudentID) > 1;

-- 10. Homework submission rate per assignment
SELECT h.HomeworkID,
       h.ClassName,
       h.SubjectName,
       h.Description,
       COUNT(sh.SubmissionID) AS Submitted,
       (SELECT COUNT(*) FROM dbo.Students s JOIN dbo.Classes c ON c.ClassID = s.ClassID
        WHERE c.ClassName = h.ClassName) AS StudentsInClass
FROM dbo.vw_Homework h
LEFT JOIN dbo.SubmittedHomework sh ON sh.HomeworkID = h.HomeworkID
GROUP BY h.HomeworkID, h.ClassName, h.SubjectName, h.Description
ORDER BY h.HomeworkID;
GO
