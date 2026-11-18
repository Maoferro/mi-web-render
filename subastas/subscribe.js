(function(){
  const subscribeBtn = document.getElementById('subscribe-btn');
  const logoutBtn = document.getElementById('logout-btn');
  const modal = document.getElementById('subscribe-modal');
  const form = document.getElementById('subscribe-form');
  const toast = document.getElementById('toast');
  let toastTimer;

  function showToast(message) {
    toast.textContent = message;
    toast.classList.add('show');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => toast.classList.remove('show'), 3400);
  }

  function updateUI() {
    const isSubscribed = localStorage.getItem('isSubscribed') === 'true';
    if (isSubscribed) {
      subscribeBtn.classList.add('hidden');
      logoutBtn.classList.remove('hidden');
    } else {
      subscribeBtn.classList.remove('hidden');
      logoutBtn.classList.add('hidden');
    }
  }

  // Open subscription modal
  subscribeBtn.addEventListener('click', e => {
    e.preventDefault();
    modal.showModal();
  });

  // Handle form submission
  form.addEventListener('submit', e => {
    e.preventDefault();
    const data = new FormData(form);
    const subscriber = {
      id: Date.now(),
      firstName: (data.get('firstName') || '').trim(),
      lastName: (data.get('lastName') || '').trim(),
      idNumber: (data.get('idNumber') || '').trim(),
      phone: (data.get('phone') || '').trim(),
      email: (data.get('email') || '').trim(),
      role: data.get('role'),
      timestamp: new Date().toISOString()
    };
    let list = [];
    try { list = JSON.parse(localStorage.getItem('subscribers') || '[]'); } catch (_) { list = []; }
    list.push(subscriber);
    localStorage.setItem('subscribers', JSON.stringify(list));
    localStorage.setItem('isSubscribed', 'true');
    modal.close();
    form.reset();
    updateUI();
    showToast('Cuenta creada. ¡Bienvenido!');
  });

  // Logout handling
  logoutBtn.addEventListener('click', () => {
    localStorage.removeItem('isSubscribed');
    updateUI();
    showToast('Sesión cerrada.');
  });

// Initialise UI state on load
updateUI();
const isSubscribed = localStorage.getItem('isSubscribed') === 'true';
if (!isSubscribed) {
  modal.showModal();
}
})();
