/* =====================================================================
   01_tables.sql
   Creates 16 tables with primary keys, foreign keys, CHECK / UNIQUE
   constraints and indexes on the columns used in joins and filters.
   ===================================================================== */

USE SchoolDB;
GO
-- Required for the persisted computed columns used in foreign keys
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

/* ---------------------------------------------------------------------
   People: supertype table for students and teachers
   (Table-per-Type inheritance: People -> Students / Teachers).
   The UNIQUE (PersonID, PersonType) constraint lets the subtype tables
   check that a person is of the right type (see Students and Teachers).
   --------------------------------------------------------------------- */
CREATE TABLE People (
    PersonID     INT IDENTITY(1,1) CONSTRAINT PK_People PRIMARY KEY,
    FirstName    NVARCHAR(50) NOT NULL,
    LastName     NVARCHAR(50) NOT NULL,
    DateOfBirth  DATE         NOT NULL,
    PersonType   NVARCHAR(10) NOT NULL
        CONSTRAINT CK_People_PersonType CHECK (PersonType IN (N'Student', N'Teacher')),
    CONSTRAINT UQ_People_PersonID_PersonType UNIQUE (PersonID, PersonType)
);
CREATE INDEX IX_People_LastName ON People (LastName);

CREATE TABLE Subjects (
    SubjectID    INT IDENTITY(1,1) CONSTRAINT PK_Subjects PRIMARY KEY,
    SubjectName  NVARCHAR(100) NOT NULL CONSTRAINT UQ_Subjects_SubjectName UNIQUE
);

-- Only a person with PersonType = 'Teacher' can be added here
CREATE TABLE Teachers (
    TeacherID   INT CONSTRAINT PK_Teachers PRIMARY KEY,
    PersonType  AS CAST(N'Teacher' AS NVARCHAR(10)) PERSISTED,
    SubjectID   INT  NOT NULL,
    HireDate    DATE NOT NULL,
    CONSTRAINT FK_Teachers_People   FOREIGN KEY (TeacherID, PersonType) REFERENCES People (PersonID, PersonType),
    CONSTRAINT FK_Teachers_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects (SubjectID)
);
CREATE INDEX IX_Teachers_SubjectID ON Teachers (SubjectID);

CREATE TABLE Classes (
    ClassID            INT IDENTITY(1,1) CONSTRAINT PK_Classes PRIMARY KEY,
    ClassName          NVARCHAR(20) NOT NULL CONSTRAINT UQ_Classes_ClassName UNIQUE,
    HomeroomTeacherID  INT NULL,
    CONSTRAINT FK_Classes_Teachers FOREIGN KEY (HomeroomTeacherID) REFERENCES Teachers (TeacherID)
);

-- Only a person with PersonType = 'Student' can be added here
CREATE TABLE Students (
    StudentID       INT CONSTRAINT PK_Students PRIMARY KEY,
    PersonType      AS CAST(N'Student' AS NVARCHAR(10)) PERSISTED,
    ClassID         INT  NOT NULL,
    EnrollmentDate  DATE NOT NULL,
    CONSTRAINT FK_Students_People  FOREIGN KEY (StudentID, PersonType) REFERENCES People (PersonID, PersonType),
    CONSTRAINT FK_Students_Classes FOREIGN KEY (ClassID) REFERENCES Classes (ClassID)
);
CREATE INDEX IX_Students_ClassID ON Students (ClassID);

-- Individual lessons. A cancelled lesson is kept and marked with IsCancelled = 1.
CREATE TABLE Lessons (
    LessonID        INT IDENTITY(1,1) CONSTRAINT PK_Lessons PRIMARY KEY,
    ClassID         INT          NOT NULL,
    SubjectID       INT          NOT NULL,
    TeacherID       INT          NOT NULL,
    LessonDateTime  DATETIME2(0) NOT NULL,
    IsCancelled     BIT          NOT NULL CONSTRAINT DF_Lessons_IsCancelled DEFAULT (0),
    CONSTRAINT FK_Lessons_Classes  FOREIGN KEY (ClassID)   REFERENCES Classes (ClassID),
    CONSTRAINT FK_Lessons_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects (SubjectID),
    CONSTRAINT FK_Lessons_Teachers FOREIGN KEY (TeacherID) REFERENCES Teachers (TeacherID)
);
CREATE INDEX IX_Lessons_ClassID_LessonDateTime   ON Lessons (ClassID, LessonDateTime);
CREATE INDEX IX_Lessons_TeacherID_LessonDateTime ON Lessons (TeacherID, LessonDateTime);

