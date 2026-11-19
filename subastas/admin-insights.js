(() => {
  const KEY = 'subastas-del-campo-market-v1';
  const $ = (selector) => document.querySelector(selector);
  const safe = (value) => String(value ?? '').replace(/[&<>"']/g, (ch) => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[ch]));
  const read = (key, fallback) => { try { return JSON.parse(localStorage.getItem(key) || JSON.stringify(fallback)); } catch (_) { return fallback; } };
  const normalized = (value) => String(value || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  const cop = (value) => new Intl.NumberFormat('es-CO', {style:'currency', currency:'COP', maximumFractionDigits:0}).format(Number(value) || 0);
  const date = (value) => value ? new Date(value).toLocaleString('es-CO', {dateStyle:'short', timeStyle:'short'}) : '—';
  function render() {
    const market = read(KEY, {}), users = read('subscribers', []);
    const listings = Array.isArray(market.lots) ? market.lots : [];
    const offers = Array.isArray(market.offers) ? market.offers : [];
    const reviews = Array.isArray(market.reviews) ? market.reviews : [];
    const cases = Array.isArray(market.moderationCases) ? market.moderationCases : [];
    const demand = new Map(listings.map(lot => [lot.id, {lot, count:0}]));
    offers.forEach(offer => { const item = demand.get(offer.lotId); if (item) item.count += 1; else demand.set(offer.lotId, {lot:{id:offer.lotId,title:offer.lotTitle || offer.lotId}, count:1}); });
    const ranked = [...demand.values()].sort((a,b) => b.count - a.count);
    $('#insight-listings').textContent = String(listings.length);
    $('#insight-ratings').textContent = String(reviews.length);
    $('#insight-deliveries').textContent = String(new Set(reviews.filter(review => review.deliveryConfirmed).map(review => review.lotId)).size);
    $('#insight-most').textContent = ranked.length && ranked[0].count ? `${ranked[0].lot.title} (${ranked[0].count})` : 'Aún sin ofertas';
    const least = ranked.filter(item => item.count > 0).sort((a,b) => a.count - b.count)[0];
    $('#insight-least').textContent = least ? `${least.lot.title} (${least.count})` : 'Aún sin ofertas';
    $('#insight-listings-body').innerHTML = listings.length ? listings.map(lot => {
      const count = offers.filter(offer => offer.lotId === lot.id).length;
      const isClosed = Boolean((market.overrides && market.overrides[lot.id] && market.overrides[lot.id].closedAt) || (lot.closeDate && Date.now() >= new Date(lot.closeDate).getTime()));
      return `<tr><td>${safe(lot.title)}</td><td>${safe(lot.seller)}</td><td>${safe(lot.location)}</td><td>${count}</td><td>${isClosed ? 'Cerrada' : 'Abierta'}</td></tr>`;
    }).join('') : '<tr><td colspan="5">No hay publicaciones de usuarios en este navegador.</td></tr>';

    $('#user-activity-body').innerHTML = users.length ? users.map(user => {
      const id = String(user.id || user.email || '');
      const userListings = listings.filter(lot => String(lot.sellerUserId || '') === id).length;
      const userOffers = offers.filter(offer => String(offer.userId || offer.bidderId || '') === id);
      const userReviews = reviews.filter(review => String(review.reviewerId) === id || String(review.revieweeId) === id).length;
      const contact = `${user.firstName || ''} ${user.lastName || ''}`.trim();
      const name = user.publicName || (user.username ? '@' + user.username : '') || user.businessName || contact;
      return `<tr><td>${safe(name)}</td><td>${safe(user.role || '')}</td><td>${userListings}</td><td>${userOffers.length}</td><td>${userOffers.filter(offer => Number(offer.tokensUsed) > 0).length}</td><td>${userReviews}</td></tr>`;
    }).join('') : '<tr><td colspan="6">No hay usuarios registrados.</td></tr>';

    const messages = Object.values(market.messages || {}).flat().filter(message => message && typeof message.text === 'string');
    const themes = [
      ['Pago', ['pago','pagar','pagaron','dinero','precio','fraude']],
      ['Entrega y transporte', ['entrega','entregar','transporte','envio','recogida','logistica']],
      ['Calidad y peso', ['calidad','peso','kilo','cantidad','foto','producto']],
      ['Precio y negociación', ['precio','oferta','regateo','negociar','acuerdo']],
      ['Confianza y soporte', ['estafa','fraude','incumplio','reclamo','ayuda','soporte']]
    ];
    const counts = themes.map(([name, terms]) => ({name, count:messages.filter(message => terms.some(term => normalized(message.text).includes(term))).length}));
    $('#chat-keyword-insights').innerHTML = counts.map(item => `<span class="filter-tab" style="cursor:default">${safe(item.name)} <b>${item.count}</b></span>`).join('') || '<small>Aún no hay mensajes registrados.</small>';

    $('#admin-reviews-body').innerHTML = reviews.length ? reviews.slice().reverse().map(review => `<tr><td>${safe(date(review.createdAt))}</td><td>${safe(review.lotTitle)}</td><td>${safe(review.reviewerRole)}</td><td>${'★'.repeat(Number(review.score)||0)}${'☆'.repeat(5-(Number(review.score)||0))}</td><td>${safe([review.criteriaSummary, review.comment].filter(Boolean).join(' · '))}</td></tr>`).join('') : '<tr><td colspan="5">Aún no hay calificaciones.</td></tr>';

    $('#identity-review-body').innerHTML = users.length ? users.map(user => `<tr><td>${safe(user.publicName || (user.username ? '@' + user.username : '') || user.businessName || `${user.firstName || ''} ${user.lastName || ''}`.trim())}<br><small>${safe(user.accountType === 'negocio' ? 'Negocio u organización' : 'Cuenta personal')} · Contacto: ${safe(`${user.firstName || ''} ${user.lastName || ''}`.trim())} · ID ${safe(user.id || '')}</small></td><td>${safe(user.idNumber || 'Sin cédula')}</td><td>${safe(user.identityStatus || 'Pendiente revisión manual')}</td><td>${user.identityStatus === 'verificada_manual' ? '<span>Revisada manualmente</span>' : `<button class="btn btn-secondary" data-identity-verify="${safe(user.id)}" ${user.idNumber ? '' : 'disabled'}>Marcar revisada</button>`}</td></tr>`).join('') : '<tr><td colspan="4">No hay usuarios registrados.</td></tr>';

    $('#moderation-cases-body').innerHTML = cases.length ? cases.slice().reverse().map(item => {
      const target = users.find(user => String(user.id || user.email) === String(item.targetId));
      const status = item.status || 'pendiente_revision';
      const actionable = status === 'pendiente_revision';
      return `<tr><td>${safe(date(item.createdAt))}</td><td>${safe(target ? `${target.firstName || ''} ${target.lastName || ''}`.trim() : item.targetId)}<br><small>Cédula: ${safe(target && target.idNumber || 'no registrada')}</small></td><td>${safe(item.reason)}</td><td>${safe(item.comment || '')}</td><td>${safe(status)}</td><td>${actionable ? `<button class="btn btn-secondary" data-case-dismiss="${safe(item.id)}">Cerrar sin bloqueo</button><br><label><input type="checkbox" data-case-evidence="${safe(item.id)}"> Evidencia solicitada y revisada</label> <button class="btn btn-primary" data-case-block="${safe(item.id)}" disabled>Confirmar y bloquear cédula</button>` : 'Revisado'}</td></tr>`;
    }).join('') : '<tr><td colspan="6">No hay reportes graves pendientes.</td></tr>';
  }
  function saveMarket(market) { localStorage.setItem(KEY, JSON.stringify(market)); }
  document.addEventListener('click', (event) => {
    const verify = event.target.closest('[data-identity-verify]');
    if (verify) {
      const users = read('subscribers', []), user = users.find(item => String(item.id) === String(verify.dataset.identityVerify));
      if (!user || !user.idNumber) return;
      user.identityStatus = 'verificada_manual'; user.identityReviewedAt = new Date().toISOString();
      localStorage.setItem('subscribers', JSON.stringify(users)); render(); return;
    }
    const dismiss = event.target.closest('[data-case-dismiss]');
    const block = event.target.closest('[data-case-block]');
    if (!dismiss && !block) return;
    const market = read(KEY, {}), users = read('subscribers', []), item = (market.moderationCases || []).find(entry => String(entry.id) === String((dismiss || block).dataset.caseDismiss || (dismiss || block).dataset.caseBlock));
    if (!item) return;
    const user = users.find(entry => String(entry.id || entry.email) === String(item.targetId));
    if (block) {
      if (!block.closest('tr')?.querySelector('[data-case-evidence]')?.checked) return;
      if (!user || !user.idNumber) return;
      user.accountStatus = 'bloqueada_revision_admin';
      const list = Array.isArray(market.idBlocklist) ? market.idBlocklist : [];
      const normalizedId = String(user.idNumber).replace(/\D/g, '');
      if (!list.some(value => String(value).replace(/\D/g, '') === normalizedId)) list.push(normalizedId);
      market.idBlocklist = list; item.status = 'bloqueo_por_revision_admin';
    } else {
      if (user && user.accountStatus === 'suspendida_revision') user.accountStatus = 'activa';
      item.status = 'cerrado_sin_bloqueo';
    }
    item.reviewedAt = new Date().toISOString();
    localStorage.setItem('subscribers', JSON.stringify(users)); saveMarket(market); render();
  });
  document.addEventListener('change', event => {
    const evidence = event.target.closest('[data-case-evidence]');
    if (!evidence) return;
    const block = evidence.closest('tr')?.querySelector('[data-case-block]');
    if (block) block.disabled = !evidence.checked;
  });
  $('#refresh-insights')?.addEventListener('click', render);
  window.addEventListener('storage', event => { if (!event.key || ['subscribers', KEY].includes(event.key)) render(); });
  window.addEventListener('focus', render);
  render();
})();
