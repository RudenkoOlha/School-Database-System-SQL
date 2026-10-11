# School Database System (SQL Server + Python GUI)

A relational database system designed to manage school data: students, teachers, classes, grades, schedules, attendance, and homework. The project includes over 15 normalized tables, several views and functions, stored procedures, and data safety mechanisms such as backup strategies. Additionally, a simple Python GUI (Tkinter) was created for managing the People table.

**Stack:** SQL Server (T-SQL), Python 3.10, Tkinter, pyodbc.

##  Key Features
- **16 normalized tables** including historical and backup-supporting tables
- **Views** for efficient querying and data presentation
- **Stored procedures and triggers** for business logic
- **Inheritance** via Table-per-Hierarchy for people (students and teachers)
- **Data-changing attributes tracked** (e.g. grades, schedules, attendance status)
- **Python GUI (Tkinter)** for CRUD operations on the `People` table
- **Backup strategy** for data protection

## System Features
 **Student management** – adding, modifying, and deleting student information.  
 **Grade tracking** – recording and updating grades and teacher comments.  
 **Lesson scheduling** – creating class timetables with assigned teachers.  
 **Homework management** – adding, grading, and storing information about submitted assignments.  
 **Attendance monitoring** – recording student attendance in classes.  
 **Consultations and events** – organizing teacher consultations and school events.  
 **Data security** – implementing procedures for database protection and recovery in case of failure.

## Tables created:
- `Osoby` 
- `Uczniowie`, `Nauczyciele`, `Przedmioty`, `Klasy`
- `Lekcje`, `Oceny`, `Obecnosci`
- `Harmonogramy`, `HistoriaOcen`, `HistoriaHarmonogramow`
- `PraceDomowe`, `OddanePraceDomowe`
- `KomentarzeOcen`, `KonsultacjeNauczycieli`, `WydarzeniaSzkolne`

Each table is defined with proper keys, foreign key constraints, and indexes.

## SQL Code
### Creating tables 
( with indexes and inserting data)

