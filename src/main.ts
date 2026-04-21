import './style.css';

type PageKey = 'home' | 'products' | 'blog';

const posts = [
  {
    title: 'Designing Data Platforms That Stay Understandable at Scale',
    date: 'February 2026',
    excerpt:
      'Scaling is not only about throughput. It is about keeping data pipelines observable, ownership clear, and failure recovery boring and fast.',
    body:
      'I approach data platform work as a long-term systems problem. A pipeline that runs quickly but nobody can reason about is already debt. In practice, that means explicit contracts between stages, operational dashboards that answer real support questions, and bounded complexity in each service. The goal is simple: make the platform resilient enough to survive growth and clear enough to be improved by the next engineer without heroics.',
  },
  {
    title: 'From Raw Signals to Decisions: Lakehouse Patterns That Work',
    date: 'January 2026',
    excerpt:
      'A practical blueprint for turning event streams and operational data into trusted, decision-ready models without over-engineering.',
    body:
      'The best lakehouse workflows are opinionated where it matters: naming standards, quality gates, and model ownership. I prefer small, composable transformations over giant jobs. Spark is powerful, but governance and testing are what make data usable by real teams. When we optimize for reliability and semantic consistency first, performance tuning becomes easier and outcomes improve across analytics and product surfaces.',
  },
  {
    title: 'AI for Nonprofits: Building Assistants That Reduce Admin Noise',
    date: 'December 2025',
    excerpt:
      'How we built a practical AI chatbot + workflow stack to handle repetitive member communications and receipts end to end.',
    body:
      'For nonprofits, the best AI systems are humble and operational. Using n8n orchestration with OpenAI and Mistral models, I designed assistants that respond across channels, classify and route requests, and trigger follow-up workflows for events, memberships, and receipts. The impact was measurable: fewer manual handoffs, faster response times, and more staff attention available for community outcomes instead of repetitive admin tasks.',
  },
];

const pageContent: Record<PageKey, string> = {
  home: `
    <section class="hero card">
      <div class="hero-text">
        <h1>I design and build software systems that scale quietly and last.</h1>
        <p>
          Most of my work lives in data platforms, cloud-native architectures, modern lakehouses,
          and Spark-based pipelines that move information from raw signals to usable insight.
        </p>
        <p>
          I enjoy shaping end-to-end data flows, simplifying complex systems, and exploring practical AI for development,
          automation, and decision support.
        </p>
        <p>
          At the core, I care about thoughtful engineering: systems that are understandable, resilient,
          and useful long after the diagrams are gone.
        </p>
      </div>
      <div class="hero-visual">
        <div class="hero-graphic-wrap">
          <img src="/eyedia_tech_g1.png" alt="EyediaTech graphic" class="hero-graphic" />
        </div>
      </div>
    </section>
  `,
  products: `
    <section class="section-head">
      <h2>Products</h2>
      <p>Two practical products focused on real outcomes.</p>
    </section>
    <section class="products-vertical">
      <article class="card product-card-vertical">
        <div class="product-header">
          <img src="/eyedeea_photos.png" alt="Eyedeea Photos" class="product-logo" />
          <h3>Eyedeea Photos</h3>
        </div>
        <p class="product-tagline">Your photos, organized and rediscovered</p>
        <p>
          A household-first cloud photo platform where you upload, curate, clean, and organize memories,
          then enjoy them as slideshows across browser, Android, and Fire TV.
        </p>
        <ul class="product-features">
          <li>Multi-device slideshow viewer</li>
          <li>Household sharing with role controls</li>
          <li>Duplicate & blur detection</li>
          <li>Secure cloud storage</li>
        </ul>
        <a class="button" href="https://eyedeeaphotos.eyediatech.com" target="_blank" rel="noreferrer noopener">Visit Product</a>
      </article>
      <article class="card product-card-vertical">
        <div class="product-header">
          <img src="/eyedia_chat_ai.png" alt="AI Chat Bot" class="product-logo" />
          <h3>AI Chat Bot for Nonprofit</h3>
        </div>
        <p class="product-tagline">Automate admin, focus on people</p>
        <p>
          A multi-channel assistant built for nonprofit operations. Handles conversations,
          receipts, events, and member workflows using n8n orchestration and modern LLMs.
        </p>
        <ul class="product-features">
          <li>Multi-channel conversation flow</li>
          <li>Receipt & event automation</li>
          <li>Member workflow triggers</li>
          <li>LLM-powered routing</li>
        </ul>
        <a class="button" href="mailto:support@eyediatech.com?subject=AI%20Chatbot%20Demo%20Request">Contact for Demo</a>
      </article>
    </section>
  `,
  blog: `
    <section class="section-head">
      <h2>Blog</h2>
      <p>Working notes on data systems, architecture, and practical AI.</p>
    </section>
    <section class="blog-list">
      ${posts
        .map(
          (post) => `
        <article class="card post-card">
          <p class="post-date">${post.date}</p>
          <h3>${post.title}</h3>
          <p class="post-excerpt">${post.excerpt}</p>
          <p>${post.body}</p>
        </article>
      `,
        )
        .join('')}
    </section>
  `,
};

const app = document.querySelector<HTMLDivElement>('#app');

if (!app) {
  throw new Error('App root not found');
}

app.innerHTML = `
  <div class="site-shell">
    <header class="top-nav">
      <a class="brand" href="#" aria-label="Go to home page">
        <img src="/logo.png" alt="EyediaTech logo" class="brand-logo" />
        <span>EyediaTech</span>
      </a>
      <nav>
        <button class="nav-link active" data-page="home">Home</button>
        <button class="nav-link" data-page="products">Products</button>
        <button class="nav-link" data-page="blog">Blog</button>
      </nav>
    </header>
    <main id="page-root"></main>
    <footer class="footer">
      <span>© ${new Date().getFullYear()} EyediaTech</span>
      <a href="mailto:support@eyediatech.com">support@eyediatech.com</a>
    </footer>
  </div>
`;

const pageRoot = document.querySelector<HTMLElement>('#page-root');
const navButtons = Array.from(document.querySelectorAll<HTMLButtonElement>('button.nav-link'));
const brandLink = document.querySelector<HTMLAnchorElement>('a.brand');

function render(page: PageKey) {
  if (!pageRoot) return;
  pageRoot.innerHTML = pageContent[page];
  navButtons.forEach((button) => {
    button.classList.toggle('active', button.dataset.page === page);
  });
}

navButtons.forEach((button) => {
  button.addEventListener('click', () => {
    const page = button.dataset.page as PageKey;
    render(page);
  });
});

brandLink?.addEventListener('click', (event) => {
  event.preventDefault();
  render('home');
});

render('home');
