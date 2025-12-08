export {
  default as localStorage,
  clearLocalStorageCache,
  initializeLocalStorageKey,
} from './decorator/localStorage.ts';

export {
  default as sessionStorage,
  clearSessionStorageCache,
  initializeSessionStorageKey,
} from './decorator/sessionStorage.ts';

export { TrackedStorage, DEFAULT_PREFIX } from './TrackedStorage.ts';

// Pre-instantiated TrackedStorage instances for convenience
import { TrackedStorage } from './TrackedStorage.ts';
export const trackedLocalStorage = new TrackedStorage(window.localStorage);
export const trackedSessionStorage = new TrackedStorage(window.sessionStorage);
