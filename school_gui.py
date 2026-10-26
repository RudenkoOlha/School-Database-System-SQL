"""School Database System - desktop GUI for the People table.

A small Tkinter application that lets you browse, add, edit and delete
people (students and teachers) stored in the SchoolDB database on
SQL Server.

Connection settings are read from environment variables, so no server
name or password is stored in the code:

    SCHOOL_DB_SERVER    SQL Server instance       (default: localhost\\SQLEXPRESS)
    SCHOOL_DB_NAME      database name             (default: SchoolDB)
    SCHOOL_DB_USER      SQL login (optional)      - if empty, Windows authentication is used
    SCHOOL_DB_PASSWORD  password for SCHOOL_DB_USER
    SCHOOL_DB_DRIVER    ODBC driver name          (default: newest SQL Server driver installed)
"""

import os
import tkinter as tk
from contextlib import closing
from datetime import date, datetime
from tkinter import messagebox, ttk

import pyodbc

PERSON_TYPES = ("Student", "Teacher")
PREFERRED_DRIVERS = (
    "ODBC Driver 18 for SQL Server",
    "ODBC Driver 17 for SQL Server",
    "SQL Server",
)


# ---------------------------------------------------------------------------
# Database access
# ---------------------------------------------------------------------------

def pick_driver() -> str:
    """Return the newest SQL Server ODBC driver installed on this machine."""
    installed = set(pyodbc.drivers())
    for name in PREFERRED_DRIVERS:
        if name in installed:
            return name
    raise RuntimeError(
        "No SQL Server ODBC driver found. Install 'ODBC Driver 18 for SQL Server'."
    )


def build_connection_string() -> str:
    """Build the ODBC connection string from environment variables."""
    driver = os.getenv("SCHOOL_DB_DRIVER") or pick_driver()
    server = os.getenv("SCHOOL_DB_SERVER", r"localhost\SQLEXPRESS")
    database = os.getenv("SCHOOL_DB_NAME", "SchoolDB")

    parts = [
        f"DRIVER={{{driver}}}",
        f"SERVER={server}",
        f"DATABASE={database}",
        "TrustServerCertificate=yes",
    ]
    user = os.getenv("SCHOOL_DB_USER")
    if user:
        parts += [f"UID={user}", f"PWD={os.getenv('SCHOOL_DB_PASSWORD', '')}"]
    else:
        parts.append("Trusted_Connection=yes")
    return ";".join(parts) + ";"


def connect() -> pyodbc.Connection:
    return pyodbc.connect(build_connection_string(), timeout=5)


def fetch_people() -> list:
    """Return all people ordered by ID."""
    with closing(connect()) as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT PersonID, FirstName, LastName, DateOfBirth, PersonType "
            "FROM dbo.People ORDER BY PersonID"
        )
        return cursor.fetchall()


def add_person(first_name: str, last_name: str, date_of_birth: date, person_type: str) -> int:
    """Insert a person and return the new PersonID."""
    with closing(connect()) as conn:
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO dbo.People (FirstName, LastName, DateOfBirth, PersonType) "
            "OUTPUT INSERTED.PersonID VALUES (?, ?, ?, ?)",
            first_name, last_name, date_of_birth, person_type,
        )
        new_id = cursor.fetchone()[0]
        conn.commit()
        return new_id


def update_person(person_id: int, first_name: str, last_name: str,
                  date_of_birth: date, person_type: str) -> None:
    with closing(connect()) as conn:
        conn.cursor().execute(
            "UPDATE dbo.People SET FirstName = ?, LastName = ?, DateOfBirth = ?, PersonType = ? "
            "WHERE PersonID = ?",
            first_name, last_name, date_of_birth, person_type, person_id,
        )
        conn.commit()


def delete_person(person_id: int) -> None:
    with closing(connect()) as conn:
        conn.cursor().execute("DELETE FROM dbo.People WHERE PersonID = ?", person_id)
        conn.commit()


# ---------------------------------------------------------------------------
# Input validation
# ---------------------------------------------------------------------------

def validate_person(first_name: str, last_name: str, date_text: str, person_type: str):
    """Check the form values and return them in the types the database expects.

    Raises ValueError with a readable message if something is wrong.
    """
    first_name, last_name = first_name.strip(), last_name.strip()
    if not first_name or not last_name:
        raise ValueError("First name and last name are required.")
    if len(first_name) > 50 or len(last_name) > 50:
        raise ValueError("First name and last name can have at most 50 characters.")
    try:
        date_of_birth = datetime.strptime(date_text.strip(), "%Y-%m-%d").date()
    except ValueError:
        raise ValueError("Date of birth must be in the format YYYY-MM-DD.") from None
    if date_of_birth > date.today():
        raise ValueError("Date of birth cannot be in the future.")
    if person_type not in PERSON_TYPES:
        raise ValueError("Person type must be 'Student' or 'Teacher'.")
    return first_name, last_name, date_of_birth, person_type


# ---------------------------------------------------------------------------
# User interface
# ---------------------------------------------------------------------------

