# HPC Email Distribution - Full Guide

## What Is This Feature?

This feature lets teachers send an email to a parent or guardian with a link to view their child's completed progress card. The email does NOT have the card attached as a file. Instead, the email has a special web address (called a link or URL). The parent clicks the link to see the card on their phone or computer.

Think of it like this: Instead of printing a paper report card and giving it to the student to take home, the school sends an email. The parent opens the email on their phone and sees a button that says "View Card." The parent taps the button, and the card opens in their phone's web browser.

The parent can also print the card from their browser if they want a paper copy.

---

## Who Can Use This Feature?

Teachers can use this feature. This includes class teachers (who are in charge of one class) and subject teachers (who teach one subject to many classes). School administrators can also use this feature.

The person must have permission from the school. Not every teacher or staff member can send emails. The school decides who gets permission.

---

## Why a Link Instead of a PDF Attached to the Email?

You might wonder: Why not just attach the PDF to the email? That would be simpler, right?

There are three important reasons why the system uses a link instead of a PDF attachment.

### Reason 1: Security

A PDF attached to an email can be forwarded to anyone. The parent might forward the email to relatives or friends. Those people might forward it to others. Soon, the student's personal information is spread to many people who should not see it.

A link is more secure because the parent must click the link and enter an access code. Only people who have both the link and the code can see the card. This makes it harder for unauthorized people to view the card.

### Reason 2: The Link Expires

The link only works for 30 days. After 30 days, the link stops working. The parent cannot open the card anymore. This is another layer of security.

A PDF attached to an email never expires. It sits in the parent's inbox forever. Anyone who gets access to the parent's email can open the PDF. Even years later, the PDF is still there.

With the link, after 30 days, the card is no longer accessible through that link. If the parent needs to see the card again, they can ask the school for a new link.

### Reason 3: Always the Latest Version

Suppose the teacher sends an email with a PDF attached. Then the teacher realizes there is a mistake in the card. The teacher fixes the mistake. But the parent still has the old PDF with the mistake.

With a link, the parent always sees the latest version of the card. When the parent clicks the link, the system shows them the current version of the card. If the teacher fixed a mistake, the parent sees the corrected version.

This is very helpful because teachers often need to make small corrections after sending the card to parents.

---

## PART 1: Sending an Email to One Parent

### How the Teacher Starts

The teacher opens the student list on the computer screen. Next to each student's name, there is a button that says "Send Email." The teacher clicks this button for the student they want.

The teacher can also click this button from inside the student's card form. While viewing the card, there is a "Send Email" button.

### Step-by-Step: What Happens Inside the Computer

#### Step 1: Find the Guardian

The computer looks up the student's record in the school database. It finds the parent or guardian information. It reads the guardian's name and email address.

If there are two guardians (for example, mother and father), the computer finds both email addresses. Both parents will receive the email.

If the student has only one guardian (for example, only the mother), only that one person receives the email.

#### Step 2: Create a Secure Link

The computer creates a unique web address for this student's card. This web address is like a key that opens the card. The address contains a long random string of characters that nobody can guess.

For example, the web address might look something like this:
https://schoolname.edu.in/hpc/view/a7x9k2m4p6r8

The random characters at the end (a7x9k2m4p6r8) make the address unique and hard to guess.

#### Step 3: Create an Access Code

The computer also creates an access code. This is like a password that the parent types after clicking the link. The access code is a short string of letters and numbers.

For example, the access code might be: HPC-A8X3K9

The access code adds an extra layer of security. Even if someone gets the link, they still need the access code to open the card.

#### Step 4: Queue the Email

The computer does NOT send the email immediately. Instead, it puts the email into a queue. A queue is like a line. The email waits in line with other emails that need to be sent.

The queue processes emails one by one in the background. This means the teacher does not have to wait for the email to be sent. The teacher can close the page and continue working. The email will be sent automatically.

Most emails are sent within a few seconds or minutes of being queued.

#### Step 5: Send the Email

When the email reaches the front of the queue, the computer sends it. The email goes to the guardian's inbox. The email contains:

The school's name and logo.
The student's name and class.
A big button that says "View Card."
The access code.
A note that the link works for 30 days.
Simple instructions on how to view the card.

### What Happens If the Guardian Has No Email Address?

Sometimes the school does not have an email address for the parent. Maybe the parent does not use email. Maybe the school forgot to collect the email address.

