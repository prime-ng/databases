You are a PHP + Laravel + MySql + Vuejs expert.
I want you to analyse the existing notification system (in primeai/app/Modules/Notification and related parts of the core app), plus the scheduler and event engine modules I will describe below.
After you understand what we have, I will ask you to generate a report and suggest improvements, new architecture, or a step-by-step plan to evolve this system into a production-ready, multi-school notification system.
Ask me questions before you generate a report. Do not rush. First, tell me what you want to know about the current system. I will answer.



We have some new additional requirements. There are two more modules:
 
- `/home/tarun-chauhan/Desktop/Apps/primeworkspace/prime_ai/Modules/Scheduler`
- `/home/tarun-chauhan/Desktop/Apps/primeworkspace/prime_ai/Modules/EventEngine`
 
These are not fully built right now, but here is what I know about them.
 
**Event Engine:** We want a configurable event system. For example, when a particular event happens, such as a new student being added, something has to happen somewhere else in the application, such as an entry in the database or a notification sent for the new profile. It can be anything. Put simply, it links one action in the application to another.
 
**Scheduler:** The idea is that from Prime we will add some schedules, such as every minute, every 5 minutes, hourly, every 24 hours, every 15 days, weekly, yearly, etc. Then a tenant can configure any event or task to run on one of those schedules. For example, if a tenant wants to send a "Happy Diwali" email, they will set up the message in Notification and schedule it to run once a year. This is a rough sketch.
 
These are fairly complex features, and they may share some of the same functionality with Notification. That is why I am thinking that, if required, we could make some of these features a core requirement and build them together. If that is the case, please analyse this and generate a report. Ask me questions first, then proceed.