-- Grades on the Polish school scale 1-6 (half grades allowed, e.g. 4.5)
CREATE TABLE Grades (
    GradeID     INT IDENTITY(1,1) CONSTRAINT PK_Grades PRIMARY KEY,
    StudentID   INT          NOT NULL,
    SubjectID   INT          NOT NULL,
    GradeValue  DECIMAL(3,1) NOT NULL,
    GradeDate   DATE         NOT NULL CONSTRAINT DF_Grades_GradeDate DEFAULT (CAST(GETDATE() AS DATE)),
    CONSTRAINT FK_Grades_Students FOREIGN KEY (StudentID) REFERENCES Students (StudentID),
    CONSTRAINT FK_Grades_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects (SubjectID)
);
CREATE INDEX IX_Grades_StudentID ON Grades (StudentID);
CREATE INDEX IX_Grades_SubjectID ON Grades (SubjectID);

-- Weekly timetable (1 = Monday ... 5 = Friday)
CREATE TABLE Schedules (
    ScheduleID  INT IDENTITY(1,1) CONSTRAINT PK_Schedules PRIMARY KEY,
    ClassID     INT     NOT NULL,
    SubjectID   INT     NOT NULL,
    TeacherID   INT     NOT NULL,
    DayOfWeek   TINYINT NOT NULL CONSTRAINT CK_Schedules_DayOfWeek CHECK (DayOfWeek BETWEEN 1 AND 5),
    StartTime   TIME(0) NOT NULL,
    CONSTRAINT FK_Schedules_Classes  FOREIGN KEY (ClassID)   REFERENCES Classes (ClassID),
    CONSTRAINT FK_Schedules_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects (SubjectID),
    CONSTRAINT FK_Schedules_Teachers FOREIGN KEY (TeacherID) REFERENCES Teachers (TeacherID),
    CONSTRAINT UQ_Schedules_Class_Slot UNIQUE (ClassID, DayOfWeek, StartTime)
);

-- Audit table: filled automatically by the LogGradeChanges trigger
CREATE TABLE GradeHistory (
    HistoryID      INT IDENTITY(1,1) CONSTRAINT PK_GradeHistory PRIMARY KEY,
    GradeID        INT          NOT NULL,
    OldGradeValue  DECIMAL(3,1) NOT NULL,
    NewGradeValue  DECIMAL(3,1) NOT NULL,
    ChangedAt      DATETIME2(0) NOT NULL CONSTRAINT DF_GradeHistory_ChangedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_GradeHistory_Grades FOREIGN KEY (GradeID) REFERENCES Grades (GradeID)
);
CREATE INDEX IX_GradeHistory_GradeID ON GradeHistory (GradeID);

-- Audit table: filled automatically by the LogScheduleChanges trigger
CREATE TABLE ScheduleHistory (
    HistoryID     INT IDENTITY(1,1) CONSTRAINT PK_ScheduleHistory PRIMARY KEY,
    ScheduleID    INT          NOT NULL,
    OldDayOfWeek  TINYINT      NOT NULL,
    NewDayOfWeek  TINYINT      NOT NULL,
    OldStartTime  TIME(0)      NOT NULL,
    NewStartTime  TIME(0)      NOT NULL,
    ChangedAt     DATETIME2(0) NOT NULL CONSTRAINT DF_ScheduleHistory_ChangedAt DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_ScheduleHistory_Schedules FOREIGN KEY (ScheduleID) REFERENCES Schedules (ScheduleID)
);
CREATE INDEX IX_ScheduleHistory_ScheduleID ON ScheduleHistory (ScheduleID);

