const nodemailer = require('nodemailer');

const TO_EMAIL = process.env.AUDIT_TO_EMAIL || 'goldpinecapital@gmail.com';

async function readBody(req) {
  if (req.body && typeof req.body === 'object') return req.body;
  if (typeof req.body === 'string') {
    try {
      return JSON.parse(req.body);
    } catch {
      return {};
    }
  }

  const chunks = [];
  for await (const chunk of req) {
    chunks.push(Buffer.from(chunk));
  }

  if (!chunks.length) return {};

  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return {};
  }
}

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

  const body = await readBody(req);

  const {
    name = '',
    email = '',
    phone = '',
    company = '',
    challenge = '',
    size = '',
    website = '',
  } = body;

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
    console.error('Flowtient audit email config missing', {
      hasGmailUser: Boolean(process.env.GMAIL_USER),
      hasGmailAppPassword: Boolean(process.env.GMAIL_APP_PASSWORD),
      toEmail: TO_EMAIL,
    });
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
    host: 'smtp.gmail.com',
    port: 465,
    secure: true,
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
    console.log('Flowtient audit lead received', {
      name,
      email,
      phoneProvided: Boolean(phone),
      company,
      size,
      toEmail: TO_EMAIL,
    });

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

    console.log('Flowtient audit lead email sent', { toEmail: TO_EMAIL, leadEmail: email });
    return res.status(200).json({ ok: true });
  } catch (error) {
    console.error('Failed to send Flowtient lead email:', {
      message: error.message,
      code: error.code,
      command: error.command,
      response: error.response,
      responseCode: error.responseCode,
    });
    return res.status(500).json({
      error: 'Could not send your request right now. Please try again later.',
    });
  }
};