If the guardian has no email address, the computer cannot send an email. The computer does NOT crash or show an error. Instead, the computer does two things:

1. The computer records a quiet warning in the system log. This warning is only visible to technical staff. It says something like: "Guardian for student Priya Sharma has no email address."

2. The computer shows a message to the teacher: "Email sent to 0 guardians. 1 guardian skipped (no email address on file)."

The teacher sees this message and knows they need to collect the guardian's email address. The teacher can ask the guardian for their email and update the student's record in the system.

### Real-World Example: Single Email

Mrs. Sharma has finished Aarav's progress card. She wants Aarav's mother to see it. Mrs. Sharma finds Aarav in the student list and clicks "Send Email."

The computer finds Aarav's mother in the database. Her name is Mrs. Patel. Her email is patel@email.com.

The computer creates a link and an access code. The email is queued. About 10 seconds later, Mrs. Patel receives the email on her phone. She sees:

From: Sunshine School
Subject: View Aarav's Progress Card

Dear Parent,

The Holistic Progress Card for your child, Aarav Patel (Class 5-A), is now ready to view.

[View Card]

Access Code: HPC-A8X3K9

This link is valid for 30 days.

Thank you,
Sunshine School

Mrs. Patel taps the "View Card" button. Her phone opens the web browser. The screen asks for the access code. She types HPC-A8X3K9. Aarav's card appears on her phone. She scrolls through it and sees all his grades, attendance, and teacher comments.

---

## PART 2: Sending Emails to Many Parents at Once

### How the Teacher Starts

The teacher goes to the student list. Next to each student's name, there is a small box called a checkbox. The teacher clicks the checkbox for each student they want to include.

After selecting the students, the teacher clicks a button that says "Send Bulk Email."

### Step-by-Step: What Happens Inside the Computer

#### Step 1: Process Students One by One

The computer goes through the selected students one at a time. For each student, it follows the same steps as a single email:

Find the guardian(s).
Create a secure link.
Create an access code.
Queue the email.

#### Step 2: Handle Students Without Guardian Email

As the computer goes through each student, it checks if the guardian has an email address.

If the guardian has an email: The computer creates the link and queues the email. Everything proceeds normally.

If the guardian does NOT have an email: The computer skips that guardian. It records a warning in the system log. It does NOT create a link or queue an email for that guardian.

#### Step 3: Show a Summary Report

After all students have been processed, the computer shows a summary report to the teacher. The summary report looks something like this:

"18 emails sent successfully."
"3 guardians skipped (no email address on file)."
"2 students with multiple guardians: both parents received the email."

This summary helps the teacher know what happened. The teacher can see how many parents received the email and how many were skipped.

### What If a Student Has Two Parents?

If a student has two guardians (for example, mother and father), both receive the email. The computer sends two separate emails. One goes to the mother's email address. The other goes to the father's email address.

Both emails have the same link and the same access code. Both parents can view the card.

### How Long Does Bulk Sending Take?

The actual queuing of emails happens very fast. If you select 50 students and each has 2 guardians, the computer queues 100 emails in just a few seconds.

The actual sending of the emails happens in the background. The emails leave the computer one by one. All 100 emails might be sent over the course of a few minutes.

The teacher does NOT need to keep the page open. The teacher can close the computer and go home. The emails will still be sent. The queue continues processing even after the teacher logs out.

### Is There a Limit on Bulk Emails?

Currently, there is no hard limit. The teacher can select any number of students. However, the system does NOT have a rate limit yet.

A rate limit is a safety measure that prevents too many emails from being sent too quickly. Without a rate limit, if someone selects hundreds of students, the system could get overloaded. The email server might slow down or crash.

An enhancement is planned to add a rate limit. The planned limit is 100 email requests per batch. This means the teacher could send emails to at most 50 students (with 2 parents each) in one batch.

Until the rate limit is added, teachers should be careful not to select too many students at once. It is better to do multiple small batches than one very large batch.

---

## PART 3: What the Email Looks Like

The email is based on a design called `hpc-report.blade.php`. This is a template that determines how the email looks. Here is exactly what the guardian receives.

### Email Subject Line

The subject line of the email says something like:
"Holistic Progress Card for Aarav Patel - Sunshine School"

The subject includes the student's name and the school's name. This helps the guardian know what the email is about before opening it.

