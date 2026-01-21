import EmberApp from 'ember-strict-application-resolver';
import EmberRouter from './router.ts';
import PageTitleService from 'ember-page-title/services/page-title';
import RouterScrollService from '@nullvoxpopuli/ember-router-scroll/services/router-scroll';
import RouterService from '@ember/routing/router-service';
class Router extends EmberRouter {
  location = 'history';
  rootURL = '/';
}
export class App extends EmberApp {
  /**
   * Any services or anything from the addon that needs to be in the app-tree registry
   * will need to be manually specified here.
   *
   * Techniques to avoid needing this:
   * - private services
   * - require the consuming app import and configure themselves
   *   (which is what we're emulating here)
   */
  modules = {
    './router': Router,
    './services/page-title': PageTitleService,
    './services/router': RouterService,
    './services/router-scroll': RouterScrollService,
    /**
     * NOTE: this glob will import everything matching the glob,
     *     and includes non-services in the services directory.
     */
    ...import.meta.glob('./services/**/*', { eager: true }),
    /**
     * These imports are not magic, but we do require that all entries in the
     * modules object match a ./[type]/[name] pattern.
     *
     * See: https://rfcs.emberjs.com/id/1132-default-strict-resolver
     */
    ...import.meta.glob('./templates/**/*', { eager: true }),
  };
}
