import { action } from '@ember/object';
import Component from '@glimmer/component';
import localStorage from 'ember-local-storage-decorator';

export default class TestComponentComponent extends Component {
  @localStorage
  foo;

  @localStorage
  bar;

  @action
  updateFoo() {
    this.foo = 'foo';
  }
}
