const nodemailer = require('nodemailer');

const TO_EMAIL = process.env.AUDIT_TO_EMAIL || 'goldpinecapital@gmail.com';

function escapeHtml(value = '') {
  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function field(label, value) {
  return `
    <tr>
      <td style="padding:10px 12px;border-bottom:1px solid #e5e7eb;color:#64748b;width:170px;">${label}</td>
      <td style="padding:10px 12px;border-bottom:1px solid #e5e7eb;color:#0f172a;font-weight:600;">${escapeHtml(value || 'Not provided')}</td>
    </tr>
  `;
}

module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const {
    name = '',
    email = '',
    phone = '',
    company = '',
    challenge = '',
    size = '',
    website = '',
  } = req.body || {};

  // Honeypot field: real users never see/fill this.
  if (website) {
    return res.status(200).json({ ok: true });
  }

  if (!name.trim() || !email.trim() || !company.trim()) {
    return res.status(400).json({
      error: 'Please provide your name, work email, and company.',
    });
  }

  if (!process.env.GMAIL_USER || !process.env.GMAIL_APP_PASSWORD) {
    console.error('Missing GMAIL_USER or GMAIL_APP_PASSWORD environment variable.');
    return res.status(500).json({
      error: 'Lead email service is not configured yet.',
    });
  }

  const submittedAt = new Date().toLocaleString('en-US', {
    timeZone: 'America/Chicago',
    dateStyle: 'medium',
    timeStyle: 'short',
  });

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.GMAIL_USER,
      pass: process.env.GMAIL_APP_PASSWORD,
    },
  });

  const html = `
    <div style="font-family:Arial,sans-serif;background:#f8fafc;padding:24px;">
      <div style="max-width:680px;margin:0 auto;background:white;border:1px solid #e5e7eb;border-radius:16px;overflow:hidden;">
        <div style="background:#080b12;color:white;padding:22px 24px;">
          <h1 style="margin:0;font-size:22px;">New Flowtient AI Audit Lead</h1>
          <p style="margin:8px 0 0;color:#cbd5e1;">Submitted ${escapeHtml(submittedAt)}</p>
        </div>
        <table style="width:100%;border-collapse:collapse;">
          ${field('Name', name)}
          ${field('Email', email)}
          ${field('Phone', phone)}
          ${field('Company / Industry', company)}
          ${field('Team Size', size)}
          ${field('Workflow Challenge', challenge)}
        </table>
        <div style="padding:18px 24px;color:#64748b;font-size:13px;">
          Reply directly to this email or contact the lead using the details above.
        </div>
      </div>
    </div>
  `;

  try {
    await transporter.sendMail({
      from: `"Flowtient Website" <${process.env.GMAIL_USER}>`,
      to: TO_EMAIL,
      replyTo: email,
      subject: `New Flowtient AI Audit Lead: ${name} (${company})`,
      text: [
        'New Flowtient AI Audit Lead',
        `Submitted: ${submittedAt}`,
        `Name: ${name}`,
        `Email: ${email}`,
        `Phone: ${phone || 'Not provided'}`,
        `Company / Industry: ${company}`,
        `Team Size: ${size || 'Not provided'}`,
        '',
        'Workflow Challenge:',
        challenge || 'Not provided',
      ].join('\n'),
      html,
    });

    return res.status(200).json({ ok: true });
  } catch (error) {
    console.error('Failed to send lead email:', error);
    return res.status(500).json({
      error: 'Could not send your request right now. Please try again later.',
    });
  }
};
