# Intro and Key Information of Prime-AI Application
===================================================

## Intro
We are in Devlopment of an Application for Indian Schools. This Application is not a normal ERP Application for Schools but it is an Academic Intelligence Plateform for schools to make them capable of taking right decesion in time by providing them detailed Data Insights and help them in decision making.


I want to update Re-defined Paths into AI-Brain for all the Files. Below is the detail Paths for all important files & folders:
We have 3 Primary Databases:
prime_db - This DB capture tables which will be used by Prime Team to manage Tenants(Schools) and serve them.
global_db - This DB posses those tables which are common for all the tenants(Schools) like city, district, state, country, academic_session, boards, menus, language etc.
tenant_db - This is the main DB which will be used by Tenants(School). This DB will be haveing views for all the tables belongs to global_db, so that data can be controled from one place but can be used by all the Tenants. As of now to make it easy in Dev Environment I have copied the complete schema for all the tables belongs to global_db. when we will go into production this(tenant_db) DB will be having tables for all the Modules but in Dev Environment I have kept all the Tables separately for every Modules to make it easy to enhance for me as an Architect and easy to understand for development team.
1. PRIME_DB_FILE = /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/0-DDL_Masters/prime_db_v3.sql
    ()
