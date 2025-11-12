const extensionApi = typeof browser !== 'undefined' ? browser : chrome;
const MENU_ID = 'addon-manager-toggle-all';
const STORAGE_KEY = 'addonManagerLastDisabled';
const DISABLE_TITLE = 'Disable all active extensions';
const MENU_CONTEXTS = ['action'];

function getStoredIds() {
  return new Promise((resolve) => {
    extensionApi.storage.local.get(STORAGE_KEY, (result) => {
      resolve(result[STORAGE_KEY] || []);
    });
  });
}

function setStoredIds(ids) {
  return new Promise((resolve) => {
    extensionApi.storage.local.set({ [STORAGE_KEY]: ids }, () => resolve(ids));
  });
}

function clearStoredIds() {
  return new Promise((resolve) => {
    extensionApi.storage.local.remove(STORAGE_KEY, () => resolve());
  });
}

function updateMenuTitle() {
  return getStoredIds().then((ids) => {
    const hasIds = Array.isArray(ids) && ids.length > 0;
    const title = hasIds
      ? `Restore ${ids.length} extensions`
      : DISABLE_TITLE;

    extensionApi.contextMenus.update(MENU_ID, { title }, () => {
      // ignore errors when menu isn't ready yet
      void extensionApi.runtime.lastError;
    });
  });
}

function createContextMenu() {
  extensionApi.contextMenus.removeAll(() => {
    void extensionApi.runtime.lastError;
    extensionApi.contextMenus.create(
      {
        id: MENU_ID,
        title: DISABLE_TITLE,
        contexts: MENU_CONTEXTS
      },
      () => {
        void extensionApi.runtime.lastError;
        updateMenuTitle();
      }
    );
  });
}

function toggleExtensions(ids, enabled) {
  if (!ids.length) {
    return Promise.resolve();
  }

  return Promise.all(
    ids.map(
      (id) =>
        new Promise((resolve) => {
          try {
            extensionApi.management.setEnabled(id, enabled, () => {
              void extensionApi.runtime?.lastError;
              resolve();
            });
          } catch (error) {
            resolve();
          }
        })
    )
  );
}

function disableAllActiveExtensions() {
  extensionApi.management.getAll((items) => {
    const targets = items.filter(
      (item) =>
        item.type === 'extension' &&
        item.enabled &&
        item.id !== extensionApi.runtime.id
    );

    const ids = targets.map((item) => item.id);
    toggleExtensions(ids, false).then(() => {
      const storageAction =
        ids.length > 0 ? setStoredIds(ids) : clearStoredIds();
      storageAction.then(updateMenuTitle);
    });
  });
}

function restoreExtensions() {
  getStoredIds().then((ids) => {
    const uniqueIds = [...new Set(ids)];
    toggleExtensions(uniqueIds, true).then(() => {
      clearStoredIds().then(updateMenuTitle);
    });
  });
}

extensionApi.contextMenus.onClicked.addListener((info) => {
  if (info.menuItemId !== MENU_ID) {
    return;
  }

  getStoredIds().then((ids) => {
    if (ids.length) {
      restoreExtensions();
    } else {
      disableAllActiveExtensions();
    }
  });
});

function bootstrap() {
  createContextMenu();
}

extensionApi.runtime.onInstalled.addListener(bootstrap);
extensionApi.runtime.onStartup.addListener(bootstrap);
bootstrap();
