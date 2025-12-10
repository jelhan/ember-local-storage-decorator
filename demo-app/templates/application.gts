import Component from '@glimmer/component';
import { localStorage } from '#src/index.ts';
import { pageTitle } from 'ember-page-title';
import type Owner from '@ember/owner';

const greetingInLanguages = [
  'Hello', // English
  'Hola', // Spanish
  'Bonjour', // French
  'Hallo', // German
  'Ciao', // Italian
  'こんにちは', // Japanese
  '안녕하세요', // Korean
  '你好', // Chinese (Mandarin)
  'Привет', // Russian
  'مرحبا', // Arabic
];
export default class Application extends Component {
  @localStorage greeting = 'Hello';

  constructor(owner: Owner, args: Record<string, unknown>) {
    super(owner, args);

    setInterval(() => {
      const randomIndex = Math.floor(
        Math.random() * greetingInLanguages.length,
      );
      this.greeting = greetingInLanguages[randomIndex] ?? 'Hello';
    }, 1000);
  }

  <template>
    {{pageTitle "Demo App"}}

    <h1>Welcome to ember!</h1>

    {{this.greeting}}, world!
  </template>
}
