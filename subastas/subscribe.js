(function() {
  const authScreen = document.getElementById('auth-screen');
  const appContent = document.getElementById('app-content');
  const toast = document.getElementById('toast');
  const logoutBtn = document.getElementById('logout-btn');
  const modalLogoutBtn = document.getElementById('modal-logout-btn');

  const tabLoginBtn = document.getElementById('tab-login-btn');
  const tabRegisterBtn = document.getElementById('tab-register-btn');
  const loginForm = document.getElementById('login-form');
  const registerForm = document.getElementById('register-form');
  const forgotPasswordLink = document.getElementById('forgot-password-link');

  const googleAuthBtn = document.getElementById('google-auth-btn');
  const googleAuthBtnReg = document.getElementById('google-auth-btn-reg');
  const googleModal = document.getElementById('google-modal');
  const googleQuickAccount = document.getElementById('google-quick-account');
  const googleCancelBtn = document.getElementById('google-cancel-btn');

  const profileDialog = document.getElementById('profile-dialog');
  const profileForm = document.getElementById('profile-form');

  let toastTimer;

  async function encodeProfilePhoto(file) {
    if (!file) return '';
    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type) || file.size > 5 * 1024 * 1024) {
      throw new Error('La foto debe ser JPG, PNG o WebP y pesar máximo 5 MB.');
    }
    const bitmap = await createImageBitmap(file);
    const side = Math.min(bitmap.width, bitmap.height);
    const sx = Math.round((bitmap.width - side) / 2);
    const sy = Math.round((bitmap.height - side) / 2);
    const canvas = document.createElement('canvas');
    canvas.width = 256; canvas.height = 256;
    canvas.getContext('2d').drawImage(bitmap, sx, sy, side, side, 0, 0, 256, 256);
    bitmap.close();
    return canvas.toDataURL('image/jpeg', 0.78);
  }

  function attachPhotoPreview(inputId, previewId) {
    const input = document.getElementById(inputId), preview = document.getElementById(previewId);
    if (!input || !preview) return;
    input.addEventListener('change', () => {
      if (preview.dataset.objectUrl) URL.revokeObjectURL(preview.dataset.objectUrl);
      const file = input.files && input.files[0];
      if (!file) { preview.hidden = true; preview.removeAttribute('src'); delete preview.dataset.objectUrl; return; }
      if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type) || file.size > 5 * 1024 * 1024) {
        input.value = ''; preview.hidden = true; showToast('La foto debe ser JPG, PNG o WebP y pesar máximo 5 MB.'); return;
      }
      const url = URL.createObjectURL(file); preview.dataset.objectUrl = url; preview.src = url; preview.hidden = false;
    });
  }

  attachPhotoPreview('reg-profile-photo', 'reg-profile-photo-preview');
  const accountTypeInput = document.getElementById('reg-account-type');
  const businessNameField = document.getElementById('reg-business-name-field');
  const businessNameInput = document.getElementById('reg-business-name');
  function syncRegistrationType(){const business=accountTypeInput?.value==='negocio';if(businessNameField)businessNameField.classList.toggle('hidden',!business);if(businessNameInput){businessNameInput.required=Boolean(business);if(!business)businessNameInput.value='';}}
  if(accountTypeInput){accountTypeInput.addEventListener('change',syncRegistrationType);syncRegistrationType();}
  attachPhotoPreview('profile-photo-input', 'profile-photo-preview');

  function setAvatar(element, name, photo) {
    if (!element) return;
    const initial = (name || 'U').trim().charAt(0).toUpperCase();
    element.replaceChildren();
    if (photo) {
      const img = document.createElement('img'); img.src = photo; img.alt = 'Foto de perfil';
      element.appendChild(img); element.classList.add('has-profile-photo');
    } else {
      element.textContent = initial; element.classList.remove('has-profile-photo');
    }
  }

  function showToast(message) {
    if (!toast) return;
    toast.textContent = message;
    toast.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove('show'), 3600);
  }

  // Obtiene los datos del usuario actual activo
  function getCurrentUser() {
    try {
      const saved = localStorage.getItem('currentUser');
      if (saved) return JSON.parse(saved);
      const list = JSON.parse(localStorage.getItem('subscribers') || '[]');
      if (list.length > 0) return list[list.length - 1];
    } catch (_) {}
    return {
      id: 101,
      firstName: 'Mauricio',
      lastName: 'Rodríguez',
      idNumber: '1018273645',
      phone: '3104567890',
      email: 'mauricio.rodriguez@gmail.com',
      role: 'comprador',
      timestamp: new Date().toISOString()
    };
  }

  function setCurrentUser(user) {
    try { localStorage.setItem('currentUser', JSON.stringify(user)); } catch (_) {}
  }

  function saveSubscriberRecord(user) {
    let list = [];
    try { list = JSON.parse(localStorage.getItem('subscribers') || '[]'); } catch (_) {}
    const index = list.findIndex(s => (user.id && s.id === user.id) || (user.email && s.email && s.email.toLowerCase() === user.email.toLowerCase()));
    if (index >= 0) list[index] = { ...list[index], ...user }; else list.push(user);
    try { localStorage.setItem('subscribers', JSON.stringify(list)); } catch (_) {}
  }

  function emitDomainEvent(type, payload) {
    window.dispatchEvent(new CustomEvent('subastas:domain-event', { detail: { eventId: 'evt-' + Date.now(), type, occurredAt: new Date().toISOString(), payload } }));
  }

  function ensureCourtesyWallet(user) {
    if (!user) return user;
    user.identityStatus = user.identityStatus || 'pendiente_revision_manual';
    user.accountStatus = user.accountStatus || 'activa';
    if (user.role === 'vendedor') {
      if (!Number.isFinite(Number(user.tokenBalance))) user.tokenBalance = 0;
      user.freeTokensGranted = Number(user.freeTokensGranted) || 0;
      user.welcomeTokensGranted = true;
      user.tokenHistory = Array.isArray(user.tokenHistory) ? user.tokenHistory : [];
      return user;
    }
    if (!user.welcomeTokensGranted) {
      const now = new Date().toISOString();
      user.tokenBalance = 10;
      user.freeTokensGranted = 10;
      user.welcomeTokensGranted = true;
      user.tokenHistory = [{ change: 10, label: '10 tokens de cortesía por inscripción', at: now }].concat(Array.isArray(user.tokenHistory) ? user.tokenHistory : []);
    } else {
      user.tokenBalance = Math.max(0, Number(user.tokenBalance) || 0);
      user.freeTokensGranted = Number(user.freeTokensGranted) || 0;
      user.tokenHistory = Array.isArray(user.tokenHistory) ? user.tokenHistory : [];
    }
    return user;
  }

  // Sincroniza datos del usuario con el mercado y la cabecera
  function syncUserProfile(name, roleLabel, extraData) {
    try {
      const KEY = 'subastas-del-campo-market-v1';
      let marketState = {};
      try {
        marketState = JSON.parse(localStorage.getItem(KEY) || '{}');
      } catch (e) {
        marketState = {};
      }
      const activeUser = ensureCourtesyWallet(extraData || getCurrentUser());
      const displayName = activeUser.publicName || activeUser.username || activeUser.businessName || name || 'Usuario';
      setCurrentUser(activeUser);
      saveSubscriberRecord(activeUser);
      const activeUserId = String(activeUser.id || activeUser.email || 'demo-user');
      marketState.profile = { name: displayName, role: roleLabel || 'Comprador (demo)', userId: activeUserId, profilePhoto: activeUser.profilePhoto || '' };
      marketState.activeUserId = activeUserId;
      marketState.accountRole = activeUser.role || 'comprador';
      marketState.tokens = activeUser.role === 'vendedor' ? 0 : Number(activeUser.tokenBalance) || 0;
      marketState.tokenHistory = Array.isArray(activeUser.tokenHistory) ? activeUser.tokenHistory : [];
      localStorage.setItem(KEY, JSON.stringify(marketState));
      window.dispatchEvent(new Event('subastas:account-changed'));

      // Actualizar UI en la barra lateral y header
      const nameEl = document.getElementById('profile-name');
      const roleEl = document.getElementById('profile-role');
      const initialEl = document.getElementById('profile-initial');
      const headerInitialEl = document.getElementById('profile-open-header');

      if (nameEl) nameEl.textContent = displayName;
      if (roleEl) roleEl.textContent = roleLabel;
      const initialChar = (name || 'U').trim().charAt(0).toUpperCase();
      if (initialEl) setAvatar(initialEl, displayName, extraData && extraData.profilePhoto);
      if (headerInitialEl) setAvatar(headerInitialEl, displayName, extraData && extraData.profilePhoto);

      // Actualizar UI en el modal de perfil
      const modalName = document.getElementById('modal-profile-name');
      const modalAvatar = document.getElementById('modal-profile-avatar');
      const modalBadge = document.getElementById('modal-profile-role-badge');

      if (modalName) modalName.textContent = displayName;
      if (modalAvatar) setAvatar(modalAvatar, displayName, extraData && extraData.profilePhoto);
      if (modalBadge) {
        const isSeller = roleLabel.toLowerCase().includes('vendedor');
        modalBadge.textContent = roleLabel;
        modalBadge.className = 'role-badge ' + (isSeller ? 'seller' : 'buyer');
      }
    } catch (err) {
      console.warn('Error al sincronizar perfil:', err);
    }
  }

  // Actualiza los valores de todos los campos del modal cuando se abre
  function refreshProfileModal() {
    const user = getCurrentUser();
    const fullName = `${user.firstName || ''} ${user.lastName || ''}`.trim() || user.name || 'Usuario';
    const isSeller = (user.role || '').toLowerCase().includes('vendedor');
    const roleLabel = isSeller ? 'Vendedor agrícola' : 'Comprador de cosechas';

    syncUserProfile(fullName, roleLabel, user);

    const fnInput = document.getElementById('profile-firstname-input');
    const lnInput = document.getElementById('profile-lastname-input');
    const idInput = document.getElementById('profile-id-input');
    const phInput = document.getElementById('profile-phone-input');
    const emInput = document.getElementById('profile-email-input');
    const roleInput = document.getElementById('profile-role-input');

    if (fnInput) fnInput.value = user.firstName || '';
    if (lnInput) lnInput.value = user.lastName || '';
    if (idInput) idInput.value = user.idNumber || '';
    if (phInput) phInput.value = user.phone || '';
    if (emInput) emInput.value = user.email || '';
    if (roleInput) roleInput.value = isSeller ? 'vendedor' : 'comprador';
    const photoInput = document.getElementById('profile-photo-input');
    const photoPreview = document.getElementById('profile-photo-preview');
    if (photoInput) photoInput.value = '';
    if (photoPreview) { photoPreview.src = user.profilePhoto || ''; photoPreview.hidden = !user.profilePhoto; }
  }

  // Exponer para llamada global desde barra de navegación u otros scripts
  window.refreshProfileModal = refreshProfileModal;

  // Interceptar la apertura de perfil para actualizar datos
  const profileOpenBtn = document.getElementById('profile-open');
  const profileOpenHeader = document.getElementById('profile-open-header');
  if (profileOpenBtn) profileOpenBtn.addEventListener('click', refreshProfileModal);
  if (profileOpenHeader) profileOpenHeader.addEventListener('click', refreshProfileModal);

  // Controla la visibilidad entre la portada de bienvenida y la app completa
  function setAuthenticated(isAuthenticated) {
    if (isAuthenticated) {
      if (authScreen) authScreen.classList.add('hidden');
      if (appContent) appContent.classList.remove('hidden');
      if (logoutBtn) logoutBtn.classList.remove('hidden');
      refreshProfileModal();
    } else {
      if (authScreen) authScreen.classList.remove('hidden');
      if (appContent) appContent.classList.add('hidden');
      if (logoutBtn) logoutBtn.classList.add('hidden');
    }
  }

  // Segmented control: Iniciar Sesión / Registrarse
  function showLoginTab() {
    if (tabLoginBtn) {
      tabLoginBtn.classList.add('active');
      tabLoginBtn.setAttribute('aria-selected', 'true');
    }
    if (tabRegisterBtn) {
      tabRegisterBtn.classList.remove('active');
      tabRegisterBtn.setAttribute('aria-selected', 'false');
    }
    if (loginForm) loginForm.classList.remove('hidden');
    if (registerForm) registerForm.classList.add('hidden');
  }

  function showRegisterTab() {
    if (tabRegisterBtn) {
      tabRegisterBtn.classList.add('active');
      tabRegisterBtn.setAttribute('aria-selected', 'true');
    }
    if (tabLoginBtn) {
      tabLoginBtn.classList.remove('active');
      tabLoginBtn.setAttribute('aria-selected', 'false');
    }
    if (registerForm) registerForm.classList.remove('hidden');
    if (loginForm) loginForm.classList.add('hidden');
  }

  if (tabLoginBtn) tabLoginBtn.addEventListener('click', showLoginTab);
  if (tabRegisterBtn) tabRegisterBtn.addEventListener('click', showRegisterTab);

  if (forgotPasswordLink) {
    forgotPasswordLink.addEventListener('click', e => {
      e.preventDefault();
      showToast('Se envió un enlace de recuperación a tu correo registrado (demo).');
    });
  }

  // Manejo de envío en Login
  if (loginForm) {
    loginForm.addEventListener('submit', e => {
      e.preventDefault();
      const email = (document.getElementById('login-email').value || '').trim();
      let subscribers = [];
      try {
        subscribers = JSON.parse(localStorage.getItem('subscribers') || '[]');
      } catch (_) {
        subscribers = [];
      }

      // Buscar si el usuario ya existe en suscriptores
      let user = subscribers.find(s => s.email && s.email.toLowerCase() === email.toLowerCase());

      if (!user) {
        let displayName = 'Usuario';
        if (email.includes('@')) {
          displayName = email.split('@')[0];
          displayName = displayName.charAt(0).toUpperCase() + displayName.slice(1);
        } else if (email) {
          displayName = 'Usuario ' + email.slice(-4);
        }

        user = {
          id: Date.now(),
          firstName: displayName,
          lastName: '',
          email: email,
          phone: '3001234567',
          idNumber: '1012345678',
          role: 'comprador',
          tokenBalance: 10, freeTokensGranted: 10, welcomeTokensGranted: true,
          tokenHistory: [{ change: 10, label: '10 tokens de cortesía por inscripción', at: new Date().toISOString() }],
          timestamp: new Date().toISOString()
        };
        subscribers.push(user);
        localStorage.setItem('subscribers', JSON.stringify(subscribers));
      }

      if (user.accountStatus === 'suspendida_revision' || user.accountStatus === 'bloqueada_revision_admin') { showToast('Esta cuenta está suspendida o bloqueada mientras se revisa un caso.'); return; }
      user = ensureCourtesyWallet(user);
      saveSubscriberRecord(user);
      setCurrentUser(user);
      localStorage.setItem('isSubscribed', 'true');
      const fullName = `${user.firstName || ''} ${user.lastName || ''}`.trim() || user.firstName || 'Usuario';
      const roleLabel = user.role === 'vendedor' ? 'Vendedor agrícola' : 'Comprador de cosechas';
      syncUserProfile(fullName, roleLabel, user);
      setAuthenticated(true);
      showToast('¡Bienvenido de nuevo, ' + fullName + '!');
      loginForm.reset();
    });
  }

  // Manejo de envío en Registro
  if (registerForm) {
    registerForm.addEventListener('submit', async e => {
      e.preventDefault();
      const formData = new FormData(registerForm);
      const firstName = (formData.get('firstName') || '').trim();
      const lastName = (formData.get('lastName') || '').trim();
      const fullName = (firstName + ' ' + lastName).trim() || 'Nuevo Usuario';
      const accountType = formData.get('accountType') === 'negocio' ? 'negocio' : 'personal';
      const businessName = (formData.get('businessName') || '').trim();
      const username = (formData.get('username') || '').trim().replace(/^@/, '');
      const publicName = accountType === 'negocio' ? businessName : (username ? '@' + username : fullName);
      const roleVal = formData.get('role');
      const idNumber = (formData.get('idNumber') || '').trim();
      let marketData = {}; try { marketData = JSON.parse(localStorage.getItem('subastas-del-campo-market-v1') || '{}'); } catch (_) {}
      const normalizedIdNumber = idNumber.replace(/\D/g, '');
      if (Array.isArray(marketData.idBlocklist) && marketData.idBlocklist.some(blockedId => String(blockedId).replace(/\D/g, '') === normalizedIdNumber)) { showToast('No es posible crear una cuenta con este documento. Contacta a soporte para revisar el caso.'); return; }
      if (username) { let existing=[]; try { existing=JSON.parse(localStorage.getItem('subscribers')||'[]'); } catch (_) {} if (existing.some(user=>String(user.username||'').toLowerCase()===username.toLowerCase())) { showToast('Ese nombre de usuario ya está ocupado. Elige otro.'); return; } }
      if (accountType === 'negocio' && !businessName) { showToast('Escribe el nombre del negocio u organización.'); return; }
      const roleLabel = roleVal === 'vendedor' ? 'Vendedor agrícola' : 'Comprador de cosechas';
      let profilePhoto = '';
      try { profilePhoto = await encodeProfilePhoto(document.getElementById('reg-profile-photo')?.files?.[0]); }
      catch (error) { showToast(error.message); return; }

      const subscriber = {
        id: Date.now(),
        firstName: firstName,
        lastName: lastName,
        accountType: accountType,
        businessName: businessName,
        username: username,
        publicName: publicName,
        idNumber: idNumber,
        phone: (formData.get('phone') || '').trim(),
        email: (formData.get('email') || '').trim(),
        role: roleVal,
        identityStatus: 'pendiente_revision_manual',
        profilePhoto: profilePhoto,
        tokenBalance: roleVal === 'comprador' ? 10 : 0,
        freeTokensGranted: roleVal === 'comprador' ? 10 : 0,
        welcomeTokensGranted: true,
        tokenHistory: roleVal === 'comprador' ? [{ change: 10, label: '10 tokens de cortesía por inscripción', at: new Date().toISOString() }] : [],
        timestamp: new Date().toISOString()
      };

      let list = [];
      try {
        list = JSON.parse(localStorage.getItem('subscribers') || '[]');
      } catch (_) {
        list = [];
      }
      list.push(subscriber);
      localStorage.setItem('subscribers', JSON.stringify(list));
      emitDomainEvent('user.registered', { userId: subscriber.id, role: subscriber.role });
      localStorage.setItem('isSubscribed', 'true');
      setCurrentUser(subscriber);

      syncUserProfile(publicName, roleLabel, subscriber);
      setAuthenticated(true);
      showToast('¡Cuenta creada con éxito! Bienvenido a Subastas del Campo.');
      registerForm.reset();
      syncRegistrationType();
    });
  }

  // Manejo de Google Auth
  function openGoogleModal() {
    if (googleModal) googleModal.showModal();
  }

  if (googleAuthBtn) googleAuthBtn.addEventListener('click', openGoogleModal);
  if (googleAuthBtnReg) googleAuthBtnReg.addEventListener('click', openGoogleModal);

  if (googleCancelBtn && googleModal) {
    googleCancelBtn.addEventListener('click', () => {
      googleModal.close();
    });
  }

  if (googleQuickAccount && googleModal) {
    googleQuickAccount.addEventListener('click', () => {
      googleModal.close();
      const googleUser = {
        id: 101,
        firstName: 'Mauricio',
        lastName: 'Rodríguez',
        email: 'mauricio.rodriguez@gmail.com',
        phone: '3104567890',
        idNumber: '1018273645',
        role: 'comprador',
        identityStatus: 'pendiente_revision_manual',
        accountStatus: 'activa',
        timestamp: new Date().toISOString()
      };

      let list = [];
      try { list = JSON.parse(localStorage.getItem('subscribers') || '[]'); } catch (_) { list = []; }
      const existingIdx = list.findIndex(s => s.id === googleUser.id || (s.email && s.email.toLowerCase() === googleUser.email.toLowerCase()));
      if (existingIdx === -1) {
        list.push(googleUser);
        emitDomainEvent('user.registered', { userId: googleUser.id, role: googleUser.role, provider: 'demo-google' });
      }
      const storedGoogleUser = existingIdx >= 0 ? { ...googleUser, ...list[existingIdx] } : googleUser;
      const readyGoogleUser = ensureCourtesyWallet(storedGoogleUser);
      if (readyGoogleUser.accountStatus === 'suspendida_revision' || readyGoogleUser.accountStatus === 'bloqueada_revision_admin') {
        showToast('Esta cuenta está suspendida o bloqueada mientras se revisa un caso.');
        return;
      }
      saveSubscriberRecord(readyGoogleUser);
      localStorage.setItem('isSubscribed', 'true');
      setCurrentUser(readyGoogleUser);

      syncUserProfile('Mauricio Rodríguez', 'Comprador de cosechas', readyGoogleUser);
      setAuthenticated(true);
      showToast('¡Acceso concedido con Google! Bienvenido, Mauricio Rodríguez.');
    });
  }

  // Manejo de Cerrar Sesión (desde sidebar o desde modal de perfil)
  function handleLogout() {
    localStorage.removeItem('isSubscribed');
    if (profileDialog && profileDialog.open) profileDialog.close();
    setAuthenticated(false);
    showToast('Has cerrado la sesión.');
  }

  if (logoutBtn) logoutBtn.addEventListener('click', handleLogout);
  if (modalLogoutBtn) modalLogoutBtn.addEventListener('click', handleLogout);

  // Guardar cambios desde el modal de perfil y sincronizarlos con la administración
  if (profileForm) {
    profileForm.addEventListener('submit', async e => {
      e.preventDefault();

      const firstName = (document.getElementById('profile-firstname-input')?.value || '').trim();
      const lastName = (document.getElementById('profile-lastname-input')?.value || '').trim();
      const idNumber = (document.getElementById('profile-id-input')?.value || '').trim();
      const phone = (document.getElementById('profile-phone-input')?.value || '').trim();
      const email = (document.getElementById('profile-email-input')?.value || '').trim();
      const roleVal = document.getElementById('profile-role-input')?.value || 'comprador';

      if (!firstName) {
        showToast('El nombre es obligatorio.');
        return;
      }

      const prevUser = getCurrentUser();
      let profilePhoto = prevUser.profilePhoto || '';
      try { const selectedPhoto = document.getElementById('profile-photo-input')?.files?.[0]; if (selectedPhoto) profilePhoto = await encodeProfilePhoto(selectedPhoto); }
      catch (error) { showToast(error.message); return; }
      const userId = prevUser.id || Date.now();
      const createdAt = prevUser.timestamp || new Date().toISOString();
      const updatedAt = new Date().toISOString();

      const updatedUser = {
        id: userId,
        firstName: firstName,
        lastName: lastName,
        idNumber: idNumber || prevUser.idNumber || '',
        phone: phone || prevUser.phone || '',
        email: email || prevUser.email || '',
        role: roleVal,
        identityStatus: prevUser.identityStatus || 'pendiente_revision_manual',
        accountStatus: prevUser.accountStatus || 'activa',
        profilePhoto: profilePhoto,
        tokenBalance: roleVal === 'vendedor' ? 0 : Number(prevUser.tokenBalance) || 0,
        freeTokensGranted: Number(prevUser.freeTokensGranted) || 0,
        welcomeTokensGranted: Boolean(prevUser.welcomeTokensGranted),
        tokenHistory: Array.isArray(prevUser.tokenHistory) ? prevUser.tokenHistory : [],
        timestamp: createdAt,
        updatedAt: updatedAt
      };

      // 1. Guardar usuario actual
      setCurrentUser(updatedUser);

      // 2. Sincronizar en la lista de suscriptores (localStorage 'subscribers') que lee admin.html
      let list = [];
      try {
        list = JSON.parse(localStorage.getItem('subscribers') || '[]');
      } catch (_) {
        list = [];
      }

      let targetIndex = list.findIndex(s => s.id && s.id === userId);
      if (targetIndex === -1 && prevUser.email) {
        targetIndex = list.findIndex(s => s.email && s.email.toLowerCase() === prevUser.email.toLowerCase());
      }
      if (targetIndex === -1 && prevUser.idNumber) {
        targetIndex = list.findIndex(s => s.idNumber && s.idNumber === prevUser.idNumber);
      }

      if (targetIndex !== -1) {
        list[targetIndex] = {
          ...list[targetIndex],
          ...updatedUser,
          id: list[targetIndex].id || userId,
          timestamp: list[targetIndex].timestamp || createdAt,
          updatedAt: updatedAt
        };
      } else {
        list.push(updatedUser);
      }

      localStorage.setItem('subscribers', JSON.stringify(list));

      // 3. Sincronizar UI de la aplicación
      const fullName = `${firstName} ${lastName}`.trim() || 'Usuario';
      const roleLabel = roleVal === 'vendedor' ? 'Vendedor agrícola' : 'Comprador de cosechas';
      syncUserProfile(fullName, roleLabel, updatedUser);

      // 4. Notificar evento a otras pestañas/páginas (como admin.html)
      try {
        window.dispatchEvent(new Event('storage'));
      } catch (_) {}

      if (profileDialog) profileDialog.close();
      showToast('✅ Tus datos se han actualizado y sincronizado con el panel de administración.');
    });
  }

  // Vinculación de la barra de navegación inferior móvil
  const mobilePublishBtn = document.getElementById('mobile-bottom-publish');
  if (mobilePublishBtn) {
    mobilePublishBtn.addEventListener('click', () => {
      const pubDialog = document.getElementById('publish-dialog');
      if (pubDialog) pubDialog.showModal();
    });
  }

  const mobileProfileBtn = document.getElementById('mobile-bottom-profile');
  if (mobileProfileBtn) {
    mobileProfileBtn.addEventListener('click', () => {
      refreshProfileModal();
      if (profileDialog) profileDialog.showModal();
    });
  }

  // Sincronizar estado activo en la barra inferior móvil
  document.querySelectorAll('.bnav-btn[data-view]').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.bnav-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });

  // Comprobar estado inicial
  const isSubscribed = localStorage.getItem('isSubscribed') === 'true';
  setAuthenticated(isSubscribed);

  if (isSubscribed) {
    refreshProfileModal();
  }
})();
