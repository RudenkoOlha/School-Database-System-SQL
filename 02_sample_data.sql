/* =====================================================================
   02_sample_data.sql
   Inserts sample data. Run it on a freshly created database:
   IDENTITY values are generated in insert order (1, 2, 3, ...).
   ===================================================================== */

USE SchoolDB;
GO
-- Required for the persisted computed columns used in foreign keys
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

INSERT INTO People (FirstName, LastName, DateOfBirth, PersonType)
VALUES (N'Jan',        N'Kowalski',    '2009-04-12', N'Student'),  -- 1
       (N'Anna',       N'Nowak',       '1990-09-25', N'Teacher'),  -- 2
       (N'Piotr',      N'Wiśniewski',  '1982-03-14', N'Teacher'),  -- 3
       (N'Katarzyna',  N'Wójcik',      '1988-11-02', N'Teacher'),  -- 4
       (N'Zofia',      N'Lewandowska', '2009-07-21', N'Student'),  -- 5
       (N'Michał',     N'Zieliński',   '2009-01-30', N'Student'),  -- 6
       (N'Aleksandra', N'Kamińska',    '2008-10-05', N'Student'),  -- 7
       (N'Tomasz',     N'Szymański',   '2008-06-17', N'Student'),  -- 8
       (N'Natalia',    N'Dąbrowska',   '2008-12-09', N'Student');  -- 9

INSERT INTO Subjects (SubjectName)
VALUES (N'Mathematics'),  -- 1
       (N'Physics'),      -- 2
       (N'English');      -- 3

INSERT INTO Teachers (TeacherID, SubjectID, HireDate)
VALUES (2, 1, '2015-08-20'),
       (3, 2, '2012-09-01'),
       (4, 3, '2018-09-01');

INSERT INTO Classes (ClassName, HomeroomTeacherID)
VALUES (N'1A', 2),  -- 1
       (N'2A', 3);  -- 2

INSERT INTO Students (StudentID, ClassID, EnrollmentDate)
VALUES (1, 1, '2024-09-01'),
       (5, 1, '2024-09-01'),
       (6, 1, '2024-09-01'),
       (7, 2, '2023-09-01'),
       (8, 2, '2023-09-01'),
       (9, 2, '2023-09-01');

-- Weekly timetable
INSERT INTO Schedules (ClassID, SubjectID, TeacherID, DayOfWeek, StartTime)
VALUES (1, 1, 2, 1, '08:00'),  -- 1A, Monday,  Mathematics
       (1, 2, 3, 1, '08:55'),  -- 1A, Monday,  Physics
       (1, 3, 4, 2, '08:00'),  -- 1A, Tuesday, English
       (2, 2, 3, 1, '08:00'),  -- 2A, Monday,  Physics
       (2, 1, 2, 1, '08:55'),  -- 2A, Monday,  Mathematics
       (2, 3, 4, 2, '08:55');  -- 2A, Tuesday, English

-- Lessons held in the week of 17 February 2025
INSERT INTO Lessons (ClassID, SubjectID, TeacherID, LessonDateTime)
VALUES (1, 1, 2, '2025-02-17 08:00'),  -- 1
       (1, 2, 3, '2025-02-17 08:55'),  -- 2
       (2, 2, 3, '2025-02-17 08:00'),  -- 3
       (2, 1, 2, '2025-02-17 08:55'),  -- 4
       (1, 3, 4, '2025-02-18 08:00'),  -- 5
       (2, 3, 4, '2025-02-18 08:55');  -- 6

INSERT INTO Attendance (StudentID, LessonID, Status)
VALUES (1, 1, N'Present'), (5, 1, N'Present'), (6, 1, N'Absent'),
       (1, 2, N'Present'), (5, 2, N'Late'),    (6, 2, N'Absent'),
       (1, 5, N'Present'), (5, 5, N'Present'), (6, 5, N'Present'),
       (7, 3, N'Present'), (8, 3, N'Absent'),  (9, 3, N'Present'),
       (7, 4, N'Present'), (8, 4, N'Present'), (9, 4, N'Late'),
       (7, 6, N'Present'), (8, 6, N'Absent'),  (9, 6, N'Present');

INSERT INTO Grades (StudentID, SubjectID, GradeValue, GradeDate)
VALUES (1, 1, 5.0, '2025-02-18'), (1, 2, 4.0, '2025-02-20'), (1, 3, 4.5, '2025-02-21'),
       (5, 1, 3.5, '2025-02-18'), (5, 2, 4.5, '2025-02-20'), (5, 3, 5.0, '2025-02-21'),
       (6, 1, 2.0, '2025-02-18'), (6, 2, 3.0, '2025-02-20'), (6, 3, 4.0, '2025-02-21'),
       (7, 1, 6.0, '2025-02-18'), (7, 2, 5.0, '2025-02-20'), (7, 3, 5.5, '2025-02-21'),
       (8, 1, 3.0, '2025-02-18'), (8, 2, 2.5, '2025-02-20'), (8, 3, 4.0, '2025-02-21'),
       (9, 1, 4.5, '2025-02-18'), (9, 2, 5.0, '2025-02-20'), (9, 3, 3.5, '2025-02-21');

INSERT INTO Homework (ClassID, SubjectID, Description, DueDate)
VALUES (1, 1, N'Solve quadratic equations (exercises 1-10)', '2025-02-25'),  -- 1
       (1, 2, N'Lab report: free fall experiment',            '2025-02-27'),  -- 2
       (2, 3, N'Essay: my favourite book',                    '2025-02-28');  -- 3

INSERT INTO SubmittedHomework (HomeworkID, StudentID, SubmissionDate, GradeValue)
VALUES (1, 1, '2025-02-24', 4.5),
       (1, 5, '2025-02-25', 5.0),
       (2, 1, '2025-02-26', NULL),  -- submitted, not marked yet
       (3, 7, '2025-02-27', 6.0),
       (3, 9, '2025-02-28', 4.0);

INSERT INTO GradeComments (GradeID, TeacherID, CommentText)
VALUES (1,  2, N'Good work, but pay more attention to details.'),
       (7,  2, N'Please review the chapter on linear functions.'),
       (14, 3, N'Needs more practice with kinematics problems.');

INSERT INTO TeacherConsultations (TeacherID, ConsultationDateTime, Notes)
VALUES (2, '2025-03-01 14:00', N'Discussion of semester projects.'),
       (4, '2025-03-03 15:00', N'Preparation for the English exam.');

INSERT INTO SchoolEvents (EventName, EventDate, Description, OrganizerID)
VALUES (N'School Open Day', '2025-04-15', N'Presentation of the school for future students.', 2),
       (N'Science Fair',    '2025-05-20', N'Student projects in physics and mathematics.',    3);
GO
