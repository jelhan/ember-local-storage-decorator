import { LinkTo } from '@ember/routing';
import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { on } from '@ember/modifier';

export default class NavBar extends Component {
  @tracked isMenuOpen = false;

  toggleMenu = () => {
    this.isMenuOpen = !this.isMenuOpen;
  };

  closeMenu = () => {
    this.isMenuOpen = false;
  };

  <template>
    {{! Mobile menu button - floats on top }}
    <button
      type="button"
      class="mobile-menu-button {{if this.isMenuOpen 'menu-open'}}"
      {{on "click" this.toggleMenu}}
      aria-label="Toggle menu"
    >
      <span class="hamburger-line"></span>
      <span class="hamburger-line"></span>
      <span class="hamburger-line"></span>
    </button>

    <aside class="sidebar {{if this.isMenuOpen 'mobile-open'}}">
      <div class="sidebar-header">
        <LinkTo
          @route="index"
          class="sidebar-logo"
          {{on "click" this.closeMenu}}
        >
          <div class="logo-icon">📦</div>
          <div class="logo-text">
            <div class="logo-smaller">Ember</div>
            <div class="logo-larger">Tracked Storage</div>
          </div>
        </LinkTo>
      </div>

      <nav class="sidebar-nav">
        <ul class="nav-list">
          <li class="nav-section">
            <span class="section-title">Getting Started</span>
            <ul class="section-links">
              <li><LinkTo
                  @route="index"
                  {{on "click" this.closeMenu}}
                >Home</LinkTo></li>
            </ul>
          </li>

          <li class="nav-section">
            <span class="section-title">API Reference</span>
            <ul class="section-links">
              <li><LinkTo
                  @route="tracked-storage"
                  {{on "click" this.closeMenu}}
                >TrackedStorage</LinkTo></li>
              <li><LinkTo
                  @route="instances"
                  {{on "click" this.closeMenu}}
                >Pre-instantiated</LinkTo></li>
              <li><LinkTo
                  @route="decorators"
                  {{on "click" this.closeMenu}}
                >Decorators</LinkTo></li>
            </ul>
          </li>

          <li class="nav-section">
            <span class="section-title">Guides</span>
            <ul class="section-links">
              <li><LinkTo
                  @route="testing"
                  {{on "click" this.closeMenu}}
                >Testing</LinkTo></li>
            </ul>
          </li>

          <li class="nav-section">
            <span class="section-title">Links</span>
            <ul class="section-links">
              <li>
                <a
                  href="https://github.com/evoactivity/ember-local-storage-decorator"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="external-link"
                >
                  GitHub →
                </a>
              </li>
            </ul>
          </li>
        </ul>
      </nav>
    </aside>
  </template>
}