### School Branding at the Top

The top of the email shows the school's name and logo. Below that, it shows the school's address and contact information.

This branding makes the email look official. The guardian knows it is really from the school, not from a stranger.

### Student Details

Below the school branding, the email shows:
Student's full name.
Class and section.
Term or academic year.

This confirms which child the email is about.

### Opening Message

The email has a friendly opening message. For example:
"Dear Parent, the Holistic Progress Card for your child is now available for viewing."

This message might be personalized with the parent's name if the system has that information.

### View Card Button

The main part of the email is a big, clickable button. The button says "View Card" or "Click Here to View."

The button is usually colored and easy to see. The guardian cannot miss it.

Behind the button is the secure link. When the guardian clicks the button, their browser opens to the card viewing page.

### Access Code

Below the button, the email shows the access code. The access code is displayed clearly. For example:
"Your Access Code: HPC-A8X3K9"

The guardian needs to type this code after clicking the link. The email tells the guardian to keep this code safe.

### Validity Notice

The email states clearly: "This link will expire in 30 days."

This tells the guardian that they cannot wait too long to view the card. They should open it soon.

### Instructions

The email provides simple step-by-step instructions:
1. Click the "View Card" button above.
2. Enter the access code: HPC-A8X3K9.
3. View your child's complete progress card.

These instructions help guardians who are not comfortable with computers.

### Footer

The bottom of the email shows the school's contact information. It might say:
"If you have any questions, please contact Sunshine School at 555-1234 or email office@sunshineschool.edu.in."

This gives the guardian a way to ask for help if they have trouble viewing the card.

### Complete Example Email

Here is the complete example email for Aarav Patel:

```
From: Sunshine School <noreply@sunshineschool.edu.in>
To: patel@email.com
Subject: View Aarav Patel's Progress Card - Sunshine School

[School Logo]

Sunshine School
123 Education Lane, Mumbai

Dear Parent,

The Holistic Progress Card for your child, Aarav Patel (Class 5-A, Term 1),
is now ready to view.

[View Card Button]

Access Code: HPC-A8X3K9

This link is valid for 30 days.

Instructions:
1. Click the "View Card" button above.
2. Enter the access code: HPC-A8X3K9.
3. View your child's complete card.

If you have any questions, please contact Sunshine School at 555-1234.

Thank you,
Sunshine School
```

---

## PART 4: The Guardian's Experience

Let us walk through what happens from the guardian's point of view. This will help you understand the complete experience.

### Step 1: Guardian Receives the Email

The guardian is at home or at work. They check their email on their phone or computer. They see an email from the school. The subject says their child's name. They open the email.

### Step 2: Guardian Reads the Email

The guardian reads the email. They see the school logo and their child's name. They see the "View Card" button. They see the access code. They read the instructions.

### Step 3: Guardian Clicks the Link

The guardian taps the "View Card" button on their phone. Or they click it on their computer. The phone or computer opens the web browser.

### Step 4: Guardian Enters the Access Code

The browser shows a page asking for the access code. The guardian types the code from the email. For example: HPC-A8X3K9.

### Step 5: The Card Appears

After entering the correct code, the student's progress card appears in the browser. The guardian sees the complete card with all sections:

School header with logo.
Student name, photo, class.
Attendance table.
Grades for each subject.
Teacher comments.
Student self-assessment.
Parent observations (if filled).
Life skills assessment.
Co-curricular activities.
Principal signature.

### Step 6: Guardian Explores the Card

The guardian can scroll through all pages. They can zoom in to read small text. They can tap or click on sections to expand them.

If the guardian wants a printed copy, they can use their browser's print function. The card will be printed as it appears on the screen.

### Step 7: Guardian Can Come Back Later

The guardian can bookmark the link and come back to it later. The link will work for 30 days. After 30 days, the link stops working.

If the guardian wants to show the card to a spouse or family member, they can share the link and access code. The card can be viewed on any device.

### What If the Guardian Cannot Find the Email?

Sometimes emails go to the wrong folder. The guardian should:

1. Check the Spam or Junk folder. Sometimes email systems mistakenly put school emails in the spam folder.

2. Search their email for the school name. Type "Sunshine School" in the search box to find the email.

3. If the email is truly lost, the guardian can ask the teacher to resend it. The teacher can click "Send Email" again to send a new email with a fresh link.

