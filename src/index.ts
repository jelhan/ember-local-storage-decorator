import { TrackedStorage, DEFAULT_PREFIX } from './TrackedStorage.ts';
const trackedLocalStorage = new TrackedStorage(window.localStorage);
const trackedSessionStorage = new TrackedStorage(window.sessionStorage);

export {
  localStorage,
  clearLocalStorageCache,
  initializeLocalStorageKey,
} from './decorator/localStorage.ts';

export {
  sessionStorage,
  clearSessionStorageCache,
  initializeSessionStorageKey,
} from './decorator/sessionStorage.ts';

export {
  TrackedStorage,
  trackedLocalStorage,
  trackedSessionStorage,
  DEFAULT_PREFIX,
};
