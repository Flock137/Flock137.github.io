#!/usr/bin/env bash
# Run from your Hugo site root:  bash setup_theme.sh
# Creates the theme at themes/synthwave-dev/

THEME="themes/electric-cyberpunk"
mkdir -p \
  $THEME/{archetypes,assets/css,assets/js,layouts/{_default,partials/{head,footer},shortcodes},static/{fonts,img},i18n}

# ── theme.toml ────────────────────────────────────────────────────────────────
cat > $THEME/theme.yaml << 'EOF'
name: "Electric Cyberpunk"
license: "MIT"
licenselink: "https://opensource.org/licenses/MIT"
description: "A synthwave-inspired dark/light Hugo theme for technical blogs."
homepage: "https://github.com/yourname/synthwave-dev"
tags:
  - blog
  - dark
  - synthwave
  - technical
  - toc
features:
  - toc
  - syntax highlighting
  - light/dark toggle
min_version: "0.112.0"
EOF

# ── archetypes/default.md ─────────────────────────────────────────────────────
cat > $THEME/archetypes/default.md << 'EOF'
---
title: "{{ replace .Name "-" " " | title }}"
date: {{ .Date }}
draft: true
description: ""
tags: []
categories: []
thumbnail: ""   # leave blank for gradient fallback
toc: true
---
EOF

# ── assets/css/main.css ───────────────────────────────────────────────────────
cat > $THEME/assets/css/main.css << 'EOF'
/* ═══════════════════════════════════════════════
   Synthwave Dev Theme — CSS
   Dark (default) + Light variant
   ═══════════════════════════════════════════════ */

/* ── Tokens: Dark (Synthwave) ── */
:root {
  --bg:          #0d0d1a;
  --bg-card:     #12122a;
  --bg-code:     #1a1a35;
  --border:      #2a2a6a;
  --text:        #e0d9f5;
  --text-muted:  #7a77a0;
  --accent:      #c678ff;       /* neon violet */
  --accent2:     #67b8ff;       /* neon blue   */
  --accent3:     #ff79c6;       /* neon pink   */
  --link:        #c678ff;
  --link-hover:  #ff79c6;
  --toc-width:   260px;
  --font-sans:   'Inter', system-ui, sans-serif;
  --font-mono:   'JetBrains Mono', 'Fira Code', monospace;
  --radius:      8px;
  --shadow:      0 2px 16px rgba(198,120,255,.12);
}

/* ── Tokens: Light ── */
[data-theme="light"] {
  --bg:          #f4f2ff;
  --bg-card:     #ffffff;
  --bg-code:     #ede8ff;
  --border:      #c5b8f0;
  --text:        #1a1232;
  --text-muted:  #6b5f8a;
  --accent:      #7c3aed;
  --accent2:     #2563eb;
  --accent3:     #db2777;
  --link:        #7c3aed;
  --link-hover:  #db2777;
  --shadow:      0 2px 16px rgba(124,58,237,.10);
}

/* ── Reset / Base ── */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

html { scroll-behavior: smooth; font-size: 16px; }

body {
  background: var(--bg);
  color: var(--text);
  font-family: var(--font-sans);
  line-height: 1.7;
  transition: background .25s, color .25s;
}

a { color: var(--link); text-decoration: none; transition: color .2s; }
a:hover { color: var(--link-hover); }

img { max-width: 100%; height: auto; display: block; border-radius: var(--radius); }

/* ── Layout ── */
.site-wrap {
  display: grid;
  grid-template-rows: auto 1fr auto;
  min-height: 100vh;
}

.container {
  width: min(90%, 1100px);
  margin-inline: auto;
  padding-inline: 1rem;
}

/* ── Header ── */
.site-header {
  border-bottom: 1px solid var(--border);
  padding: 1rem 0;
  position: sticky;
  top: 0;
  z-index: 100;
  background: var(--bg);
  backdrop-filter: blur(8px);
}

