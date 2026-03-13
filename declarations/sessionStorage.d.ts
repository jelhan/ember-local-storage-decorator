import type { ElementDescriptor } from '@ember/-internals/metal';
declare const clearCache: () => void, initializeKey: (key: string) => void;
export default function sessionStorageDecoratorFactory(...args: ElementDescriptor): void;
export default function sessionStorageDecoratorFactory(): (target: object, key: string) => void;
export default function sessionStorageDecoratorFactory(customKey: string): (target: object, key: string) => void;
export { clearCache as clearSessionStorageCache, initializeKey as initializeSessionStorageKey, };
//# sourceMappingURL=sessionStorage.d.ts.map