```sql 
CREATE TABLE Osoby (
OsobaID INT PRIMARY KEY IDENTITY,
Imie NVARCHAR(50),
Nazwisko NVARCHAR(50),
DataUrodzenia DATE,
TypOsoby NVARCHAR(10) CHECK (TypOsoby IN ('Uczen', 'Nauczyciel'))
);
CREATE INDEX idx_osoby_nazwisko ON Osoby (Nazwisko);

INSERT INTO Osoby (Imie, Nazwisko, DataUrodzenia, TypOsoby)
VALUES ('Jan', 'Kowalski', '2005-04-12', 'Uczen'),
('Anna', 'Nowak', '1990-09-25', 'Nauczyciel');

CREATE TABLE Przedmioty (
PrzedmiotID INT PRIMARY KEY IDENTITY,
NazwaPrzedmiotu NVARCHAR(100)
);
INSERT INTO Przedmioty (NazwaPrzedmiotu)
VALUES ('Matematyka'),
('Fizyka');

CREATE TABLE Nauczyciele (
NauczycielID INT PRIMARY KEY,
PrzedmiotID INT,
DataZatrudnienia DATE,
FOREIGN KEY (NauczycielID) REFERENCES Osoby(OsobaID),
FOREIGN KEY (PrzedmiotID) REFERENCES Przedmioty(PrzedmiotID)
);
CREATE INDEX idx_nauczyciele_przedmiot ON Nauczyciele (PrzedmiotID);

INSERT INTO Nauczyciele (NauczycielID, PrzedmiotID, DataZatrudnienia)
VALUES (2, 1, '2015-08-20');

CREATE TABLE Klasy (
KlasaID INT PRIMARY KEY IDENTITY,
NazwaKlasy NVARCHAR(50),
NauczycielID INT,
FOREIGN KEY (NauczycielID) REFERENCES Nauczyciele(NauczycielID)
);
INSERT INTO Klasy (NazwaKlasy, NauczycielID)
VALUES ('1A', 2);


CREATE TABLE Uczniowie (
UczenID INT PRIMARY KEY,
KlasaID INT,
DataZapisania DATE,
FOREIGN KEY (UczenID) REFERENCES Osoby(OsobaID),
FOREIGN KEY (KlasaID) REFERENCES Klasy(KlasaID)
);
CREATE INDEX idx_uczniowie_klasa ON Uczniowie (KlasaID);

INSERT INTO Uczniowie (UczenID, KlasaID, DataZapisania)
VALUES (1, 1, '2020-09-01');

CREATE TABLE Lekcje (
LekcjaID INT PRIMARY KEY IDENTITY,
KlasaID INT,
PrzedmiotID INT,
NauczycielID INT,
DataGodzinaLekcji DATETIME,
FOREIGN KEY (KlasaID) REFERENCES Klasy(KlasaID),
FOREIGN KEY (PrzedmiotID) REFERENCES Przedmioty(PrzedmiotID),
FOREIGN KEY (NauczycielID) REFERENCES Nauczyciele(NauczycielID)
);
CREATE INDEX idx_lekcje_klasa ON Lekcje (KlasaID);
CREATE INDEX idx_lekcje_nauczyciel ON Lekcje (NauczycielID);

INSERT INTO Lekcje (KlasaID, PrzedmiotID, NauczycielID, DataGodzinaLekcji)
VALUES (1, 1, 2, '2024-02-19 08:00:00');

CREATE TABLE Oceny (
OcenaID INT PRIMARY KEY IDENTITY,
UczenID INT,
PrzedmiotID INT,
WartoscOceny DECIMAL(3,1),
DataOceny DATE,
FOREIGN KEY (UczenID) REFERENCES Uczniowie(UczenID),
FOREIGN KEY (PrzedmiotID) REFERENCES Przedmioty(PrzedmiotID)
);
CREATE INDEX idx_oceny_uczen ON Oceny (UczenID);
CREATE INDEX idx_oceny_przedmiot ON Oceny (PrzedmiotID);

INSERT INTO Oceny (UczenID, PrzedmiotID, WartoscOceny, DataOceny)
VALUES (1, 1, 5.0, '2024-02-18');

CREATE TABLE Harmonogramy (
HarmonogramID INT PRIMARY KEY IDENTITY,
KlasaID INT,
PrzedmiotID INT,
NauczycielID INT,
GodzinaLekcji TIME,
FOREIGN KEY (KlasaID) REFERENCES Klasy(KlasaID),
FOREIGN KEY (PrzedmiotID) REFERENCES Przedmioty(PrzedmiotID),
FOREIGN KEY (NauczycielID) REFERENCES Nauczyciele(NauczycielID)
);

INSERT INTO Harmonogramy (KlasaID, PrzedmiotID, NauczycielID, GodzinaLekcji)
VALUES (1, 1, 2, '08:00:00');

CREATE TABLE HistoriaOcen (
HistoriaID INT PRIMARY KEY IDENTITY,
UczenID INT,
PrzedmiotID INT,
StaraWartoscOceny DECIMAL(3,1),
NowaWartoscOceny DECIMAL(3,1),
DataZmiany DATETIME,
FOREIGN KEY (UczenID) REFERENCES Uczniowie(UczenID),
FOREIGN KEY (PrzedmiotID) REFERENCES Przedmioty(PrzedmiotID)
);

INSERT INTO HistoriaOcen (UczenID, PrzedmiotID, StaraWartoscOceny, NowaWartoscOceny,
DataZmiany)
VALUES (1, 1, 3.5, 4.0, '2025-02-01 14:30:00');

CREATE TABLE HistoriaHarmonogramow (
HistoriaID INT PRIMARY KEY IDENTITY,
HarmonogramID INT,
StaraGodzinaLekcji TIME,
NowaGodzinaLekcji TIME,
DataZmiany DATETIME,
FOREIGN KEY (HarmonogramID) REFERENCES Harmonogramy(HarmonogramID)
);

INSERT INTO HistoriaHarmonogramow (HarmonogramID, StaraGodzinaLekcji, NowaGodzinaLekcji,
DataZmiany)
VALUES (1, '08:00:00', '08:30:00', '2025-02-01 15:00:00');

CREATE TABLE Obecnosci (
ObecnoscID INT PRIMARY KEY IDENTITY,
UczenID INT,
LekcjaID INT,
Status NVARCHAR(20) CHECK (Status IN ('Obecny', 'Nieobecny', 'Spozniony')),
FOREIGN KEY (UczenID) REFERENCES Uczniowie(UczenID),
FOREIGN KEY (LekcjaID) REFERENCES Lekcje(LekcjaID)
);
CREATE INDEX idx_obecnosci_uczen ON Obecnosci (UczenID);

INSERT INTO Obecnosci (UczenID, LekcjaID, Status)
VALUES (1, 1, 'Obecny');

CREATE TABLE PraceDomowe (
PracaDomowaID INT PRIMARY KEY IDENTITY,
KlasaID INT,
PrzedmiotID INT,
Opis NVARCHAR(255),
TerminOddania DATE,
FOREIGN KEY (KlasaID) REFERENCES Klasy(KlasaID),
FOREIGN KEY (PrzedmiotID) REFERENCES Przedmioty(PrzedmiotID)
);
CREATE INDEX idx_pracedomowe_klasa ON PraceDomowe (KlasaID);

INSERT INTO PraceDomowe (KlasaID, PrzedmiotID, Opis, TerminOddania)
VALUES (1, 1, 'Rozwiązanie równań kwadratowych', '2024-02-25');

CREATE TABLE OddanePraceDomowe (
OddanieID INT PRIMARY KEY IDENTITY,
PracaDomowaID INT,
UczenID INT,
DataOddania DATE,
WartoscOceny DECIMAL(3,1),
FOREIGN KEY (PracaDomowaID) REFERENCES PraceDomowe(PracaDomowaID),
FOREIGN KEY (UczenID) REFERENCES Uczniowie(UczenID)
);
CREATE INDEX idx_oddaneprace_uczen ON OddanePraceDomowe (UczenID);
CREATE INDEX idx_oddaneprace_praca ON OddanePraceDomowe (PracaDomowaID);

INSERT INTO OddanePraceDomowe (PracaDomowaID, UczenID, DataOddania, WartoscOceny)
VALUES (1, 1, '2025-02-10', 4.5);

CREATE TABLE KomentarzeOcen (
KomentarzID INT PRIMARY KEY IDENTITY,
OcenaID INT,
NauczycielID INT,
TrescKomentarza NVARCHAR(255),
FOREIGN KEY (OcenaID) REFERENCES Oceny(OcenaID),
FOREIGN KEY (NauczycielID) REFERENCES Nauczyciele(NauczycielID)
);

INSERT INTO KomentarzeOcen (OcenaID, NauczycielID, TrescKomentarza)
VALUES (1, 2, 'Dobra praca, ale wymaga poprawy w szczegółach.');

CREATE TABLE KonsultacjeNauczycieli (
KonsultacjaID INT PRIMARY KEY IDENTITY,
NauczycielID INT,
DataKonsultacji DATETIME,
Notatki NVARCHAR(255),
FOREIGN KEY (NauczycielID) REFERENCES Nauczyciele(NauczycielID)
);

INSERT INTO KonsultacjeNauczycieli (NauczycielID, DataKonsultacji, Notatki)
VALUES (2, '2025-03-01 14:00:00', 'Omówienie projektów semestralnych.');

CREATE TABLE WydarzeniaSzkolne (
WydarzenieID INT PRIMARY KEY IDENTITY,
Nazwa NVARCHAR(100) NOT NULL,
DataWydarzenia DATE NOT NULL,
Opis NVARCHAR(255),
OrganizatorID INT,
FOREIGN KEY (OrganizatorID) REFERENCES Nauczyciele(NauczycielID)
);

INSERT INTO WydarzeniaSzkolne (Nazwa, DataWydarzenia, Opis, OrganizatorID)
VALUES ('Dzień Otwarty Szkoły', '2025-04-15', 'Prezentacja szkoły dla przyszłych uczniów.', 2);
```
### Creating Views
```sql 
-- Description: The view returns a list of students along with their first name, last name, date of birth, and the name of the class they belong to
CREATE VIEW WidokUczniow AS
SELECT
Uczniowie.UczenID,
Osoby.Imie,
Osoby.Nazwisko,
Osoby.DataUrodzenia,
Klasy.NazwaKlasy
FROM Uczniowie
JOIN Osoby ON Uczniowie.UczenID = Osoby.OsobaID
JOIN Klasy ON Uczniowie.KlasaID = Klasy.KlasaID;

-- Description: The view displays teachers, their first name, last name, subject they teach, and their employment date
CREATE VIEW WidokNauczycieli AS
SELECT
Nauczyciele.NauczycielID,
Osoby.Imie,
Osoby.Nazwisko,
Przedmioty.NazwaPrzedmiotu,
Nauczyciele.DataZatrudnienia
FROM Nauczyciele
JOIN Osoby ON Nauczyciele.NauczycielID = Osoby.OsobaID
JOIN Przedmioty ON Nauczyciele.PrzedmiotID = Przedmioty.PrzedmiotID;

-- Description: The view returns a list of students' grades, their first and last name, subject name, grade value, and the date it was given
CREATE VIEW WidokOcen AS
SELECT
Oceny.OcenaID,
Osoby.Imie,
Osoby.Nazwisko,
Przedmioty.NazwaPrzedmiotu,
Oceny.WartoscOceny,
Oceny.DataOceny
FROM Oceny
JOIN Uczniowie ON Oceny.UczenID = Uczniowie.UczenID
JOIN Osoby ON Uczniowie.UczenID = Osoby.OsobaID
JOIN Przedmioty ON Oceny.PrzedmiotID = Przedmioty.PrzedmiotID;

-- Description: The view contains information about lessons – their ID, class, subject, teacher, and the date and time of the lesson
CREATE VIEW WidokLekcji AS
SELECT
Lekcje.LekcjaID,
Klasy.NazwaKlasy,
Przedmioty.NazwaPrzedmiotu,
Osoby.Imie AS Nauczyciel,
Lekcje.DataGodzinaLekcji
FROM Lekcje
JOIN Klasy ON Lekcje.KlasaID = Klasy.KlasaID
JOIN Przedmioty ON Lekcje.PrzedmiotID = Przedmioty.PrzedmiotID
JOIN Nauczyciele ON Lekcje.NauczycielID = Nauczyciele.NauczycielID
JOIN Osoby ON Nauczyciele.NauczycielID = Osoby.OsobaID;

-- Description: The view presents student attendance in lessons, including their first name, last name, class, subject, and attendance status
CREATE VIEW WidokObecnosci AS
SELECT
Obecnosci.ObecnoscID,
Osoby.Imie,
Osoby.Nazwisko,
Klasy.NazwaKlasy,
Przedmioty.NazwaPrzedmiotu,
Lekcje.DataGodzinaLekcji,
Obecnosci.Status
FROM Obecnosci
JOIN Uczniowie ON Obecnosci.UczenID = Uczniowie.UczenID
JOIN Osoby ON Uczniowie.UczenID = Osoby.OsobaID
JOIN Lekcje ON Obecnosci.LekcjaID = Lekcje.LekcjaID
JOIN Klasy ON Lekcje.KlasaID = Klasy.KlasaID
JOIN Przedmioty ON Lekcje.PrzedmiotID = Przedmioty.PrzedmiotID;

-- Description: The view shows homework assignments assigned to classes, including their description and submission deadline
CREATE VIEW WidokPracDomowych AS
SELECT
PraceDomowe.PracaDomowaID,
Klasy.NazwaKlasy,
Przedmioty.NazwaPrzedmiotu,
PraceDomowe.Opis,
PraceDomowe.TerminOddania
FROM PraceDomowe
JOIN Klasy ON PraceDomowe.KlasaID = Klasy.KlasaID
JOIN Przedmioty ON PraceDomowe.PrzedmiotID = Przedmioty.PrzedmiotID;

-- Description: The view returns information about submitted homework, including the student, subject, submission date, and grade
CREATE VIEW WidokOddanychPrac AS
SELECT
OddanePraceDomowe.OddanieID,
Osoby.Imie,
Osoby.Nazwisko,
Przedmioty.NazwaPrzedmiotu,
PraceDomowe.Opis,
OddanePraceDomowe.DataOddania,
OddanePraceDomowe.WartoscOceny
FROM OddanePraceDomowe
JOIN Uczniowie ON OddanePraceDomowe.UczenID = Uczniowie.UczenID
JOIN Osoby ON Uczniowie.UczenID = Osoby.OsobaID
JOIN PraceDomowe ON OddanePraceDomowe.PracaDomowaID = PraceDomowe.PracaDomowaID
JOIN Przedmioty ON PraceDomowe.PrzedmiotID = Przedmioty.PrzedmiotID;

-- Description: The view contains teachers' comments on students' grades, including the teacher's first and last name and the comment content
CREATE VIEW WidokKomentarzyOcen AS
SELECT
KomentarzeOcen.KomentarzID,
Osoby.Imie AS Nauczyciel,
Osoby.Nazwisko,
Oceny.WartoscOceny,
KomentarzeOcen.TrescKomentarza
FROM KomentarzeOcen
JOIN Oceny ON KomentarzeOcen.OcenaID = Oceny.OcenaID
JOIN Nauczyciele ON KomentarzeOcen.NauczycielID = Nauczyciele.NauczycielID
JOIN Osoby ON Nauczyciele.NauczycielID = Osoby.OsobaID;

-- Description: The view presents a list of teachers' consultations along with information about them
CREATE VIEW WidokKonsultacji AS
SELECT
KonsultacjeNauczycieli.KonsultacjaID,
Osoby.Imie AS Nauczyciel,
Osoby.Nazwisko,
KonsultacjeNauczycieli.DataKonsultacji,
KonsultacjeNauczycieli.Notatki
FROM KonsultacjeNauczycieli
JOIN Nauczyciele ON KonsultacjeNauczycieli.NauczycielID = Nauczyciele.NauczycielID
JOIN Osoby ON Nauczyciele.NauczycielID = Osoby.OsobaID;
```
### Creating functions
```sql
-- Returns the average grade of a student based on their ID.
CREATE FUNCTION GetAverageGrade(@StudentID INT)
RETURNS DECIMAL(4,2)
AS
BEGIN
DECLARE @Average DECIMAL(4,2);
-- Calculate the average grade for the student
SELECT @Average = AVG(GradeValue)
FROM Grades
WHERE StudentID = @StudentID;
-- If the student has no grades, return NULL
IF @Average IS NULL
BEGIN
RETURN NULL;
END
RETURN @Average;
END;

-- Returns the number of absences for a student marked as "Absent"
CREATE FUNCTION GetAbsenceCount(@StudentID INT)
RETURNS INT
AS
BEGIN
DECLARE @AbsenceCount INT;
-- Count the student's absences
SELECT @AbsenceCount = COUNT(*)
FROM Attendance
WHERE StudentID = @StudentID AND Status = 'Absent';
-- If the student has no absences, return 0
IF @AbsenceCount IS NULL
BEGIN
RETURN 0;
END
RETURN @AbsenceCount;
END;

-- Returns the highest grade recorded for a student in the system.
CREATE FUNCTION GetHighestGrade(@StudentID INT)
RETURNS DECIMAL(3,1)
AS
BEGIN
DECLARE @MaxGrade DECIMAL(3,1);
-- Find the highest grade for the student
SELECT @MaxGrade = MAX(GradeValue)
FROM Grades
WHERE StudentID = @StudentID;
-- If the student has no grades, return NULL
IF @MaxGrade IS NULL
BEGIN
RETURN NULL;
END
RETURN @MaxGrade;
END;
```
### Procedures and Triggers
Includes operations on Grades, Attendance, Homework, Lessons, and Students tables, with data validation and consistency checks.

