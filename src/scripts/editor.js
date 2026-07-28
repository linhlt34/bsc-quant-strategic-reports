const STORAGE_KEY = 'bsc_report_state_' + ##DOC_CODE##;
let isEditing = false;
let saveTimer = null;

function editableElements() {
  return document.querySelectorAll('[data-edit]');
}

function toggleEdit() {
  isEditing = !isEditing;
  document.body.classList.toggle('editing-on', isEditing);
  const toggleButton = document.getElementById('btn-toggle-edit');
  const saveButton = document.getElementById('btn-save');
  const resetButton = document.getElementById('btn-reset');

  editableElements().forEach((element) => {
    if (isEditing) {
      element.setAttribute('contenteditable', 'true');
      element.setAttribute('spellcheck', 'false');
      element.addEventListener('input', scheduleSave);
    } else {
      element.removeAttribute('contenteditable');
      element.removeEventListener('input', scheduleSave);
    }
  });

  toggleButton.textContent = isEditing ? 'Hoàn tất' : 'Chỉnh sửa';
  toggleButton.classList.toggle('active', isEditing);
  saveButton.hidden = !isEditing;
  resetButton.hidden = !isEditing;
  setStatus(isEditing ? 'Đang chỉnh sửa' : '');
  if (!isEditing) saveState();
}

function scheduleSave() {
  clearTimeout(saveTimer);
  saveTimer = setTimeout(() => saveState(true), 800);
}

function saveState(silent = false) {
  const state = {};
  editableElements().forEach((element, index) => {
    state[`el_${index}`] = element.innerHTML;
  });
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    const time = new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
    setStatus(silent ? `Tự động lưu ${time}` : `Đã lưu lúc ${time}`);
  } catch (error) {
    setStatus('Không thể lưu trên trình duyệt');
  }
}

function resetState() {
  if (!window.confirm('Đặt lại về dữ liệu gốc?')) return;
  localStorage.removeItem(STORAGE_KEY);
  window.location.reload();
}

function setStatus(message) {
  const status = document.getElementById('editor-status');
  if (status) status.textContent = message;
}

function restoreState() {
  try {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) return;
    const state = JSON.parse(saved);
    editableElements().forEach((element, index) => {
      const key = `el_${index}`;
      if (state[key] !== undefined) element.innerHTML = state[key];
    });
    setStatus('Đã khôi phục bản lưu');
  } catch (error) {
    console.warn('Restore failed', error);
  }
}

document.addEventListener('DOMContentLoaded', restoreState);