4. If the guardian has changed their email address, they should inform the school. The teacher can update the guardian's email address in the system and send the email again.

---

## PART 5: What the Teacher Sees After Sending

After the teacher sends an email or bulk emails, the student list shows indicators next to each student's name. These indicators tell the teacher what happened.

### Indicator: Email Sent

A small envelope icon appears next to the student's name. This icon means the email was queued successfully. The teacher knows the parent should receive the email soon.

If the teacher hovers their mouse over the icon, a tooltip might say: "Email sent on March 15, 2025."

### Indicator: No Email

A different icon (maybe a grey envelope with a slash through it) appears next to the student's name. This icon means the guardian has no email address on file. No email was sent.

The teacher sees this and knows they need to collect the guardian's email address. The teacher can ask the guardian directly or check the student's admission form for an email address.

### Future Enhancement: Delivery Tracking

In the future (not built yet), the system might show:

Has the guardian opened the email?
Has the guardian clicked the link?
Has the guardian viewed the card?

This information would help teachers know which parents have seen the card and which parents need a reminder. This feature is planned but not yet implemented.

---

## PART 6: What Is Built and What Is Missing

Let us look at which parts of this feature are working and which parts still need to be built.

### What Is Built and Working

Single email sending: The teacher can send an email to a single student's guardian. This works completely from start to finish. The email is created, queued, and sent.

Bulk email sending: The teacher can select multiple students and send emails to all their guardians. This also works completely.

Email template: The design of the email is complete. It has school branding, instructions, and the access code display. The email looks professional and is easy to read.

Queued sending: Emails are sent in the background using a queue. The teacher does not have to wait for the email to be sent. The teacher can continue working immediately.

Guardian email lookup: The system correctly finds guardians and their email addresses from the student's records. If there are two guardians, both are found and both receive emails.

Skip behavior: Guardians without email addresses are skipped gracefully. The computer does not crash or freeze. It just skips those guardians and notes it in the summary.

### What Is Not Built Yet

Rate limiting: There is currently no limit on how many emails can be sent in one batch. If a teacher selects 200 students, the system will try to send all 200 emails at once. This could overload the email server.

A rate limit would cap the number of emails at 100 per request. This would protect the system from overload. This enhancement is planned.

Delivery tracking: The system does not currently track whether the guardian opened the email or clicked the link. The teacher cannot know if the parent has seen the card.

Delivery tracking would add a small image or code to the email that tells the system when the email is opened. This would help teachers know who has viewed their child's card. This enhancement is planned.

---

## PART 7: Important Rules to Remember

### Rule 1: Emails Go to Guardians, Not Students

Emails are sent to parents or guardians. Students do NOT receive these emails. If a student asks for a copy of their card, they should ask their parents or teacher.

### Rule 2: Guardian Must Have a Valid Email Address

The guardian must have a valid email address in the school's system. If there is no email on file, the guardian is skipped. A warning is recorded but no error is shown to the teacher.

### Rule 3: Link, Not PDF Attachment

The email contains a view-link, not a PDF attachment. The card is viewed in the browser, not downloaded as a file. This is more secure and ensures the parent sees the latest version.

### Rule 4: Link Expires in 30 Days

The link is valid for 30 days from the time the email is sent. After 30 days, the link expires. The guardian would need to request a new link from the school.

### Rule 5: Emails Are Queued

Emails are sent in the background through a queue. The teacher does not need to keep the page open. The teacher can log out and the emails will still be sent.

### Rule 6: Skipped Guardians Are Noted

If a guardian is skipped because they have no email address, this is noted in the summary report. The teacher can see how many emails were sent and how many were skipped.

### Rule 7: No Rate Limit Currently

There is no rate limit on email sending. If you send a very large batch, it could slow down the system. It is better to send multiple small batches. An enhancement is planned to add a cap of 100 emails per request.

---

## Summary

The Email Distribution feature lets teachers send an email to parents with a link to view their child's progress card. The email does not contain a PDF attachment. Instead, it has a secure link and an access code.

Parents click the link, enter the code, and view the card in their browser. The link works for 30 days. Parents can view the card on any device and can print it if they want.

Teachers can send email to one parent or many parents at once. Bulk sending processes students one by one and shows a summary of how many emails were sent and how many were skipped.

The feature is mostly built and working. Two enhancements are planned: rate limiting and delivery tracking.
