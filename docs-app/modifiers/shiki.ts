import { modifier } from 'ember-modifier';
import { codeToHtml } from 'shiki';

export const shiki = modifier((element: HTMLPreElement) => {
  const code = element.textContent || '';
  const language = element.getAttribute('data-language') || 'glimmer-ts';
  const theme = element.getAttribute('data-theme') || 'dark-plus';

  void (async () => {
    const highlightedCode = await codeToHtml(code, {
      lang: language,
      theme: theme,
    });
    element.innerHTML = highlightedCode;
  })();
});
