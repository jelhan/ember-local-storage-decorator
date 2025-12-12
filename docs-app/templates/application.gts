import { pageTitle } from 'ember-page-title';
import Component from '@glimmer/component';
import type Owner from '@ember/owner';

export default class Application extends Component {
  constructor(owner: Owner, args: Record<string, unknown>) {
    super(owner, args);
    owner.lookup('service:router-scroll');
  }
  <template>
    {{pageTitle "Ember Tracked Storage"}}

    {{outlet}}
  </template>
}
