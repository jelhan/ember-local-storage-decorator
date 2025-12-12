import EmberRouter from '@embroider/router';

export default class Router extends EmberRouter {
  location = 'history';
  rootURL = '/';
}

Router.map(function () {
  this.route('tracked-storage');
  this.route('instances');
  this.route('decorators');
  this.route('testing');
});
