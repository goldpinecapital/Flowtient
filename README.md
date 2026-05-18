# Flowtient Landing Page

Static landing page for Flowtient, an AI consulting business helping small and medium businesses improve workflows, automate repetitive operations, and scale with existing resources.

## Files

- `index.html` - main website content
- `styles.css` - visual design, layout, animation, responsive styling
- `script.js` - navigation, scroll reveal, FAQ accordion, form placeholder behavior
- `flowtient-logo.png` - square rounded logo and favicon
- `vercel.json` - Vercel deployment headers and static asset caching

## Deploy on Vercel

1. Push this folder to a GitHub repository.
2. Go to [Vercel](https://vercel.com/).
3. Click **Add New Project**.
4. Import the GitHub repository.
5. Use these settings:
   - Framework Preset: **Other**
   - Build Command: leave empty
   - Output Directory: leave empty
   - Install Command: leave default (`npm install`)
6. Click **Deploy**.

Vercel will serve `index.html` from the project root.

## Lead Capture Email Setup

The audit form posts to `api/audit.js`, a Vercel serverless function that emails every submission to `goldpinecapital@gmail.com`.

In Vercel, add these environment variables:

- `GMAIL_USER` - Gmail account used to send lead notifications, usually `goldpinecapital@gmail.com`
- `GMAIL_APP_PASSWORD` - Gmail App Password, not your normal Gmail password
- `AUDIT_TO_EMAIL` - where leads should be sent, usually `goldpinecapital@gmail.com`

To create a Gmail App Password:

1. Turn on 2-Step Verification for the Gmail account.
2. Go to Google Account -> Security -> App passwords.
3. Create an app password for "Mail".
4. Copy the 16-character password into Vercel as `GMAIL_APP_PASSWORD`.

After adding environment variables, redeploy the Vercel project.

If `GMAIL_USER` and `AUDIT_TO_EMAIL` are both `goldpinecapital@gmail.com`, Gmail may thread the message with sent mail or place it in **All Mail / Sent** instead of showing it as a fresh inbox message. For testing, you can temporarily set `AUDIT_TO_EMAIL` to another email address, redeploy, and submit the form again.

If the form shows success but no email arrives, check **Vercel -> Project -> Functions/Logs** for `Flowtient audit lead received` and `Flowtient audit lead email sent`.

## Custom Domain

After the first deploy:

1. Open the Vercel project.
2. Go to **Settings -> Domains**.
3. Add `flowtient.com`.
4. Follow the DNS instructions Vercel gives you.

## Important

The form sends lead details by email. There is no database yet. If you want a lead database later, the cheapest simple options are Google Sheets via Apps Script or Supabase free tier.
