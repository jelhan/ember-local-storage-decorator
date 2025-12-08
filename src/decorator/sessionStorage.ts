import type { ElementDescriptor } from '@ember/-internals/metal';
import { createStorageManager } from './manager.ts';

const { decoratorFactory, clearCache, initializeKey } = createStorageManager(
  window.sessionStorage,
);

export default function sessionStorageDecoratorFactory(
  ...args: ElementDescriptor
): void;
export default function sessionStorageDecoratorFactory(): (
  target: object,
  key: string,
) => void;
export default function sessionStorageDecoratorFactory(
  customKey: string,
): (target: object, key: string) => void;
export default function sessionStorageDecoratorFactory(
  ...args: unknown[]
): unknown {
  return decoratorFactory(...args);
}

export {
  clearCache as clearSessionStorageCache,
  initializeKey as initializeSessionStorageKey,
};
