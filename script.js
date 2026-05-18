/* ---------------------------------------------
   Flowtient - Landing Page Interactions
--------------------------------------------- */

'use strict';

// -- NAV: scroll state & mobile toggle ----------
(function initNav() {
  const nav = document.getElementById('nav');
  const toggle = document.getElementById('navToggle');

  function onScroll() {
    nav.classList.toggle('scrolled', window.scrollY > 20);
  }

  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  toggle.addEventListener('click', () => {
    nav.classList.toggle('mobile-open');
  });

  // close mobile nav on link click
  nav.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => nav.classList.remove('mobile-open'));
  });
})();

// -- SCROLL REVEAL ------------------------------
(function initReveal() {
  const els = document.querySelectorAll('.reveal');

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('in-view');
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.1, rootMargin: '0px 0px -48px 0px' }
  );

  els.forEach(el => observer.observe(el));
})();

// -- FAQ ACCORDION ------------------------------
(function initFaq() {
  const items = document.querySelectorAll('.faq-question');

  items.forEach(btn => {
    btn.addEventListener('click', () => {
      const answer = btn.nextElementSibling;
      const isOpen = btn.getAttribute('aria-expanded') === 'true';

      // close all others
      document.querySelectorAll('.faq-question[aria-expanded="true"]').forEach(other => {
        if (other !== btn) {
          other.setAttribute('aria-expanded', 'false');
          other.nextElementSibling.style.maxHeight = null;
        }
      });

      if (isOpen) {
        btn.setAttribute('aria-expanded', 'false');
        answer.style.maxHeight = null;
      } else {
        btn.setAttribute('aria-expanded', 'true');
        answer.style.maxHeight = answer.scrollHeight + 'px';
      }
    });
  });
})();

// -- CONTACT FORM -------------------------------
(function initForm() {
  const form = document.getElementById('contactForm');
  if (!form) return;

  form.addEventListener('submit', (e) => {
    e.preventDefault();

    const btn = form.querySelector('button[type="submit"]');
    const original = btn.textContent;

    btn.textContent = 'Sending...';
    btn.disabled = true;

    // Simulate submission - replace with actual endpoint (Formspree, EmailJS, etc.)
    setTimeout(() => {
      btn.textContent = 'Sent! We\'ll be in touch within 4 hours.';
      btn.style.background = 'var(--success)';

      // Collect form data for logging / debugging
      const data = {
        name:      form.querySelector('#name').value,
        email:     form.querySelector('#email').value,
        company:   form.querySelector('#company').value,
        challenge: form.querySelector('#challenge').value,
        size:      form.querySelector('#size').value,
        timestamp: new Date().toISOString(),
      };
      console.log('[Flowtient] Form submission:', data);

      // Reset after delay
      setTimeout(() => {
        form.reset();
        btn.textContent = original;
        btn.disabled = false;
        btn.style.background = '';
      }, 5000);
    }, 1200);
  });
})();

// -- SMOOTH ANCHOR SCROLL -----------------------
(function initSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', (e) => {
      const target = document.querySelector(anchor.getAttribute('href'));
      if (!target) return;
      e.preventDefault();
      const offset = document.getElementById('nav').offsetHeight + 16;
      const top = target.getBoundingClientRect().top + window.scrollY - offset;
      window.scrollTo({ top, behavior: 'smooth' });
    });
  });
})();

// -- ACTIVE NAV HIGHLIGHT -----------------------
(function initActiveNav() {
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-links a');

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const id = entry.target.getAttribute('id');
          navLinks.forEach(link => {
            link.style.color = link.getAttribute('href') === `#${id}`
              ? 'var(--text-primary)'
              : '';
          });
        }
      });
    },
    { threshold: 0.3 }
  );

  sections.forEach(s => observer.observe(s));
})();

// -- HERO TYPING EFFECT (optional subtle animation) -
(function initHeroAnimation() {
  const heading = document.querySelector('.hero-heading');
  if (!heading) return;

  // Subtle entrance - heading already has CSS reveal
  // Add a small shimmer to the accent span after load
  const accent = heading.querySelector('.text-accent');
  if (!accent) return;

  setTimeout(() => {
    accent.style.transition = 'opacity 0.3s ease';
  }, 1000);
})();

// -- COUNTER ANIMATION for proof stats ----------
(function initCounters() {
  const proofNums = document.querySelectorAll('.proof-num');

  const parseValue = (str) => {
    const num = parseFloat(str.replace(/[^0-9.]/g, ''));
    const suffix = str.replace(/[0-9.]/g, '').trim();
    return { num, suffix };
  };

  const animateCounter = (el) => {
    const raw = el.textContent.trim();
    if (raw.includes('-') || raw.includes('–')) return;
    const { num, suffix } = parseValue(raw);
    if (isNaN(num)) return;

    const duration = 1400;
    const start = performance.now();
    const startVal = 0;

    const tick = (now) => {
      const elapsed = now - start;
      const progress = Math.min(elapsed / duration, 1);
      // easeOutCubic
      const eased = 1 - Math.pow(1 - progress, 3);
      const current = startVal + (num - startVal) * eased;

      // Format integer vs decimal
      const formatted = Number.isInteger(num)
        ? Math.round(current).toString()
        : current.toFixed(1);

      el.textContent = formatted + suffix;

      if (progress < 1) requestAnimationFrame(tick);
    };

    requestAnimationFrame(tick);
  };

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          animateCounter(entry.target);
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.5 }
  );

  proofNums.forEach(el => observer.observe(el));
})();