.site-header .container {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.site-logo {
  font-size: 1.25rem;
  font-weight: 800;
  background: linear-gradient(90deg, var(--accent), var(--accent2));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  letter-spacing: -.5px;
}

.site-nav { display: flex; gap: 1.5rem; align-items: center; }
.site-nav a { color: var(--text-muted); font-size: .9rem; font-weight: 500; }
.site-nav a:hover { color: var(--accent); }

/* Theme toggle */
#theme-toggle {
  background: none;
  border: 1px solid var(--border);
  border-radius: 20px;
  padding: .25rem .65rem;
  cursor: pointer;
  color: var(--text-muted);
  font-size: .85rem;
  transition: border-color .2s, color .2s;
}
#theme-toggle:hover { border-color: var(--accent); color: var(--accent); }

/* ── Post with ToC sidebar ── */
.post-layout {
  display: grid;
  grid-template-columns: 1fr var(--toc-width);
  gap: 2.5rem;
  align-items: start;
  padding: 2.5rem 0 4rem;
  min-width: 0;
}

[data-theme="light"] .post-content pre {
  background: #1a1a35;
}
[data-theme="light"] .post-content pre:not(.chroma) code {
  color: #e0d9f5;
}
  .post-layout { grid-template-columns: 1fr; }
  .toc-sidebar { display: none; }
}

@media (max-width: 600px) {
  .post-content pre { font-size: .78rem; padding: .8rem .9rem; }
  .post-content table { display: block; overflow-x: auto; }
}

/* ── ToC Sidebar ── */
.toc-sidebar {
  position: sticky;
  top: 80px;
  max-height: calc(100vh - 100px);
  overflow-y: auto;
  padding: 1rem 1.2rem;
  border-left: 2px solid var(--border);
  font-size: .82rem;
}

.toc-sidebar h3 {
  font-size: .7rem;
  text-transform: uppercase;
  letter-spacing: .1em;
  color: var(--text-muted);
  margin-bottom: .75rem;
}

.toc-sidebar nav ul { list-style: none; }
.toc-sidebar nav ul li { margin: .35rem 0; }
.toc-sidebar nav ul ul { padding-left: .9rem; }

.toc-sidebar nav a {
  color: var(--text-muted);
  display: block;
  border-left: 2px solid transparent;
  padding-left: .5rem;
  transition: color .15s, border-color .15s;
}
.toc-sidebar nav a:hover,
.toc-sidebar nav a.active {
  color: var(--accent);
  border-left-color: var(--accent);
}

/* ── Post content ── */
.post-content h1,h2,h3,h4 { margin: 1.8rem 0 .8rem; line-height: 1.3; color: var(--text); }
.post-content h2 { border-bottom: 1px solid var(--border); padding-bottom: .4rem; }
.post-content p  { margin-bottom: 1rem; }

.post-content code {
  font-family: var(--font-mono);
  background: var(--bg-code);
  border: 1px solid var(--border);
  border-radius: 4px;
  padding: .15em .4em;
  font-size: .88em;
  color: var(--accent3);
}

.post-content pre {
  background: var(--bg-code);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 1.1rem 1.3rem;
  overflow-x: auto;
  margin: 1.2rem 0;
  box-shadow: var(--shadow);
  max-width: 100%;
  white-space: pre-wrap;
  word-break: break-all;
}
.post-content pre code {
  background: none;
  border: none;
  padding: 0;
  color: var(--code-text, var(--text));
  font-size: .87em;
}

.post-content blockquote {
  border-left: 3px solid var(--accent);
  padding: .6rem 1rem;
  margin: 1.2rem 0;
  color: var(--text-muted);
  background: var(--bg-card);
  border-radius: 0 var(--radius) var(--radius) 0;
}

.post-content table {
  width: 100%;
  border-collapse: collapse;
  margin: 1.2rem 0;
  font-size: .9rem;
}
.post-content th { background: var(--bg-code); color: var(--accent2); }
.post-content th, .post-content td {
  border: 1px solid var(--border);
  padding: .5rem .8rem;
  text-align: left;
}
.post-content tr:nth-child(even) { background: var(--bg-card); }