-- One attendance record per student per lesson
CREATE TABLE Attendance (
    AttendanceID  INT IDENTITY(1,1) CONSTRAINT PK_Attendance PRIMARY KEY,
    StudentID     INT          NOT NULL,
    LessonID      INT          NOT NULL,
    Status        NVARCHAR(20) NOT NULL
        CONSTRAINT CK_Attendance_Status CHECK (Status IN (N'Present', N'Absent', N'Late', N'Cancelled')),
    CONSTRAINT FK_Attendance_Students FOREIGN KEY (StudentID) REFERENCES Students (StudentID),
    CONSTRAINT FK_Attendance_Lessons  FOREIGN KEY (LessonID)  REFERENCES Lessons (LessonID),
    CONSTRAINT UQ_Attendance_Student_Lesson UNIQUE (StudentID, LessonID)
);
CREATE INDEX IX_Attendance_LessonID ON Attendance (LessonID);

CREATE TABLE Homework (
    HomeworkID   INT IDENTITY(1,1) CONSTRAINT PK_Homework PRIMARY KEY,
    ClassID      INT           NOT NULL,
    SubjectID    INT           NOT NULL,
    Description  NVARCHAR(255) NOT NULL,
    DueDate      DATE          NOT NULL,
    CONSTRAINT FK_Homework_Classes  FOREIGN KEY (ClassID)   REFERENCES Classes (ClassID),
    CONSTRAINT FK_Homework_Subjects FOREIGN KEY (SubjectID) REFERENCES Subjects (SubjectID)
);
CREATE INDEX IX_Homework_ClassID ON Homework (ClassID);

-- One submission per student per homework; the grade is NULL until it is marked
CREATE TABLE SubmittedHomework (
    SubmissionID    INT IDENTITY(1,1) CONSTRAINT PK_SubmittedHomework PRIMARY KEY,
    HomeworkID      INT          NOT NULL,
    StudentID       INT          NOT NULL,
    SubmissionDate  DATE         NOT NULL,
    GradeValue      DECIMAL(3,1) NULL
        CONSTRAINT CK_SubmittedHomework_GradeValue CHECK (GradeValue BETWEEN 1 AND 6),
    CONSTRAINT FK_SubmittedHomework_Homework FOREIGN KEY (HomeworkID) REFERENCES Homework (HomeworkID),
    CONSTRAINT FK_SubmittedHomework_Students FOREIGN KEY (StudentID)  REFERENCES Students (StudentID),
    CONSTRAINT UQ_SubmittedHomework_Homework_Student UNIQUE (HomeworkID, StudentID)
);
CREATE INDEX IX_SubmittedHomework_StudentID ON SubmittedHomework (StudentID);

CREATE TABLE GradeComments (
    CommentID    INT IDENTITY(1,1) CONSTRAINT PK_GradeComments PRIMARY KEY,
    GradeID      INT           NOT NULL,
    TeacherID    INT           NOT NULL,
    CommentText  NVARCHAR(255) NOT NULL,
    CONSTRAINT FK_GradeComments_Grades   FOREIGN KEY (GradeID)   REFERENCES Grades (GradeID),
    CONSTRAINT FK_GradeComments_Teachers FOREIGN KEY (TeacherID) REFERENCES Teachers (TeacherID)
);
CREATE INDEX IX_GradeComments_GradeID ON GradeComments (GradeID);

CREATE TABLE TeacherConsultations (
    ConsultationID        INT IDENTITY(1,1) CONSTRAINT PK_TeacherConsultations PRIMARY KEY,
    TeacherID             INT           NOT NULL,
    ConsultationDateTime  DATETIME2(0)  NOT NULL,
    Notes                 NVARCHAR(255) NULL,
    CONSTRAINT FK_TeacherConsultations_Teachers FOREIGN KEY (TeacherID) REFERENCES Teachers (TeacherID)
);

CREATE TABLE SchoolEvents (
    EventID      INT IDENTITY(1,1) CONSTRAINT PK_SchoolEvents PRIMARY KEY,
    EventName    NVARCHAR(100) NOT NULL,
    EventDate    DATE          NOT NULL,
    Description  NVARCHAR(255) NULL,
    OrganizerID  INT           NULL,
    CONSTRAINT FK_SchoolEvents_Teachers FOREIGN KEY (OrganizerID) REFERENCES Teachers (TeacherID)
);
GO