```sql 
-- Procedure and trigger for the Grades table (Student grades)
-- Procedure: AddGrade
-- Description: Adds a new grade for a student in a specified subject and records the date the grade was given.
CREATE PROCEDURE AddGrade
@StudentID INT,
@SubjectID INT,
@GradeValue DECIMAL(3,1)
AS
BEGIN
INSERT INTO Grades (StudentID, SubjectID, GradeValue, GradeDate)
VALUES (@StudentID, @SubjectID, @GradeValue, GETDATE());
END;

-- Trigger: CheckGrade
-- Description: Checks if the inserted or updated grade is within the range from 1 to 6. If the grade is invalid, the transaction is rolled back.
CREATE TRIGGER CheckGrade
ON Grades
AFTER INSERT, UPDATE
AS
BEGIN
IF EXISTS (SELECT * FROM inserted WHERE GradeValue < 1 OR GradeValue > 6)
BEGIN
RAISERROR ('Grade must be between 1 and 6', 16, 1);
ROLLBACK TRANSACTION;
END;
END;

-- Procedure and trigger for the Attendance table (Student attendance)
-- Procedure: AddAttendance
-- Description: Registers a student's attendance for a lesson along with their status (present, absent, late).
CREATE PROCEDURE AddAttendance
@StudentID INT,
@LessonID INT,
@Status NVARCHAR(20)
AS
BEGIN
INSERT INTO Attendance (StudentID, LessonID, Status)
VALUES (@StudentID, @LessonID, @Status);
END;

-- Trigger: UpdateAttendanceStatusAfterLessonDeletion
-- Description: After a lesson is deleted from the database, changes the attendance status of all students registered for that lesson to "Cancelled".
CREATE TRIGGER UpdateAttendanceStatusAfterLessonDeletion
ON Lessons
AFTER DELETE
AS
BEGIN
UPDATE Attendance
SET Status = 'Cancelled'
WHERE LessonID IN (SELECT LessonID FROM deleted);
END;

-- Procedure and trigger for the Homework table (Homework assignments)
-- Procedure: AddHomework
-- Description: Adds a new homework assignment for a given class in a specified subject and sets its due date.
CREATE PROCEDURE AddHomework
@ClassID INT,
@SubjectID INT,
@Description NVARCHAR(255),
@DueDate DATE
AS
BEGIN
INSERT INTO Homework (ClassID, SubjectID, Description, DueDate)
VALUES (@ClassID, @SubjectID, @Description, @DueDate);
END;

-- Trigger: CheckHomeworkDueDate
-- Description: Checks if the homework due date is not in the past. If it is, the transaction is rolled back.
CREATE TRIGGER CheckHomeworkDueDate
ON Homework
AFTER INSERT, UPDATE
AS
BEGIN
IF EXISTS (SELECT * FROM inserted WHERE DueDate < GETDATE())
BEGIN
RAISERROR ('Homework due date cannot be in the past', 16, 1);
ROLLBACK TRANSACTION;
END;
END;

-- Procedure and trigger for the Lessons table (Class schedule)
-- Procedure: AddLesson
-- Description: Adds a new lesson to the schedule, assigning it to a class, subject, and teacher.
CREATE PROCEDURE AddLesson
@ClassID INT,
@SubjectID INT,
@TeacherID INT,
@LessonDateTime DATETIME
AS
BEGIN
INSERT INTO Lessons (ClassID, SubjectID, TeacherID, LessonDateTime)
VALUES (@ClassID, @SubjectID, @TeacherID, @LessonDateTime);
END;

-- Trigger: CheckLessonConflict
-- Description: Checks if the newly added lesson conflicts with another lesson for the same class at the same time. If a conflict exists, the transaction is rolled back.
CREATE TRIGGER CheckLessonConflict
ON Lessons
AFTER INSERT
AS
BEGIN
IF EXISTS (
SELECT 1
FROM Lessons l1
JOIN inserted l2 ON l1.ClassID = l2.ClassID
WHERE l1.LessonDateTime = l2.LessonDateTime
)
BEGIN
RAISERROR ('Schedule conflict for lessons!', 16, 1);
ROLLBACK TRANSACTION;
END;
END;

-- Procedure and trigger for the Students table (Student list)
-- Procedure: AddStudent
-- Description: Adds a new student to the school, assigning them to the appropriate class and recording the enrollment date.
CREATE PROCEDURE AddStudent
@PersonID INT,
@ClassID INT,
@EnrollmentDate DATE
AS
BEGIN
INSERT INTO Students (StudentID, ClassID, EnrollmentDate)
VALUES (@PersonID, @ClassID, @EnrollmentDate);
END;

-- Trigger: DeleteStudentGrades
-- Description: After deleting a student from the database, automatically deletes all their grades.
CREATE TRIGGER DeleteStudentGrades
ON Students
AFTER DELETE
AS
BEGIN
DELETE FROM Grades WHERE StudentID IN (SELECT StudentID FROM deleted);
END;
``` 
### Backup Strategy