/* ── Thumbnail: with image or gradient fallback ── */
.post-thumbnail {
  width: 100%;
  aspect-ratio: 16/7;
  border-radius: var(--radius);
  overflow: hidden;
  margin-bottom: 1.8rem;
  box-shadow: var(--shadow);
}
.post-thumbnail img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 0;
}
/* Fallback gradient when no image */
.post-thumbnail.no-image {
  background: linear-gradient(135deg, #1a0533 0%, #0d1b4d 40%, #12082e 70%, #1a0533 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
}
.post-thumbnail.no-image::before {
  content: '';
  position: absolute;
  inset: 0;
  background:
    radial-gradient(ellipse at 20% 80%, rgba(198,120,255,.25) 0%, transparent 55%),
    radial-gradient(ellipse at 80% 20%, rgba(103,184,255,.2) 0%, transparent 55%);
}
.post-thumbnail.no-image .thumb-title {
  position: relative;
  z-index: 1;
  font-size: 1.6rem;
  font-weight: 800;
  text-align: center;
  padding: 1rem 2rem;
  background: linear-gradient(90deg, var(--accent), var(--accent2));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  line-height: 1.3;
}

[data-theme="light"] .post-thumbnail.no-image {
  background: linear-gradient(135deg, #ede8ff 0%, #dbeafe 50%, #f5d0fe 100%);
}

/* ── Post header meta ── */
.post-meta {
  display: flex;
  flex-wrap: wrap;
  gap: .5rem 1rem;
  font-size: .82rem;
  color: var(--text-muted);
  margin-bottom: 2rem;
}
.post-meta .tag {
  background: var(--bg-code);
  border: 1px solid var(--border);
  border-radius: 20px;
  padding: .15rem .6rem;
  color: var(--accent);
  font-size: .78rem;
}

/* ── Card grid (list page) ── */
.post-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1.5rem;
  padding: 2rem 0 4rem;
}

.post-card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  overflow: hidden;
  transition: transform .2s, box-shadow .2s, border-color .2s;
  display: flex;
  flex-direction: column;
}
.post-card:hover {
  transform: translateY(-3px);
  box-shadow: var(--shadow);
  border-color: var(--accent);
}

/* Card thumbnail */
.card-thumb {
  aspect-ratio: 16/9;
  overflow: hidden;
}
.card-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  border-radius: 0;
  transition: transform .3s;
}
.post-card:hover .card-thumb img { transform: scale(1.04); }

