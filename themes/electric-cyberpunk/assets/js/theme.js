/* Theme toggle + ToC active link on scroll */
(function () {
  const root = document.documentElement;
  const btn  = document.getElementById('theme-toggle');
  const stored = localStorage.getItem('theme');
  if (stored) root.setAttribute('data-theme', stored);

  btn?.addEventListener('click', () => {
    const cur  = root.getAttribute('data-theme');
    const next = cur === 'light' ? 'dark' : 'light';
    root.setAttribute('data-theme', next);
    localStorage.setItem('theme', next);
    btn.textContent = next === 'light' ? '🌙 Dark' : '☀️ Light';
  });

  // ── ToC scroll spy ──────────────────────────────
  const tocLinks = document.querySelectorAll('.toc-sidebar nav a');
  if (!tocLinks.length) return;

  const headings = [...document.querySelectorAll('.post-content h2, .post-content h3, .post-content h4')];

  const observer = new IntersectionObserver(entries => {
    entries.forEach(e => {
      if (e.isIntersecting) {
        tocLinks.forEach(l => l.classList.remove('active'));
        const active = document.querySelector(`.toc-sidebar nav a[href="#${e.target.id}"]`);
        active?.classList.add('active');
      }
    });
  }, { rootMargin: '-20% 0px -75% 0px' });

  headings.forEach(h => observer.observe(h));
})();
