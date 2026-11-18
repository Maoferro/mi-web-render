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
    try {
      localStorage.setItem('currentUser', JSON.stringify(user));
    } catch (_) {}
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
      marketState.profile = {
        name: name || 'Usuario',
        role: roleLabel || 'Comprador (demo)'
      };
      localStorage.setItem(KEY, JSON.stringify(marketState));

      // Actualizar UI en la barra lateral y header
      const nameEl = document.getElementById('profile-name');
      const roleEl = document.getElementById('profile-role');
      const initialEl = document.getElementById('profile-initial');
      const headerInitialEl = document.getElementById('profile-open-header');

      if (nameEl) nameEl.textContent = name;
      if (roleEl) roleEl.textContent = roleLabel;
      const initialChar = (name || 'U').trim().charAt(0).toUpperCase();
      if (initialEl) initialEl.textContent = initialChar;
      if (headerInitialEl) headerInitialEl.textContent = initialChar;

      // Actualizar UI en el modal de perfil
      const modalName = document.getElementById('modal-profile-name');
      const modalAvatar = document.getElementById('modal-profile-avatar');
      const modalBadge = document.getElementById('modal-profile-role-badge');

      if (modalName) modalName.textContent = name;
      if (modalAvatar) modalAvatar.textContent = initialChar;
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
          timestamp: new Date().toISOString()
        };
        subscribers.push(user);
        localStorage.setItem('subscribers', JSON.stringify(subscribers));
      }

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
    registerForm.addEventListener('submit', e => {
      e.preventDefault();
      const formData = new FormData(registerForm);
      const firstName = (formData.get('firstName') || '').trim();
      const lastName = (formData.get('lastName') || '').trim();
      const fullName = (firstName + ' ' + lastName).trim() || 'Nuevo Usuario';
      const roleVal = formData.get('role');
      const roleLabel = roleVal === 'vendedor' ? 'Vendedor agrícola' : 'Comprador de cosechas';

      const subscriber = {
        id: Date.now(),
        firstName: firstName,
        lastName: lastName,
        idNumber: (formData.get('idNumber') || '').trim(),
        phone: (formData.get('phone') || '').trim(),
        email: (formData.get('email') || '').trim(),
        role: roleVal,
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
      localStorage.setItem('isSubscribed', 'true');
      setCurrentUser(subscriber);

      syncUserProfile(fullName, roleLabel, subscriber);
      setAuthenticated(true);
      showToast('¡Cuenta creada con éxito! Bienvenido a Subastas del Campo.');
      registerForm.reset();
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
        timestamp: new Date().toISOString()
      };

      let list = [];
      try { list = JSON.parse(localStorage.getItem('subscribers') || '[]'); } catch (_) { list = []; }
      const existingIdx = list.findIndex(s => s.id === googleUser.id || (s.email && s.email.toLowerCase() === googleUser.email.toLowerCase()));
      if (existingIdx === -1) {
        list.push(googleUser);
      }
      localStorage.setItem('subscribers', JSON.stringify(list));
      localStorage.setItem('isSubscribed', 'true');
      setCurrentUser(googleUser);

      syncUserProfile('Mauricio Rodríguez', 'Comprador de cosechas', googleUser);
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
    profileForm.addEventListener('submit', e => {
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