```sql 
-- Full database backup daily at 11:00 PM
BACKUP DATABASE Szkola TO DISK = 'D:\Backups\Szkola_FULL.bak' WITH FORMAT, MEDIANAME =
'SzkolaBackup', NAME = 'Full Backup of Szkola';

-- Differential backup every 6 hours
BACKUP DATABASE Szkola TO DISK = 'D:\Backups\Szkola_DIFF.bak' WITH DIFFERENTIAL, NAME =
'Differential Backup of Szkola';
```

## Examples of common queries
```sql 
-- Description: Retrieves a list of all students along with the names of their classes.
SELECT
  O.FirstName,
  O.LastName,
  K.ClassName
FROM Students U
JOIN People O ON U.StudentID = O.PersonID
JOIN Classes K ON U.ClassID = K.ClassID;

-- Description: Returns all grades of a selected student along with subjects and dates.
SELECT
  P.SubjectName,
  G.GradeValue,
  G.GradeDate
FROM Grades G
JOIN Subjects P ON G.SubjectID = P.SubjectID
WHERE G.StudentID = 1;

-- Description: Displays the timetable for a selected class, including subjects, teachers, and times.
SELECT
  P.SubjectName,
  T.FirstName AS TeacherFirstName,
  L.LessonDateTime
FROM Lessons L
JOIN Subjects P ON L.SubjectID = P.SubjectID
JOIN Teachers N ON L.TeacherID = N.TeacherID
JOIN People T ON N.TeacherID = T.PersonID
WHERE L.ClassID = 1
ORDER BY L.LessonDateTime;

-- Description: Calculates the average grade for each student.
SELECT
  O.FirstName,
  O.LastName,
  dbo.GetAverageGrade(U.StudentID) AS AverageGrade
FROM Students U
JOIN People O ON U.StudentID = O.PersonID;

-- Description: Displays a list of teachers along with the subjects they teach.
SELECT
  O.FirstName,
  O.LastName,
  P.SubjectName
FROM Teachers N
JOIN People O ON N.TeacherID = O.PersonID
JOIN Subjects P ON N.SubjectID = P.SubjectID;
```