.card-thumb.no-image {
  background: linear-gradient(135deg, #1a0533, #0d1b4d, #12082e);
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}
.card-thumb.no-image::before {
  content: '';
  position: absolute;
  inset: 0;
  background: radial-gradient(ellipse at 30% 70%, rgba(198,120,255,.2) 0%, transparent 60%);
}
.card-thumb.no-image span {
  font-size: 2rem;
  position: relative;
  z-index: 1;
}

[data-theme="light"] .card-thumb.no-image {
  background: linear-gradient(135deg, #ede8ff, #dbeafe);
}

.card-body { padding: 1.1rem 1.2rem; flex: 1; display: flex; flex-direction: column; gap: .5rem; }
.card-title { font-size: 1rem; font-weight: 700; color: var(--text); line-height: 1.35; }
.card-title:hover { color: var(--accent); }
.card-desc { font-size: .85rem; color: var(--text-muted); flex: 1; }
.card-meta { font-size: .75rem; color: var(--text-muted); margin-top: auto; }
.card-tags { display: flex; flex-wrap: wrap; gap: .3rem; margin-top: .4rem; }
.card-tags .tag {
  background: var(--bg-code);
  border: 1px solid var(--border);
  border-radius: 20px;
  padding: .1rem .5rem;
  font-size: .72rem;
  color: var(--accent);
}

/* ── Pagination ── */
.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: .4rem;
  padding: 1rem 0 3rem;
  list-style: none;
}
.pagination a,
.pagination span {
  display: inline-block;
  padding: .35rem .8rem;
  border-radius: var(--radius);
  font-size: .85rem;
  color: var(--text-muted);
  transition: .2s;
  line-height: 1.4;
}
.pagination a:hover { color: var(--accent); }
.pagination .active a,
.pagination .active span {
  border: 1px solid var(--accent);
  color: var(--accent);
}
.pagination li { list-style: none; }
/* hide Hugo's dot separators */
.pagination li::marker,
.pagination li > span:only-child:not([class]) { display: none; }

/* ── Footer ── */
.site-footer {
  border-top: 1px solid var(--border);
  padding: 1.5rem 0;
  text-align: center;
  font-size: .8rem;
  color: var(--text-muted);
}

/* ── Scrollbar ── */
::-webkit-scrollbar { width: 6px; }
::-webkit-scrollbar-track { background: var(--bg); }
::-webkit-scrollbar-thumb { background: var(--border); border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: var(--accent); }
EOF

# ── assets/js/theme.js ────────────────────────────────────────────────────────
cat > $THEME/assets/js/theme.js << 'EOF'
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
EOF

# ── layouts/_default/baseof.html ─────────────────────────────────────────────
cat > $THEME/layouts/_default/baseof.html << 'EOF'
<!DOCTYPE html>
<html lang="{{ .Site.Language.Lang | default "en" }}" data-theme="dark">
<head>
  {{ partial "head/meta.html" . }}
</head>
<body class="site-wrap">
  {{ partial "header.html" . }}
  <main class="container">
    {{ block "main" . }}{{ end }}
  </main>
  {{ partial "footer/footer.html" . }}
  {{ $js := resources.Get "js/theme.js" | minify }}
  <script src="{{ $js.RelPermalink }}" defer></script>
</body>
</html>
EOF

# ── layouts/partials/head/meta.html ──────────────────────────────────────────
cat > $THEME/layouts/partials/head/meta.html << 'EOF'
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{{ if .IsHome }}{{ .Site.Title }}{{ else }}{{ .Title }} | {{ .Site.Title }}{{ end }}</title>
<meta name="description" content="{{ with .Description }}{{ . }}{{ else }}{{ .Site.Params.description }}{{ end }}">
{{ $css := resources.Get "css/main.css" | minify }}
<link rel="stylesheet" href="{{ $css.RelPermalink }}">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;700;800&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
{{ hugo.Generator }}
EOF

# ── layouts/partials/header.html ─────────────────────────────────────────────
cat > $THEME/layouts/partials/header.html << 'EOF'
<header class="site-header">
  <div class="container">
    <a class="site-logo" href="{{ "/" | relURL }}">{{ .Site.Title }}</a>
    <nav class="site-nav">
      {{ range .Site.Menus.main }}
        <a href="{{ .URL }}">{{ .Name }}</a>
      {{ end }}
      <button id="theme-toggle" aria-label="Toggle theme">☀️ Light</button>
    </nav>
  </div>
</header>
EOF

# ── layouts/partials/footer/footer.html ──────────────────────────────────────
cat > $THEME/layouts/partials/footer/footer.html << 'EOF'
<footer class="site-footer">
  <div class="container">
    <p>© {{ now.Year }} {{ .Site.Title }} · Built with <a href="https://gohugo.io">Hugo</a></p>
  </div>
</footer>
EOF

# ── layouts/partials/pagination.html ─────────────────────────────────────────
cat > $THEME/layouts/partials/pagination.html << 'EOF'
{{ $p := .Paginator }}
{{ if gt $p.TotalPages 1 }}
<nav class="pagination">
  {{ if $p.HasPrev }}
    <a href="{{ $p.First.URL }}">&laquo;</a>
    <a href="{{ $p.Prev.URL }}">&lsaquo;</a>
  {{ end }}
  {{ range $p.Pagers }}
    {{ if eq . $p }}
      <span class="active">{{ .PageNumber }}</span>
    {{ else }}
      <a href="{{ .URL }}">{{ .PageNumber }}</a>
    {{ end }}
  {{ end }}
  {{ if $p.HasNext }}
    <a href="{{ $p.Next.URL }}">&rsaquo;</a>
    <a href="{{ $p.Last.URL }}">&raquo;</a>
  {{ end }}
</nav>
{{ end }}
EOF

# ── layouts/partials/thumbnail.html ──────────────────────────────────────────
cat > $THEME/layouts/partials/thumbnail.html << 'EOF'
{{/* Usage: {{ partial "thumbnail.html" (dict "thumb" .Params.thumbnail "title" .Title "class" "post-thumbnail") }} */}}
{{ $thumb := .thumb }}
{{ $title := .title }}
{{ $class := .class | default "post-thumbnail" }}
<div class="{{ $class }}{{ if not $thumb }} no-image{{ end }}">
  {{ if $thumb }}
    <img src="{{ $thumb }}" alt="{{ $title }}" loading="lazy">
  {{ end }}
</div>
EOF

# ── layouts/_default/list.html ───────────────────────────────────────────────
cat > $THEME/layouts/_default/list.html << 'EOF'
{{ define "main" }}
<h1 style="padding: 2rem 0 .5rem; font-size: 1.6rem; color: var(--text);">
  {{ .Title | default "Posts" }}
</h1>
<div class="post-grid">
  {{ range where .Paginator.Pages "Kind" "page" }}
  <article class="post-card">
    <a href="{{ .RelPermalink }}">
      {{ $thumb := .Params.thumbnail }}
      <div class="card-thumb{{ if not $thumb }} no-image{{ end }}">
        {{ if $thumb }}
          <img src="{{ $thumb }}" alt="{{ .Title }}" loading="lazy">
        {{ else }}
        {{ end }}
      </div>
    </a>
    <div class="card-body">
      <a class="card-title" href="{{ .RelPermalink }}">{{ .Title }}</a>
      {{ with .Description }}<p class="card-desc">{{ . }}</p>{{ end }}
      <p class="card-meta">{{ .Date.Format "Jan 2, 2006" }} · {{ .ReadingTime }} min read</p>
      {{ with .Params.tags }}
      <div class="card-tags">
        {{ range . }}<span class="tag">{{ . }}</span>{{ end }}
      </div>
      {{ end }}
    </div>
  </article>
  {{ end }}
</div>
{{ partial "pagination.html" . }}
{{ end }}
EOF

# ── layouts/_default/single.html ─────────────────────────────────────────────
cat > $THEME/layouts/_default/single.html << 'EOF'
{{ define "main" }}
<div class="post-layout">
  <!-- Article -->
  <article>
    {{ partial "thumbnail.html" (dict "thumb" .Params.thumbnail "title" .Title "class" "post-thumbnail") }}

    <h1 style="font-size: 2rem; line-height: 1.2; margin-bottom: .8rem;">{{ .Title }}</h1>
    <div class="post-meta">
      <span>{{ .Date.Format "January 2, 2006" }}</span>
      <span>{{ .ReadingTime }} min read</span>
      {{ with .Params.tags }}
        {{ range . }}<span class="tag">{{ . }}</span>{{ end }}
      {{ end }}
    </div>

    <div class="post-content">
      {{ .Content }}
    </div>
  </article>

  <!-- ToC Sidebar -->
  {{ if .Params.showToc }}
  <aside class="toc-sidebar">
    <h3>On this page</h3>
    <nav>{{ .TableOfContents }}</nav>
  </aside>
  {{ end }}
</div>
{{ end }}
EOF

# ── layouts/index.html ────────────────────────────────────────────────────────
cat > $THEME/layouts/index.html << 'EOF'
{{ define "main" }}
<section style="padding: 4rem 0 2rem;">
  <h1 style="font-size: 2.6rem; font-weight: 800; background: linear-gradient(90deg, var(--accent), var(--accent2)); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-clip: text;">
    {{ .Site.Title }}
  </h1>
  {{ with .Site.Params.tagline }}
  <p style="color: var(--text-muted); margin-top: .6rem; font-size: 1.1rem;">{{ . }}</p>
  {{ end }}

</section>

<h2 style="font-size: 1.1rem; color: var(--text-muted); letter-spacing: .05em; text-transform: uppercase; margin-bottom: 1rem;">Latest Posts</h2>
<div class="post-grid">
  {{ range first 6 (where .Site.RegularPages "Type" "posts") }}
  <article class="post-card">
    <a href="{{ .RelPermalink }}">
      {{ $thumb := .Params.thumbnail }}
      <div class="card-thumb{{ if not $thumb }} no-image{{ end }}">
        {{ if $thumb }}
          <img src="{{ $thumb }}" alt="{{ .Title }}" loading="lazy">
        {{ else }}
        {{ end }}
      </div>
    </a>
    <div class="card-body">
      <a class="card-title" href="{{ .RelPermalink }}">{{ .Title }}</a>
      {{ with .Description }}<p class="card-desc">{{ . }}</p>{{ end }}
      <p class="card-meta">{{ .Date.Format "Jan 2, 2006" }} · {{ .ReadingTime }} min read</p>
    </div>
  </article>
  {{ end }}
</div>
{{ end }}
EOF

# ── hugo.toml additions (example) ────────────────────────────────────────────
echo "⚠️  Copy hugo.yaml into your site root separately."

echo "✅ Theme scaffolded at $THEME"
echo "   Place hugo.yaml in your site root, then run: hugo server"