class PeopleManagerApp:
    """Browse and edit the People table one record at a time."""

    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("School Database - People")
        self.root.resizable(False, False)
        self.rows = []
        self.current_index = 0

        form = ttk.Frame(root, padding=12)
        form.grid(row=0, column=0, sticky="nsew")

        self.var_id = tk.StringVar()
        self.var_first = tk.StringVar()
        self.var_last = tk.StringVar()
        self.var_dob = tk.StringVar()
        self.var_type = tk.StringVar()
        self.var_status = tk.StringVar()

        fields = [
            ("ID:", ttk.Entry(form, textvariable=self.var_id, state="readonly", width=28)),
            ("First name:", ttk.Entry(form, textvariable=self.var_first, width=28)),
            ("Last name:", ttk.Entry(form, textvariable=self.var_last, width=28)),
            ("Date of birth (YYYY-MM-DD):", ttk.Entry(form, textvariable=self.var_dob, width=28)),
            ("Person type:", ttk.Combobox(form, textvariable=self.var_type, values=PERSON_TYPES,
                                          state="readonly", width=26)),
        ]
        for row_number, (label, widget) in enumerate(fields):
            ttk.Label(form, text=label).grid(row=row_number, column=0, sticky="w", pady=3)
            widget.grid(row=row_number, column=1, sticky="w", pady=3, padx=(8, 0))

        navigation = ttk.Frame(form)
        navigation.grid(row=5, column=0, columnspan=2, pady=(10, 4))
        ttk.Button(navigation, text="< Previous", command=self.show_previous).pack(side="left", padx=3)
        ttk.Label(navigation, textvariable=self.var_status, width=16, anchor="center").pack(side="left")
        ttk.Button(navigation, text="Next >", command=self.show_next).pack(side="left", padx=3)

        actions = ttk.Frame(form)
        actions.grid(row=6, column=0, columnspan=2, pady=(4, 0))
        ttk.Button(actions, text="New", command=self.clear_form).pack(side="left", padx=3)
        ttk.Button(actions, text="Add", command=self.add).pack(side="left", padx=3)
        ttk.Button(actions, text="Update", command=self.update).pack(side="left", padx=3)
        ttk.Button(actions, text="Delete", command=self.delete).pack(side="left", padx=3)

        self.reload()

    # ----- helpers -------------------------------------------------------

    def reload(self, select_id=None):
        """Read all rows again and show the selected (or current) one."""
        self.rows = fetch_people()
        if select_id is not None:
            ids = [row.PersonID for row in self.rows]
            self.current_index = ids.index(select_id) if select_id in ids else 0
        self.current_index = max(0, min(self.current_index, len(self.rows) - 1))
        self.show_current()

    def show_current(self):
        if not self.rows:
            self.clear_form()
            self.var_status.set("No records")
            return
        row = self.rows[self.current_index]
        self.var_id.set(row.PersonID)
        self.var_first.set(row.FirstName)
        self.var_last.set(row.LastName)
        self.var_dob.set(row.DateOfBirth.isoformat())
        self.var_type.set(row.PersonType)
        self.var_status.set(f"Record {self.current_index + 1} of {len(self.rows)}")

    def form_values(self):
        return validate_person(self.var_first.get(), self.var_last.get(),
                               self.var_dob.get(), self.var_type.get())

    # ----- button actions ------------------------------------------------

    def show_previous(self):
        if self.current_index > 0:
            self.current_index -= 1
            self.show_current()

    def show_next(self):
        if self.current_index < len(self.rows) - 1:
            self.current_index += 1
            self.show_current()

    def clear_form(self):
        for variable in (self.var_id, self.var_first, self.var_last, self.var_dob, self.var_type):
            variable.set("")
        self.var_status.set("New record")

    def add(self):
        try:
            new_id = add_person(*self.form_values())
        except ValueError as error:
            messagebox.showwarning("Check the form", str(error))
            return
        except pyodbc.Error as error:
            messagebox.showerror("Database error", f"The person could not be added.\n\n{error}")
            return
        self.reload(select_id=new_id)
        messagebox.showinfo("Added", f"Person added with ID {new_id}.")

    def update(self):
        if not self.var_id.get():
            messagebox.showwarning("No record", "Select an existing record to update.")
            return
        person_id = int(self.var_id.get())
        try:
            update_person(person_id, *self.form_values())
        except ValueError as error:
            messagebox.showwarning("Check the form", str(error))
            return
        except pyodbc.IntegrityError:
            messagebox.showerror(
                "Cannot change type",
                "This person is already registered as a student or teacher, "
                "so the person type cannot be changed.",
            )
            return
        except pyodbc.Error as error:
            messagebox.showerror("Database error", f"The record could not be updated.\n\n{error}")
            return
        self.reload(select_id=person_id)
        messagebox.showinfo("Updated", "The record was updated.")

    def delete(self):
        if not self.var_id.get():
            messagebox.showwarning("No record", "Select an existing record to delete.")
            return
        person_id = int(self.var_id.get())
        if not messagebox.askyesno("Delete", f"Delete person with ID {person_id}?"):
            return
        try:
            delete_person(person_id)
        except pyodbc.IntegrityError:
            messagebox.showerror(
                "Cannot delete",
                "This person is still registered as a student or teacher. "
                "Remove that record first.",
            )
            return
        except pyodbc.Error as error:
            messagebox.showerror("Database error", f"The record could not be deleted.\n\n{error}")
            return
        self.reload()


def main():
    root = tk.Tk()
    try:
        PeopleManagerApp(root)
    except (pyodbc.Error, RuntimeError) as error:
        root.withdraw()
        messagebox.showerror(
            "Connection error",
            "Could not connect to the database. Check that SQL Server is running "
            f"and that the SCHOOL_DB_* settings are correct.\n\n{error}",
        )
        root.destroy()
        return
    root.mainloop()


if __name__ == "__main__":
    main()
