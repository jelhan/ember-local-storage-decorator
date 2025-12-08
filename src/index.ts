export { default as localStorage } from './localStorage.ts';
export { default as sessionStorage } from './sessionStorage.ts';
export {
  clearLocalStorageCache,
  initializeLocalStorageKey,
} from './localStorage.ts';
export {
  clearSessionStorageCache,
  initializeSessionStorageKey,
} from './sessionStorage.ts';
export { TrackedStorage, DEFAULT_PREFIX } from './TrackedStorage.ts';

// Pre-instantiated TrackedStorage instances for convenience
import { TrackedStorage } from './TrackedStorage.ts';
export const trackedLocalStorage = new TrackedStorage(window.localStorage);
export const trackedSessionStorage = new TrackedStorage(window.sessionStorage);
