(() => {
  const STORAGE_KEY = 'subastas-del-campo-prototype-v1';
  const grid = document.querySelector('#lot-grid');
  const search = document.querySelector('#lot-search');
  const empty = document.querySelector('#empty-state');
  const publishModal = document.querySelector('#publish-modal');
  const lotModal = document.querySelector('#lot-modal');
  const publishForm = document.querySelector('#publish-form');
  const bidForm = document.querySelector('#bid-form');
  const toast = document.querySelector('#toast');
  let selectedCategory = 'Todos';
  let selectedLotId = null;
  let toastTimer;

  const seedLots = [
    { id: 'sample-coffee', title: 'Café pergamino de cosecha reciente', category: 'Café', location: 'Líbano, Tolima', quantity: '12 sacos · 720 kg', price: 1980000, currentBid: 2180000, bids: 6, emoji: '☕', bg1: '#efe4c8', bg2: '#c0a879', note: 'Café secado al sol. Lote de demostración.', isSample: true },
    { id: 'sample-avocado', title: 'Aguacate Hass seleccionado', category: 'Frutas', location: 'Fresno, Tolima', quantity: '1.200 kg', price: 1460000, currentBid: 1620000, bids: 4, emoji: '🥑', bg1: '#e1edcd', bg2: '#a8c77f', note: 'Fruta clasificada para comercialización. Lote de demostración.', isSample: true },
    { id: 'sample-beans', title: 'Fríjol cargamanto seco', category: 'Granos', location: 'Villahermosa, Tolima', quantity: '450 kg', price: 2700000, currentBid: 2700000, bids: 1, emoji: '🫘', bg1: '#f0e1d2', bg2: '#caa780', note: 'Grano seco, almacenamiento en costales. Lote de demostración.', isSample: true }
  ];

  const money = value => new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'COP', maximumFractionDigits: 0 }).format(Number(value) || 0);
  const allLots = () => {
    try {
      const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
      return [...saved, ...seedLots];
    } catch {
      return seedLots;
    }
  };
  const saveUserLots = lots => {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(lots)); return true; }
    catch { return false; }
  };
  const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, char => ({ '&':'&amp;', '<':'&lt;', '>':'&gt;', '"':'&quot;', "'":'&#39;' })[char]);

  function notify(message) {
    toast.textContent = message;
    toast.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove('show'), 3400);
  }

  function renderLots() {
    const term = search.value.trim().toLocaleLowerCase('es');
    const visible = allLots().filter(lot => {
      const matchesCategory = selectedCategory === 'Todos' || lot.category === selectedCategory;
      const matchesSearch = `${lot.title} ${lot.location} ${lot.category}`.toLocaleLowerCase('es').includes(term);
      return matchesCategory && matchesSearch;
    });
    grid.innerHTML = visible.map(lot => `
      <article class="lot-card">
        <div class="lot-art" style="--lot-bg1:${escapeHtml(lot.bg1 || '#e9efdd')};--lot-bg2:${escapeHtml(lot.bg2 || '#cad9b9')}">
          <span class="sample-tag">${lot.isSample ? 'Ejemplo' : 'Guardado aquí'}</span>
          <span class="lot-emoji" aria-hidden="true">${escapeHtml(lot.emoji || '🌱')}</span>
          <span class="lot-category">${escapeHtml(lot.category)}</span>
        </div>
        <div class="lot-body">
          <div class="lot-location"><span>⌖ ${escapeHtml(lot.location)}</span><strong>ABIERTO · DEMO</strong></div>
          <h3>${escapeHtml(lot.title)}</h3>
          <div class="lot-info"><span>▦ ${escapeHtml(lot.quantity)}</span><span>↗ Recogida por acordar</span></div>
          <div class="lot-price-row"><div><span class="lot-price-label">Mínimo de ejemplo</span><strong class="lot-price">${money(lot.price)}</strong></div><div class="lot-offers"><strong>${money(lot.currentBid)}</strong>oferta más alta · ${lot.bids || 0} ofertas</div></div>
          <button class="lot-button" type="button" data-offer="${escapeHtml(lot.id)}">Ver lote y ofertar <span aria-hidden="true">↗</span></button>
        </div>
      </article>`).join('');
    empty.hidden = visible.length > 0;
    grid.hidden = visible.length === 0;
    grid.querySelectorAll('[data-offer]').forEach(button => button.addEventListener('click', () => openBid(button.dataset.offer)));
  }

  function openBid(id) {
    const lot = allLots().find(item => item.id === id);
    if (!lot) return;
    selectedLotId = id;
    document.querySelector('#bid-category').textContent = `${lot.category} · ${lot.location}`;
    document.querySelector('#lot-modal-title').textContent = lot.title;
    document.querySelector('#lot-modal-summary').textContent = `${lot.quantity}. ${lot.note || 'Publicación de demostración.'} Oferta actual de ejemplo: ${money(lot.currentBid)}. La próxima oferta debe superar ese valor.`;
    bidForm.elements.offer.min = Math.max(Number(lot.currentBid) + 1000, Number(lot.price) + 1000);
    bidForm.elements.offer.value = Math.max(Number(lot.currentBid) + 1000, Number(lot.price) + 1000);
    lotModal.showModal();
  }

  document.querySelector('#open-publish').addEventListener('click', () => publishModal.showModal());
  document.querySelectorAll('[data-close]').forEach(button => button.addEventListener('click', () => document.getElementById(button.dataset.close).close()));
  document.querySelectorAll('dialog').forEach(dialog => dialog.addEventListener('click', event => { if (event.target === dialog) dialog.close(); }));
  search.addEventListener('input', renderLots);
  document.querySelectorAll('[data-category]').forEach(button => button.addEventListener('click', () => {
    selectedCategory = button.dataset.category;
    document.querySelectorAll('[data-category]').forEach(chip => chip.classList.toggle('active', chip === button));
    renderLots();
  }));

  publishForm.addEventListener('submit', event => {
    event.preventDefault();
    const data = new FormData(publishForm);
    const lot = {
      id: `local-${Date.now()}`,
      title: String(data.get('title')).trim(),
      category: String(data.get('category')),
      location: String(data.get('location')).trim(),
      quantity: String(data.get('quantity')).trim(),
      price: Number(data.get('minimum')),
      currentBid: Number(data.get('minimum')),
      bids: 0,
      emoji: ({ Café: '☕', Frutas: '🥑', Granos: '🫘', Otros: '🌾' })[String(data.get('category'))] || '🌾',
      note: String(data.get('details')).trim() || 'Lote agregado como ejemplo local.',
      isSample: false
    };
    let saved;
    try { saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]'); } catch { saved = []; }
    saved.unshift(lot);
    if (!saveUserLots(saved)) {
      notify('Este navegador no permitió guardar la publicación.');
      return;
    }
    publishModal.close();
    publishForm.reset();
    search.value = '';
    selectedCategory = 'Todos';
    document.querySelectorAll('[data-category]').forEach(chip => chip.classList.toggle('active', chip.dataset.category === 'Todos'));
    renderLots();
    notify('Publicación de ejemplo guardada solo en este dispositivo.');
    document.querySelector('#lotes').scrollIntoView({ behavior: 'smooth' });
  });

  bidForm.addEventListener('submit', event => {
    event.preventDefault();
    const offer = Number(bidForm.elements.offer.value);
    const sample = seedLots.find(item => item.id === selectedLotId);
    if (sample) {
      if (offer <= sample.currentBid) { notify('La oferta debe superar la oferta de ejemplo actual.'); return; }
      sample.currentBid = offer;
      sample.bids += 1;
    } else {
      let userLots;
      try { userLots = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]'); } catch { userLots = []; }
      const lot = userLots.find(item => item.id === selectedLotId);
      if (!lot || offer <= lot.currentBid) { notify('La oferta debe superar la oferta actual.'); return; }
      lot.currentBid = offer;
      lot.bids += 1;
      saveUserLots(userLots);
    }
    lotModal.close();
    renderLots();
    notify('Oferta de prueba registrada solo en este dispositivo; no se avisó a ningún productor.');
  });

  renderLots();
})();
