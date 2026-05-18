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
   - Install Command: leave empty
6. Click **Deploy**.

Vercel will serve `index.html` from the project root.

## Custom Domain

After the first deploy:

1. Open the Vercel project.
2. Go to **Settings -> Domains**.
3. Add `flowtient.com`.
4. Follow the DNS instructions Vercel gives you.

## Important

The current contact form is front-end only. It shows a success message but does not send email or save leads yet. To make it production-ready, connect it to a form service or a Vercel serverless API route.
