import { action } from '@ember/object';
import Component from '@glimmer/component';
import localStorage from 'ember-local-storage-decorator';

export default class TestComponentComponent extends Component {
  @localStorage
  foo: unknown;

  @localStorage
  bar: unknown;

  @action
  updateFoo() {
    this.foo = 'foo';
  }
}
