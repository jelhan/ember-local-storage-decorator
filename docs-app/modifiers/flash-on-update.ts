import { modifier } from 'ember-modifier';

export const flashOnUpdate = modifier((element: HTMLElement) => {
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      // Find the closest tr element to the mutation target
      const target = mutation.target as HTMLElement;
      if (target === element) {
        return;
      }

      const row = target.parentElement?.closest('tr');

      if (!row) {
        return;
      }

      // Force remove the class to restart animation if it's already playing
      row.classList.remove('flash-update');

      // Trigger reflow to restart the animation
      void row.offsetWidth;

      row.classList.add('flash-update');

      const handleAnimationEnd = () => {
        row.classList.remove('flash-update');
        row.removeEventListener('animationend', handleAnimationEnd);
      };

      row.addEventListener('animationend', handleAnimationEnd);
    });
  });

  observer.observe(element, {
    childList: true,
    subtree: true,
    characterData: true,
  });

  return () => {
    observer.disconnect();
  };
});