# Python GUI with Tkinter for the 'Osoby' table
```python 
import tkinter as tk
from tkinter import messagebox
import pyodbc

# Function to connect to the database
def connect_db():
    conn = pyodbc.connect(
        "DRIVER={SQL Server};"
        "SERVER=DESKTOP-78SQMD3\SQLEXPRESS;"
        "DATABASE=SCHOOL;"
    )
    return conn

# Get all rows from the table
def get_all_rows():
    conn = connect_db()
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM Osoby")
    rows = cursor.fetchall()
    conn.close()
    return rows

# Add a new row to the table
def add_row(imie, nazwisko, data_urodzenia, typ_osoby):
    conn = connect_db()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "INSERT INTO Osoby (Imie, Nazwisko, DataUrodzenia, TypOsoby) VALUES (?, ?, ?, ?)",
            imie, nazwisko, data_urodzenia, typ_osoby
        )
        conn.commit()
        messagebox.showinfo("Success", "Row was successfully added!")
    except Exception as e:
        messagebox.showerror("Error", f"Error while adding row: {e}")
    finally:
        conn.close()

# Delete a row from the table
def delete_row(osoba_id):
    conn = connect_db()
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM Osoby WHERE OsobaID = ?", osoba_id)
        conn.commit()
        messagebox.showinfo("Success", "Row was successfully deleted!")
    except Exception as e:
        messagebox.showerror("Error", f"Error while deleting row: {e}")
    finally:
        conn.close()

# Update a row in the table
def update_row(osoba_id, imie, nazwisko, data_urodzenia, typ_osoby):
    conn = connect_db()
    cursor = conn.cursor()
    try:
        cursor.execute(
            "UPDATE Osoby SET Imie = ?, Nazwisko = ?, DataUrodzenia = ?, TypOsoby = ? WHERE OsobaID = ?",
            imie, nazwisko, data_urodzenia, typ_osoby, osoba_id
        )
        conn.commit()
        messagebox.showinfo("Success", "Row was successfully updated!")
    except Exception as e:
        messagebox.showerror("Error", f"Error while updating row: {e}")
    finally:
        conn.close()

# Main application window
class TableManagerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Person Table Management")
        self.current_index = 0

        # Labels and entry fields for data input
        self.label_id = tk.Label(root, text="ID:")
        self.label_id.grid(row=0, column=0)
        self.entry_id = tk.Entry(root, state="readonly")
        self.entry_id.grid(row=0, column=1)

        self.label_imie = tk.Label(root, text="First Name:")
        self.label_imie.grid(row=1, column=0)
        self.entry_imie = tk.Entry(root)
        self.entry_imie.grid(row=1, column=1)

        self.label_nazwisko = tk.Label(root, text="Last Name:")
        self.label_nazwisko.grid(row=2, column=0)
        self.entry_nazwisko = tk.Entry(root)
        self.entry_nazwisko.grid(row=2, column=1)

        self.label_data_urodzenia = tk.Label(root, text="Date of Birth:")
        self.label_data_urodzenia.grid(row=3, column=0)
        self.entry_data_urodzenia = tk.Entry(root)
        self.entry_data_urodzenia.grid(row=3, column=1)

        self.label_typ_osoby = tk.Label(root, text="Person Type:")
        self.label_typ_osoby.grid(row=4, column=0)
        self.entry_typ_osoby = tk.Entry(root)
        self.entry_typ_osoby.grid(row=4, column=1)

        # Navigation buttons
        self.btn_previous = tk.Button(root, text="Previous", command=self.show_previous_row)
        self.btn_previous.grid(row=5, column=0)
        self.btn_next = tk.Button(root, text="Next", command=self.show_next_row)
        self.btn_next.grid(row=5, column=1)

        # Data management buttons
        self.btn_add = tk.Button(root, text="Add", command=self.add_row)
        self.btn_add.grid(row=6, column=0)
        self.btn_update = tk.Button(root, text="Update", command=self.update_row)
        self.btn_update.grid(row=6, column=1)
        self.btn_delete = tk.Button(root, text="Delete", command=self.delete_row)
        self.btn_delete.grid(row=6, column=2)

        # Load data from table
        self.rows = get_all_rows()
        self.show_row(self.current_index)

    # Display row by index
    def show_row(self, index):
        if 0 <= index < len(self.rows):
            row = self.rows[index]
            self.entry_id.config(state="normal")
            self.entry_id.delete(0, tk.END)
            self.entry_id.insert(0, row.OsobaID)
            self.entry_id.config(state="readonly")

            self.entry_imie.delete(0, tk.END)
            self.entry_imie.insert(0, row.Imie)

            self.entry_nazwisko.delete(0, tk.END)
            self.entry_nazwisko.insert(0, row.Nazwisko)

            self.entry_data_urodzenia.delete(0, tk.END)
            self.entry_data_urodzenia.insert(0, row.DataUrodzenia)

            self.entry_typ_osoby.delete(0, tk.END)
            self.entry_typ_osoby.insert(0, row.TypOsoby)

    # Show previous row
    def show_previous_row(self):
        if self.current_index > 0:
            self.current_index -= 1
            self.show_row(self.current_index)

    # Show next row
    def show_next_row(self):
        if self.current_index < len(self.rows) - 1:
            self.current_index += 1
            self.show_row(self.current_index)

    # Add new row
    def add_row(self):
        imie = self.entry_imie.get()
        nazwisko = self.entry_nazwisko.get()
        data_urodzenia = self.entry_data_urodzenia.get()
        typ_osoby = self.entry_typ_osoby.get()
        if imie and nazwisko and data_urodzenia and typ_osoby:
            add_row(imie, nazwisko, data_urodzenia, typ_osoby)
            self.rows = get_all_rows()  # Refresh row list
            self.current_index = len(self.rows) - 1
            self.show_row(self.current_index)
        else:
            messagebox.showwarning("Warning", "Please fill in all fields!")

    # Update row
    def update_row(self):
        osoba_id = self.entry_id.get()
        imie = self.entry_imie.get()
        nazwisko = self.entry_nazwisko.get()
        data_urodzenia = self.entry_data_urodzenia.get()
        typ_osoby = self.entry_typ_osoby.get()
        if osoba_id and imie and nazwisko and data_urodzenia and typ_osoby:
            update_row(osoba_id, imie, nazwisko, data_urodzenia, typ_osoby)
            self.rows = get_all_rows()  # Refresh row list
            self.show_row(self.current_index)
        else:
            messagebox.showwarning("Warning", "Please fill in all fields!")

    # Delete row
    def delete_row(self):
        osoba_id = self.entry_id.get()
        if osoba_id:
            delete_row(osoba_id)
            self.rows = get_all_rows()  # Refresh row list
            if self.rows:
                self.current_index = min(self.current_index, len(self.rows) - 1)
                self.show_row(self.current_index)
            else:
                self.clear_entries()
        else:
            messagebox.showwarning("Warning", "No row selected to delete!")

    # Clear input fields
    def clear_entries(self):
        self.entry_id.config(state="normal")
        self.entry_id.delete(0, tk.END)
        self.entry_id.config(state="readonly")
        self.entry_imie.delete(0, tk.END)
        self.entry_nazwisko.delete(0, tk.END)
        self.entry_data_urodzenia.delete(0, tk.END)
        self.entry_typ_osoby.delete(0, tk.END)

# Run the application
if __name__ == "__main__":
    root = tk.Tk()
    app = TableManagerApp(root)
    root.mainloop()
```
