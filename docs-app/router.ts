import EmberRouter from '@embroider/router';

export default class Router extends EmberRouter {
  location = 'history';
  rootURL = '/';
}

Router.map(function () {
  // comment is an example of how to define routes
  //
  // this.route('about');
  // this.route('map', function () {
  //   this.route('location', { path: '/location/:location_id' }, function () {
  //     this.route('artifact', function () {
  //       this.route('view', { path: '/:artifact_id' });
  //     });
  //     this.route('add-artifact', { path: '/artifact/edit' });
  //     this.route('edit');
  //   });
  // });
  // this.route('authenticated', { path: '' }, function () {
  //   this.route('profile');
  // });
});
