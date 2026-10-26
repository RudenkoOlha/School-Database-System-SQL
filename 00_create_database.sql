/* =====================================================================
   00_create_database.sql
   Creates the SchoolDB database. Run this script first.
   ===================================================================== */

IF DB_ID(N'SchoolDB') IS NULL
    CREATE DATABASE SchoolDB;
GO
